import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../services/special_offers.dart';

/// Loads the shared offers once (from the app-wide cache) and rebuilds with the ones that reach
/// a product. A failed read leaves the list empty, so the badge simply does not show.
class _OffersLoader extends StatefulWidget {
  const _OffersLoader({required this.productId, required this.categoryIds, required this.builder});
  final String productId;
  final List<String> categoryIds;
  final Widget Function(BuildContext context, List<SpecialOffer> offers) builder;

  @override
  State<_OffersLoader> createState() => _OffersLoaderState();
}

class _OffersLoaderState extends State<_OffersLoader> {
  List<SpecialOffer> _all = SpecialOffers.cached ?? const [];

  @override
  void initState() {
    super.initState();
    if (SpecialOffers.cached == null) {
      SpecialOffers.load().then((offers) {
        if (mounted) setState(() => _all = offers);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offers = offersForProduct(widget.productId, widget.categoryIds, _all);
    return widget.builder(context, offers);
  }
}

/// A coloured text pill: the offer's short badge («عرض خاص», «المصنعية 15 ريال»…).
class _OfferPill extends StatelessWidget {
  const _OfferPill({required this.offer, required this.lang, this.maxWidth});
  final SpecialOffer offer;
  final String lang;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final palette = offer.palette;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_outlined, size: 12, color: palette.ink),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              offer.badge.of(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.ink, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return maxWidth == null ? pill : ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth!), child: pill);
  }
}

/// Compact offer badge for a product card: the first offer that reaches the product, in its
/// colour scheme. Text only; the price beside it is the real one. Renders nothing without offers.
class SpecialOfferBadge extends StatelessWidget {
  const SpecialOfferBadge({super.key, required this.productId, required this.categoryIds});
  final String productId;
  final List<String> categoryIds;

  @override
  Widget build(BuildContext context) {
    return _OffersLoader(
      productId: productId,
      categoryIds: categoryIds,
      builder: (context, offers) {
        if (offers.isEmpty) return const SizedBox.shrink();
        return _OfferPill(offer: offers.first, lang: context.i18n.lang, maxWidth: 180);
      },
    );
  }
}

/// Every offer reaching the product, each as badge + detail line — the product page, under the
/// price. Renders nothing without offers.
class SpecialOfferBox extends StatelessWidget {
  const SpecialOfferBox({super.key, required this.productId, required this.categoryIds});
  final String productId;
  final List<String> categoryIds;

  @override
  Widget build(BuildContext context) {
    return _OffersLoader(
      productId: productId,
      categoryIds: categoryIds,
      builder: (context, offers) {
        if (offers.isEmpty) return const SizedBox.shrink();
        final i18n = context.i18n;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(
            container: true,
            label: i18n.t('specialOffers'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF0E6C4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final offer in offers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _OfferPill(offer: offer, lang: i18n.lang),
                          Text(
                            offer.text.of(i18n.lang),
                            style: const TextStyle(
                                color: AppColors.deepGreen, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The offers bound to a category, as slim strips above its product grid — one per offer, in its
/// colour scheme (the site's `CategoryOfferBanner`). Loads the shared cache, so it costs no
/// request of its own. Renders nothing without offers.
class CategoryOfferBanner extends StatefulWidget {
  const CategoryOfferBanner({super.key, required this.categoryId});
  final String categoryId;

  @override
  State<CategoryOfferBanner> createState() => _CategoryOfferBannerState();
}

class _CategoryOfferBannerState extends State<CategoryOfferBanner> {
  List<SpecialOffer> _all = SpecialOffers.cached ?? const [];

  @override
  void initState() {
    super.initState();
    if (SpecialOffers.cached == null) {
      SpecialOffers.load().then((offers) {
        if (mounted) setState(() => _all = offers);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offers = offersForCategory(widget.categoryId, _all);
    if (offers.isEmpty) return const SizedBox.shrink();
    final i18n = context.i18n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Semantics(
        container: true,
        label: i18n.t('categoryOffers'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final offer in offers)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: offer.palette.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: offer.palette.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_offer_outlined, size: 16, color: offer.palette.ink),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(offer.badge.of(i18n.lang),
                                style: TextStyle(color: offer.palette.ink, fontSize: 13, fontWeight: FontWeight.w800)),
                            Text(offer.text.of(i18n.lang),
                                style: TextStyle(color: offer.palette.soft, fontSize: 13, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
