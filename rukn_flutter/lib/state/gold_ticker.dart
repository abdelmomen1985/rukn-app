import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/gold_prices.dart';
import '../services/store_settings.dart';

enum TickDirection { up, down, neutral }

/// Live metal prices, polled from `/store/gold-prices` while the app is in the
/// foreground (port of rukn-site/src/hooks/useLivePricing.ts).
///
/// Two cadences, as on the site: the ticker updates every poll, while the
/// catalogue-scaling ratio ([productCatalogPrice]) only moves every 25 s so
/// product prices do not flicker.
class GoldTicker extends ChangeNotifier with WidgetsBindingObserver {
  GoldTicker() {
    WidgetsBinding.instance.addObserver(this);
  }

  static const pollInterval = Duration(seconds: 5);
  static const productInterval = Duration(seconds: 25);

  GoldPrices? _data;
  GoldPrices? get data => _data;
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool _failed = false;
  bool get failed => _failed && _data == null;

  final Map<String, TickDirection> _directions = {};
  final Map<String, double> _last = {};
  TickDirection direction(String key) => _directions[key] ?? TickDirection.neutral;

  double? _productCatalogPrice;
  DateTime? _productAt;

  /// The 21K retail rate product prices are currently scaled to.
  double? get productCatalogPrice => _productCatalogPrice;

  Timer? _timer;
  int _listeners = 0;
  final List<void Function(GoldPrices)> _onTick = [];

  void addTickListener(void Function(GoldPrices) fn) => _onTick.add(fn);

  void start() {
    _listeners++;
    if (_timer != null) return;
    _poll();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_listeners > 0 && _timer == null) {
        _poll();
        _timer = Timer.periodic(pollInterval, (_) => _poll());
      }
    } else if (state == AppLifecycleState.paused) {
      _stopTimer();
    }
  }

  Future<void> refresh() => _poll();

  void _track(String key, double? value) {
    if (value == null || !value.isFinite) return;
    final prev = _last[key];
    if (prev != null && prev != value) {
      _directions[key] = value > prev ? TickDirection.up : TickDirection.down;
    } else {
      _directions.putIfAbsent(key, () => TickDirection.neutral);
    }
    _last[key] = value;
  }

  Future<void> _poll() async {
    try {
      final data = await StoreSettings.goldPrices();
      _data = data;
      _failed = false;
      _updatedAt = DateTime.now();
      for (final k in data.karatBlock.keys) {
        _track('karat:$k', data.tickerKarat(k));
      }
      for (final k in data.silverBlock.keys) {
        _track('silver:$k', data.tickerSilver(k));
      }
      _track('ounce:gold', data.ounceGold);
      _track('ounce:silver', data.ounceSilver);

      final now = DateTime.now();
      if (_productAt == null || now.difference(_productAt!) >= productInterval) {
        _productCatalogPrice = data.catalogPrice ?? _productCatalogPrice;
        _productAt = now;
      }
      for (final fn in _onTick) {
        fn(data);
      }
      notifyListeners();
    } catch (_) {
      _failed = true;
      if (_data == null) notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    super.dispose();
  }
}

/// Scales catalogue prices by how far the 21K rate moved since they were fetched.
class PriceScaler {
  PriceScaler(this.baseline);

  /// The 21K retail rate at the time the products were loaded.
  final double? baseline;

  double ratio(double? current) {
    final b = baseline;
    if (b == null || !b.isFinite || b <= 0) return 1;
    if (current == null || !current.isFinite || current <= 0) return 1;
    return current / b;
  }

  double scale(double basePrice, double? current) => (basePrice * ratio(current) * 100).roundToDouble() / 100;
}
