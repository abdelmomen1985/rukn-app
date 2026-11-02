import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wishlisted product ids, persisted on the device.
class WishlistState extends ChangeNotifier {
  static const _key = 'wishlist_v2';
  final List<String> _ids = [];

  List<String> get ids => List.unmodifiable(_ids);
  int get count => _ids.length;
  bool contains(String id) => _ids.contains(id);

  Future<void> load() async {
    try {
      _ids
        ..clear()
        ..addAll((await SharedPreferences.getInstance()).getStringList(_key) ?? const []);
    } catch (_) {}
    notifyListeners();
  }

  void toggle(String id) {
    if (!_ids.remove(id)) _ids.insert(0, id);
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setStringList(_key, _ids)).catchError((_) => false);
  }

  void clear() {
    _ids.clear();
    notifyListeners();
  }
}
