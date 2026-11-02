import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api.dart';
import '../core/config.dart';
import '../models/gold_prices.dart';
import '../models/portfolio.dart';
import 'store_settings.dart';

/// Hosted-checkout payment for a consultation or a portfolio subscription.
class HostedPayment {
  const HostedPayment({required this.checkoutUrl, required this.amountCents, required this.currency, required this.simulated});
  final String checkoutUrl;
  final int amountCents;
  final String currency;
  final bool simulated;

  factory HostedPayment.fromJson(Map<String, dynamic> m) => HostedPayment(
        checkoutUrl: asString(m['checkout_url']),
        amountCents: asInt(m['amount_cents']) ?? 0,
        currency: asString(m['currency'], 'SAR'),
        simulated: m['simulated'] == true,
      );
}

class ConsultationConfig {
  const ConsultationConfig({required this.enabled, required this.feeAmountCents, required this.currency});
  final bool enabled;
  final int feeAmountCents;
  final String currency;
}

class ConsultationRequest {
  const ConsultationRequest({required this.id, required this.status, this.payment});
  final String id;
  final String status;
  final HostedPayment? payment;
}

class OfferedPlan {
  const OfferedPlan(this.plan, this.priceCents, this.months);
  final String plan; // semiannual | annual | lifetime
  final int priceCents;
  final int? months;

  double? get monthlyEquivalent => months == null || months == 0 ? null : (priceCents / months!).round() / 100;
}

class SubscriptionConfig {
  const SubscriptionConfig(this.paid, this.currency, this.plans);
  final bool paid;
  final String currency;
  final List<OfferedPlan> plans;
}

class CustomerSubscription {
  const CustomerSubscription({required this.id, required this.plan, required this.status, required this.amountCents, this.startsAt, this.expiresAt});
  final String id;
  final String plan;
  final String status;
  final int amountCents;
  final String? startsAt;
  final String? expiresAt;

  int? get daysRemaining {
    final e = DateTime.tryParse(expiresAt ?? '');
    if (e == null) return null;
    final ms = e.difference(DateTime.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 86400000).ceil();
  }

  static CustomerSubscription? fromJson(Object? raw) {
    final m = asMap(raw);
    final plan = asString(m['plan']);
    if (m.isEmpty || !const ['semiannual', 'annual', 'lifetime'].contains(plan)) return null;
    return CustomerSubscription(
      id: asString(m['id']),
      plan: plan,
      status: asString(m['status']),
      amountCents: asInt(m['amount_cents']) ?? 0,
      startsAt: asStringOrNull(m['starts_at']),
      expiresAt: asStringOrNull(m['expires_at']),
    );
  }
}

class PortfolioAccess {
  const PortfolioAccess({required this.required, required this.allowed, this.subscription, this.lastExpired});
  final bool required;
  final bool allowed;
  final CustomerSubscription? subscription;
  final CustomerSubscription? lastExpired;

  static const open = PortfolioAccess(required: false, allowed: true);
}

class InvestService {
  InvestService._();

  // --- Spot prices -----------------------------------------------------------

  static const _fallbackUsdPerOz = {'XAU': 4600.0, 'XAG': 69.0, 'XPT': 960.0, 'XPD': 1080.0};

  /// XAU/XAG from our own metals feed (SAR/oz → USD/oz), XPT/XPD from gold-api.com.
  static Future<Map<String, double>> fetchSpot() async {
    final prices = <String, double>{};
    Future<double?> safe(Future<double> f) => f.then<double?>((v) => v).catchError((Object _) => null);

    final backend = StoreSettings.goldPrices().then<GoldPrices?>((g) => g).catchError((Object _) => null);
    final pt = safe(_goldApi('XPT'));
    final pd = safe(_goldApi('XPD'));

    final gold = await backend;
    if (gold?.ounceGold != null) prices['XAU'] = gold!.ounceGold! / usdToSar;
    if (gold?.ounceSilver != null) prices['XAG'] = gold!.ounceSilver! / usdToSar;
    for (final s in ['XAU', 'XAG']) {
      if (!prices.containsKey(s)) {
        final v = await safe(_goldApi(s));
        if (v != null) prices[s] = v;
      }
    }
    final ptv = await pt;
    final pdv = await pd;
    if (ptv != null) prices['XPT'] = ptv;
    if (pdv != null) prices['XPD'] = pdv;
    if (prices.isEmpty) throw StateError('All symbol fetches failed');
    return prices;
  }

  static Map<String, double> get fallbackSpot => Map.of(_fallbackUsdPerOz);

  static Future<double> _goldApi(String symbol) async {
    final res = await http.get(Uri.parse('https://api.gold-api.com/price/$symbol')).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw StateError('HTTP ${res.statusCode}');
    final price = asDouble(asMap(jsonDecode(res.body))['price']);
    if (price == null) throw StateError('no price');
    return price;
  }

  // --- Portfolio assets (Medusa portfolio module) ---------------------------

  static Future<List<PortfolioAsset>> listAssets() async {
    final data = asMap(await Api.get('/store/portfolio-assets'));
    return [for (final a in asList(data['assets'])) PortfolioAsset.fromJson(asMap(a))];
  }

  static Future<PortfolioAsset> createAsset(PortfolioAsset asset) async {
    final data = asMap(await Api.post('/store/portfolio-assets', asset.toApiBody()));
    return PortfolioAsset.fromJson(asMap(data['asset']));
  }

  static Future<PortfolioAsset> updateAsset(PortfolioAsset asset) async {
    final data = asMap(await Api.post('/store/portfolio-assets/${asset.id}', asset.toApiBody()));
    return PortfolioAsset.fromJson(asMap(data['asset']));
  }

  static Future<void> deleteAsset(String id) => Api.delete('/store/portfolio-assets/$id');

  // --- Portfolio subscriptions -------------------------------------------------

  static Future<SubscriptionConfig> subscriptionConfig() async {
    final body = asMap(await Api.get('/store/portfolio-subscriptions/config'));
    const order = ['semiannual', 'annual', 'lifetime'];
    final plans = <OfferedPlan>[];
    for (final p in asList(body['plans'])) {
      final m = asMap(p);
      final plan = asString(m['plan']);
      final price = asInt(m['price_cents']) ?? 0;
      if (!order.contains(plan) || price <= 0) continue;
      plans.add(OfferedPlan(plan, price, asInt(m['months'])));
    }
    plans.sort((a, b) => order.indexOf(a.plan) - order.indexOf(b.plan));
    final paid = body['paid'] == true && plans.isNotEmpty;
    return SubscriptionConfig(paid, asString(body['currency'], 'SAR'), paid ? plans : const []);
  }

  static Future<PortfolioAccess> portfolioAccess() async {
    final access = asMap(asMap(await Api.get('/store/portfolio-subscriptions'))['access']);
    final required = access['required'] == true;
    return PortfolioAccess(
      required: required,
      allowed: !required || access['allowed'] == true,
      subscription: CustomerSubscription.fromJson(access['subscription']),
      lastExpired: CustomerSubscription.fromJson(access['last_expired']),
    );
  }

  static Future<({CustomerSubscription? subscription, HostedPayment payment})> subscribe(String plan) async {
    final data = asMap(await Api.post('/store/portfolio-subscriptions', {'plan': plan}));
    return (
      subscription: CustomerSubscription.fromJson(data['subscription']),
      payment: HostedPayment.fromJson(asMap(data['payment'])),
    );
  }

  /// paid | pending | failed | cancelled | not_found
  static Future<String> confirmSubscription(String id) async {
    final data = asMap(await Api.post('/store/portfolio-subscriptions/${Uri.encodeComponent(id)}/confirm'));
    return asString(data['state'], 'pending');
  }

  // --- Consultations ----------------------------------------------------------

  static Future<ConsultationConfig> consultationConfig() async {
    final paid = asMap(asMap(await Api.get('/store/consultations/config'))['paid']);
    return ConsultationConfig(
      enabled: paid['enabled'] == true,
      feeAmountCents: asInt(paid['fee_amount_cents'] ?? paid['feeAmountCents']) ?? 0,
      currency: asString(paid['currency'], 'SAR'),
    );
  }

  static Future<ConsultationRequest> submitConsultation({
    required String fullName,
    String? email,
    String? phone,
    String? preferredDate,
    List<String> preferredTimes = const [],
    String? notes,
  }) async {
    final data = asMap(await Api.post('/store/consultations', {
      'full_name': fullName,
      if ((email ?? '').isNotEmpty) 'email': email,
      if ((phone ?? '').isNotEmpty) 'phone': phone,
      if ((preferredDate ?? '').isNotEmpty) 'preferred_date': preferredDate,
      if (preferredTimes.isNotEmpty) 'preferred_times': preferredTimes,
      if ((notes ?? '').isNotEmpty) 'notes': notes,
    }));
    final c = asMap(data['consultation']);
    return ConsultationRequest(
      id: asString(c['id']),
      status: asString(c['status'], 'new'),
      payment: data['payment'] is Map ? HostedPayment.fromJson(asMap(data['payment'])) : null,
    );
  }

  /// paid | pending | failed | not_required | not_found
  static Future<String> confirmConsultationPayment(String id) async {
    final data = asMap(await Api.post('/store/consultations/${Uri.encodeComponent(id)}/confirm'));
    return asString(data['state'], 'pending');
  }

  static Future<HostedPayment> retryConsultationPayment(String id) async {
    final data = asMap(await Api.post('/store/consultations/${Uri.encodeComponent(id)}/pay'));
    return HostedPayment.fromJson(asMap(data['payment']));
  }
}
