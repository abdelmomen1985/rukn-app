import '../core/api.dart';
import '../models/customer.dart';
import 'national_address.dart';

class OtpSent {
  const OtpSent(this.expiresIn, this.resendAfter);
  final int expiresIn;
  final int resendAfter;
}

/// Customer auth + account (port of rukn-site/src/lib/auth.ts and account.ts).
class AccountService {
  AccountService._();

  static Future<Customer> getMe() async {
    final data = asMap(await Api.get('/store/customers/me'));
    return Customer.fromJson(asMap(data['customer']));
  }

  // --- Email + password (legacy; switchable in the admin) -------------------

  static Future<Customer> login(String email, String password) async {
    final data = asMap(await Api.post('/auth/customer/emailpass', {'email': email, 'password': password}));
    await TokenStore.write(asString(data['token']));
    return getMe();
  }

  static Future<Customer> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final reg = asMap(await Api.post('/auth/customer/emailpass/register', {'email': email, 'password': password}));
    await Api.post(
      '/store/customers',
      {
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
      {'Authorization': 'Bearer ${asString(reg['token'])}'},
    );
    return login(email, password);
  }

  // --- Phone OTP (primary) ---------------------------------------------------

  /// Sends a code. With a [purpose] the backend refuses early: `login` to an
  /// unregistered number → 404 NO_ACCOUNT, `register` to a known one → 409 PHONE_REGISTERED.
  static Future<OtpSent> sendOtp(String phone, {String? name, String? purpose}) async {
    final res = asMap(await Api.post('/store/otp/send', {
      'phone': phone,
      if (name != null) 'name': name,
      if (purpose != null) 'purpose': purpose,
    }));
    return OtpSent(asInt(res['expires_in']) ?? 300, asInt(res['resend_after']) ?? 60);
  }

  /// Returns the single-use verification token the auth routes accept.
  static Future<String> verifyOtp(String phone, String code) async {
    final res = asMap(await Api.post('/store/otp/verify', {'phone': phone, 'code': code}));
    return asString(res['verification_token']);
  }

  /// Throws MedusaError 404 / NO_ACCOUNT when the number has no account.
  static Future<Customer> otpLogin(String verificationToken) async {
    final res = asMap(await Api.post('/store/auth/otp/login', {'verification_token': verificationToken}));
    await TokenStore.write(asString(res['token']));
    return getMe();
  }

  static Future<Customer> otpRegister({
    required String verificationToken,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final res = asMap(await Api.post('/store/auth/otp/register', {
      'verification_token': verificationToken,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    }));
    await TokenStore.write(asString(res['token']));
    return getMe();
  }

  static Future<void> logout() => TokenStore.clear();

  /// Hard-deletes the signed-in customer (App Store 5.1.1(v) / Play account deletion).
  static Future<String> deleteAccount() async {
    try {
      await Api.delete('/store/customers/me');
      await TokenStore.clear();
      return 'deleted';
    } on MedusaError catch (e) {
      if (e.status == 401 || e.status == 403) {
        await TokenStore.clear();
        return 'unauthorized';
      }
      if (e.status == 404 || e.status == 405) return 'unsupported';
      return 'error';
    } catch (_) {
      return 'error';
    }
  }

  // --- Profile -------------------------------------------------------------

  static Future<Customer> updateName(String firstName, String lastName) async {
    final data = asMap(await Api.post('/store/customers/me', {'first_name': firstName, 'last_name': lastName}));
    return Customer.fromJson(asMap(data['customer']));
  }

  static Future<Customer> changeEmail(String email) async {
    final data = asMap(await Api.post('/store/customers/me/email', {'email': email}));
    return Customer.fromJson(asMap(data['customer']));
  }

  static Future<Customer> changePhone(String verificationToken) async {
    final data = asMap(await Api.post('/store/customers/me/phone', {'verification_token': verificationToken}));
    return Customer.fromJson(asMap(data['customer']));
  }

  // --- Addresses -------------------------------------------------------------

  static Future<List<CustomerAddress>> listAddresses() async {
    final data = asMap(await Api.get('/store/customers/me/addresses?limit=50'));
    return [for (final a in asList(data['addresses'])) CustomerAddress.fromJson(asMap(a))];
  }

  static Future<void> saveAddress({String? id, required Map<String, dynamic> input}) async {
    final body = {'country_code': 'sa', ...input};
    if (id == null) {
      await Api.post('/store/customers/me/addresses', body);
    } else {
      await Api.post('/store/customers/me/addresses/${Uri.encodeComponent(id)}', body);
    }
  }

  static Future<void> deleteAddress(String id) =>
      Api.delete('/store/customers/me/addresses/${Uri.encodeComponent(id)}');

  // --- Orders ----------------------------------------------------------------

  static Future<List<Order>> listOrders() async {
    final data = asMap(await Api.get('/store/orders?order=-created_at&limit=50'));
    return [for (final o in asList(data['orders'])) Order.fromJson(asMap(o))];
  }

  /// Full order detail — the list endpoint omits addresses and totals on purpose.
  static Future<Order> getOrder(String id) async {
    final data = asMap(await Api.get('/store/orders/${Uri.encodeComponent(id)}?fields=%2Bmetadata'));
    return Order.fromJson(asMap(data['order']));
  }

  /// The tax invoice HTML, rendered by the backend.
  static Future<String> invoiceHtml(String orderId) =>
      Api.getText('/store/customers/me/orders/${Uri.encodeComponent(orderId)}/invoice');

  /// «طلب الشحن» — ship an order kept in the branch vault, optionally to a new National Address.
  static Future<void> requestVaultRelease(String orderId, [NationalAddressDraft? address]) async {
    await Api.post(
      '/store/customers/me/orders/${Uri.encodeComponent(orderId)}/vault-release',
      address == null ? {} : {'address': address.toJson()},
    );
  }
}
