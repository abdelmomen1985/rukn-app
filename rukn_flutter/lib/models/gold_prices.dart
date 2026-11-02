import '../core/api.dart';

class KaratPrice {
  const KaratPrice(this.raw, this.retail);
  final double raw;
  final double retail;
}

/// `GET /store/gold-prices` (see GoldPrices in rukn-site/src/lib/store.ts).
class GoldPrices {
  const GoldPrices({
    required this.currency,
    required this.prices,
    required this.silverPrices,
    this.live,
    this.silverLive,
    this.tickerIncludesTax = false,
    this.ounceGold,
    this.ounceSilver,
    this.asOf,
    this.marketOpen,
    this.lastFetchedAt,
  });

  final String currency;

  /// Karat ("24" … "14") → per-gram SAR, in lockstep with what the catalogue charges.
  final Map<String, KaratPrice> prices;
  final Map<String, KaratPrice> silverPrices;

  /// Faster ticker-feed block; null when that feed has nothing fresh.
  final Map<String, KaratPrice>? live;
  final Map<String, KaratPrice>? silverLive;

  /// Admin switch: the ticker shows retail (VAT incl.) rather than the metal rate.
  final bool tickerIncludesTax;

  /// Live SAR per troy ounce, no tax or margin.
  final double? ounceGold;
  final double? ounceSilver;
  final DateTime? asOf;
  final bool? marketOpen;
  final DateTime? lastFetchedAt;

  static Map<String, KaratPrice> _block(Object? raw) {
    final out = <String, KaratPrice>{};
    asMap(raw).forEach((k, v) {
      final m = asMap(v);
      final r = asDouble(m['raw']);
      final t = asDouble(m['retail']);
      if (r != null && t != null) out[k] = KaratPrice(r, t);
    });
    return out;
  }

  factory GoldPrices.fromJson(Map<String, dynamic> json) {
    final ounce = asMap(json['ounce']);
    final live = json['live'] == null ? null : _block(json['live']);
    final silverLive = json['silverLive'] == null ? null : _block(json['silverLive']);
    return GoldPrices(
      currency: asString(json['currency'], 'sar'),
      prices: _block(json['prices']),
      silverPrices: _block(json['silverPrices']),
      live: (live?.isEmpty ?? true) ? null : live,
      silverLive: (silverLive?.isEmpty ?? true) ? null : silverLive,
      tickerIncludesTax: json['tickerIncludesTax'] == true,
      ounceGold: asDouble(ounce['gold']),
      ounceSilver: asDouble(ounce['silver']),
      asOf: DateTime.tryParse(asString(json['asOf'])),
      marketOpen: json['marketOpen'] is bool ? json['marketOpen'] as bool : null,
      lastFetchedAt: DateTime.tryParse(asString(json['lastFetchedAt'])),
    );
  }

  Map<String, KaratPrice> get karatBlock => live ?? prices;
  Map<String, KaratPrice> get silverBlock => silverLive ?? silverPrices;

  /// What the live ticker shows for a karat.
  double? tickerKarat(String karat) {
    final p = karatBlock[karat];
    if (p == null) return null;
    return tickerIncludesTax ? p.retail : p.raw;
  }

  double? tickerSilver(String purity) {
    final p = silverBlock[purity];
    if (p == null) return null;
    return tickerIncludesTax ? p.retail : p.raw;
  }

  /// The 21K retail price the catalogue is priced from; used to scale product prices live.
  double? get catalogPrice {
    final p = prices['21']?.retail;
    return (p != null && p > 0) ? p : null;
  }
}
