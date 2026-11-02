import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../l10n/i18n.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../state/wishlist_state.dart';
import '../widgets/common.dart';
import '../widgets/product_widgets.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Map<String, Product> _cache = {};
  bool _loading = false;
  Object? _error;
  List<String> _lastIds = const [];

  Future<void> _fetch(List<String> ids) async {
    final missing = ids.where((id) => !_cache.containsKey(id)).toList();
    if (missing.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await CatalogService.getProductsByIds(missing);
      if (!mounted) return;
      stampBaseline(context, products);
      setState(() {
        for (final p in products) {
          _cache[p.id] = p;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final ids = context.watch<WishlistState>().ids;
    if (ids.join() != _lastIds.join()) {
      _lastIds = ids;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetch(ids));
    }
    final products = [for (final id in ids) ?_cache[id]];

    Widget body;
    if (ids.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/animations/wishlist-empty-2.json', width: 240, height: 240),
              Text(i18n.t('wishlistEmpty'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(i18n.t('wishlistEmptySubtitle'), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(width: 220, child: GoldButton(label: i18n.t('continueShopping'), onPressed: () => context.go('/'))),
            ],
          ),
        ),
      );
    } else if (_loading && products.isEmpty) {
      body = const LoadingView();
    } else if (_error != null && products.isEmpty) {
      body = ErrorView(onRetry: () => _fetch(ids));
    } else {
      body = CustomScrollView(slivers: [
        SliverPadding(padding: const EdgeInsets.all(16), sliver: ProductSliverGrid(products: products)),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('myWishlist'))),
      body: body,
    );
  }
}
