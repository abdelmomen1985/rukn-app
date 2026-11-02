import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../models/trips.dart';

/// Shopping trips, stored on the device.
class TripsState extends ChangeNotifier {
  static const _key = 'market_trips';
  List<MarketTrip> _trips = [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<MarketTrip> get trips {
    final sorted = [..._trips]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  int get activeCount => _trips.where((t) => t.status == 'active').length;
  MarketTrip? byId(String id) => _trips.where((t) => t.id == id).firstOrNull;

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) _trips = [for (final t in asList(jsonDecode(raw))) MarketTrip.fromJson(asMap(t))];
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode([for (final t in _trips) t.toJson()]));
    } catch (_) {}
  }

  String get _now => DateTime.now().toIso8601String();

  MarketTrip addTrip({
    required String name,
    required String city,
    required String goal,
    required String category,
    required String purityLabel,
    required double purityFactor,
    double? weightGrams,
  }) {
    final trip = MarketTrip(
      id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      city: city,
      goal: goal,
      category: category,
      purityLabel: purityLabel,
      purityFactor: purityFactor,
      weightGrams: weightGrams,
      status: 'active',
      stops: [],
      createdAt: _now,
      updatedAt: _now,
    );
    _trips.insert(0, trip);
    _persist();
    return trip;
  }

  void setStatus(String id, String status) {
    final t = byId(id);
    if (t == null) return;
    t.status = status;
    t.updatedAt = _now;
    _persist();
  }

  void deleteTrip(String id) {
    _trips.removeWhere((t) => t.id == id);
    _persist();
  }

  void addStop(String tripId, TripStop stop) {
    final t = byId(tripId);
    if (t == null) return;
    t.stops = [...t.stops, stop];
    t.updatedAt = _now;
    _persist();
  }

  void deleteStop(String tripId, String stopId) {
    final t = byId(tripId);
    if (t == null) return;
    t.stops = t.stops.where((s) => s.id != stopId).toList();
    t.updatedAt = _now;
    _persist();
  }

  void clear() {
    _trips = [];
    _persist();
  }
}
