import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../services/store_settings.dart';
import '../state/cart_state.dart';
import '../widgets/common.dart';
import '../widgets/product_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Timer? _timer;
  VatInfo _vat = VatInfo.none;
  OrderingStatus _ordering = OrderingStatus.openStatus;
  String _vatSignature = '';

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartState>();
    cart.reprice();
    // Gold moves: keep the basket on the authoritative variant prices.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => cart.reprice());
    StoreSettings.orderingStatus().then((s) {
      if (mounted) setState(() => _ordering = s);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncVat(List<CartItem> items) {
    final sig = items.map((i) => i.productId).toSet().join('|');
    if (sig == _vatSignature) return;
    _vatSignature = sig;
    StoreSettings.productVat(items.map((i) => i.productId).toList()).then((v) {
      if (mounted) setState(() => _vat = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final cart = context.watch<CartState>();
    final items = cart.items;
    _syncVat(items);
    final vat = items.fold<double>(0, (s, i) => s + (_vat.lineVat(i.productId, i.lineTotal) ?? 0));

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(i18n.t('myCart'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('assets/animations/empty-cart.json', width: 240, height: 240),
                Text(i18n.t('cartEmpty'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(i18n.t('cartEmptySubtitle'), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                SizedBox(width: 220, child: GoldButton(label: i18n.t('continueShopping'), onPressed: () => context.go('/'))),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.t('myCart')),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: i18n.t('clearCart'), message: i18n.t('clearCartConfirm'), confirmLabel: i18n.t('clearCart'), destructive: true);
              if (ok) cart.clear();
            },
            child: Text(i18n.t('clearCart'), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_ordering.open) ...[
            OrderingClosedNotice(status: _ordering),
            const SizedBox(height: 12),
          ],
          for (final item in items) ...[
            _CartLine(item: item),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.bolt, size: 15, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(child: Text(i18n.t('cartLivePriceNote'), style: const TextStyle(color: AppColors.muted, fontSize: 12))),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (vat > 0)
                InfoRow(label: i18n.t('vatIncludedLine'), valueWidget: Price(vat)),
              Row(
                children: [
                  Expanded(child: Text(i18n.t('cartTotal'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                  Price(cart.subtotal, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
                ],
              ),
              const SizedBox(height: 10),
              GoldButton(
                label: i18n.t('checkout'),
                onPressed: _ordering.open ? () => context.push('/checkout') : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final cart = context.read<CartState>();
    return CardBox(
      padding: const EdgeInsets.all(10),
      onTap: () => context.push('/product/${item.productId}'),
      child: Row(
        children: [
          NetImage(item.image, width: 84, height: 84, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name.of(i18n.lang), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (item.optionLabel != null)
                  Text(item.optionLabel!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 6),
                Price(item.price, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                onPressed: () {
                  haptic();
                  cart.remove(item.id);
                },
              ),
              Container(
                decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(onTap: () => cart.decrement(item.id), child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 16))),
                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    InkWell(onTap: () => cart.increment(item.id), child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 16))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderingClosedNotice extends StatelessWidget {
  const OrderingClosedNotice({super.key, required this.status});
  final OrderingStatus status;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final msg = i18n.pick(status.messageAr, status.messageEn);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.pause_circle_outline, color: Color(0xFF92400E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i18n.t('orderingClosedTitle'), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                const SizedBox(height: 4),
                Text(msg.isNotEmpty ? msg : i18n.t('orderingClosedBody'), style: const TextStyle(color: Color(0xFF92400E), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
