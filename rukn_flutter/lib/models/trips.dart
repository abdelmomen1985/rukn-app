import '../core/api.dart';

/// Market-trip («جولة تسوق») model — compares store quotes on a shopping round.

class TripStop {
  TripStop({
    required this.id,
    required this.storeName,
    this.location,
    required this.totalPriceSar,
    required this.weightGrams,
    required this.purityLabel,
    required this.purityFactor,
    required this.vatIncluded,
    required this.origin,
    this.notes,
    required this.visitedAt,
    required this.verdict,
    required this.makingPerGramSar,
    required this.marketReferencePerGramSar,
  });

  final String id;
  final String storeName;
  final String? location;
  final double totalPriceSar;
  final double weightGrams;
  final String purityLabel;
  final double purityFactor;
  final bool vatIncluded;
  final String origin; // local | imported
  final String? notes;
  final String visitedAt;
  final String verdict; // excellent | fair | high
  final double makingPerGramSar;
  final double marketReferencePerGramSar;

  double get perGramSar => weightGrams <= 0 ? 0 : totalPriceSar / weightGrams;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeName': storeName,
        'location': location,
        'totalPriceSAR': totalPriceSar,
        'weightGrams': weightGrams,
        'purityLabel': purityLabel,
        'purityFactor': purityFactor,
        'vatIncluded': vatIncluded,
        'origin': origin,
        'notes': notes,
        'visitedAt': visitedAt,
        'verdict': verdict,
        'makingPerGramSAR': makingPerGramSar,
        'marketReferencePerGramSAR': marketReferencePerGramSar,
      };

  factory TripStop.fromJson(Map<String, dynamic> m) => TripStop(
        id: asString(m['id']),
        storeName: asString(m['storeName']),
        location: asStringOrNull(m['location']),
        totalPriceSar: asDouble(m['totalPriceSAR']) ?? 0,
        weightGrams: asDouble(m['weightGrams']) ?? 0,
        purityLabel: asString(m['purityLabel'], '21K'),
        purityFactor: asDouble(m['purityFactor']) ?? 21 / 24,
        vatIncluded: m['vatIncluded'] == true,
        origin: asString(m['origin'], 'local'),
        notes: asStringOrNull(m['notes']),
        visitedAt: asString(m['visitedAt']),
        verdict: asString(m['verdict'], 'fair'),
        makingPerGramSar: asDouble(m['makingPerGramSAR']) ?? 0,
        marketReferencePerGramSar: asDouble(m['marketReferencePerGramSAR']) ?? 0,
      );
}

class MarketTrip {
  MarketTrip({
    required this.id,
    required this.name,
    required this.city,
    required this.goal,
    required this.category,
    required this.purityLabel,
    required this.purityFactor,
    this.weightGrams,
    required this.status,
    required this.stops,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String name;
  String city;
  String goal; // compare | buy-today
  String category;
  String purityLabel;
  double purityFactor;
  double? weightGrams;
  String status; // active | completed
  List<TripStop> stops;
  final String createdAt;
  String updatedAt;

  TripStop? get cheapestStop =>
      stops.isEmpty ? null : stops.reduce((best, s) => s.totalPriceSar < best.totalPriceSar ? s : best);

  double get averageTotal =>
      stops.isEmpty ? 0 : stops.fold<double>(0, (s, x) => s + x.totalPriceSar) / stops.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'goal': goal,
        'category': category,
        'purityLabel': purityLabel,
        'purityFactor': purityFactor,
        'weightGrams': weightGrams,
        'status': status,
        'stops': [for (final s in stops) s.toJson()],
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory MarketTrip.fromJson(Map<String, dynamic> m) => MarketTrip(
        id: asString(m['id']),
        name: asString(m['name']),
        city: asString(m['city']),
        goal: asString(m['goal'], 'compare'),
        category: asString(m['category'], 'ring'),
        purityLabel: asString(m['purityLabel'], '21K'),
        purityFactor: asDouble(m['purityFactor']) ?? 21 / 24,
        weightGrams: asDouble(m['weightGrams']),
        status: asString(m['status'], 'active'),
        stops: [for (final s in asList(m['stops'])) TripStop.fromJson(asMap(s))],
        createdAt: asString(m['createdAt']),
        updatedAt: asString(m['updatedAt']),
      );
}

class City {
  const City(this.id, this.nameAr, this.nameEn);
  final String id;
  final String nameAr;
  final String nameEn;
}

const popularCities = [
  City('riyadh', 'الرياض', 'Riyadh'),
  City('jeddah', 'جدة', 'Jeddah'),
  City('mecca', 'مكة المكرمة', 'Mecca'),
  City('medina', 'المدينة المنورة', 'Medina'),
  City('dammam', 'الدمام', 'Dammam'),
  City('khobar', 'الخبر', 'Al Khobar'),
  City('taif', 'الطائف', 'Taif'),
  City('abha', 'أبها', 'Abha'),
];

String cityLabel(String id, String lang) {
  final c = popularCities.where((c) => c.id == id).firstOrNull;
  if (c == null) return id;
  return lang == 'ar' ? c.nameAr : c.nameEn;
}

const tripPurities = [
  (label: '24K', factor: 1.0),
  (label: '22K', factor: 22 / 24),
  (label: '21K', factor: 21 / 24),
  (label: '18K', factor: 18 / 24),
  (label: '14K', factor: 14 / 24),
];

const tripCategories = ['ring', 'bracelet', 'necklace', 'earring', 'bar', 'coin'];

/// Gold bars are fine gold: a bar trip/stop is locked to 24K (as on the site).
List<({String label, double factor})> tripPuritiesFor(String category) =>
    category == 'bar' ? [tripPurities.first] : tripPurities;

const vatRate = 0.15;
const fairMakingLow = 25.0;
const fairMakingHigh = 45.0;

class FairPriceResult {
  const FairPriceResult({
    required this.preTaxTotal,
    required this.makingPerGram,
    required this.goldValue,
    required this.vatAmount,
    required this.fairPerGram,
    required this.verdict,
  });
  final double preTaxTotal;
  final double makingPerGram;
  final double goldValue;
  final double vatAmount;
  final double fairPerGram;
  final String verdict;
}

/// Fair-price verdict for one quote: workmanship per gram vs. the typical band.
FairPriceResult evaluateFairPrice({
  required double totalPriceSar,
  required double weightGrams,
  required double purityFactor,
  required bool vatIncluded,
  required double purePerGramSar,
}) {
  final preTax = vatIncluded ? totalPriceSar / (1 + vatRate) : totalPriceSar;
  final vat = vatIncluded ? totalPriceSar - preTax : 0.0;
  final goldPerGram = purePerGramSar * purityFactor;
  final goldValue = weightGrams * goldPerGram;
  final making = weightGrams > 0 ? (preTax - goldValue) / weightGrams : 0.0;
  final fair = goldPerGram + (fairMakingLow + fairMakingHigh) / 2;
  final verdict = making <= fairMakingLow ? 'excellent' : (making <= fairMakingHigh ? 'fair' : 'high');
  return FairPriceResult(
    preTaxTotal: preTax,
    makingPerGram: making,
    goldValue: goldValue,
    vatAmount: vat,
    fairPerGram: fair,
    verdict: verdict,
  );
}
