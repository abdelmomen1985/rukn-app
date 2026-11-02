import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../services/site_analytics.dart';
import '../services/store_settings.dart';

/// A cart line. Keyed by variant so two sizes of one ring are two lines.
class CartItem {
  CartItem({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    this.optionLabel,
  });

  final String id;
  final String productId;
  final String? variantId;
  final LocalizedText name;
  final String image;
  double price;
  int quantity;
  final String? optionLabel;

  double get lineTotal => price * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'variantId': variantId,
        'name': name.toJson(),
        'image': image,
        'price': price,
        'quantity': quantity,
        'optionLabel': optionLabel,
      };

  static CartItem? fromJson(Object? raw) {
    final m = asMap(raw);
    final price = asDouble(m['price']);
    final qty = asInt(m['quantity']) ?? 0;
    if (asStringOrNull(m['id']) == null || price == null || qty <= 0) return null;
    return CartItem(
      id: asString(m['id']),
      productId: asString(m['productId']),
      variantId: asStringOrNull(m['variantId']),
      name: LocalizedText.fromJson(m['name']),
      image: asString(m['image'], fallbackProductImage),
      price: price,
      quantity: qty,
      optionLabel: asStringOrNull(m['optionLabel']),
    );
  }
}

class CartState extends ChangeNotifier {
  static const _key = 'cart_v2';

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (s, i) => s + i.quantity);
  double get subtotal => _items.fold(0.0, (s, i) => s + i.lineTotal);
  bool get isEmpty => _items.isEmpty;
  bool contains(String productId) => _items.any((i) => i.productId == productId);

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) {
        _items
          ..clear()
          ..addAll([for (final e in asList(jsonDecode(raw))) ?CartItem.fromJson(e)]);
      }
    } catch (_) {}
    notifyListeners();
    // Warm the branch catalogue so the add-to-cart check runs synchronously.
    StoreSettings.branchCatalog();
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance())
          .setString(_key, jsonEncode([for (final i in _items) i.toJson()]));
    } catch (_) {}
  }

  /// Adds one unit. Returns a human-readable refusal when the product is
  /// exclusive to a branch other than the one the cart is already tied to.
  String? add(Product product, {PurchaseOption? option, double? price, int quantity = 1, required String lang}) {
    final conflict = StoreSettings.cachedBranchCatalog
        .addToCartConflict(_items.map((i) => i.productId), product.id, lang);
    if (conflict != null) return conflict;
    final variantId = option?.variantId ?? product.variantId;
    final id = variantId ?? product.id;
    final unit = price ?? option?.price ?? product.basePrice;
    if (!unit.isFinite) return null;
    final existing = _items.where((i) => i.id == id).firstOrNull;
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      final label = option == null || option.choices.isEmpty ? null : option.choices.values.join(' · ');
      _items.add(CartItem(
        id: id,
        productId: product.id,
        variantId: variantId,
        name: product.name,
        image: product.image,
        price: unit,
        quantity: quantity,
        optionLabel: label,
      ));
    }
    SiteAnalytics.shared.addedToCart(productId: product.id, variantId: id, value: unit * quantity);
    _save();
    return null;
  }

  void increment(String id) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;
    item.quantity++;
    _save();
  }

  void decrement(String id) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;
    if (item.quantity <= 1) {
      _items.remove(item);
    } else {
      item.quantity--;
    }
    _save();
  }

  void remove(String id) {
    _items.removeWhere((i) => i.id == id);
    _save();
  }

  void clear() {
    _items.clear();
    _save();
  }

  DateTime? _pricedAt;
  DateTime? get pricedAt => _pricedAt;

  /// Re-reads every line's authoritative variant price from Medusa.
  Future<void> reprice() async {
    if (_items.isEmpty) return;
    try {
      final prices = await CatalogService.getVariantPrices(_items.map((i) => i.productId).toList());
      var changed = false;
      for (final item in _items) {
        final p = item.variantId == null ? null : prices[item.variantId];
        if (p != null && p > 0 && p != item.price) {
          item.price = p;
          changed = true;
        }
      }
      _pricedAt = DateTime.now();
      if (changed) {
        await _save();
      } else {
        notifyListeners();
      }
    } catch (_) {}
  }
}
