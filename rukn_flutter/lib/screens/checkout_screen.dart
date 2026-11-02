import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../models/customer.dart';
import '../services/account_service.dart';
import '../services/checkout_service.dart';
import '../services/national_address.dart';
import '../services/site_analytics.dart';
import '../services/store_settings.dart';
import '../services/ups_coverage.dart';
import '../state/auth_state.dart';
import '../state/cart_state.dart';
import '../widgets/common.dart';
import '../widgets/national_address_form.dart';
import 'cart_screen.dart';
import 'payment_webview_screen.dart';

const _maxReceiptBytes = 5 * 1024 * 1024;

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _step = 0; // 0 info · 1 payment · 2 done
  final _form = CheckoutForm();
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController();
  late final _email = TextEditingController();
  late final _phone = TextEditingController();
  late final _city = TextEditingController();
  late final _address = TextEditingController();
  final _sender = TextEditingController();

  OrderingStatus _ordering = OrderingStatus.openStatus;
  DeliveryOptions? _delivery;
  bool _loadingDelivery = true;
  DeliveryChoice? _choice;
  bool _vaultAvailable = false;
  String? _vaultBranch;
  NationalAddressDraft? _national;
  List<CustomerAddress> _saved = [];

  // UPS coverage of the shipping address; null = covered, or not known yet.
  UpsCoverage? _coverage;
  String _district = '';
  Timer? _coverageTimer;
  int _coverageSeq = 0;

  PaymentMethods? _methods;
  String _method = 'bank_transfer';
  BankTransferProof? _receipt;
  String? _receiptLabel;
  bool _submitting = false;
  String? _error;

  // Result
  String? _orderNumber;
  String? _placedMethod;
  String _paymobState = 'idle'; // idle | waiting | slow | failed
  /// The total of the order being placed, for the analytics purchase event.
  double _checkoutTotal = 0;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartState>();
    cart.reprice();
    if (!cart.isEmpty) SiteAnalytics.shared.checkoutStarted(cart.subtotal);
    StoreSettings.orderingStatus().then((s) {
      if (mounted) setState(() => _ordering = s);
    });
    CheckoutService.deliveryOptions(cart.items.map((i) => i.productId).toSet().toList()).then((d) {
      if (!mounted) return;
      setState(() {
        _delivery = d;
        _loadingDelivery = false;
        _settleCarrier();
      });
    });
    final customer = context.read<AuthState>().customer;
    if (customer != null) {
      _name.text = customer.fullName;
      _email.text = customer.email ?? '';
      _phone.text = customer.phone ?? '';
      AccountService.listAddresses().then((a) {
        if (!mounted) return;
        setState(() => _saved = a);
        final def = a.where((x) => x.isDefaultShipping).firstOrNull ?? a.firstOrNull;
        if (def != null) _applySaved(def);
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _coverageTimer?.cancel();
    for (final c in [_name, _email, _phone, _city, _address, _sender]) {
      c.dispose();
    }
    super.dispose();
  }

  void _applySaved(CustomerAddress a) {
    setState(() {
      if (a.fullName.isNotEmpty) _name.text = a.fullName;
      if ((a.phone ?? '').isNotEmpty) _phone.text = a.phone!;
      _city.text = a.city ?? '';
      _address.text = [a.address1, a.address2].where((e) => (e ?? '').isNotEmpty).join(' - ');
      final draft = NationalAddressDraft.fromCustomerAddress(a);
      _national = draft.isComplete ? draft : null;
      _district = draft.district;
    });
    _resolveVault();
    _scheduleCoverage();
  }

  /// The carrier the address calls for: UPS, or SMSA where UPS does not reach it.
  String _carrier(DeliveryOptions d) => deliveryCarrier(_coverage, d.smsa.isNotEmpty);

  List<ShippingOptionInfo> _carrierOptions(DeliveryOptions d) => _carrier(d) == 'smsa' ? d.smsa : d.ups;

  /// The UPS «not available» message, when UPS is the carrier the address calls for and cannot reach it.
  String? _upsUncovered(DeliveryOptions? d, String lang) =>
      d == null || _carrier(d) != 'ups' ? null : uncoveredMessage(_coverage, lang);

  /// Keeps the delivery choice on the carrier the address calls for, both ways. The same option is
  /// kept when the new carrier still offers it, else the first option of that carrier is taken.
  /// A pickup choice is left alone. Call inside setState.
  void _settleCarrier() {
    final d = _delivery;
    final current = _choice;
    if (d == null || current?.kind == 'pickup') return;
    final carrier = _carrier(d);
    final options = carrier == 'smsa' ? d.smsa : d.ups;
    if (options.isEmpty) {
      _choice = null;
      return;
    }
    final kept = current == null ? null : options.where((o) => o.optionId == current.optionId).firstOrNull;
    final option = kept ?? options.first;
    _choice = DeliveryChoice(
      optionId: option.optionId,
      kind: carrier,
      name: option.name,
      amount: option.amount,
      freeOver: option.freeOver,
      vault: current?.kind == carrier && current!.vault,
    );
  }

  /// Debounced: the address is still being typed.
  void _scheduleCoverage() {
    _coverageSeq++; // any reply still in flight is for an address that has changed
    _coverageTimer?.cancel();
    _coverageTimer = Timer(const Duration(milliseconds: 500), _checkCoverage);
  }

  Future<void> _checkCoverage() async {
    final seq = _coverageSeq;
    final before = _choice?.kind;
    final result = await fetchUpsCoverage(_city.text.trim(), _district.trim());
    if (!mounted || seq != _coverageSeq) return;
    setState(() {
      _coverage = result;
      _settleCarrier();
    });
    if (_choice?.kind != before) _resolveVault();
  }

  Future<void> _resolveVault() async {
    final choice = _choice;
    if (choice == null || choice.kind == 'pickup') {
      setState(() => _vaultAvailable = false);
      return;
    }
    final ids = context.read<CartState>().items.map((i) => i.productId).toSet().toList();
    final r = await CheckoutService.resolveFulfillmentBranch(ids, kind: 'ship', city: _city.text.trim());
    if (!mounted) return;
    final i18n = context.i18nRead;
    setState(() {
      _vaultAvailable = r != null && r.ok && r.vaultAvailable;
      _vaultBranch = r == null ? null : i18n.pick(r.branchName, r.branchNameEn);
      if (!_vaultAvailable && (_choice?.vault ?? false)) _choice = _withVault(_choice!, false);
    });
  }

  DeliveryChoice _withVault(DeliveryChoice c, bool vault) => DeliveryChoice(
        optionId: c.optionId,
        kind: c.kind,
        name: c.name,
        amount: c.amount,
        freeOver: c.freeOver,
        branchId: c.branchId,
        branchName: c.branchName,
        vault: vault,
      );

  Future<void> _toPayment() async {
    final i18n = context.i18nRead;
    if (!_formKey.currentState!.validate()) return;
    if (_choice == null) {
      showSnack(context, i18n.t('chooseDelivery'), error: true);
      return;
    }
    final uncovered = _upsUncovered(_delivery, i18n.lang);
    if (_choice!.kind == 'ups' && uncovered != null) {
      showSnack(context, uncovered, error: true);
      return;
    }
    _form
      ..name = _name.text.trim()
      ..email = _email.text.trim()
      ..phone = _phone.text.trim()
      ..city = _choice!.kind == 'pickup' ? (_city.text.trim().isEmpty ? 'Riyadh' : _city.text.trim()) : _city.text.trim()
      ..address = _address.text.trim().isEmpty && _choice!.kind == 'pickup' ? (_choice!.branchName ?? '-') : _address.text.trim()
      ..nationalAddress = _national;
    setState(() {
      _step = 1;
      _error = null;
    });
    final methods = await CheckoutService.paymentMethods(_choice?.kind == 'pickup' ? _choice?.branchId : null);
    if (!mounted) return;
    setState(() {
      _methods = methods;
      if (!methods.isEnabled(_method)) {
        _method = ['bank_transfer', 'paymob', 'cod'].firstWhere(methods.isEnabled, orElse: () => _method);
      }
    });
  }

  Future<void> _pickReceipt(String source) async {
    final i18n = context.i18nRead;
    try {
      String? name;
      List<int>? bytes;
      String? mime;
      if (source == 'pdf') {
        final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
        final f = res.firstOrNull;
        if (f == null) return;
        name = f.name;
        bytes = await f.readAsBytes();
        mime = 'application/pdf';
      } else {
        final x = await ImagePicker().pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 2000,
          maxHeight: 2000,
          imageQuality: 82,
        );
        if (x == null) return;
        name = x.name;
        bytes = await x.readAsBytes();
        final lower = x.name.toLowerCase();
        mime = lower.endsWith('.png')
            ? 'image/png'
            : lower.endsWith('.webp')
                ? 'image/webp'
                : (lower.endsWith('.heic') || lower.endsWith('.heif'))
                    ? 'image/heic'
                    : 'image/jpeg';
      }
      if (bytes.length > _maxReceiptBytes) {
        if (mounted) showSnack(context, i18n.t('receiptTooLarge'), error: true);
        return;
      }
      setState(() {
        _receipt = BankTransferProof(senderName: _sender.text.trim(), base64: base64Encode(bytes!), mimeType: mime!, filename: name ?? 'receipt');
        _receiptLabel = '$name · ${(bytes.length / 1024).toStringAsFixed(0)} KB';
      });
    } catch (_) {
      if (mounted) showSnack(context, i18n.t('receiptReadFailed'), error: true);
    }
  }

  String _errorMessage(Object e) {
    final i18n = context.i18nRead;
    if (e is CheckoutError) {
      return switch (e.code) {
        'no_shipping_options' || 'delivery_option_unavailable' => i18n.t('checkoutNoShipping'),
        'paymob_session_unavailable' => i18n.t('checkoutPaymobUnavailable'),
        'bank_transfer_proof_required' => i18n.t('bankProofRequired'),
        'receipt_upload_failed' => i18n.t('receiptUploadFailed'),
        'cart_has_no_purchasable_items' => i18n.t('productUnavailable'),
        _ => e.message ?? i18n.t('orderFailed'),
      };
    }
    if (e is MedusaError && e.message != null) return e.message!;
    return i18n.t('orderFailed');
  }

  Future<void> _confirm() async {
    final i18n = context.i18nRead;
    final cart = context.read<CartState>();
    if (_method == 'bank_transfer' && (_receipt == null || _sender.text.trim().isEmpty)) {
      setState(() => _error = i18n.t('bankProofRequired'));
      return;
    }
    haptic(Haptic.medium);
    setState(() {
      _submitting = true;
      _error = null;
    });
    await cart.reprice();
    final items = cart.items;
    final subtotal = cart.subtotal;
    _checkoutTotal = subtotal + (_choice?.feeFor(subtotal) ?? 0) + (_method == 'paymob' && (_methods?.paymobAvailable ?? false) ? _methods!.cardFee(subtotal) : 0);
    SiteAnalytics.shared.paymentInfoSubmitted(_checkoutTotal);
    try {
      if (_method == 'paymob') {
        final redirect = await CheckoutService.startPaymob(items: items, form: _form, delivery: _choice);
        if (!mounted) return;
        await PaymentWebViewScreen.open(context, redirect.checkoutUrl, title: i18n.t('securePayment'));
        if (!mounted) return;
        await _pollPaymob(redirect);
        return;
      }
      final proof = _method == 'bank_transfer' && _receipt != null
          ? BankTransferProof(senderName: _sender.text.trim(), base64: _receipt!.base64, mimeType: _receipt!.mimeType, filename: _receipt!.filename)
          : null;
      final order = await CheckoutService.placeOrder(items: items, form: _form, paymentMethod: _method, delivery: _choice, proof: proof);
      SiteAnalytics.shared.checkoutCompleted(orderId: order.displayId, value: _checkoutTotal);
      cart.clear();
      if (!mounted) return;
      setState(() {
        _orderNumber = order.displayId;
        _placedMethod = _method;
        _step = 2;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _errorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Asks the backend (never the redirect) whether the card payment went through.
  Future<void> _pollPaymob(PaymobRedirect redirect) async {
    setState(() => _paymobState = 'waiting');
    final started = DateTime.now();
    while (mounted) {
      final elapsed = DateTime.now().difference(started);
      try {
        final s = await CheckoutService.paymobStatus(redirect.paymentSessionId);
        if (s.state == 'paid' && s.orderDisplayId != null) return _paymobSucceeded(s.orderDisplayId!);
        if (s.state == 'failed') {
          if (mounted) setState(() => _paymobState = 'failed');
          return;
        }
      } catch (_) {
        // a transient poll error is not a failed payment
      }
      if (elapsed > const Duration(seconds: 6)) {
        final order = await CheckoutService.completePaymobCart(redirect.cartId);
        if (order != null) return _paymobSucceeded(order.displayId);
      }
      if (elapsed > const Duration(seconds: 90)) {
        // Not "failed": we do not know the customer was not charged.
        if (mounted) setState(() => _paymobState = 'slow');
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  void _paymobSucceeded(String displayId) {
    SiteAnalytics.shared.checkoutCompleted(orderId: displayId, value: _checkoutTotal);
    if (!mounted) return;
    context.read<CartState>().clear();
    setState(() {
      _orderNumber = displayId;
      _placedMethod = 'paymob';
      _paymobState = 'idle';
      _step = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final cart = context.watch<CartState>();

    if (_step == 2) return _done(i18n);
    if (_paymobState != 'idle') return _paymobWaiting(i18n);
    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(i18n.t('checkout'))),
        body: MessageState(icon: Icons.shopping_bag_outlined, title: i18n.t('cartEmpty'), action: () => context.go('/'), actionLabel: i18n.t('continueShopping')),
      );
    }

    return PopScope(
      canPop: _step == 0 && !_submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == 1 && !_submitting) setState(() => _step = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(i18n.t('checkout')),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(36),
            child: _StepBar(step: _step, labels: [i18n.t('stepShipping'), i18n.t('stepPayment'), i18n.t('stepConfirmation')]),
          ),
        ),
        body: !_ordering.open
            ? ListView(padding: const EdgeInsets.all(16), children: [OrderingClosedNotice(status: _ordering)])
            : (_step == 0 ? _infoStep(i18n, cart) : _paymentStep(i18n, cart)),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  Widget _infoStep(I18n i18n, CartState cart) {
    final d = _delivery;
    String? required(String? v) => (v ?? '').trim().isEmpty ? i18n.t('fieldRequired') : null;
    final pickup = _choice?.kind == 'pickup';
    final uncoveredText = d == null ? null : _upsUncovered(d, i18n.lang);
    final upsBlocked = _choice?.kind == 'ups' && uncoveredText != null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionLabel(i18n.t('contactDetails')),
          TextFormField(controller: _name, decoration: InputDecoration(hintText: i18n.t('fullName')), validator: required),
          const SizedBox(height: 10),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: i18n.t('email')),
            validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : i18n.t('emailInvalid'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(hintText: i18n.t('phoneNumber')),
            validator: (v) => toWesternDigits(v ?? '').replaceAll(RegExp(r'\D'), '').length >= 8 ? null : i18n.t('phoneInvalid'),
          ),
          const SizedBox(height: 22),
          SectionLabel(i18n.t('deliveryMethod')),
          if (_loadingDelivery)
            const LoadingView()
          else if (d == null)
            Text(i18n.t('deliveryOptionsFailed'), style: const TextStyle(color: AppColors.error))
          else ...[
            for (final u in _carrierOptions(d)) _carrierCard(i18n, cart, d, u),
            if (d.pickupAvailable && d.pickupOptionId != null) ...[
              if (d.branches.isEmpty)
                _RadioCard(
                  selected: pickup,
                  icon: Icons.storefront_outlined,
                  title: i18n.t('pickupFromBranch'),
                  subtitle: [i18n.pick(d.pickupBranchNameAr, d.pickupBranchNameEn), d.pickupAddressAr].where((e) => e.isNotEmpty).join(' · '),
                  trailing: Text(i18n.t('free'), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                  onTap: () => setState(() => _choice = DeliveryChoice(
                      optionId: d.pickupOptionId!, kind: 'pickup', name: i18n.t('pickupFromBranch'), amount: d.pickupAmount,
                      branchName: i18n.pick(d.pickupBranchNameAr, d.pickupBranchNameEn))),
                )
              else
                for (final b in d.branches)
                  _RadioCard(
                    selected: pickup && _choice?.branchId == b.id,
                    icon: Icons.storefront_outlined,
                    title: '${i18n.t('pickupFrom')} ${i18n.pick(b.name, b.nameEn)}',
                    subtitle: [b.addressAr, i18n.pick(b.hoursAr, b.hoursEn)].where((e) => e.isNotEmpty).join(' · '),
                    trailing: Text(i18n.t('free'), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                    onTap: () => setState(() {
                      _choice = DeliveryChoice(
                          optionId: d.pickupOptionId!, kind: 'pickup', name: i18n.pick(b.name, b.nameEn), amount: d.pickupAmount,
                          branchId: b.id, branchName: b.name);
                      _city.text = b.city;
                      _scheduleCoverage();
                    }),
                  ),
            ] else if (d.pickupRestrictionAr != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(d.pickupRestrictionAr!, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ),
          ],
          if (!pickup) ...[
            const SizedBox(height: 22),
            SectionLabel(
              i18n.t('shippingAddress'),
              trailing: _saved.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () async {
                        final picked = await showModalBottomSheet<CustomerAddress>(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                for (final a in _saved)
                                  ListTile(
                                    leading: const Icon(Icons.place_outlined),
                                    title: Text(a.addressName ?? a.fullName),
                                    subtitle: Text([a.address1, a.city].where((e) => (e ?? '').isNotEmpty).join(' · ')),
                                    onTap: () => Navigator.pop(ctx, a),
                                  ),
                              ],
                            ),
                          ),
                        );
                        if (picked != null) _applySaved(picked);
                      },
                      child: Text(i18n.t('savedAddresses')),
                    ),
            ),
            NationalAddressForm(
              initial: _national,
              onChanged: (draft) {
                _national = draft != null && draft.isComplete ? draft : null;
                _district = draft?.district ?? '';
                _scheduleCoverage();
                if (draft != null && draft.isComplete) {
                  if (_city.text.trim().isEmpty || draft.verified) _city.text = draft.city;
                  if (_address.text.trim().isEmpty || draft.verified) _address.text = draft.format(i18n.lang);
                  _resolveVault();
                }
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _city,
              decoration: InputDecoration(hintText: i18n.t('city')),
              validator: required,
              onChanged: (_) => _scheduleCoverage(),
              onEditingComplete: _resolveVault,
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _address, maxLines: 2, decoration: InputDecoration(hintText: i18n.t('deliveryAddress')), validator: required),
            if (_vaultAvailable && _choice != null) ...[
              const SizedBox(height: 14),
              CardBox(
                color: AppColors.cream,
                borderColor: AppColors.goldBorder,
                padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.darkGreen,
                  value: _choice!.vault,
                  onChanged: (v) => setState(() => _choice = _withVault(_choice!, v ?? false)),
                  title: Text(i18n.t('vaultLabel'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(i18n.t('vaultHint', {'branch': _vaultBranch ?? i18n.t('theBranch')}), style: const TextStyle(fontSize: 12, height: 1.5)),
                ),
              ),
            ],
          ],
          const SizedBox(height: 22),
          _Summary(cart: cart, delivery: _choice, cardFee: 0),
          const SizedBox(height: 16),
          if (upsBlocked) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFECACA)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(uncoveredText, style: const TextStyle(color: AppColors.error, fontSize: 13, height: 1.5)),
            ),
            const SizedBox(height: 10),
          ],
          GoldButton(label: i18n.t('continueToPayment'), onPressed: (_choice == null || upsBlocked) ? null : _toPayment),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// One option of the carrier the address calls for. An uncovered UPS option stays tappable (the
  /// address form is below it, and the customer may need to correct the address) but is dimmed.
  Widget _carrierCard(I18n i18n, CartState cart, DeliveryOptions d, ShippingOptionInfo u) {
    final carrier = _carrier(d);
    final uncovered = _upsUncovered(d, i18n.lang);
    final smsaNotice = carrier == 'smsa' ? uncoveredMessage(_coverage, i18n.lang) : null;
    final freeOverText = u.freeOver != null && u.freeOver! > 0
        ? i18n.t('freeShippingOver', {'amount': formatSar(u.freeOver!, i18n.lang)})
        : null;
    return _RadioCard(
      selected: _choice?.optionId == u.optionId && _choice?.kind == carrier,
      icon: Icons.local_shipping_outlined,
      title: u.name,
      subtitle: [
        if (carrier == 'smsa') i18n.t('deliverySmsaDesc'),
        ?freeOverText,
      ].join('\n'),
      notice: smsaNotice ?? (uncovered == null ? null : i18n.t('deliveryNotForAddress')),
      noticeColor: smsaNotice != null ? const Color(0xFFA8830A) : AppColors.error,
      dimmed: uncovered != null,
      trailing: (u.freeOver != null && cart.subtotal >= u.freeOver!)
          ? Text(i18n.t('free'), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700))
          : Price(u.amount, style: const TextStyle(fontWeight: FontWeight.w700)),
      onTap: () {
        setState(() => _choice = DeliveryChoice(optionId: u.optionId, kind: carrier, name: u.name, amount: u.amount, freeOver: u.freeOver));
        _resolveVault();
      },
    );
  }

  Widget _paymentStep(I18n i18n, CartState cart) {
    final m = _methods;
    if (m == null) return const LoadingView();
    if (!m.anyEnabled) return MessageState(icon: Icons.payments_outlined, title: i18n.t('noPaymentMethods'));
    final subtotal = cart.subtotal;
    final cardFee = _method == 'paymob' && m.paymobAvailable ? m.cardFee(subtotal) : 0.0;
    final potentialFee = m.paymobAvailable ? m.cardFee(subtotal) : 0.0;
    final discountPct = potentialFee > 0 ? ((potentialFee / (subtotal + potentialFee)) * 1000).round() / 10 : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionLabel(i18n.t('paymentMethod')),
        if (m.bankTransferEnabled)
          _RadioCard(
            selected: _method == 'bank_transfer',
            icon: Icons.account_balance_outlined,
            title: i18n.t('bankTransfer'),
            subtitle: discountPct > 0 ? i18n.t('directDiscount', {'percent': discountPct}) : i18n.t('bankTransferDesc'),
            onTap: () => setState(() => _method = 'bank_transfer'),
          )
        else if (m.bankUnavailableReason != null)
          Text(m.bankUnavailableReason!, style: const TextStyle(color: AppColors.muted)),
        if (_method == 'bank_transfer' && m.bankTransferEnabled) _bankDetails(i18n, m),
        if (m.paymobAvailable)
          _RadioCard(
            selected: _method == 'paymob',
            icon: Icons.credit_card,
            title: i18n.pick(m.paymobNameAr, m.paymobNameEn).isNotEmpty ? i18n.pick(m.paymobNameAr, m.paymobNameEn) : i18n.t('cardPayment'),
            subtitle: potentialFee > 0 ? i18n.t('cardFeeNote', {'fee': formatSar(potentialFee, i18n.lang)}) : null,
            onTap: () => setState(() => _method = 'paymob'),
          ),
        if (m.codEnabled)
          _RadioCard(
            selected: _method == 'cod',
            icon: Icons.payments_outlined,
            title: i18n.t('cashOnDelivery'),
            subtitle: i18n.t('cashOnDeliveryDesc'),
            onTap: () => setState(() => _method = 'cod'),
          ),
        const SizedBox(height: 18),
        _Summary(cart: cart, delivery: _choice, cardFee: cardFee),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 16),
        GoldButton(
          label: _method == 'paymob' ? i18n.t('payNow') : i18n.t('placeOrder'),
          loading: _submitting,
          onPressed: _confirm,
        ),
        TextButton(onPressed: _submitting ? null : () => setState(() => _step = 0), child: Text(i18n.t('backToShipping'))),
      ],
    );
  }

  Widget _bankDetails(I18n i18n, PaymentMethods m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardBox(
        color: AppColors.cream,
        borderColor: AppColors.goldBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (m.bankAccounts.isEmpty)
              Text(i18n.t('bankDetailsByEmail'), style: const TextStyle(fontSize: 13))
            else
              for (final a in m.bankAccounts) ...[
                Text(a.bankName, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(a.accountName, style: const TextStyle(fontSize: 13)),
                _CopyRow(label: i18n.t('accountNumber'), value: a.accountNumber),
                _CopyRow(label: 'IBAN', value: a.iban),
                const SizedBox(height: 8),
              ],
            const Divider(),
            const SizedBox(height: 8),
            TextField(controller: _sender, decoration: InputDecoration(hintText: i18n.t('senderName'), fillColor: Colors.white)),
            const SizedBox(height: 10),
            Text(i18n.t('uploadReceipt'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(avatar: const Icon(Icons.photo_library_outlined, size: 18), label: Text(i18n.t('gallery')), onPressed: () => _pickReceipt('gallery')),
                ActionChip(avatar: const Icon(Icons.photo_camera_outlined, size: 18), label: Text(i18n.t('camera')), onPressed: () => _pickReceipt('camera')),
                ActionChip(avatar: const Icon(Icons.picture_as_pdf_outlined, size: 18), label: const Text('PDF'), onPressed: () => _pickReceipt('pdf')),
              ],
            ),
            if (_receiptLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_receiptLabel!, style: const TextStyle(fontSize: 12.5))),
                ]),
              ),
            const SizedBox(height: 6),
            Text(i18n.t('bankTransferNote'), style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _paymobWaiting(I18n i18n) {
    final (icon, title, body, color) = switch (_paymobState) {
      'failed' => (Icons.cancel_outlined, i18n.t('paymentFailedTitle'), i18n.t('paymentFailedBody'), AppColors.error),
      'slow' => (Icons.hourglass_bottom, i18n.t('paymentSlowTitle'), i18n.t('paymentSlowBody'), AppColors.warning),
      _ => (Icons.lock_clock_outlined, i18n.t('paymentConfirmingTitle'), i18n.t('paymentConfirmingBody'), AppColors.darkGreen),
    };
    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('checkout')), automaticallyImplyLeading: _paymobState != 'waiting'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_paymobState == 'waiting') const CircularProgressIndicator(color: AppColors.darkGreen) else Icon(icon, size: 64, color: color),
              const SizedBox(height: 18),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.6)),
              const SizedBox(height: 22),
              if (_paymobState == 'failed')
                GoldButton(label: i18n.t('tryAgain'), onPressed: () => setState(() => _paymobState = 'idle')),
              if (_paymobState == 'slow') ...[
                GoldButton(label: i18n.t('orderHistory'), onPressed: () => context.pushReplacement('/orders')),
                TextButton(onPressed: () => setState(() => _paymobState = 'idle'), child: Text(i18n.t('backToPayment'))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _done(I18n i18n) {
    final note = switch (_placedMethod) {
      'bank_transfer' => i18n.t('confirmBankNote'),
      'cod' => i18n.t('confirmCodNote'),
      _ => i18n.t('confirmPaidNote'),
    };
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(i18n.t('stepConfirmation'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline, size: 80, color: AppColors.primary),
              const SizedBox(height: 14),
              Text(i18n.t('orderSuccessTitle'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(i18n.t('orderSuccessSubtitle'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 18),
              CardBox(
                child: Column(children: [
                  Text(i18n.t('orderNumberLabel'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  Text('#$_orderNumber', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(height: 14),
              Text(note, textAlign: TextAlign.center, style: const TextStyle(height: 1.6)),
              const SizedBox(height: 24),
              GoldButton(label: i18n.t('continueShopping'), onPressed: () => context.go('/')),
              if (context.watch<AuthState>().isSignedIn)
                TextButton(onPressed: () => context.pushReplacement('/orders'), child: Text(i18n.t('orderHistory'))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart, required this.delivery, required this.cardFee});
  final CartState cart;
  final DeliveryChoice? delivery;
  final double cardFee;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final subtotal = cart.subtotal;
    final shipping = delivery?.feeFor(subtotal) ?? 0;
    final total = subtotal + shipping + cardFee;
    return CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(i18n.t('orderSummary')),
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(
                  child: Text('${item.quantity} × ${item.name.of(i18n.lang)}${item.optionLabel == null ? '' : ' (${item.optionLabel})'}',
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ),
                const SizedBox(width: 8),
                Price(item.lineTotal, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          const Divider(height: 18),
          InfoRow(label: i18n.t('subtotal'), valueWidget: Price(subtotal)),
          if (delivery != null)
            InfoRow(
              label: i18n.t('shipping'),
              valueWidget: shipping == 0 ? Text(i18n.t('free'), style: const TextStyle(color: AppColors.success)) : Price(shipping),
            ),
          if (cardFee > 0) InfoRow(label: i18n.t('cardFee'), valueWidget: Price(cardFee)),
          const Divider(height: 18),
          InfoRow(
            label: i18n.t('cartTotal'),
            highlight: true,
            valueWidget: Price(total, style: const TextStyle(fontSize: 17, color: AppColors.darkGreen, fontWeight: FontWeight.w800)),
          ),
          Text(i18n.t('pricesIncludeVat'), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.selected,
    required this.icon,
    required this.title,
    this.subtitle,
    this.notice,
    this.noticeColor = AppColors.error,
    this.dimmed = false,
    this.trailing,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? notice;
  final Color noticeColor;
  final bool dimmed;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: dimmed ? 0.6 : 1,
        child: CardBox(
          color: selected ? const Color(0xFFFFFAF0) : Colors.white,
          borderColor: selected ? AppColors.primary : AppColors.border,
          onTap: () {
            haptic();
            onTap();
          },
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.darkGreen : AppColors.muted),
              const SizedBox(width: 10),
              Icon(icon, color: AppColors.darkGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4)),
                    if (notice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(notice!, style: TextStyle(color: noticeColor, fontSize: 12.5, height: 1.4)),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
        Expanded(child: SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value.replaceAll(' ', '')));
            showSnack(context, context.i18nRead.t('copied'));
          },
        ),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.labels});
  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            CircleAvatar(
              radius: 11,
              backgroundColor: i <= step ? AppColors.darkGreen : AppColors.border,
              child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: i <= step ? AppColors.primary : AppColors.muted)),
            ),
            const SizedBox(width: 6),
            Text(labels[i], style: TextStyle(fontSize: 12, fontWeight: i == step ? FontWeight.w700 : FontWeight.w400)),
            if (i < labels.length - 1) const Expanded(child: Divider(indent: 8, endIndent: 8)),
          ],
        ],
      ),
    );
  }
}
