import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../models/portfolio.dart';
import '../services/invest_service.dart';

class PortfolioSummary {
  const PortfolioSummary(this.totalValue, this.totalCost, this.metalValues, this.assetCount);
  final double totalValue;
  final double totalCost;
  final Map<String, double> metalValues;
  final int assetCount;
  double get gainLoss => totalValue - totalCost;
  double get gainLossPercent => totalCost > 0 ? gainLoss / totalCost * 100 : 0;
}

/// Investment portfolio.
///
/// Signed-in customers: the Medusa portfolio module (`/store/portfolio-assets`)
/// is the source of truth and the device keeps a per-customer cache for instant
/// paint. Guests get a device-only portfolio. Spot prices refresh every 60 s.
class PortfolioState extends ChangeNotifier {
  static const _spotKey = 'spot_prices_cache';
  static const pollInterval = Duration(seconds: 60);

  List<PortfolioAsset> _assets = [];
  List<PortfolioAsset> get assets => List.unmodifiable(_assets);
  SpotPrices? _spot;
  SpotPrices? get spot => _spot;
  bool _loadingPrices = true;
  bool get loadingPrices => _loadingPrices;
  bool get isOffline => _spot?.isStale ?? false;
  bool _syncing = false;
  bool get syncing => _syncing;
  String? _customerId;
  Timer? _timer;

  String _storageKey(String? customerId) => 'portfolio:${customerId ?? 'guest'}';

  void start() {
    if (_timer != null) return;
    refreshPrices();
    _timer = Timer.periodic(pollInterval, (_) => refreshPrices());
  }

  /// Switches the portfolio to [customerId] (null = guest) and loads it.
  Future<void> setCustomer(String? customerId) async {
    if (customerId == _customerId && _assets.isNotEmpty) return;
    _customerId = customerId;
    final prefs = await SharedPreferences.getInstance();
    _assets = _decode(prefs.getString(_storageKey(customerId)));
    notifyListeners();
    if (customerId == null) return;
    try {
      _assets = await InvestService.listAssets();
      await _cache();
      notifyListeners();
    } catch (_) {
      // offline / expired token — cached copy stays
    }
  }

  List<PortfolioAsset> _decode(String? raw) {
    if (raw == null) return [];
    try {
      return [for (final a in asList(jsonDecode(raw))) PortfolioAsset.fromJson(asMap(a))];
    } catch (_) {
      return [];
    }
  }

  Future<void> _cache() async {
    try {
      await (await SharedPreferences.getInstance())
          .setString(_storageKey(_customerId), jsonEncode([for (final a in _assets) a.toJson()]));
    } catch (_) {}
  }

  void _persist(List<PortfolioAsset> next) {
    _assets = next;
    notifyListeners();
    _cache();
  }

  Future<void> _sync(Future<void> Function() action) async {
    _syncing = true;
    notifyListeners();
    try {
      await action();
    } catch (_) {
      // local copy remains; reconciled on the next full load
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> addAsset(PortfolioAsset asset) async {
    final now = DateTime.now().toIso8601String();
    final tempId = 'asset-${DateTime.now().millisecondsSinceEpoch}';
    final local = asset.copyWith(id: tempId, createdAt: now, updatedAt: now);
    _persist([..._assets, local]);
    if (_customerId == null) return;
    await _sync(() async {
      final created = await InvestService.createAsset(local);
      if (!_assets.any((a) => a.id == tempId)) {
        await InvestService.deleteAsset(created.id);
        return;
      }
      _persist([for (final a in _assets) a.id == tempId ? created : a]);
    });
  }

  Future<void> updateAsset(PortfolioAsset asset) async {
    final updated = asset.copyWith(updatedAt: DateTime.now().toIso8601String());
    _persist([for (final a in _assets) a.id == asset.id ? updated : a]);
    if (_customerId == null || !asset.isServerRow) return;
    await _sync(() async {
      final saved = await InvestService.updateAsset(updated);
      _persist([for (final a in _assets) a.id == asset.id ? saved : a]);
    });
  }

  Future<void> deleteAsset(String id) async {
    _persist(_assets.where((a) => a.id != id).toList());
    if (_customerId == null || !id.startsWith('passet_')) return;
    await _sync(() => InvestService.deleteAsset(id));
  }

  PortfolioAsset? byId(String id) => _assets.where((a) => a.id == id).firstOrNull;

  Future<void> refreshPrices() async {
    _loadingPrices = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    SpotPrices? cached;
    try {
      final raw = prefs.getString(_spotKey);
      if (raw != null) cached = SpotPrices.fromJson(asMap(jsonDecode(raw)));
    } catch (_) {}
    try {
      final fresh = await InvestService.fetchSpot();
      _spot = SpotPrices({...?cached?.prices, ...fresh}, DateTime.now());
      await prefs.setString(_spotKey, jsonEncode(_spot!.toJson()));
    } catch (_) {
      _spot = cached ?? SpotPrices(InvestService.fallbackSpot, DateTime.fromMillisecondsSinceEpoch(0));
    }
    _loadingPrices = false;
    notifyListeners();
  }

  double valueOf(PortfolioAsset asset) => _spot == null ? 0 : currentValueSar(asset, _spot!);

  PortfolioSummary get summary {
    final values = <String, double>{};
    var total = 0.0;
    var cost = 0.0;
    for (final a in _assets) {
      final v = valueOf(a);
      total += v;
      cost += a.totalCost;
      values[a.metalType] = (values[a.metalType] ?? 0) + v;
    }
    return PortfolioSummary(total, cost, values, _assets.length);
  }

  ZakatResult? get zakat => _spot == null ? null : calculateZakat(_assets, _spot!);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
