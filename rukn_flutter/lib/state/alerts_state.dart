import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../models/gold_prices.dart';
import '../models/price_alert.dart';

/// Price alerts, evaluated on every live gold tick while the app is open.
class AlertsState extends ChangeNotifier {
  static const _key = 'price_alerts';

  List<PriceAlert> _alerts = [];
  List<PriceAlert> get alerts => List.unmodifiable(_alerts);
  int get activeCount => _alerts.where((a) => a.active).length;

  /// Set by the shell to surface a fired alert (snackbar / banner).
  void Function(FiredAlert)? onFired;

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) {
        final body = asMap(jsonDecode(raw));
        _alerts = [for (final a in asList(body['alerts'])) PriceAlert.fromJson(asMap(a))];
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persist() async {
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode({'version': 1, 'alerts': [for (final a in _alerts) a.toJson()]}),
      );
    } catch (_) {}
  }

  void add(PriceAlert alert) {
    _alerts = [alert, ..._alerts];
    _persist();
  }

  void remove(String id) {
    _alerts = _alerts.where((a) => a.id != id).toList();
    _persist();
  }

  void setActive(String id, bool active, {double? currentPrice}) {
    _alerts = [
      for (final a in _alerts)
        if (a.id == id)
          a.copyWith(active: active, armed: currentPrice == null ? true : !a.conditionMet(currentPrice))
        else
          a,
    ];
    _persist();
  }

  void evaluate(GoldPrices data) {
    if (_alerts.isEmpty) return;
    final result = evaluateAlerts(_alerts, data);
    if (!result.changed) return;
    _alerts = result.next;
    _persist();
    for (final f in result.fired) {
      onFired?.call(f);
    }
  }

  void clear() {
    _alerts = [];
    _persist();
  }
}
