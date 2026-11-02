import '../core/api.dart';
import '../models/product.dart';

class ProductPage {
  const ProductPage(this.products, this.count, {this.countKnown = true});
  final List<Product> products;
  /// Medusa's total for the query (falls back to this page's length when absent).
  final int count;
  /// False when Medusa sent no `count`; such a listing has nothing more to load.
  final bool countKnown;
}

/// Products a category listing asks Medusa for per request: the first page and each «عرض المزيد».
const int categoryPageSize = 100;

/// Keeps the first occurrence of each id, in the order given (port of `uniqueById`).
List<T> uniqueById<T>(Iterable<T> items, String Function(T) idOf) {
  final seen = <String>{};
  return [
    for (final item in items)
      if (seen.add(idOf(item))) item,
  ];
}

/// [shown] followed by [next], still one entry per id (port of `appendPage`).
List<T> appendPage<T>(List<T> shown, List<T> next, String Function(T) idOf) =>
    uniqueById([...shown, ...next], idOf);

/// Whether «عرض المزيد» has anything left. Medusa's total is the authority; with no total
/// there is nothing more to fetch (port of `hasMoreProducts`).
bool hasMoreProducts(int loaded, int? total) => total != null && loaded < total;

class Review {
  const Review({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.title,
    required this.body,
    this.createdAt,
  });
  final String id;
  final String customerName;
  final int rating;
  final String title;
  final String body;
  final String? createdAt;
}

class ExclusiveItem {
  const ExclusiveItem({required this.handle, this.productId, this.badge, this.metaLabel, this.order = 0});
  final String handle;
  final String? productId;
  final LocalizedText? badge;
  final LocalizedText? metaLabel;
  final int order;
}

/// Catalogue reads (port of rukn-site/src/lib/store.ts).
class CatalogService {
  CatalogService._();

  static Future<String>? _region;

  /// Resolves (and caches) the SAR region used for pricing and carts.
  static Future<String> regionId() {
    return _region ??= () async {
      try {
        final data = asMap(await Api.get('/store/regions'));
        final regions = [for (final r in asList(data['regions'])) asMap(r)];
        final region = regions.firstWhere(
          (r) => r['currency_code'] == 'sar',
          orElse: () => regions.isNotEmpty ? regions.first : <String, dynamic>{},
        );
        final id = asStringOrNull(region['id']);
        if (id == null) throw StateError('No region configured in Medusa');
        return id;
      } catch (e) {
        _region = null;
        rethrow;
      }
    }();
  }

  static Future<ProductPage> listProducts({
    String? categoryId,
    String? query,
    int limit = 24,
    int offset = 0,
  }) async {
    final region = await regionId();
    final params = <String>[
      'region_id=$region',
      'limit=$limit',
      'offset=$offset',
      'fields=$productFields',
      if (categoryId != null) 'category_id=${Uri.encodeQueryComponent(categoryId)}',
      if (query != null && query.trim().isNotEmpty) 'q=${Uri.encodeQueryComponent(query.trim())}',
    ];
    final data = asMap(await Api.get('/store/products?${params.join('&')}'));
    final products = [for (final p in asList(data['products'])) mapProduct(asMap(p))];
    final total = asInt(data['count']);
    return ProductPage(products, total ?? products.length, countKnown: total != null);
  }

  /// Accepts a `prod_…` id or a handle.
  static Future<Product?> getProduct(String idOrHandle) async {
    final region = await regionId();
    final filter = idOrHandle.startsWith('prod_')
        ? 'id=${Uri.encodeQueryComponent(idOrHandle)}'
        : 'handle=${Uri.encodeQueryComponent(idOrHandle)}';
    final data = asMap(await Api.get('/store/products?$filter&region_id=$region&fields=$productFields'));
    final list = asList(data['products']);
    return list.isEmpty ? null : mapProduct(asMap(list.first));
  }

  static Future<List<Product>> getProductsByIds(List<String> ids) async {
    final unique = ids.toSet().where((e) => e.isNotEmpty).toList();
    if (unique.isEmpty) return [];
    final region = await regionId();
    final params = unique.map((id) => 'id[]=${Uri.encodeQueryComponent(id)}').join('&');
    final data = asMap(await Api.get(
        '/store/products?$params&region_id=$region&limit=${unique.length}&fields=$productFields'));
    return [for (final p in asList(data['products'])) mapProduct(asMap(p))];
  }

  static Future<Map<String, Product>> getProductsByHandles(List<String> handles) async {
    if (handles.isEmpty) return {};
    final region = await regionId();
    final params = handles.map((h) => 'handle[]=${Uri.encodeQueryComponent(h)}').join('&');
    final data = asMap(await Api.get(
        '/store/products?$params&region_id=$region&limit=${handles.length}&fields=$productFields'));
    final result = <String, Product>{};
    for (final p in asList(data['products'])) {
      final product = mapProduct(asMap(p));
      if (product.handle.isNotEmpty) result[product.handle] = product;
    }
    return result;
  }

  /// Authoritative current price of every variant of the given products.
  static Future<Map<String, double>> getVariantPrices(List<String> productIds) async {
    final ids = productIds.toSet().where((e) => e.isNotEmpty).toList();
    if (ids.isEmpty) return {};
    final region = await regionId();
    final params = ids.map((id) => 'id[]=${Uri.encodeQueryComponent(id)}').join('&');
    final data = asMap(await Api.get(
        '/store/products?$params&region_id=$region&limit=${ids.length}&fields=id,*variants,*variants.calculated_price'));
    final prices = <String, double>{};
    for (final p in asList(data['products'])) {
      for (final v in asList(asMap(p)['variants'])) {
        final vm = asMap(v);
        final amount = asDouble(asMap(vm['calculated_price'])['calculated_amount']);
        if (amount != null) prices[asString(vm['id'])] = amount;
      }
    }
    return prices;
  }

  static Future<List<Category>> listCategories() async {
    final data = asMap(await Api.get(
        '/store/product-categories?limit=200&fields=id,name,handle,description,metadata,parent_category_id'));
    return [for (final c in asList(data['product_categories'])) mapCategory(asMap(c))];
  }

  static Future<List<ExclusiveItem>> exclusiveProducts() async {
    try {
      final data = asMap(await Api.get('/store/exclusive-products'));
      final items = [
        for (final raw in asList(data['items']))
          () {
            final m = asMap(raw);
            LocalizedText? text(Object? v) {
              final t = asMap(v);
              final ar = asString(t['ar']);
              final en = asString(t['en']);
              return ar.isEmpty && en.isEmpty ? null : LocalizedText.bilingual(ar.isEmpty ? en : ar, en);
            }

            return ExclusiveItem(
              handle: asString(m['handle']),
              productId: asStringOrNull(m['productId']),
              badge: text(m['badge']),
              metaLabel: text(m['metaLabel']),
              order: asInt(m['order']) ?? 0,
            );
          }(),
      ]..sort((a, b) => a.order.compareTo(b.order));
      return items;
    } catch (_) {
      return [];
    }
  }

  static Future<List<Review>> listReviews(String productId) async {
    final data = asMap(await Api.get('/store/reviews?productId=${Uri.encodeQueryComponent(productId)}'));
    return [
      for (final r in asList(data['reviews']))
        () {
          final m = asMap(r);
          return Review(
            id: asString(m['id']),
            customerName: asString(m['customerName']),
            rating: (asInt(m['rating']) ?? 0).clamp(0, 5),
            title: asString(m['title']),
            body: asString(m['body']),
            createdAt: asStringOrNull(m['createdAt']),
          );
        }(),
    ];
  }

  /// Submitted reviews stay "pending" until approved in the admin.
  static Future<void> submitReview({
    required String productId,
    required String customerName,
    String? customerEmail,
    required int rating,
    required String title,
    required String body,
  }) async {
    await Api.post('/store/reviews', {
      'productId': productId,
      'customerName': customerName,
      if (customerEmail != null && customerEmail.isNotEmpty) 'customerEmail': customerEmail,
      'rating': rating,
      'title': title,
      'body': body,
    });
  }
}
