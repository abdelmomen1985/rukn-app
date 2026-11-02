import 'package:flutter/foundation.dart';

import '../core/api.dart';
import '../models/customer.dart';
import '../services/account_service.dart';

/// The signed-in customer, if any.
class AuthState extends ChangeNotifier {
  Customer? _customer;
  bool _loading = true;

  Customer? get customer => _customer;
  bool get isSignedIn => _customer != null;
  bool get loading => _loading;

  Future<void> load() async {
    final token = await TokenStore.read();
    if (token == null || token.isEmpty) {
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      _customer = await AccountService.getMe();
    } on MedusaError catch (e) {
      // An expired token is dropped; a network failure keeps it for next launch.
      if (e.status == 401 || e.status == 403) await TokenStore.clear();
      _customer = null;
    } catch (_) {
      _customer = null;
    }
    _loading = false;
    notifyListeners();
  }

  void setCustomer(Customer? customer) {
    _customer = customer;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      _customer = await AccountService.getMe();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> signOut() async {
    await AccountService.logout();
    _customer = null;
    notifyListeners();
  }
}
