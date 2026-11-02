import '../core/api.dart';

const fallbackProductImage =
    'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800&q=80';

/// Bilingual text (Arabic is the catalogue's source language).
class LocalizedText {
  const LocalizedText(this.ar, this.en);
  final String ar;
  final String en;

  factory LocalizedText.bilingual(String ar, [String? en]) =>
      LocalizedText(ar, (en == null || en.isEmpty) ? ar : en);

  String of(String lang) => lang == 'ar' ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);
  bool get isEmpty => ar.isEmpty && en.isEmpty;

  Map<String, dynamic> toJson() => {'ar': ar, 'en': en};
  factory LocalizedText.fromJson(Object? json) {
    final m = asMap(json);
    return LocalizedText(asString(m['ar']), asString(m['en']));
  }
}

enum ProductOptionKind { size, weight, other }

class ProductOption {
  const ProductOption({required this.title, required this.kind, required this.values});
  final String title;
  final ProductOptionKind kind;
  final List<String> values;
}

/// One buyable variant of a product.
class PurchaseOption {
  const PurchaseOption({
    required this.variantId,
    required this.title,
    required this.choices,
    this.size,
    this.price,
    this.sku,
    this.weight,
  });

  final String variantId;
  final String title;
  final String? size;
  final Map<String, String> choices;
  final double? price;
  final String? sku;
  final LocalizedText? weight;
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.metaLabel,
    required this.weight,
    required this.basePrice,
    required this.image,
    required this.images,
    required this.purchaseOptions,
    required this.options,
    required this.categoryIds,
    required this.handle,
    this.oldPrice,
    this.badge,
    this.description,
    this.variantId,
    this.certificateSerial,
    this.karat,
    this.isSilver = false,
    this.isBar = false,
  });

  final String id;
  final String handle;
  final LocalizedText name;
  final LocalizedText metaLabel;
  final LocalizedText weight;

  /// Price of the default (cheapest priced) variant, in SAR, VAT inclusive.
  final double basePrice;
  final double? oldPrice;
  final String image;
  final List<String> images;
  final LocalizedText? badge;
  final String? description;
  final String? variantId;
  final String? certificateSerial;
  final String? karat;
  final bool isSilver;
  final bool isBar;
  final List<PurchaseOption> purchaseOptions;
  final List<ProductOption> options;
  final List<String> categoryIds;

  /// The 21K catalogue rate when this product's prices were read; live display
  /// prices are scaled from it (see PriceScaler).
  double? baseline;

  bool get isPurchasable => variantId != null;

  /// This product with an editorial badge / meta label laid over it (admin product sections).
  /// Ids, prices and variants are unchanged, so cart and wishlist behave as for the product itself.
  Product withOverlay({LocalizedText? badge, LocalizedText? metaLabel}) {
    if (badge == null && metaLabel == null) return this;
    return Product(
      id: id,
      handle: handle,
      name: name,
      metaLabel: metaLabel ?? this.metaLabel,
      weight: weight,
      basePrice: basePrice,
      oldPrice: oldPrice,
      image: image,
      images: images,
      badge: badge ?? this.badge,
      description: description,
      variantId: variantId,
      certificateSerial: certificateSerial,
      karat: karat,
      isSilver: isSilver,
      isBar: isBar,
      purchaseOptions: purchaseOptions,
      options: options,
      categoryIds: categoryIds,
    )..baseline = baseline;
  }
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.handle,
    this.parentId,
    this.description,
  });

  final String id;
  final LocalizedText name;
  final String handle;
  final String? parentId;
  final String? description;

  bool get isTopLevel => parentId == null;
}

// ---------------------------------------------------------------------------
// Mapping from the Medusa store payload (port of rukn-site/src/lib/store.ts)
// ---------------------------------------------------------------------------

const productFields = 'id,title,subtitle,handle,description,thumbnail,metadata,*images,*categories,'
    '*variants,*variants.options,*variants.options.option,*variants.calculated_price';

final _sizeOption = RegExp(r'size|مقاس', caseSensitive: false);
final _weightOption = RegExp(r'weight|وزن', caseSensitive: false);

String _meta(Map<String, dynamic> m, String key) {
  final v = asMap(m['metadata'])[key];
  return v == null ? '' : '$v';
}

double? _variantPrice(Map<String, dynamic> variant) =>
    asDouble(asMap(variant['calculated_price'])['calculated_amount']);

String _variantWeight(Map<String, dynamic> variant, Map<String, dynamic> product) {
  final v = asMap(variant['metadata'])['weight_grams'];
  if (v != null && '$v'.isNotEmpty) return '$v';
  return _meta(product, 'weight_grams');
}

bool isBarProduct(Map<String, dynamic> product, [Map<String, dynamic>? variant]) {
  final variantMetal = asMap(variant?['metadata'])['metal'];
  if (variantMetal != null && '$variantMetal'.isNotEmpty) return true;
  return _meta(product, 'metal').isNotEmpty;
}

Map<String, String> _variantChoices(Map<String, dynamic> variant) {
  final choices = <String, String>{};
  for (final o in asList(variant['options'])) {
    final om = asMap(o);
    final title = asString(asMap(om['option'])['title']);
    final value = asString(om['value']);
    if (title.isNotEmpty && value.isNotEmpty) choices[title] = value;
  }
  return choices;
}

/// Sizes smallest first, numeric on the digits inside the label.
List<String> sortSizes(List<String> values) {
  double? numberIn(String v) {
    final western = v.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(western);
    return match == null ? null : double.tryParse(match[0]!);
  }

  final entries = [for (var i = 0; i < values.length; i++) (value: values[i], index: i, n: numberIn(values[i]))];
  entries.sort((a, b) {
    if (a.n != null && b.n != null) {
      final c = a.n!.compareTo(b.n!);
      return c != 0 ? c : a.index - b.index;
    }
    if (a.n != null) return -1;
    if (b.n != null) return 1;
    return a.index - b.index;
  });
  return [for (final e in entries) e.value];
}

LocalizedText _weightText(String grams) => LocalizedText('الوزن $grams جم', 'Weight $grams g');

Product mapProduct(Map<String, dynamic> p) {
  final variants = [for (final v in asList(p['variants'])) asMap(v)];
  final priced = variants.where((v) => _variantPrice(v) != null).toList()
    ..sort((a, b) => _variantPrice(a)!.compareTo(_variantPrice(b)!));
  final variant = priced.isNotEmpty ? priced.first : (variants.isNotEmpty ? variants.first : null);

  final karat = _meta(p, 'karat');
  final isSilver = [
    _meta(p, 'price_metal'),
    asString(asMap(variant?['metadata'])['metal']),
    _meta(p, 'metal'),
  ].any((v) => v.toLowerCase() == 'silver');
  final weight = variant != null ? _variantWeight(variant, p) : _meta(p, 'weight_grams');
  final fromPrice = double.tryParse(_meta(p, 'from_price'));
  final basePrice = (variant != null ? _variantPrice(variant) : null) ?? fromPrice ?? 0;

  // Option pickers: offered when values tell variants apart; a lone size is still shown.
  final byTitle = <String, List<String>>{};
  for (final v in variants) {
    _variantChoices(v).forEach((title, value) {
      final list = byTitle.putIfAbsent(title, () => []);
      if (!list.contains(value)) list.add(value);
    });
  }
  final options = <ProductOption>[];
  byTitle.forEach((title, values) {
    final kind = _sizeOption.hasMatch(title)
        ? ProductOptionKind.size
        : (_weightOption.hasMatch(title) ? ProductOptionKind.weight : ProductOptionKind.other);
    if (values.length < 2 && kind != ProductOptionKind.size) return;
    options.add(ProductOption(title: title, kind: kind, values: sortSizes(values)));
  });
  options.sort((x, y) => (y.kind == ProductOptionKind.size ? 1 : 0) - (x.kind == ProductOptionKind.size ? 1 : 0));

  final purchaseOptions = [
    for (final v in variants)
      () {
        final choices = _variantChoices(v);
        final size = choices.entries.where((e) => _sizeOption.hasMatch(e.key)).map((e) => e.value).firstOrNull;
        final grams = _variantWeight(v, p);
        return PurchaseOption(
          variantId: asString(v['id']),
          title: asString(v['title']),
          size: size,
          choices: choices,
          price: _variantPrice(v),
          sku: asStringOrNull(v['sku']),
          weight: grams.isNotEmpty ? _weightText(grams) : null,
        );
      }(),
  ];

  final title = asString(p['title']);
  final titleEn = _meta(p, 'title_en');
  final badgeAr = _meta(p, 'badge_ar');
  final badgeEn = _meta(p, 'badge_en');
  final oldPrice = double.tryParse(_meta(p, 'old_price'));
  final subtitle = asString(p['subtitle']);
  final images = [
    for (final i in asList(p['images']))
      if (asStringOrNull(asMap(i)['url']) != null) asString(asMap(i)['url']),
  ];
  final thumb = asStringOrNull(p['thumbnail']) ?? (images.isNotEmpty ? images.first : fallbackProductImage);
  final bar = isBarProduct(p, variant);

  return Product(
    id: asString(p['id']),
    handle: asString(p['handle']),
    name: LocalizedText.bilingual(title, titleEn),
    metaLabel: karat.isNotEmpty
        ? (isSilver
            ? LocalizedText('فضة عيار $karat', '$karat Silver')
            : LocalizedText('ذهب عيار $karat', '${karat}K Gold'))
        : LocalizedText.bilingual(subtitle, subtitle),
    weight: weight.isNotEmpty ? _weightText(weight) : const LocalizedText('', ''),
    basePrice: basePrice,
    oldPrice: oldPrice,
    image: thumb,
    images: images.isEmpty ? [thumb] : ([thumb, ...images.where((i) => i != thumb)]),
    badge: badgeAr.isNotEmpty || badgeEn.isNotEmpty
        ? LocalizedText(badgeAr.isNotEmpty ? badgeAr : badgeEn, badgeEn.isNotEmpty ? badgeEn : badgeAr)
        : null,
    description: asStringOrNull(p['description']),
    variantId: asStringOrNull(variant?['id']),
    certificateSerial: bar ? asStringOrNull(variant?['sku']) : null,
    karat: karat.isEmpty ? null : karat,
    isSilver: isSilver,
    isBar: bar,
    purchaseOptions: purchaseOptions,
    options: options,
    categoryIds: [for (final c in asList(p['categories'])) asString(asMap(c)['id'])],
  );
}

Category mapCategory(Map<String, dynamic> c) {
  final name = asString(c['name']);
  final nameEn = asString(asMap(c['metadata'])['name_en']);
  return Category(
    id: asString(c['id']),
    name: LocalizedText.bilingual(name, nameEn),
    handle: asString(c['handle']),
    parentId: asStringOrNull(c['parent_category_id']),
    description: asStringOrNull(c['description']),
  );
}
