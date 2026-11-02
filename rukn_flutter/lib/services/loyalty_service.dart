import '../core/api.dart';
import '../models/customer.dart';
import 'account_service.dart';

class LoyaltyTier {
  const LoyaltyTier(this.id, this.minSpend);
  final String id; // bronze | silver | gold | platinum
  final double minSpend;
}

const tierThresholds = [
  LoyaltyTier('bronze', 0),
  LoyaltyTier('silver', 25000),
  LoyaltyTier('gold', 100000),
  LoyaltyTier('platinum', 250000),
];

class LoyaltyStatus {
  const LoyaltyStatus({
    required this.memberNumber,
    required this.memberSince,
    required this.points,
    required this.lifetimeSpend,
    required this.orderCount,
    required this.qualifyingOrderCount,
    required this.tier,
    required this.nextTier,
    required this.progress,
    required this.remainingToNext,
    required this.tiers,
  });

  final String memberNumber;
  final String? memberSince;
  final int points;
  final double lifetimeSpend;
  final int orderCount;
  final int qualifyingOrderCount;
  final LoyaltyTier tier;
  final LoyaltyTier? nextTier;
  final double progress;
  final double remainingToNext;
  final List<LoyaltyTier> tiers;
}

/// `GET /store/loyalty`, or a client-side derivation from orders on older backends.
class LoyaltyService {
  LoyaltyService._();

  static LoyaltyTier _tier(Object? raw) {
    final m = asMap(raw);
    return LoyaltyTier(asString(m['id'], 'bronze'), asDouble(m['min_spend']) ?? 0);
  }

  static Future<LoyaltyStatus> status(Customer customer) async {
    try {
      final data = asMap(asMap(await Api.get('/store/loyalty'))['loyalty']);
      return LoyaltyStatus(
        memberNumber: asString(data['member_number']),
        memberSince: asStringOrNull(data['member_since']),
        points: asInt(data['points']) ?? 0,
        lifetimeSpend: asDouble(data['lifetime_spend']) ?? 0,
        orderCount: asInt(data['order_count']) ?? 0,
        qualifyingOrderCount: asInt(data['qualifying_order_count']) ?? 0,
        tier: _tier(data['tier']),
        nextTier: data['next_tier'] == null ? null : _tier(data['next_tier']),
        progress: asDouble(data['progress']) ?? 0,
        remainingToNext: asDouble(data['remaining_to_next']) ?? 0,
        tiers: [for (final t in asList(data['tiers'])) _tier(t)],
      );
    } on MedusaError catch (e) {
      if (e.status != 404) rethrow;
      return derive(await AccountService.listOrders(), customer);
    }
  }

  static String memberNumber(String customerId) {
    final alnum = customerId.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toUpperCase();
    final tail = alnum.length > 6 ? alnum.substring(alnum.length - 6) : alnum;
    return tail.padLeft(6, '0');
  }

  static LoyaltyStatus derive(List<Order> orders, Customer customer) {
    var spend = 0.0;
    var qualifying = 0;
    DateTime? earliest;
    for (final o in orders) {
      final t = DateTime.tryParse(o.createdAt);
      if (t != null && (earliest == null || t.isBefore(earliest))) earliest = t;
      if (o.status == 'canceled') continue;
      final ps = o.paymentStatus;
      if (ps != null && ps != 'captured' && ps != 'partially_captured') continue;
      spend += o.total;
      qualifying++;
    }
    var tier = tierThresholds.first;
    for (final t in tierThresholds) {
      if (spend >= t.minSpend) tier = t;
    }
    final idx = tierThresholds.indexOf(tier);
    final next = idx + 1 < tierThresholds.length ? tierThresholds[idx + 1] : null;
    var progress = 1.0;
    var remaining = 0.0;
    if (next != null) {
      final span = next.minSpend - tier.minSpend;
      remaining = (next.minSpend - spend).clamp(0, double.infinity).toDouble();
      progress = span > 0 ? ((spend - tier.minSpend) / span).clamp(0, 1).toDouble() : 1;
    }
    return LoyaltyStatus(
      memberNumber: memberNumber(customer.id),
      memberSince: customer.createdAt ?? earliest?.toIso8601String(),
      points: spend.floor(),
      lifetimeSpend: spend,
      orderCount: orders.length,
      qualifyingOrderCount: qualifying,
      tier: tier,
      nextTier: next,
      progress: progress,
      remainingToNext: remaining,
      tiers: tierThresholds,
    );
  }
}
