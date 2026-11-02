import '../core/api.dart';
import '../models/product.dart';
import 'catalog_service.dart';

class Article {
  const Article({
    required this.slug,
    required this.titleAr,
    required this.titleEn,
    required this.contentAr,
    required this.contentEn,
    required this.excerptAr,
    required this.excerptEn,
    this.badge,
    this.publishedAt,
    this.image,
  });

  final String slug;
  final String titleAr;
  final String titleEn;
  final String contentAr;
  final String contentEn;
  final String excerptAr;
  final String excerptEn;
  final String? badge;
  final String? publishedAt;
  final String? image;

  String title(String lang) => lang == 'ar' ? (titleAr.isNotEmpty ? titleAr : titleEn) : (titleEn.isNotEmpty ? titleEn : titleAr);
  String content(String lang) => lang == 'ar' ? (contentAr.isNotEmpty ? contentAr : contentEn) : (contentEn.isNotEmpty ? contentEn : contentAr);
  String excerpt(String lang) {
    final e = lang == 'ar' ? (excerptAr.isNotEmpty ? excerptAr : excerptEn) : (excerptEn.isNotEmpty ? excerptEn : excerptAr);
    if (e.isNotEmpty) return e;
    final text = stripHtml(content(lang));
    return text.length > 160 ? '${text.substring(0, 160).trim()}…' : text;
  }

  int readMinutes(String lang) {
    final words = stripHtml(content(lang)).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return (words / 200).round().clamp(1, 999);
  }
}

String stripHtml(String html) => html
    .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
    .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
    .replaceAll(RegExp(r'<[^>]+>'), ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class CertificateInfo {
  const CertificateInfo({
    required this.serial,
    required this.metal,
    required this.weightGrams,
    required this.purity,
    required this.refiner,
    required this.assayer,
    required this.mintedAt,
    required this.issuedAt,
    required this.dimensions,
    required this.revoked,
    required this.product,
    required this.registeredAt,
  });

  final String serial;
  final String metal;
  final double? weightGrams;
  final String purity;
  final LocalizedText? refiner;
  final LocalizedText? assayer;
  final String? mintedAt;
  final String? issuedAt;
  final String? dimensions;
  final bool revoked;
  final Product product;
  final String? registeredAt;
}

String normalizeSerial(String raw) => raw
    .trim()
    .toUpperCase()
    .replaceAll(RegExp(r'[\s._‐-―-]+'), '-')
    .replaceAll(RegExp(r'-{2,}'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

String formatSerial(String serial) => serial.replaceAll('-', ' · ');

class ContentService {
  ContentService._();

  // --- Blog --------------------------------------------------------------------

  static String _pick(Map<String, dynamic> post, String field, String lang) {
    final fromTranslations = asString(asMap(asMap(post['translations'])[lang])[field]);
    if (fromTranslations.trim().isNotEmpty) return fromTranslations;
    final fromLangField = asString(post['${field}_$lang']);
    if (fromLangField.trim().isNotEmpty) return fromLangField;
    if (lang == 'en') {
      // English falls back to the base field only when that field is English;
      // the base is Arabic in this CMS, so leave English empty and let the UI fall back.
      return '';
    }
    final base = asString(post[field]);
    if (base.trim().isNotEmpty) return base;
    if (field == 'content') {
      for (final alias in ['contentHtml', 'htmlContent', 'body']) {
        final v = asString(post[alias]);
        if (v.trim().isNotEmpty) return v;
      }
    }
    return '';
  }

  static Article? _mapArticle(Map<String, dynamic> post) {
    final slug = asStringOrNull(post['slug']) ?? asStringOrNull(post['handle']);
    if (slug == null) return null;
    final badge = asStringOrNull(post['category']) ?? asStringOrNull(post['tag']);
    return Article(
      slug: slug,
      titleAr: _pick(post, 'title', 'ar'),
      titleEn: _pick(post, 'title', 'en'),
      contentAr: _pick(post, 'content', 'ar'),
      contentEn: _pick(post, 'content', 'en'),
      excerptAr: _pick(post, 'excerpt', 'ar'),
      excerptEn: _pick(post, 'excerpt', 'en'),
      badge: badge,
      publishedAt: asStringOrNull(post['published_at']),
      image: asStringOrNull(post['cover_image']) ?? asStringOrNull(post['image']) ?? asStringOrNull(post['thumbnail']),
    );
  }

  static Future<List<Article>> blogPosts({int limit = 20, int offset = 0}) async {
    final data = asMap(await Api.get('/store/blog?limit=$limit&offset=$offset'));
    return [for (final p in asList(data['data'])) ?_mapArticle(asMap(p))];
  }

  static Future<Article?> blogPost(String slug) async {
    try {
      final data = asMap(await Api.get('/store/blog/${Uri.encodeComponent(slug)}'));
      return _mapArticle(asMap(data['data']));
    } on MedusaError catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  // --- Bar certificates -----------------------------------------------------------

  static String _variantMeta(Map<String, dynamic> variant, Map<String, dynamic> product, String key) {
    final v = asMap(variant['metadata'])[key];
    if (v != null && '$v'.isNotEmpty) return '$v';
    final p = asMap(product['metadata'])[key];
    return p == null ? '' : '$p';
  }

  static LocalizedText? _localized(Map<String, dynamic> v, Map<String, dynamic> p, String key) {
    final ar = _variantMeta(v, p, key);
    final en = _variantMeta(v, p, '${key}_en');
    if (ar.isEmpty && en.isEmpty) return null;
    return LocalizedText.bilingual(ar.isNotEmpty ? ar : en, en.isNotEmpty ? en : ar);
  }

  static Future<CertificateInfo?> lookupCertificate(String serialInput) async {
    final serial = normalizeSerial(serialInput);
    if (serial.isEmpty) return null;
    Map<String, dynamic> bar;
    try {
      bar = asMap(asMap(await Api.get('/store/bar-serials/${Uri.encodeComponent(serial)}'))['bar']);
    } on MedusaError catch (e) {
      if (e.status == 404 || e.status == 400) return null;
      rethrow;
    }
    final productId = asStringOrNull(bar['product_id']);
    if (productId == null) return null;
    final region = await CatalogService.regionId();
    final data = asMap(await Api.get(
        '/store/products?id=${Uri.encodeQueryComponent(productId)}&region_id=$region&limit=1&fields=$productFields'));
    final products = asList(data['products']);
    if (products.isEmpty) return null;
    final p = asMap(products.first);
    final variants = [for (final v in asList(p['variants'])) asMap(v)];
    final variantId = asStringOrNull(bar['variant_id']);
    final v = variants.where((x) => x['id'] == variantId).firstOrNull ?? variants.firstOrNull;
    if (v == null || !isBarProduct(p, v)) return null;
    final weight = double.tryParse(_variantMeta(v, p, 'weight_grams'));
    return CertificateInfo(
      serial: asString(bar['serial'], serial),
      metal: _variantMeta(v, p, 'metal').toLowerCase() == 'silver' ? 'silver' : 'gold',
      weightGrams: weight,
      purity: _variantMeta(v, p, 'purity'),
      refiner: _localized(v, p, 'refiner'),
      assayer: _localized(v, p, 'assayer'),
      mintedAt: _variantMeta(v, p, 'minted_at').isEmpty ? null : _variantMeta(v, p, 'minted_at'),
      issuedAt: _variantMeta(v, p, 'issued_at').isEmpty ? null : _variantMeta(v, p, 'issued_at'),
      dimensions: _variantMeta(v, p, 'dimensions').isEmpty ? null : _variantMeta(v, p, 'dimensions'),
      revoked: _variantMeta(v, p, 'certificate_status').toLowerCase() == 'revoked',
      product: mapProduct(p),
      registeredAt: asStringOrNull(bar['registered_at']),
    );
  }

  /// Serials of the bars in an order, keyed by line item id.
  static Future<Map<String, List<String>>> orderBarSerials(String orderId) async {
    final serials = <String, List<String>>{};
    try {
      final data = asMap(await Api.get('/store/bar-serials?order_id=${Uri.encodeQueryComponent(orderId)}'));
      for (final b in asList(data['bars'])) {
        final m = asMap(b);
        final line = asStringOrNull(m['line_item_id']);
        final serial = asStringOrNull(m['serial']);
        if (line == null || serial == null) continue;
        serials.putIfAbsent(line, () => []).add(serial);
      }
    } catch (_) {}
    return serials;
  }
}
