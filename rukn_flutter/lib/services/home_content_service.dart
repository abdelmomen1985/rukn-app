/// Admin-managed home page content (port of rukn-site/src/lib/homeCategories.ts and
/// rukn-site/src/lib/productSections.ts).
///
/// Three outcomes, and the home page treats them differently:
/// - `null`  — not answered yet, or the backend failed: keep the built-in content, so an outage
///             never blanks the home page.
/// - `[]`    — the operator switched every section off: render nothing.
/// - list    — render these, in the operator's order.
library;

import '../core/api.dart';
import '../core/config.dart';
import '../models/product.dart';
import 'catalog_service.dart';

enum HomeSectionLayout { circles, cards }

enum HomeSectionPlacement { hero, body }

class HomeCategoryTile {
  const HomeCategoryTile({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.image,
    required this.alt,
    required this.link,
    required this.categoryId,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;

  /// Absolute URL, or a site-relative path (resolved with [homeImageUrl]).
  final String image;
  final String alt;

  /// Own link — a site path, a `#anchor` or an http(s) URL. Wins over the category.
  final String? link;
  final String? categoryId;

  String get title => titleAr.isNotEmpty ? titleAr : titleEn;
}

class HomeViewAll {
  const HomeViewAll({required this.labelAr, required this.labelEn, required this.href});
  final String labelAr;
  final String labelEn;
  final String href;
}

class HomeCategorySection {
  const HomeCategorySection({
    required this.id,
    required this.layout,
    required this.placement,
    required this.titleAr,
    required this.titleEn,
    required this.viewAll,
    required this.tiles,
  });

  final String id;
  final HomeSectionLayout layout;
  final HomeSectionPlacement placement;
  final String titleAr;
  final String titleEn;
  final HomeViewAll? viewAll;
  final List<HomeCategoryTile> tiles;
}

/// One curated product card: the operator's selection plus its editorial overlay.
class HomeProductItem {
  const HomeProductItem({
    required this.id,
    required this.handle,
    required this.badgeDark,
    required this.badge,
    required this.metaLabel,
    required this.order,
  });

  final String id;
  final String handle;
  final bool badgeDark;
  final LocalizedText? badge;
  final LocalizedText? metaLabel;
  final int order;
}

class HomeProductSection {
  const HomeProductSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.viewAllLabel,
    required this.viewAllHref,
    required this.items,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText? subtitle;
  final LocalizedText? viewAllLabel;
  final String? viewAllHref;
  final List<HomeProductItem> items;
}

/// Where a link goes: a screen inside the app, or a URL to open outside it.
sealed class HomeLinkTarget {
  const HomeLinkTarget();
}

class InAppLink extends HomeLinkTarget {
  const InAppLink(this.route);
  final String route;
}

class ExternalLink extends HomeLinkTarget {
  const ExternalLink(this.url);
  final String url;
}

// ─── Parsers ─────────────────────────────────────────────────────────────

final _anchorLink = RegExp(r'^#[\w-]+$');
final _httpLink = RegExp(r'^https?://', caseSensitive: false);

/// A link becomes an href: a site path, a home-page anchor or http(s) only. The backend already
/// refuses anything else; this is the second line for a payload that did not come from it.
String? safeLink(Object? value) {
  if (value is! String) return null;
  final raw = value.trim();
  if (raw.isEmpty) return null;
  if (_anchorLink.hasMatch(raw)) return raw;
  if (raw.startsWith('/') && !raw.startsWith('//')) return raw;
  return _httpLink.hasMatch(raw) ? raw : null;
}

String _str(Object? value) => value is String ? value.trim() : '';

LocalizedText? _overlay(Object? value) {
  if (value is! Map) return null;
  final ar = _str(value['ar']);
  final en = _str(value['en']);
  return ar.isEmpty && en.isEmpty ? null : LocalizedText(ar, en);
}

/// Null means "keep the built-in rails"; a list (possibly empty) is the operator's answer.
List<HomeCategorySection>? toHomeCategorySections(Object? raw) {
  final body = asMap(raw);
  final entries = body['sections'];
  if (entries is! List) return null;

  final out = <HomeCategorySection>[];
  for (final entry in entries) {
    if (entry is! Map) continue;
    final e = asMap(entry);
    final tiles = <HomeCategoryTile>[];
    for (final rawItem in asList(e['items'])) {
      if (rawItem is! Map) continue;
      final item = asMap(rawItem);
      final image = safeLink(item['image_url']);
      final link = safeLink(item['link_url']);
      final category = item['category'] is Map ? asMap(item['category']) : const <String, dynamic>{};
      final categoryId = category['id'] is String && (category['id'] as String).isNotEmpty
          ? category['id'] as String
          : null;
      final titleAr = _str(item['title_ar']).isNotEmpty ? _str(item['title_ar']) : _str(category['name']);
      final titleEn = _str(item['title_en']);
      if (image == null || (link == null && categoryId == null) || (titleAr.isEmpty && titleEn.isEmpty)) {
        continue;
      }
      tiles.add(HomeCategoryTile(
        id: asString(item['id'], '${tiles.length}'),
        titleAr: titleAr,
        titleEn: titleEn,
        descriptionAr: _str(item['description_ar']),
        descriptionEn: _str(item['description_en']),
        image: image,
        alt: _str(item['image_alt']),
        link: link,
        categoryId: categoryId,
      ));
    }
    if (tiles.isEmpty) continue;

    final viewAllRaw = e['view_all'] is Map ? asMap(e['view_all']) : null;
    final viewAllHref = safeLink(viewAllRaw?['url']);
    final labelAr = _str(viewAllRaw?['label_ar']);
    final labelEn = _str(viewAllRaw?['label_en']);
    out.add(HomeCategorySection(
      id: asString(e['id'], '${out.length}'),
      layout: e['layout'] == 'circles' ? HomeSectionLayout.circles : HomeSectionLayout.cards,
      placement: e['placement'] == 'hero' ? HomeSectionPlacement.hero : HomeSectionPlacement.body,
      titleAr: _str(e['title_ar']),
      titleEn: _str(e['title_en']),
      viewAll: viewAllHref == null
          ? null
          : HomeViewAll(
              labelAr: labelAr.isNotEmpty ? labelAr : 'عرض الكل',
              labelEn: labelEn.isNotEmpty ? labelEn : 'View all',
              href: viewAllHref,
            ),
      tiles: tiles,
    ));
  }
  return out;
}

HomeProductItem? _productItem(Object? value) {
  if (value is! Map) return null;
  final v = asMap(value);
  final id = v['id'];
  final handle = v['handle'];
  if (id is! String || handle is! String || handle.isEmpty) return null;
  final order = v['order'];
  return HomeProductItem(
    id: id,
    handle: handle,
    badgeDark: v['badgeDark'] == true,
    badge: _overlay(v['badge']),
    metaLabel: _overlay(v['metaLabel']),
    order: order is num ? order.toInt() : 0,
  );
}

/// Null means "keep the built-in showcase"; a list (possibly empty) is the operator's answer.
List<HomeProductSection>? toProductSections(Object? payload) {
  final raw = asMap(payload)['sections'];
  if (raw is! List) return null;
  final out = <HomeProductSection>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final s = asMap(entry);
    if (s['id'] is! String) continue;
    final items = [for (final i in asList(s['items'])) ?_productItem(i)];
    if (items.isEmpty) continue;
    final va = s['viewAll'] is Map ? asMap(s['viewAll']) : null;
    final href = va == null ? null : safeLink(va['url']);
    out.add(HomeProductSection(
      id: s['id'] as String,
      title: _overlay(s['title']) ?? const LocalizedText('', ''),
      subtitle: _overlay(s['subtitle']),
      viewAllLabel: href == null ? null : _overlay(va!['label']),
      viewAllHref: href,
      items: items,
    ));
  }
  return out;
}

// ─── Links ───────────────────────────────────────────────────────────────

final _langPrefix = RegExp(r'^/(?:ar|en)(?=/|$)');
final _categoryPath = RegExp(r'^/category/([^/]+)/?$');
final _productPath = RegExp(r'^/product/([^/]+)/?$');
final _articlesPath = RegExp(r'^/articles/?$');
final _articlePath = RegExp(r'^/articles/([^/]+)/?$');
final _certificatePath = RegExp(r'^/certificate(?:/([^/]+))?/?$');
final _investPath = RegExp(r'^/invest/(zakat|converter|consultation|alerts)/?$');

/// Maps a home-page link to an in-app route where the app has the screen, and to the website
/// otherwise. Anchors and unknown site paths open on the website; http(s) opens as given.
HomeLinkTarget resolveSiteLink(String href, {required String lang, required String origin}) {
  final raw = href.trim();
  if (_httpLink.hasMatch(raw)) return ExternalLink(raw);

  final base = origin.replaceAll(RegExp(r'/+$'), '');
  if (!raw.startsWith('/')) {
    // A `#anchor` on the home page: the app has no such section, so the website shows it.
    return ExternalLink('$base/$lang/$raw');
  }

  // A link that names its language keeps it on the website, whatever the app language is.
  final explicitLang = _langPrefix.firstMatch(raw)?.group(0)?.substring(1);
  final websiteLang = explicitLang ?? lang;
  final queryAt = raw.indexOf('?');
  final pathOnly = (queryAt < 0 ? raw : raw.substring(0, queryAt)).replaceFirst(_langPrefix, '');
  String? route;
  if (_categoryPath.hasMatch(pathOnly)) {
    route = '/category/${_categoryPath.firstMatch(pathOnly)!.group(1)}';
  } else if (_productPath.hasMatch(pathOnly)) {
    route = '/product/${_productPath.firstMatch(pathOnly)!.group(1)}';
  } else if (_articlesPath.hasMatch(pathOnly)) {
    route = '/blog';
  } else if (_articlePath.hasMatch(pathOnly)) {
    route = '/blog/${_articlePath.firstMatch(pathOnly)!.group(1)}';
  } else if (pathOnly == '/pricing' || pathOnly == '/search') {
    route = pathOnly;
  } else if (_certificatePath.hasMatch(pathOnly)) {
    final serial = _certificatePath.firstMatch(pathOnly)!.group(1);
    route = serial == null ? '/certificate' : '/certificate?serial=${Uri.encodeQueryComponent(serial)}';
  } else if (_investPath.hasMatch(pathOnly)) {
    route = '/invest/${_investPath.firstMatch(pathOnly)!.group(1)}';
  }
  if (route != null) return InAppLink(route);
  return ExternalLink('$base/$websiteLang${raw.replaceFirst(_langPrefix, '')}');
}

/// The category route a tile falls back to when it has no link of its own.
String categoryRoute(String categoryId) => '/category/${Uri.encodeComponent(categoryId)}';

/// Site-relative images (`/categories/…`) are served by the website.
String homeImageUrl(String image) {
  if (!image.startsWith('/')) return image;
  return '${AppConfig.origin}$image';
}

// ─── Fetchers ────────────────────────────────────────────────────────────

/// Cached per app session. Only a real answer is cached; a failure is retried next time.
/// Never throws.
class HomeContentService {
  HomeContentService._();

  static List<HomeCategorySection>? _categories;
  static Future<List<HomeCategorySection>?>? _categoriesInflight;
  static List<HomeProductSection>? _productSections;
  static Future<List<HomeProductSection>?>? _productSectionsInflight;

  static Future<List<HomeCategorySection>?> homeCategories({bool refresh = false}) {
    if (!refresh && _categories != null) return Future.value(_categories);
    if (_categoriesInflight != null) return _categoriesInflight!;
    final future = () async {
      try {
        final sections = toHomeCategorySections(await Api.get('/store/home-categories'));
        if (sections != null) _categories = sections;
        return sections;
      } catch (_) {
        return null;
      } finally {
        _categoriesInflight = null;
      }
    }();
    _categoriesInflight = future;
    return future;
  }

  static Future<List<HomeProductSection>?> productSections({bool refresh = false}) {
    if (!refresh && _productSections != null) return Future.value(_productSections);
    if (_productSectionsInflight != null) return _productSectionsInflight!;
    final future = () async {
      try {
        final sections = toProductSections(await Api.get('/store/product-sections'));
        if (sections != null) _productSections = sections;
        return sections;
      } catch (_) {
        return null;
      } finally {
        _productSectionsInflight = null;
      }
    }();
    _productSectionsInflight = future;
    return future;
  }

  /// Resolves every handle the sections list, in one request. Throws on a failed request so the
  /// caller can fall back; a handle the store does not return simply stays absent.
  static Future<Map<String, Product>> resolveProducts(List<HomeProductSection> sections) {
    final handles = {for (final s in sections) for (final i in s.items) i.handle}.toList();
    return CatalogService.getProductsByHandles(handles);
  }

  /// Test hook: forget everything fetched so far.
  static void resetCache() {
    _categories = null;
    _categoriesInflight = null;
    _productSections = null;
    _productSectionsInflight = null;
  }
}
