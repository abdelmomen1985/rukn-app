import '../core/api.dart';
import '../l10n/site_sync/checkout.dart';

/// Whether UPS delivers to the customer's National Address (port of rukn-site/src/lib/upsCoverage.ts).
/// The matching lives in the backend (`GET /store/ups-coverage`), never in the app.
class UpsCoverage {
  const UpsCoverage({
    required this.covered,
    this.area,
    this.parent,
    this.messageAr,
    this.messageEn,
    this.fallback,
  });

  final bool covered;
  final String? area;
  final String? parent;
  final String? messageAr;
  final String? messageEn;

  /// `'smsa'` when the store has an SMSA option to deliver instead; null otherwise (or on older backends).
  final String? fallback;

  factory UpsCoverage.fromJson(Map<String, dynamic> m) => UpsCoverage(
        covered: m['covered'] == true,
        area: asStringOrNull(m['area']),
        parent: asStringOrNull(m['parent']),
        messageAr: asStringOrNull(m['message_ar']),
        messageEn: asStringOrNull(m['message_en']),
        fallback: asStringOrNull(m['fallback']),
      );
}

/// Which carrier delivers to this address: SMSA only where UPS does not and SMSA is offered.
/// Returns the delivery kind: `'ups'` or `'smsa'`.
String deliveryCarrier(UpsCoverage? coverage, bool smsaOffered) =>
    coverage != null && !coverage.covered && coverage.fallback == 'smsa' && smsaOffered ? 'smsa' : 'ups';

/// Nothing to ask about until the address names a city or a district.
String? coverageQuery(String? city, String? district) {
  final c = (city ?? '').trim();
  final d = (district ?? '').trim();
  if (c.isEmpty && d.isEmpty) return null;
  return 'city=${Uri.encodeQueryComponent(c)}&district=${Uri.encodeQueryComponent(d)}';
}

/// The message to show, or null when UPS can deliver (or nobody knows yet).
String? uncoveredMessage(UpsCoverage? coverage, String lang) {
  if (coverage == null || coverage.covered) return null;
  final ar = lang == 'ar';
  final fallback = (ar ? syncCheckoutAr : syncCheckoutEn)['upsUncoveredFallback'] ?? '';
  final message = ar ? coverage.messageAr : coverage.messageEn;
  return (message == null || message.trim().isEmpty) ? fallback : message;
}

/// A failed request answers null — treated as covered. An outage must not take UPS away from every
/// customer; the admin still flags an order that reaches it from an uncovered area.
Future<UpsCoverage?> fetchUpsCoverage(String? city, String? district) async {
  final query = coverageQuery(city, district);
  if (query == null) return null;
  try {
    final res = asMap(await Api.get('/store/ups-coverage?$query'));
    if (res['covered'] is! bool) return null;
    return UpsCoverage.fromJson(res);
  } catch (_) {
    return null;
  }
}
