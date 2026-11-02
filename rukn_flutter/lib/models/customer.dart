import '../core/api.dart';

class Customer {
  const Customer({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.createdAt,
  });

  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? createdAt;

  String get fullName => [firstName, lastName].where((e) => (e ?? '').trim().isNotEmpty).join(' ').trim();
  String get displayName => fullName.isNotEmpty ? fullName : (email ?? phone ?? '');

  factory Customer.fromJson(Map<String, dynamic> m) => Customer(
        id: asString(m['id']),
        email: asStringOrNull(m['email']),
        firstName: asStringOrNull(m['first_name']),
        lastName: asStringOrNull(m['last_name']),
        phone: asStringOrNull(m['phone']),
        createdAt: asStringOrNull(m['created_at']),
      );
}

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    this.addressName,
    this.firstName,
    this.lastName,
    this.phone,
    this.address1,
    this.address2,
    this.city,
    this.postalCode,
    this.province,
    this.isDefaultShipping = false,
    this.metadata = const {},
  });

  final String id;
  final String? addressName;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address1;
  final String? address2;
  final String? city;
  final String? postalCode;
  final String? province;
  final bool isDefaultShipping;
  final Map<String, dynamic> metadata;

  String get fullName => [firstName, lastName].where((e) => (e ?? '').trim().isNotEmpty).join(' ');

  Map<String, dynamic>? get nationalAddress {
    final n = metadata['national_address'];
    return n is Map ? asMap(n) : null;
  }

  factory CustomerAddress.fromJson(Map<String, dynamic> m) => CustomerAddress(
        id: asString(m['id']),
        addressName: asStringOrNull(m['address_name']),
        firstName: asStringOrNull(m['first_name']),
        lastName: asStringOrNull(m['last_name']),
        phone: asStringOrNull(m['phone']),
        address1: asStringOrNull(m['address_1']),
        address2: asStringOrNull(m['address_2']),
        city: asStringOrNull(m['city']),
        postalCode: asStringOrNull(m['postal_code']),
        province: asStringOrNull(m['province']),
        isDefaultShipping: m['is_default_shipping'] == true,
        metadata: asMap(m['metadata']),
      );
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.subtitle,
    this.thumbnail,
    this.productId,
    this.variantId,
    this.variantSku,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? thumbnail;
  final int quantity;
  final double unitPrice;
  final double total;
  final String? productId;
  final String? variantId;
  final String? variantSku;

  factory OrderItem.fromJson(Map<String, dynamic> m) {
    final qty = asInt(m['quantity']) ?? 1;
    final unit = asDouble(m['unit_price']) ?? 0;
    return OrderItem(
      id: asString(m['id']),
      title: asString(m['title']),
      subtitle: asStringOrNull(m['subtitle']),
      thumbnail: asStringOrNull(m['thumbnail']),
      quantity: qty,
      unitPrice: unit,
      total: asDouble(m['total']) ?? unit * qty,
      productId: asStringOrNull(m['product_id']),
      variantId: asStringOrNull(m['variant_id']),
      variantSku: asStringOrNull(m['variant_sku']),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.displayId,
    required this.status,
    required this.createdAt,
    required this.total,
    required this.currencyCode,
    required this.items,
    this.paymentStatus,
    this.fulfillmentStatus,
    this.email,
    this.itemSubtotal = 0,
    this.shippingTotal = 0,
    this.taxTotal = 0,
    this.discountTotal = 0,
    this.metadata = const {},
    this.shippingAddress,
    this.shippingMethodName,
  });

  final String id;
  final String displayId;
  final String status;
  final String? paymentStatus;
  final String? fulfillmentStatus;
  final String createdAt;
  final double total;
  final String currencyCode;
  final List<OrderItem> items;
  final String? email;
  final double itemSubtotal;
  final double shippingTotal;
  final double taxTotal;
  final double discountTotal;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic>? shippingAddress;
  final String? shippingMethodName;

  String? get paymentMethod => asStringOrNull(metadata['payment_method']);
  String? get vaultStatus => asStringOrNull(metadata['vault_status']);
  String? get branchName => asStringOrNull(metadata['fulfillment_branch_name']);
  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  /// The customer-facing state, folding Medusa's three status axes into one.
  String get displayStatus {
    if (status == 'canceled' || status == 'cancelled') return 'cancelled';
    if (fulfillmentStatus == 'delivered' || status == 'completed') return 'delivered';
    if (fulfillmentStatus == 'shipped' || fulfillmentStatus == 'partially_shipped') return 'shipped';
    if (paymentStatus == 'captured' || fulfillmentStatus == 'fulfilled') return 'processing';
    return 'pending';
  }

  factory Order.fromJson(Map<String, dynamic> m) {
    final methods = asList(m['shipping_methods']);
    return Order(
      id: asString(m['id']),
      displayId: asString(m['display_id'], asString(m['id'])),
      status: asString(m['status']),
      paymentStatus: asStringOrNull(m['payment_status']),
      fulfillmentStatus: asStringOrNull(m['fulfillment_status']),
      createdAt: asString(m['created_at']),
      total: asDouble(m['total']) ?? 0,
      currencyCode: asString(m['currency_code'], 'sar'),
      items: [for (final i in asList(m['items'])) OrderItem.fromJson(asMap(i))],
      email: asStringOrNull(m['email']),
      itemSubtotal: asDouble(m['item_subtotal']) ?? 0,
      shippingTotal: asDouble(m['shipping_total']) ?? 0,
      taxTotal: asDouble(m['tax_total']) ?? 0,
      discountTotal: asDouble(m['discount_total']) ?? 0,
      metadata: asMap(m['metadata']),
      shippingAddress: m['shipping_address'] is Map ? asMap(m['shipping_address']) : null,
      shippingMethodName: methods.isEmpty ? null : asStringOrNull(asMap(methods.first)['name']),
    );
  }
}
