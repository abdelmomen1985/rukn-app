import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../models/product.dart';
import '../services/home_content_service.dart';
import 'product_widgets.dart';

/// Opens a home-page link: in-app where the app has the screen, otherwise on the website or in
/// the browser.
void openHomeLink(BuildContext context, String href) {
  final lang = context.i18nRead.lang;
  final target = resolveSiteLink(href, lang: lang, origin: AppConfig.origin);
  switch (target) {
    case InAppLink(:final route):
      context.push(route);
    case ExternalLink(:final url):
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
  }
}

String _pick(I18n i18n, String ar, String en) => i18n.pick(ar, en);

/// One admin-managed category section: circles or cards, with an optional «view all».
class HomeCategoryRail extends StatelessWidget {
  const HomeCategoryRail({super.key, required this.section});
  final HomeCategorySection section;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final title = _pick(i18n, section.titleAr, section.titleEn);
    final viewAll = section.viewAll;
    final viewAllLabel = viewAll == null ? null : _pick(i18n, viewAll.labelAr, viewAll.labelEn);
    final isCircles = section.layout == HomeSectionLayout.circles;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title.isNotEmpty || (viewAll != null && !isCircles))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  ),
                  if (viewAll != null && !isCircles)
                    TextButton(
                      onPressed: () => openHomeLink(context, viewAll.href),
                      child: Text(viewAllLabel!,
                          style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          if (isCircles)
            _CirclesRow(tiles: section.tiles, viewAll: viewAll, viewAllLabel: viewAllLabel)
          else
            _CardsRow(tiles: section.tiles),
        ],
      ),
    );
  }
}

class _CirclesRow extends StatelessWidget {
  const _CirclesRow({required this.tiles, required this.viewAll, required this.viewAllLabel});
  final List<HomeCategoryTile> tiles;
  final HomeViewAll? viewAll;
  final String? viewAllLabel;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final count = tiles.length + (viewAll == null ? 0 : 1);
    return SizedBox(
      height: 124,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          if (i < tiles.length) {
            final tile = tiles[i];
            return _CircleTile(
              label: tile.title,
              image: tile.image,
              alt: tile.alt,
              onTap: () => openHomeLink(context, tile.link ?? categoryRoute(tile.categoryId!)),
            );
          }
          return _CircleTile(
            label: viewAllLabel ?? i18n.t('homeViewAll'),
            onTap: () => openHomeLink(context, viewAll!.href),
          );
        },
      ),
    );
  }
}

class _CircleTile extends StatelessWidget {
  const _CircleTile({required this.label, required this.onTap, this.image, this.alt = ''});
  final String label;
  final String? image;
  final String alt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: alt.isNotEmpty ? alt : label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 84,
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: image == null
                    ? const Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 26)
                    : Padding(
                        padding: const EdgeInsets.all(6),
                        child: ClipOval(child: NetImage(homeImageUrl(image!))),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.25, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardsRow extends StatelessWidget {
  const _CardsRow({required this.tiles});
  final List<HomeCategoryTile> tiles;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return SizedBox(
      height: 230,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final tile = tiles[i];
          final description = i18n.pick(tile.descriptionAr, tile.descriptionEn);
          return SizedBox(
            width: 170,
            child: Material(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => openHomeLink(context, tile.link ?? categoryRoute(tile.categoryId!)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(homeImageUrl(tile.image)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: 12,
                      end: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tile.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                          if (description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3)),
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
      ),
    );
  }
}

/// One admin-managed product section: a title, an optional subtitle and «view all», then the
/// curated products resolved by handle. Handles the store does not return are skipped.
class HomeProductRail extends StatelessWidget {
  const HomeProductRail({super.key, required this.section, required this.productsByHandle});
  final HomeProductSection section;
  final Map<String, Product> productsByHandle;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final cards = <Widget>[];
    for (final item in section.items) {
      final product = productsByHandle[item.handle];
      if (product == null) continue;
      cards.add(ProductCard(product: _withOverlay(product, item), width: 170));
    }
    if (cards.isEmpty) return const SizedBox.shrink();

    final title = _pick(i18n, section.title.ar, section.title.en);
    final subtitle = section.subtitle == null ? '' : _pick(i18n, section.subtitle!.ar, section.subtitle!.en);
    final viewAllHref = section.viewAllHref;
    final viewAllLabel = section.viewAllLabel == null
        ? i18n.t('homeViewAll')
        : _pick(i18n, section.viewAllLabel!.ar, section.viewAllLabel!.en);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.isEmpty ? i18n.t('homeProductsFallbackTitle') : title,
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                      ),
                  ],
                ),
              ),
              if (viewAllHref != null)
                TextButton(
                  onPressed: () => openHomeLink(context, viewAllHref),
                  child: Text(viewAllLabel,
                      style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 290,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => cards[i],
          ),
        ),
      ],
    );
  }
}

Product _withOverlay(Product p, HomeProductItem item) =>
    p.withOverlay(badge: item.badge, metaLabel: item.metaLabel);
