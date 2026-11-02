import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../models/customer.dart';
import '../services/account_service.dart';
import '../services/content_service.dart';
import '../services/national_address.dart';
import '../services/order_statuses.dart';
import '../state/auth_state.dart';
import '../widgets/common.dart';
import '../widgets/national_address_form.dart';
import '../widgets/product_widgets.dart';
import 'account_screens.dart';

({Color color, IconData icon}) _statusStyle(String status) => switch (status) {
      'delivered' => (color: const Color(0xFF065F46), icon: Icons.check_circle_outline),
      'shipped' => (color: const Color(0xFF5B21B6), icon: Icons.local_shipping_outlined),
      'processing' => (color: const Color(0xFF1E40AF), icon: Icons.settings_outlined),
      'cancelled' => (color: const Color(0xFF991B1B), icon: Icons.cancel_outlined),
      _ => (color: const Color(0xFF92400E), icon: Icons.schedule),
    };

/// The operator's wording and tone («حالات الطلب») for one status, or null to keep the built-in.
({String label, Color color})? _remote(OrderStatusesData? statuses, String scope, String? code, String lang) {
  final label = remoteStatusLabel(statuses, scope, code, lang);
  final entry = remoteStatusEntry(statuses, scope, code);
  if (label == null || entry == null) return null;
  return (label: label, color: toneColorsFor(statuses, entry.tone).fg);
}

/// «مراحل الطلب» — the operator's stage pipeline for one order, as a vertical timeline. Hidden
/// when the backend has no progress for the order or cannot be reached.
class _OrderProgressSection extends StatefulWidget {
  const _OrderProgressSection({required this.orderId, required this.statuses});
  final String orderId;
  final OrderStatusesData? statuses;

  @override
  State<_OrderProgressSection> createState() => _OrderProgressSectionState();
}

class _OrderProgressSectionState extends State<_OrderProgressSection> {
  OrderStageProgress? _data;

  @override
  void initState() {
    super.initState();
    fetchOrderStageProgress(widget.orderId).then((d) {
      if (mounted && d != null) setState(() => _data = d);
    });
  }

  String? _day(String? iso, String lang) {
    final date = iso == null ? null : DateTime.tryParse(iso);
    if (date == null) return null;
    // Wall-clock in Riyadh, like the website.
    final riyadh = date.toUtc().add(const Duration(hours: 3));
    return DateFormat.MMMd(lang).format(riyadh);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final data = _data;
    final current = data?.current;
    if (data == null || current == null || data.progress.isEmpty) return const SizedBox.shrink();

    final lang = i18n.lang;
    final currentIndex = data.progress.indexWhere((s) => s.key == current.key);
    final canceled = current.kind == 'canceled';
    const reachedColor = AppColors.darkGreen;
    final lineIdle = AppColors.border;

    Color dotFor(PublicStage stage) => toneColorsFor(widget.statuses, stage.color).dot;

    return CardBox(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(i18n.t('orderStageTitle')),
          for (var i = 0; i < data.progress.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 22,
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 2,
                              color: i == 0 ? Colors.transparent : (i <= currentIndex ? reachedColor : lineIdle),
                            ),
                          ),
                        ),
                        _StageDot(
                          reached: i <= currentIndex,
                          isCurrent: i == currentIndex,
                          canceled: canceled && i == currentIndex,
                          color: i == currentIndex && canceled ? AppColors.error : dotFor(data.progress[i]),
                          halo: i == currentIndex && !canceled ? toneColorsFor(widget.statuses, data.progress[i].color).bg : null,
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 2,
                              color: i == data.progress.length - 1
                                  ? Colors.transparent
                                  : (i < currentIndex ? reachedColor : lineIdle),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stageLabel(data.progress[i], lang),
                            style: TextStyle(
                              fontWeight: i == currentIndex ? FontWeight.w800 : FontWeight.w600,
                              color: i == currentIndex && canceled
                                  ? AppColors.error
                                  : (i <= currentIndex ? AppColors.foreground : AppColors.muted),
                            ),
                          ),
                          if (i <= currentIndex && _day(data.reachedAt[data.progress[i].key], lang) != null)
                            Text(
                              _day(data.reachedAt[data.progress[i].key], lang)!,
                              style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.reached, required this.isCurrent, required this.canceled, required this.color, this.halo});
  final bool reached;
  final bool isCurrent;
  final bool canceled;
  final Color color;
  final Color? halo;

  @override
  Widget build(BuildContext context) {
    final size = isCurrent ? 16.0 : 12.0;
    final fill = isCurrent || canceled ? color : (reached ? AppColors.darkGreen : Colors.white);
    final border = isCurrent || canceled ? color : (reached ? AppColors.darkGreen : const Color(0xFFD1D5DB));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
        boxShadow: halo == null ? null : [BoxShadow(color: halo!, spreadRadius: 3)],
      ),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order>? _orders;
  Object? _error;
  OrderStatusesData? _statuses;

  @override
  void initState() {
    super.initState();
    _load();
    fetchOrderStatuses().then((s) {
      if (mounted && s != null) setState(() => _statuses = s);
    });
  }

  Future<void> _load() async {
    if (!context.read<AuthState>().isSignedIn) return;
    setState(() => _error = null);
    try {
      final o = await AccountService.listOrders();
      if (mounted) setState(() => _orders = o);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final signedIn = context.watch<AuthState>().isSignedIn;
    if (signedIn && _orders == null && _error == null) WidgetsBinding.instance.addPostFrameCallback((_) => _load());

    Widget body;
    if (!signedIn) {
      body = SignInRequired(message: i18n.t('signInToViewOrders'));
    } else if (_error != null) {
      body = ErrorView(onRetry: _load);
    } else if (_orders == null) {
      body = const LoadingView();
    } else if (_orders!.isEmpty) {
      body = MessageState(icon: Icons.receipt_long_outlined, title: i18n.t('noOrdersYet'), action: () => context.go('/'), actionLabel: i18n.t('continueShopping'));
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _orders!.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _OrderCard(order: _orders![i], statuses: _statuses),
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: Text(i18n.t('orderHistory'))), body: body);
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.statuses});
  final Order order;
  final OrderStatusesData? statuses;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final style = _statusStyle(order.displayStatus);
    final remote = _remote(statuses, 'order', order.status, i18n.lang);
    final vault = _remote(statuses, 'vault', 'stored', i18n.lang);
    return CardBox(
      onTap: () => context.push('/orders/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('#${order.displayId}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            StatusChip(
              label: remote?.label ?? i18n.t('orderStatus_${order.displayStatus}'),
              color: remote?.color ?? style.color,
              icon: style.icon,
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.muted),
            const SizedBox(width: 4),
            Text(formatDate(order.createdAt, i18n.lang), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            const SizedBox(width: 12),
            const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.muted),
            const SizedBox(width: 4),
            Text(i18n.t('itemsCount', {'n': order.itemCount}), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ]),
          if (order.items.any((i) => i.thumbnail != null)) ...[
            const SizedBox(height: 10),
            Row(children: [
              for (final item in order.items.take(4))
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: NetImage(item.thumbnail ?? '', width: 48, height: 48, radius: 8),
                ),
            ]),
          ],
          const Divider(height: 20),
          Row(children: [
            if (order.vaultStatus == 'stored')
              StatusChip(
                label: vault?.label ?? i18n.t('inVault'),
                color: vault?.color ?? AppColors.goldText,
                icon: Icons.lock_outline,
              ),
            const Spacer(),
            Price(order.total, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
          ]),
        ],
      ),
    );
  }
}

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  Object? _error;
  Map<String, List<String>> _serials = {};
  bool _invoiceLoading = false;
  bool _releasing = false;
  OrderStatusesData? _statuses;

  @override
  void initState() {
    super.initState();
    _load();
    fetchOrderStatuses().then((s) {
      if (mounted && s != null) setState(() => _statuses = s);
    });
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final o = await AccountService.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() => _order = o);
      ContentService.orderBarSerials(o.id).then((s) {
        if (mounted) setState(() => _serials = s);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _invoice() async {
    final i18n = context.i18nRead;
    if (kIsWeb) return showSnack(context, i18n.t('invoiceAppOnly'));
    setState(() => _invoiceLoading = true);
    try {
      final html = await AccountService.invoiceHtml(widget.orderId);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => _InvoiceScreen(html: html, title: '#${_order?.displayId}')));
    } catch (e) {
      if (mounted) showSnack(context, (e is MedusaError ? e.message : null) ?? i18n.t('invoiceUnavailable'), error: true);
    } finally {
      if (mounted) setState(() => _invoiceLoading = false);
    }
  }

  Future<void> _requestShipping() async {
    final i18n = context.i18nRead;
    NationalAddressDraft? address;
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(i18n.t('requestShipping'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(i18n.t('requestShippingBody'), style: const TextStyle(color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 12),
              NationalAddressForm(onChanged: (d) => address = d),
              const SizedBox(height: 14),
              GoldButton(label: i18n.t('requestShipping'), onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        ),
      ),
    );
    if (proceed != true || !mounted) return;
    setState(() => _releasing = true);
    try {
      await AccountService.requestVaultRelease(widget.orderId, address != null && address!.isComplete ? address : null);
      if (!mounted) return;
      showSnack(context, i18n.t('shippingRequested'));
      _load();
    } catch (e) {
      if (mounted) showSnack(context, (e is MedusaError ? e.message : null) ?? i18n.t('genericError'), error: true);
    } finally {
      if (mounted) setState(() => _releasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final o = _order;
    Widget body;
    if (_error != null) {
      body = ErrorView(onRetry: _load);
    } else if (o == null) {
      body = const LoadingView();
    } else {
      final style = _statusStyle(o.displayStatus);
      final addr = o.shippingAddress;
      final statusRemote = _remote(_statuses, 'order', o.status, i18n.lang);
      final vaultRemote = _remote(_statuses, 'vault', 'stored', i18n.lang);
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('#${o.displayId}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                StatusChip(
                  label: statusRemote?.label ?? i18n.t('orderStatus_${o.displayStatus}'),
                  color: statusRemote?.color ?? style.color,
                  icon: style.icon,
                ),
              ]),
              const SizedBox(height: 4),
              Text(formatDate(o.createdAt, i18n.lang, withTime: true), style: const TextStyle(color: AppColors.muted)),
              if (o.paymentMethod != null) ...[
                const SizedBox(height: 8),
                InfoRow(label: i18n.t('paymentMethod'), value: i18n.t('pm_${o.paymentMethod}')),
              ],
              if (o.paymentStatus != null)
                InfoRow(
                  label: i18n.t('paymentStatus'),
                  value: remoteStatusLabel(_statuses, 'payment', o.paymentStatus, i18n.lang) ?? i18n.t('ps_${o.paymentStatus}'),
                ),
              if (o.branchName != null) InfoRow(label: i18n.t('branch'), value: o.branchName),
            ]),
          ),
          _OrderProgressSection(orderId: o.id, statuses: _statuses),
          if (o.vaultStatus != null) ...[
            const SizedBox(height: 12),
            CardBox(
              color: AppColors.cream,
              borderColor: AppColors.goldBorder,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const Icon(Icons.lock_outline, color: AppColors.goldText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        o.vaultStatus == 'stored'
                            ? (vaultRemote?.label ?? i18n.t('vaultStored'))
                            : i18n.t('vaultReleaseRequested'),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.goldText)),
                  ),
                ]),
                if (o.vaultStatus == 'stored') ...[
                  const SizedBox(height: 10),
                  GoldButton(label: i18n.t('requestShipping'), loading: _releasing, onPressed: _requestShipping),
                ],
              ]),
            ),
          ],
          const SizedBox(height: 12),
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SectionLabel(i18n.t('items')),
              for (final item in o.items) ...[
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  NetImage(item.thumbnail ?? '', width: 56, height: 56, radius: 8),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if ((item.subtitle ?? '').isNotEmpty) Text(item.subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      Text('${item.quantity} × ${formatSar(item.unitPrice, i18n.lang)}', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      for (final serial in _serials[item.id] ?? const <String>[])
                        TextButton.icon(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                          onPressed: () => context.push('/certificate?serial=${Uri.encodeQueryComponent(serial)}'),
                          icon: const Icon(Icons.verified, size: 16),
                          label: Text('${i18n.t('certificate')} ${formatSerial(serial)}'),
                        ),
                    ]),
                  ),
                  Price(item.total, style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 10),
              ],
              const Divider(),
              InfoRow(label: i18n.t('subtotal'), valueWidget: Price(o.itemSubtotal)),
              InfoRow(label: i18n.t('shipping'), valueWidget: Price(o.shippingTotal)),
              if (o.discountTotal > 0) InfoRow(label: i18n.t('discount'), valueWidget: Price(-o.discountTotal)),
              if (o.taxTotal > 0) InfoRow(label: i18n.t('vatIncludedLine'), valueWidget: Price(o.taxTotal)),
              InfoRow(label: i18n.t('cartTotal'), highlight: true, valueWidget: Price(o.total, style: const TextStyle(color: AppColors.darkGreen, fontSize: 16))),
            ]),
          ),
          if (addr != null) ...[
            const SizedBox(height: 12),
            CardBox(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionLabel(o.shippingMethodName ?? i18n.t('shippingAddress')),
                Text([asString(addr['first_name']), asString(addr['last_name'])].where((e) => e.isNotEmpty && e != '-').join(' '),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text([addr['address_1'], addr['address_2'], addr['city'], addr['postal_code']].where((e) => asString(e).isNotEmpty).join('، '),
                    style: const TextStyle(color: AppColors.muted)),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _invoiceLoading ? null : _invoice,
            icon: _invoiceLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.description_outlined),
            label: Text(i18n.t('taxInvoice')),
          ),
        ],
      );
    }
    return Scaffold(appBar: AppBar(title: Text(i18n.t('orderDetails'))), body: body);
  }
}

class _InvoiceScreen extends StatefulWidget {
  const _InvoiceScreen({required this.html, required this.title});
  final String html;
  final String title;

  @override
  State<_InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<_InvoiceScreen> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    // The invoice opens its own print dialog on load; strip that for in-app viewing.
    ..loadHtmlString(widget.html.replaceAll(RegExp(r'window\.print\(\)'), 'void 0'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${context.tr('taxInvoice')} ${widget.title}')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
