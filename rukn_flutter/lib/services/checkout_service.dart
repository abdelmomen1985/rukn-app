import '../core/api.dart';
import '../state/cart_state.dart';
import 'catalog_service.dart';
import 'national_address.dart';

class CheckoutForm {
  CheckoutForm({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.city = '',
    this.address = '',
    this.nationalAddress,
  });

  String name;
  String email;
  String phone;
  String city;
  String address;
  NationalAddressDraft? nationalAddress;
}

class PickupBranch {
  const PickupBranch({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.addressAr,
    required this.city,
    required this.phone,
    required this.hoursAr,
    required this.hoursEn,
    required this.mapUrl,
  });

  final String id;
  final String name;
  final String nameEn;
  final String addressAr;
  final String city;
  final String phone;
  final String hoursAr;
  final String hoursEn;
  final String mapUrl;

  factory PickupBranch.fromJson(Map<String, dynamic> m) => PickupBranch(
        id: asString(m['id']),
        name: asString(m['name']),
        nameEn: asString(m['name_en']),
        addressAr: asString(m['address_ar']),
        city: asString(m['city']),
        phone: asString(m['phone']),
        hoursAr: asString(m['hours_ar']),
        hoursEn: asString(m['hours_en']),
        mapUrl: asString(m['map_url']),
      );
}

class ShippingOptionInfo {
  const ShippingOptionInfo({required this.optionId, required this.name, required this.amount, this.freeOver});
  final String optionId;
  final String name;
  final double amount;
  final double? freeOver;
}

class DeliveryOptions {
  const DeliveryOptions({
    required this.pickupAvailable,
    required this.pickupOptionId,
    required this.pickupAmount,
    required this.branches,
    required this.pickupRestrictionAr,
    required this.pickupBranchNameAr,
    required this.pickupBranchNameEn,
    required this.pickupAddressAr,
    required this.pickupHoursAr,
    required this.ups,
    this.smsa = const [],
    required this.vaultAvailable,
  });

  final bool pickupAvailable;
  final String? pickupOptionId;
  final double pickupAmount;
  final List<PickupBranch> branches;
  final String? pickupRestrictionAr;
  final String pickupBranchNameAr;
  final String pickupBranchNameEn;
  final String pickupAddressAr;
  final String pickupHoursAr;
  final List<ShippingOptionInfo> ups;

  /// SMSA options: offered only where UPS does not deliver. Empty on older backends.
  final List<ShippingOptionInfo> smsa;
  final bool vaultAvailable;

  factory DeliveryOptions.fromJson(Map<String, dynamic> m) {
    final pickup = asMap(m['pickup']);
    final restriction = pickup['restriction'] is Map ? asMap(pickup['restriction']) : null;
    return DeliveryOptions(
      pickupAvailable: pickup['available'] == true,
      pickupOptionId: asStringOrNull(pickup['option_id']),
      pickupAmount: asDouble(pickup['amount']) ?? 0,
      branches: [for (final b in asList(pickup['branches'])) PickupBranch.fromJson(asMap(b))],
      pickupRestrictionAr: restriction == null ? null : asStringOrNull(restriction['message_ar']),
      pickupBranchNameAr: asString(pickup['branch_name_ar']),
      pickupBranchNameEn: asString(pickup['branch_name_en']),
      pickupAddressAr: asString(pickup['address_ar']),
      pickupHoursAr: asString(pickup['hours_ar']),
      ups: _carrierOptions(m['ups']),
      smsa: _carrierOptions(m['smsa']),
      vaultAvailable: asMap(m['vault'])['available'] == true,
    );
  }

  static List<ShippingOptionInfo> _carrierOptions(Object? list) => [
        for (final u in asList(list))
          ShippingOptionInfo(
            optionId: asString(asMap(u)['option_id']),
            name: asString(asMap(u)['name']),
            amount: asDouble(asMap(u)['amount']) ?? 0,
            freeOver: asDouble(asMap(u)['free_shipping_threshold']),
          ),
      ];
}

/// What the customer picked on the delivery step.
class DeliveryChoice {
  const DeliveryChoice({
    required this.optionId,
    required this.kind,
    required this.name,
    required this.amount,
    this.freeOver,
    this.branchId,
    this.branchName,
    this.vault = false,
  });

  final String optionId;
  final String kind; // pickup | ups | smsa
  final String name;
  final double amount;
  final double? freeOver;
  final String? branchId;
  final String? branchName;

  /// Keep the order in the branch vault («خزنة الفرع») instead of shipping it now.
  final bool vault;

  /// Shipping is charged now even for a vault order; storage is free.
  double feeFor(double subtotal) {
    final t = freeOver;
    if (t != null && t > 0 && subtotal >= t) return 0;
    return amount;
  }
}

class BankAccount {
  const BankAccount({required this.id, required this.bankName, required this.accountName, required this.accountNumber, required this.iban});
  final String id;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String iban;
}

class PaymentMethods {
  const PaymentMethods({
    required this.bankTransferEnabled,
    required this.bankUnavailableReason,
    required this.bankAccounts,
    required this.codEnabled,
    required this.paymobAvailable,
    required this.paymobNameAr,
    required this.paymobNameEn,
    required this.cardFeePercent,
    required this.cardFeeFixed,
  });

  final bool bankTransferEnabled;
  final String? bankUnavailableReason;
  final List<BankAccount> bankAccounts;
  final bool codEnabled;
  final bool paymobAvailable;
  final String paymobNameAr;
  final String paymobNameEn;
  final double cardFeePercent;
  final double cardFeeFixed;

  bool get anyEnabled => bankTransferEnabled || codEnabled || paymobAvailable;

  bool isEnabled(String method) => switch (method) {
        'bank_transfer' => bankTransferEnabled,
        'cod' => codEnabled,
        'paymob' => paymobAvailable,
        _ => false,
      };

  factory PaymentMethods.fromJson(Map<String, dynamic> m) {
    final b = asMap(m['bank_transfer']);
    final p = asMap(m['paymob']);
    final accounts = <BankAccount>[
      for (final a in asList(b['accounts']))
        BankAccount(
          id: asString(asMap(a)['id']),
          bankName: asString(asMap(a)['bank_name']),
          accountName: asString(asMap(a)['account_name']),
          accountNumber: asString(asMap(a)['account_number']),
          iban: asString(asMap(a)['iban']),
        ),
    ].where((a) => a.bankName.isNotEmpty || a.accountNumber.isNotEmpty || a.iban.isNotEmpty).toList();
    if (accounts.isEmpty &&
        (asString(b['bank_name']).isNotEmpty || asString(b['bank_iban']).isNotEmpty)) {
      accounts.add(BankAccount(
        id: 'legacy',
        bankName: asString(b['bank_name']),
        accountName: asString(b['bank_account_name']),
        accountNumber: asString(b['bank_account_number']),
        iban: asString(b['bank_iban']),
      ));
    }
    return PaymentMethods(
      bankTransferEnabled: b['enabled'] == true,
      bankUnavailableReason: asStringOrNull(b['unavailable_reason']),
      bankAccounts: accounts,
      codEnabled: asMap(m['cod'])['enabled'] == true,
      paymobAvailable: p['available'] == true,
      paymobNameAr: asString(p['display_name_ar']),
      paymobNameEn: asString(p['display_name_en']),
      cardFeePercent: asDouble(p['card_fee_percent']) ?? 0,
      cardFeeFixed: asDouble(p['card_fee_fixed']) ?? 0,
    );
  }

  /// Formula-identical to the backend's card surcharge, computed in halalas.
  double cardFee(double subtotal) {
    if (!subtotal.isFinite || subtotal < 0) return 0;
    final percent = cardFeePercent.clamp(0, 100);
    final fixed = cardFeeFixed < 0 ? 0 : cardFeeFixed;
    if (percent == 0 && fixed == 0) return 0;
    final subtotalHalalas = (subtotal * 100).round();
    final feeHalalas = (subtotalHalalas * percent / 100).round() + (fixed * 100).round();
    return feeHalalas / 100;
  }
}

class PlacedOrder {
  const PlacedOrder(this.id, this.displayId);
  final String id;
  final String displayId;
}

class PaymobRedirect {
  const PaymobRedirect({required this.cartId, required this.paymentSessionId, required this.checkoutUrl});
  final String cartId;
  final String paymentSessionId;
  final String checkoutUrl;
}

class BankTransferProof {
  const BankTransferProof({
    required this.senderName,
    required this.base64,
    required this.mimeType,
    required this.filename,
  });
  final String senderName;
  final String base64;
  final String mimeType;
  final String filename;
}

/// Error codes surfaced to the UI (mirrors CheckoutErrorCode on the site).
class CheckoutError implements Exception {
  const CheckoutError(this.code, [this.message]);
  final String code;
  final String? message;
  @override
  String toString() => 'CheckoutError($code)';
}

/// Cart → address → shipping → payment → order (port of rukn-site/src/lib/checkout.ts).
class CheckoutService {
  CheckoutService._();

  static const _paymobProvider = 'pp_paymob_online';
  static const _systemProvider = 'pp_system_default';

  static Future<DeliveryOptions?> deliveryOptions(List<String> productIds) async {
    try {
      final q = productIds.isEmpty ? '' : '?product_ids=${Uri.encodeQueryComponent(productIds.join(','))}';
      return DeliveryOptions.fromJson(asMap(await Api.get('/store/delivery-options$q')));
    } catch (_) {
      return null;
    }
  }

  static Future<PaymentMethods> paymentMethods([String? branchId]) async {
    try {
      final q = branchId == null ? '' : '?branch_id=${Uri.encodeQueryComponent(branchId)}';
      return PaymentMethods.fromJson(asMap(await Api.get('/store/payment-methods$q')));
    } catch (_) {
      return const PaymentMethods(
        bankTransferEnabled: true,
        bankUnavailableReason: null,
        bankAccounts: [],
        codEnabled: true,
        paymobAvailable: false,
        paymobNameAr: '',
        paymobNameEn: '',
        cardFeePercent: 0,
        cardFeeFixed: 0,
      );
    }
  }

  static Map<String, dynamic> _address(CheckoutForm form, {DeliveryChoice? delivery, bool billing = false}) {
    final parts = form.name.trim().split(RegExp(r'\s+'));
    final base = <String, dynamic>{
      'first_name': parts.first.isEmpty ? form.name : parts.first,
      'last_name': parts.length > 1 ? parts.skip(1).join(' ') : '-',
      'phone': form.phone,
      'address_1': form.address,
      'city': form.city,
      'country_code': 'sa',
    };
    final na = form.nationalAddress;
    if (!billing && delivery?.kind != 'pickup' && na != null && na.isComplete) {
      final fields = na.toMedusaAddressFields();
      final street = asString(fields.remove('address_1'));
      base.addAll(fields);
      base['address_1'] = street.isNotEmpty ? street : form.address;
    }
    return base;
  }

  static Future<String> _buildCart(List<CartItem> items, CheckoutForm form, DeliveryChoice? delivery) async {
    if (items.any((i) => i.variantId == null)) throw const CheckoutError('cart_has_no_purchasable_items');
    final region = await CatalogService.regionId();
    final cart = asMap(asMap(await Api.post('/store/carts', {'region_id': region, 'email': form.email}))['cart']);
    final cartId = asString(cart['id']);
    for (final item in items) {
      await Api.post('/store/carts/$cartId/line-items', {'variant_id': item.variantId, 'quantity': item.quantity});
    }
    await Api.post('/store/carts/$cartId', {
      'shipping_address': _address(form, delivery: delivery),
      'billing_address': _address(form, billing: true),
    });

    final options = [
      for (final o in asList(asMap(await Api.get('/store/shipping-options?cart_id=$cartId'))['shipping_options']))
        asString(asMap(o)['id']),
    ];
    if (options.isEmpty) throw const CheckoutError('no_shipping_options');
    var optionId = options.first;
    if (delivery != null && delivery.optionId.isNotEmpty) {
      if (!options.contains(delivery.optionId)) throw const CheckoutError('delivery_option_unavailable');
      optionId = delivery.optionId;
    }
    await Api.post('/store/carts/$cartId/shipping-methods', {'option_id': optionId});

    if (delivery?.kind == 'pickup' && delivery?.branchId != null) {
      await Api.post('/store/carts/$cartId', {
        'metadata': {'pickup_branch_id': delivery!.branchId, 'pickup_branch_name': delivery.branchName ?? ''},
      });
    }
    if (delivery != null && delivery.kind != 'pickup' && delivery.vault) {
      await Api.post('/store/carts/$cartId', {
        'metadata': {'vault_requested': true},
      });
    }
    return cartId;
  }

  static Future<Map<String, dynamic>> _openPaymentSession(String cartId, String providerId, [Map<String, dynamic>? data]) async {
    final created = asMap(asMap(await Api.post('/store/payment-collections', {'cart_id': cartId}))['payment_collection']);
    final updated = asMap(await Api.post(
      '/store/payment-collections/${asString(created['id'])}/payment-sessions',
      {'provider_id': providerId, if (data != null) 'data': data},
    ));
    return asMap(updated['payment_collection']);
  }

  static Future<PlacedOrder> _complete(String cartId) async {
    final res = asMap(await Api.post('/store/carts/$cartId/complete'));
    final order = asMap(res['order']);
    if (res['type'] != 'order' || order.isEmpty) {
      throw CheckoutError('cart_completion_failed', asStringOrNull(asMap(res['error'])['message']));
    }
    return PlacedOrder(asString(order['id']), asString(order['display_id'], asString(order['id'])));
  }

  /// Bank transfer / cash on delivery.
  static Future<PlacedOrder> placeOrder({
    required List<CartItem> items,
    required CheckoutForm form,
    required String paymentMethod,
    DeliveryChoice? delivery,
    BankTransferProof? proof,
  }) async {
    if (paymentMethod == 'bank_transfer' && proof == null) throw const CheckoutError('bank_transfer_proof_required');
    final cartId = await _buildCart(items, form, delivery);
    await Api.post('/store/carts/$cartId', {
      'metadata': {'payment_method': paymentMethod},
    });
    if (paymentMethod == 'bank_transfer' && proof != null) {
      try {
        await Api.post('/store/bank-transfer-receipt', {
          'cart_id': cartId,
          'sender_name': proof.senderName,
          'content': proof.base64,
          'mime_type': proof.mimeType,
          'filename': proof.filename,
        });
      } on MedusaError {
        rethrow;
      } catch (_) {
        throw const CheckoutError('receipt_upload_failed');
      }
    }
    await _openPaymentSession(cartId, _systemProvider);
    return _complete(cartId);
  }

  /// Card / mada through Paymob's hosted checkout.
  static Future<PaymobRedirect> startPaymob({
    required List<CartItem> items,
    required CheckoutForm form,
    DeliveryChoice? delivery,
  }) async {
    final cartId = await _buildCart(items, form, delivery);
    await Api.post('/store/carts/$cartId', {
      'metadata': {'payment_method': 'paymob'},
    });
    await Api.post('/store/carts/$cartId/card-fee');
    final collection = await _openPaymentSession(cartId, _paymobProvider, {'cart_id': cartId});
    final session = asList(collection['payment_sessions'])
        .map(asMap)
        .where((s) => s['provider_id'] == _paymobProvider)
        .firstOrNull;
    final url = asStringOrNull(asMap(session?['data'])['checkout_url']);
    if (session == null || url == null) throw const CheckoutError('paymob_session_unavailable');
    return PaymobRedirect(cartId: cartId, paymentSessionId: asString(session['id']), checkoutUrl: url);
  }

  /// Which branch would fulfil the order, and whether it keeps a vault.
  static Future<({bool ok, String? branchId, String? branchName, String? branchNameEn, bool vaultAvailable, String? message})?>
      resolveFulfillmentBranch(List<String> productIds, {required String kind, String? branchId, String? city}) async {
    try {
      final res = asMap(await Api.post('/store/fulfillment-branch/resolve', {
        'product_ids': productIds,
        'delivery': kind == 'pickup'
            ? {'kind': 'pickup', 'branch_id': branchId}
            : {'kind': 'ship', 'city': city, 'region': null},
      }));
      return (
        ok: res['ok'] == true,
        branchId: asStringOrNull(res['branch_id']),
        branchName: asStringOrNull(res['branch_name']),
        branchNameEn: asStringOrNull(res['branch_name_en']),
        vaultAvailable: res['vault_available'] == true,
        message: asStringOrNull(res['message']),
      );
    } catch (_) {
      return null;
    }
  }

  /// state: paid | pending | failed | not_found
  static Future<({String state, String? orderDisplayId})> paymobStatus(String paymentSessionId) async {
    final res = asMap(await Api.get('/store/paymob/status?payment_session=${Uri.encodeQueryComponent(paymentSessionId)}'));
    return (state: asString(res['state'], 'pending'), orderDisplayId: asStringOrNull(res['order_display_id']));
  }

  static Future<PlacedOrder?> completePaymobCart(String cartId) async {
    try {
      return await _complete(cartId);
    } catch (_) {
      return null;
    }
  }
}
