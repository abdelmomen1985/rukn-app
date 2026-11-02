import 'dart:ui' show Color;

import '../core/api.dart';
import '../models/product.dart';

/// «العروض الخاصة» — offer labels («المصنعية 15 ريال بدلا من 40») edited in the admin and
/// published at `GET /store/special-offers`. Port of rukn-site/src/lib/specialOffers.ts.
///
/// TEXT ONLY. A label never changes a price: the merchant lowers the making charge (or the price)
/// in the admin, which the normal price already reflects, and the offer only says so.
///
/// Each offer is bound to hand-picked product ids and/or category ids. A product shows EVERY offer
/// that reaches it, direct ones first — [offersForProduct] mirrors the admin's
/// `src/utils/special-offers.ts`; change both together.
///
/// A read failure, a network error and a malformed payload all resolve to "no offers".
enum OfferColor { green, gold, emerald, cream, amber, ruby, charcoal }

/// The admin-chosen colour scheme of an offer. Mirrors `OFFER_PALETTES` on the site.
class OfferPalette {
  const OfferPalette({required this.bg, required this.ink, required this.soft, required this.border});
  final Color bg;
  final Color ink;
  final Color soft;
  final Color border;
}

const Map<OfferColor, OfferPalette> offerPalettes = {
  OfferColor.green: OfferPalette(
    bg: Color(0xFF041D18), ink: Color(0xFFFFC508), soft: Color(0xFFF4F1EA), border: Color(0x99FFC508)),
  OfferColor.gold: OfferPalette(
    bg: Color(0xFFFFC508), ink: Color(0xFF041D18), soft: Color(0xFF041D18), border: Color(0xFFE6B107)),
  OfferColor.emerald: OfferPalette(
    bg: Color(0xFF0B4A3B), ink: Color(0xFFFFFFFF), soft: Color(0xFFF4F1EA), border: Color(0xFF07352B)),
  OfferColor.cream: OfferPalette(
    bg: Color(0xFFF4F1EA), ink: Color(0xFF041D18), soft: Color(0xFF4A605C), border: Color(0xFFE6DCC0)),
  OfferColor.amber: OfferPalette(
    bg: Color(0xFF92400E), ink: Color(0xFFFFF3CD), soft: Color(0xFFFFF3CD), border: Color(0xFF7C350C)),
  OfferColor.ruby: OfferPalette(
    bg: Color(0xFFA61B1B), ink: Color(0xFFFFFFFF), soft: Color(0xFFFDE8E8), border: Color(0xFF8A1616)),
  OfferColor.charcoal: OfferPalette(
    bg: Color(0xFF141414), ink: Color(0xFFFFC508), soft: Color(0xFFE7E9EC), border: Color(0x73FFC508)),
};

/// A known scheme keeps its colour; a missing or unknown key reads as green, the original look.
OfferColor offerColorOf(Object? value) {
  for (final c in OfferColor.values) {
    if (c.name == value) return c;
  }
  return OfferColor.green;
}

class SpecialOffer {
  const SpecialOffer({
    required this.id,
    required this.badge,
    required this.text,
    required this.color,
    required this.productIds,
    required this.categoryIds,
  });

  final String id;
  final LocalizedText badge;
  final LocalizedText text;
  final OfferColor color;
  final List<String> productIds;
  final List<String> categoryIds;

  OfferPalette get palette => offerPalettes[color]!;
}

String _str(Object? value) => value is String ? value.trim() : '';

List<String> _ids(Object? value) =>
    value is List ? [for (final v in value) if (v is String && v.isNotEmpty) v] : const [];

/// Parses a `/store/special-offers` payload. Incomplete or unbound entries are dropped.
List<SpecialOffer> toSpecialOffers(Object? raw) {
  final body = asMap(raw);
  final entries = body['offers'];
  if (entries is! List) return const [];
  final out = <SpecialOffer>[];
  for (final entry in entries) {
    if (entry is! Map) continue;
    final e = asMap(entry);
    final badge = asMap(e['badge']);
    final text = asMap(e['text']);
    final badgeAr = _str(badge['ar']);
    final textAr = _str(text['ar']);
    if (badgeAr.isEmpty || textAr.isEmpty) continue;
    final productIds = _ids(e['product_ids']);
    final categoryIds = _ids(e['category_ids']);
    if (productIds.isEmpty && categoryIds.isEmpty) continue;
    final badgeEn = _str(badge['en']);
    final textEn = _str(text['en']);
    final rawId = e['id'];
    out.add(SpecialOffer(
      id: rawId == null ? '${out.length}' : '$rawId',
      badge: LocalizedText(badgeAr, badgeEn.isNotEmpty ? badgeEn : badgeAr),
      text: LocalizedText(textAr, textEn.isNotEmpty ? textEn : textAr),
      color: offerColorOf(e['color']),
      productIds: productIds,
      categoryIds: categoryIds,
    ));
  }
  return out;
}

/// Every offer reaching a product — picked directly first, then through a category — each once.
List<SpecialOffer> offersForProduct(String productId, List<String>? categoryIds, List<SpecialOffer> offers) {
  final cats = (categoryIds ?? const <String>[]).toSet();
  final direct = <SpecialOffer>[];
  final viaCategory = <SpecialOffer>[];
  for (final offer in offers) {
    if (offer.productIds.contains(productId)) {
      direct.add(offer);
    } else if (offer.categoryIds.any(cats.contains)) {
      viaCategory.add(offer);
    }
  }
  return [...direct, ...viaCategory];
}

/// The offers bound to a category itself — the category page's banner.
List<SpecialOffer> offersForCategory(String categoryId, List<SpecialOffer> offers) =>
    offers.where((o) => o.categoryIds.contains(categoryId)).toList();

/// One request per app session, shared by every card. Never throws. A payload without an `offers`
/// list (a backend read failure) is not cached, so a later call tries again.
class SpecialOffers {
  SpecialOffers._();

  static List<SpecialOffer>? _cached;
  static Future<List<SpecialOffer>>? _inflight;

  /// The offers already fetched, or null before the first successful read.
  static List<SpecialOffer>? get cached => _cached;

  static Future<List<SpecialOffer>> load() {
    final hit = _cached;
    if (hit != null) return Future.value(hit);
    return _inflight ??= _fetch();
  }

  static Future<List<SpecialOffer>> _fetch() async {
    try {
      final raw = await Api.get('/store/special-offers');
      final offers = toSpecialOffers(raw);
      if (asMap(raw)['offers'] is List) _cached = offers;
      return offers;
    } catch (_) {
      return const [];
    } finally {
      _inflight = null;
    }
  }
}
