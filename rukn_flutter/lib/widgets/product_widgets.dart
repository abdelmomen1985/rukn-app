import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../models/product.dart';
import '../state/cart_state.dart';
import '../state/gold_ticker.dart';
import '../state/wishlist_state.dart';
import 'common.dart';
import 'offer_badge.dart';

/// Stamps the current catalogue rate on freshly fetched products so their
/// prices can follow the live gold rate afterwards.
void stampBaseline(BuildContext context, Iterable<Product> products) {
  final rate = context.read<GoldTicker>().data?.catalogPrice;
  for (final p in products) {
    p.baseline ??= rate;
  }
}

/// A product price scaled to the live 21K rate.
double livePrice(BuildContext context, Product product, [double? base]) {
  final current = context.watch<GoldTicker>().productCatalogPrice;
  return PriceScaler(product.baseline).scale(base ?? product.basePrice, current);
}

class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height, this.radius = 0});
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(color: AppColors.surface);
    final broken = Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(Icons.diamond_outlined, color: AppColors.muted),
    );
    // The catalogue's image host sends no CORS headers, which the web canvas
    // renderer needs; on web fall back to a plain <img> element.
    final Widget img = kIsWeb
        ? Image.network(
            url,
            fit: fit,
            width: width,
            height: height,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
            errorBuilder: (_, _, _) => broken,
          )
        : CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => broken,
          );
    return radius == 0 ? img : ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.width});
  final Product product;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final wish = context.watch<WishlistState>();
    final inCart = context.watch<CartState>().contains(product.id);
    final price = livePrice(context, product);
    final wished = wish.contains(product.id);

    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/product/${product.id}'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetImage(product.image),
                      PositionedDirectional(
                        bottom: 8,
                        start: 8,
                        end: 8,
                        child: Align(
                          alignment: AlignmentDirectional.bottomStart,
                          child: SpecialOfferBadge(productId: product.id, categoryIds: product.categoryIds),
                        ),
                      ),
                      if (product.badge != null)
                        PositionedDirectional(
                          top: 8,
                          start: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(999)),
                            child: Text(product.badge!.of(i18n.lang),
                                style: const TextStyle(color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      PositionedDirectional(
                        top: 4,
                        end: 4,
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.85)),
                          icon: Icon(wished ? Icons.favorite : Icons.favorite_border,
                              size: 19, color: wished ? AppColors.primary : AppColors.foreground),
                          onPressed: () {
                            haptic();
                            wish.toggle(product.id);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name.of(i18n.lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                      if (!product.metaLabel.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(product.metaLabel.of(i18n.lang),
                              maxLines: 1, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              alignment: AlignmentDirectional.centerStart,
                              fit: BoxFit.scaleDown,
                              child: Price(price, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
                            ),
                          ),
                          _QuickAdd(product: product, inCart: inCart),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({required this.product, required this.inCart});
  final Product product;
  final bool inCart;

  @override
  Widget build(BuildContext context) {
    // Products with real choices (sizes, weights) are added from their page.
    final needsChoice = product.options.isNotEmpty;
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton.filled(
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(backgroundColor: inCart ? AppColors.primary : AppColors.darkGreen),
        icon: Icon(inCart ? Icons.check : Icons.add_shopping_cart, size: 17, color: inCart ? AppColors.darkGreen : AppColors.primary),
        onPressed: !product.isPurchasable
            ? null
            : () {
                if (needsChoice) {
                  context.push('/product/${product.id}');
                  return;
                }
                haptic();
                final i18n = context.i18nRead;
                final refusal = context.read<CartState>().add(product,
                    price: PriceScaler(product.baseline).scale(product.basePrice, context.read<GoldTicker>().productCatalogPrice),
                    lang: i18n.lang);
                showSnack(context, refusal ?? i18n.t('addedToCart'), error: refusal != null);
              },
      ),
    );
  }
}

/// Two-column responsive grid of product cards for slivers.
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({super.key, required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 900 ? 4 : (width > 600 ? 3 : 2);
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: (width - 32 - 12 * (columns - 1)) / columns + 112,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => ProductCard(product: products[i]),
        childCount: products.length,
      ),
    );
  }
}
