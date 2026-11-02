import 'dart:math' as math;

import '../core/api.dart';
import '../core/config.dart';
import 'gold_prices.dart';
import 'portfolio.dart';

/// Per-gram price alert (port of rukn-site/src/lib/price-alerts.ts).
///
/// `armed` makes an alert fire once per crossing: it disarms on firing and
/// re-arms only after the price moves back across the target.
class PriceAlert {
  PriceAlert({
    required this.id,
    required this.metal,
    required this.purityLabel,
    required this.purityFactor,
    required this.direction,
    required this.targetPerGramSar,
    required this.repeat,
    required this.active,
    required this.armed,
    required this.createdAt,
    this.lastTriggeredAt,
  });

  final String id;
  final String metal; // gold | silver
  final String purityLabel;
  final double purityFactor;
  final String direction; // above | below
  final double targetPerGramSar;
  final bool repeat;
  final bool active;
  final bool armed;
  final String createdAt;
  final String? lastTriggeredAt;

  PriceAlert copyWith({bool? active, bool? armed, String? lastTriggeredAt}) => PriceAlert(
        id: id,
        metal: metal,
        purityLabel: purityLabel,
        purityFactor: purityFactor,
        direction: direction,
        targetPerGramSar: targetPerGramSar,
        repeat: repeat,
        active: active ?? this.active,
        armed: armed ?? this.armed,
        createdAt: createdAt,
        lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      );

  bool conditionMet(double price) => direction == 'above' ? price >= targetPerGramSar : price <= targetPerGramSar;

  Map<String, dynamic> toJson() => {
        'id': id,
        'metal': metal,
        'purityLabel': purityLabel,
        'purityFactor': purityFactor,
        'direction': direction,
        'targetPerGramSAR': targetPerGramSar,
        'repeat': repeat,
        'active': active,
        'armed': armed,
        'createdAt': createdAt,
        'lastTriggeredAt': lastTriggeredAt,
      };

  factory PriceAlert.fromJson(Map<String, dynamic> m) => PriceAlert(
        id: asString(m['id']),
        metal: asString(m['metal'], 'gold'),
        purityLabel: asString(m['purityLabel'], '21K'),
        purityFactor: asDouble(m['purityFactor']) ?? 21 / 24,
        direction: asString(m['direction'], 'above'),
        targetPerGramSar: asDouble(m['targetPerGramSAR']) ?? 0,
        repeat: m['repeat'] == true,
        active: m['active'] != false,
        armed: m['armed'] != false,
        createdAt: asString(m['createdAt']),
        lastTriggeredAt: asStringOrNull(m['lastTriggeredAt']),
      );
}

List<MetalPurity> alertPurities(String metal) => metalById(metal)?.purities ?? const [];

/// Live per-gram SAR for a metal/purity: the karat block for gold, the ounce feed otherwise.
double? alertPerGramSar(GoldPrices? data, String metal, double purityFactor, String purityLabel) {
  if (data == null) return null;
  if (metal == 'gold') {
    final karat = purityLabel.replaceAll(RegExp(r'k$', caseSensitive: false), '');
    final raw = data.karatBlock[karat]?.raw;
    if (raw != null) return raw;
    final ounce = data.ounceGold;
    return ounce == null ? null : ounce / gramsPerOz * purityFactor;
  }
  final silver = data.silverBlock[purityLabel]?.raw;
  if (silver != null) return silver;
  final ounce = data.ounceSilver;
  return ounce == null ? null : ounce / gramsPerOz * purityFactor;
}

PriceAlert createAlert({
  required String metal,
  required String purityLabel,
  required double purityFactor,
  required String direction,
  required double target,
  required bool repeat,
  double? currentPrice,
}) {
  final rand = math.Random().nextInt(1 << 32).toRadixString(36);
  final alert = PriceAlert(
    id: 'alert-${DateTime.now().millisecondsSinceEpoch}-$rand',
    metal: metal,
    purityLabel: purityLabel,
    purityFactor: purityFactor,
    direction: direction,
    targetPerGramSar: target,
    repeat: repeat,
    active: true,
    armed: true,
    createdAt: DateTime.now().toIso8601String(),
  );
  // An alert whose condition already holds starts disarmed, so it does not fire instantly.
  return currentPrice == null ? alert : alert.copyWith(armed: !alert.conditionMet(currentPrice));
}

class FiredAlert {
  const FiredAlert(this.alert, this.price);
  final PriceAlert alert;
  final double price;
}

({List<PriceAlert> next, List<FiredAlert> fired, bool changed}) evaluateAlerts(
  List<PriceAlert> alerts,
  GoldPrices? data,
) {
  final fired = <FiredAlert>[];
  var changed = false;
  final now = DateTime.now().toIso8601String();
  final next = alerts.map((alert) {
    if (!alert.active) return alert;
    final price = alertPerGramSar(data, alert.metal, alert.purityFactor, alert.purityLabel);
    if (price == null) return alert;
    final met = alert.conditionMet(price);
    if (alert.armed && met) {
      final triggered = alert.copyWith(armed: false, active: alert.repeat, lastTriggeredAt: now);
      fired.add(FiredAlert(triggered, price));
      changed = true;
      return triggered;
    }
    if (!alert.armed && !met) {
      changed = true;
      return alert.copyWith(armed: true);
    }
    return alert;
  }).toList();
  return (next: next, fired: fired, changed: changed);
}

double distanceToTargetPercent(PriceAlert alert, double price) =>
    price <= 0 ? 0 : (alert.targetPerGramSar - price) / price * 100;
