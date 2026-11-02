import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../models/customer.dart';
import '../services/account_service.dart';
import '../services/loyalty_service.dart';
import '../services/national_address.dart';
import '../services/phone.dart';
import '../state/auth_state.dart';
import '../widgets/common.dart';
import '../widgets/national_address_form.dart';
import 'auth_screen.dart';

/// Screens that need a session show a sign-in prompt instead of an error.
class SignInRequired extends StatelessWidget {
  const SignInRequired({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return MessageState(
      icon: Icons.lock_outline,
      title: message ?? i18n.t('signInRequired'),
      action: () => context.push('/auth'),
      actionLabel: i18n.t('signIn'),
    );
  }
}

// ---------------------------------------------------------------------------
// Account details
// ---------------------------------------------------------------------------

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  bool _savingName = false;
  bool _savingEmail = false;

  @override
  void initState() {
    super.initState();
    final c = context.read<AuthState>().customer;
    _first.text = c?.firstName ?? '';
    _last.text = c?.lastName ?? '';
    _email.text = c?.email ?? '';
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final i18n = context.i18nRead;
    if (_first.text.trim().isEmpty) return showSnack(context, i18n.t('authInvalidName'), error: true);
    setState(() => _savingName = true);
    try {
      final c = await AccountService.updateName(_first.text.trim(), _last.text.trim());
      if (!mounted) return;
      context.read<AuthState>().setCustomer(c);
      showSnack(context, i18n.t('saved'));
    } catch (e) {
      if (mounted) showSnack(context, authErrorMessage(e, i18n), error: true);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _saveEmail() async {
    final i18n = context.i18nRead;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      return showSnack(context, i18n.t('emailInvalid'), error: true);
    }
    setState(() => _savingEmail = true);
    try {
      final c = await AccountService.changeEmail(_email.text.trim());
      if (!mounted) return;
      context.read<AuthState>().setCustomer(c);
      showSnack(context, i18n.t('saved'));
    } catch (e) {
      if (mounted) showSnack(context, authErrorMessage(e, i18n), error: true);
    } finally {
      if (mounted) setState(() => _savingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final c = context.watch<AuthState>().customer;
    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('accountDetails'))),
      body: c == null
          ? const SignInRequired()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionLabel(i18n.t('name')),
                Row(children: [
                  Expanded(child: TextField(controller: _first, decoration: InputDecoration(hintText: i18n.t('firstName')))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _last, decoration: InputDecoration(hintText: i18n.t('lastName')))),
                ]),
                const SizedBox(height: 10),
                GoldButton(label: i18n.t('save'), loading: _savingName, onPressed: _saveName),
                const SizedBox(height: 28),
                SectionLabel(i18n.t('email')),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: i18n.t('email'))),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: _savingEmail ? null : _saveEmail, child: Text(i18n.t('updateEmail'))),
                const SizedBox(height: 28),
                SectionLabel(i18n.t('phoneNumber')),
                CardBox(
                  child: Row(children: [
                    const Icon(Icons.phone_iphone, color: AppColors.darkGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(c.phone == null ? '—' : nationalPhoneOf(c.phone), textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                    ),
                    TextButton(
                      onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const _ChangePhoneSheet()),
                      child: Text(i18n.t('change')),
                    ),
                  ]),
                ),
                if (c.createdAt != null) ...[
                  const SizedBox(height: 20),
                  Text(i18n.t('memberSince', {'date': formatDate(c.createdAt, i18n.lang)}), style: const TextStyle(color: AppColors.muted)),
                ],
              ],
            ),
    );
  }
}

class _ChangePhoneSheet extends StatefulWidget {
  const _ChangePhoneSheet();

  @override
  State<_ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends State<_ChangePhoneSheet> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String _dial = '966';
  String? _e164;
  bool _busy = false;
  String? _error;

  Future<void> _send() async {
    final i18n = context.i18nRead;
    final e = normalizeOtpPhone(_phone.text, _dial);
    if (e == null) return setState(() => _error = i18n.t('phoneInvalid'));
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AccountService.sendOtp(e);
      setState(() => _e164 = e);
    } catch (err) {
      setState(() => _error = authErrorMessage(err, i18n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final i18n = context.i18nRead;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await AccountService.verifyOtp(_e164!, toWesternDigits(_code.text.trim()));
      final c = await AccountService.changePhone(token);
      if (!mounted) return;
      context.read<AuthState>().setCustomer(c);
      Navigator.pop(context);
      showSnack(context, i18n.t('saved'));
    } catch (err) {
      if (mounted) setState(() => _error = authErrorMessage(err, i18n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(i18n.t('changePhone'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          if (_e164 == null)
            Row(children: [
              DropdownButton<String>(
                value: _dial,
                underline: const SizedBox.shrink(),
                items: [for (final c in otpCountries) DropdownMenuItem(value: c.dialCode, child: Text('${c.flag} +${c.dialCode}'))],
                onChanged: (v) => setState(() => _dial = v ?? '966'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(hintText: i18n.t('mobilePlaceholder')),
                ),
              ),
            ])
          else ...[
            Text(i18n.t('otpSentTo', {'phone': nationalPhoneOf(_e164)})),
            const SizedBox(height: 10),
            TextField(controller: _code, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: InputDecoration(hintText: i18n.t('otpCode'))),
          ],
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.error))),
          const SizedBox(height: 14),
          GoldButton(label: _e164 == null ? i18n.t('sendCode') : i18n.t('verify'), loading: _busy, onPressed: _e164 == null ? _send : _verify),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Address book
// ---------------------------------------------------------------------------

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  List<CustomerAddress>? _addresses;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final a = await AccountService.listAddresses();
      if (mounted) setState(() => _addresses = a);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _edit([CustomerAddress? address]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressSheet(address: address),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final signedIn = context.watch<AuthState>().isSignedIn;
    Widget body;
    if (!signedIn) {
      body = const SignInRequired();
    } else if (_error != null) {
      body = ErrorView(onRetry: _load);
    } else if (_addresses == null) {
      body = const LoadingView();
    } else if (_addresses!.isEmpty) {
      body = MessageState(icon: Icons.place_outlined, title: i18n.t('noAddresses'), action: _edit, actionLabel: i18n.t('addAddress'));
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final a in _addresses!)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CardBox(
                onTap: () => _edit(a),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place_outlined, color: AppColors.darkGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(child: Text(a.addressName ?? a.fullName, style: const TextStyle(fontWeight: FontWeight.w700))),
                            if (a.isDefaultShipping) ...[
                              const SizedBox(width: 6),
                              StatusChip(label: i18n.t('defaultAddress'), color: AppColors.darkGreen),
                            ],
                          ]),
                          Text([a.address1, a.address2, a.city].where((e) => (e ?? '').isNotEmpty).join(' · '),
                              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                          if ((a.phone ?? '').isNotEmpty) Text(nationalPhoneOf(a.phone), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () async {
                        final ok = await confirmDialog(context,
                            title: i18n.t('deleteAddress'), message: i18n.t('deleteAddressConfirm'), confirmLabel: i18n.t('delete'), destructive: true);
                        if (!ok) return;
                        try {
                          await AccountService.deleteAddress(a.id);
                          _load();
                        } catch (_) {
                          if (context.mounted) showSnack(context, i18n.t('genericError'), error: true);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('addressBook'))),
      floatingActionButton: signedIn && (_addresses?.isNotEmpty ?? false)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: AppColors.primary,
              onPressed: _edit,
              icon: const Icon(Icons.add),
              label: Text(i18n.t('addAddress')),
            )
          : null,
      body: body,
    );
  }
}

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({this.address});
  final CustomerAddress? address;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  late final _label = TextEditingController(text: widget.address?.addressName ?? '');
  late final _name = TextEditingController(text: widget.address?.fullName ?? context.read<AuthState>().customer?.fullName ?? '');
  late final _phone = TextEditingController(text: widget.address?.phone ?? context.read<AuthState>().customer?.phone ?? '');
  late NationalAddressDraft? _draft = widget.address == null ? null : NationalAddressDraft.fromCustomerAddress(widget.address!);
  late bool _default = widget.address?.isDefaultShipping ?? false;
  bool _saving = false;

  Future<void> _save() async {
    final i18n = context.i18nRead;
    final d = _draft;
    if (d == null || !d.isComplete) return showSnack(context, i18n.t('nationalAddressIncomplete'), error: true);
    if (_name.text.trim().isEmpty) return showSnack(context, i18n.t('fieldRequired'), error: true);
    setState(() => _saving = true);
    final parts = _name.text.trim().split(RegExp(r'\s+'));
    try {
      await AccountService.saveAddress(id: widget.address?.id, input: {
        'address_name': _label.text.trim().isEmpty ? null : _label.text.trim(),
        'first_name': parts.first,
        'last_name': parts.skip(1).join(' '),
        'phone': _phone.text.trim(),
        'is_default_shipping': _default,
        ...d.toMedusaAddressFields(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, authErrorMessage(e, i18n), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.address == null ? i18n.t('addAddress') : i18n.t('editAddress'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(controller: _label, decoration: InputDecoration(hintText: i18n.t('addressLabel'))),
            const SizedBox(height: 10),
            TextField(controller: _name, decoration: InputDecoration(hintText: i18n.t('fullName'))),
            const SizedBox(height: 10),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: i18n.t('phoneNumber'))),
            const SizedBox(height: 10),
            NationalAddressForm(initial: _draft, onChanged: (d) => _draft = d),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.darkGreen,
              value: _default,
              onChanged: (v) => setState(() => _default = v),
              title: Text(i18n.t('makeDefault')),
            ),
            const SizedBox(height: 10),
            GoldButton(label: i18n.t('save'), loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loyalty
// ---------------------------------------------------------------------------

const tierColors = {
  'bronze': Color(0xFFB0753F),
  'silver': Color(0xFF9CA3AF),
  'gold': AppColors.primary,
  'platinum': Color(0xFF7B8FA1),
};

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  LoyaltyStatus? _status;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = context.read<AuthState>().customer;
    if (c == null) return;
    setState(() => _error = null);
    try {
      final s = await LoyaltyService.status(c);
      if (mounted) setState(() => _status = s);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final signedIn = context.watch<AuthState>().isSignedIn;
    final s = _status;
    Widget body;
    if (!signedIn) {
      body = const SignInRequired();
    } else if (_error != null) {
      body = ErrorView(onRetry: _load);
    } else if (s == null) {
      body = const LoadingView();
    } else {
      final color = tierColors[s.tier.id] ?? AppColors.primary;
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.darkGreen, AppColors.deepGreen]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.workspace_premium, color: color, size: 30),
                  const SizedBox(width: 8),
                  Text(i18n.t('tier_${s.tier.id}'), style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('#${s.memberNumber}', style: const TextStyle(color: Colors.white70, letterSpacing: 2)),
                ]),
                const SizedBox(height: 18),
                Text(i18n.t('loyaltyPoints'), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                Text(formatNumber(s.points), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                if (s.memberSince != null)
                  Text(i18n.t('memberSince', {'date': formatDate(s.memberSince, i18n.lang)}), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 16),
                if (s.nextTier != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: s.progress, minHeight: 8, color: color, backgroundColor: Colors.white12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i18n.t('toNextTier', {'amount': formatSar(s.remainingToNext, i18n.lang, decimals: 0), 'tier': i18n.t('tier_${s.nextTier!.id}')}),
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ] else
                  Text(i18n.t('topTierReached'), style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CardBox(
            child: Column(children: [
              InfoRow(label: i18n.t('lifetimeSpend'), valueWidget: Price(s.lifetimeSpend, decimals: 0)),
              InfoRow(label: i18n.t('qualifyingOrders'), value: '${s.qualifyingOrderCount} / ${s.orderCount}'),
            ]),
          ),
          const SizedBox(height: 16),
          SectionLabel(i18n.t('loyaltyTiers')),
          for (final t in s.tiers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.workspace_premium, color: tierColors[t.id]),
              title: Text(i18n.t('tier_${t.id}'), style: TextStyle(fontWeight: t.id == s.tier.id ? FontWeight.w800 : FontWeight.w500)),
              trailing: t.minSpend == 0 ? Text(i18n.t('tierEntry')) : Price(t.minSpend, decimals: 0),
            ),
          const SizedBox(height: 8),
          Text(i18n.t('loyaltyNote'), style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
        ],
      );
    }
    return Scaffold(appBar: AppBar(title: Text(i18n.t('loyaltyProgram'))), body: body);
  }
}
