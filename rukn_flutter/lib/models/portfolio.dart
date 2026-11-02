import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/config.dart';

class MetalPurity {
  const MetalPurity(this.label, this.factor);
  final String label;
  final double factor;
}

class MetalDefinition {
  const MetalDefinition({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.apiSymbol,
    required this.purities,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.emoji,
  });

  final String id;
  final String name;
  final String nameAr;
  final String apiSymbol;
  final List<MetalPurity> purities;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final String emoji;

  String label(String lang) => lang == 'ar' ? nameAr : name;
}

const defaultMetals = <MetalDefinition>[
  MetalDefinition(
    id: 'gold',
    name: 'Gold',
    nameAr: 'ذهب',
    apiSymbol: 'XAU',
    purities: [
      MetalPurity('24K', 1.0),
      MetalPurity('22K', 22 / 24),
      MetalPurity('21K', 21 / 24),
      MetalPurity('18K', 18 / 24),
      MetalPurity('14K', 14 / 24),
    ],
    color: Color(0xFFD4AF37),
    bgColor: Color(0xFFFFF9E6),
    borderColor: Color(0xFFF5D766),
    textColor: Color(0xFF5A460A),
    emoji: '🥇',
  ),
  MetalDefinition(
    id: 'silver',
    name: 'Silver',
    nameAr: 'فضة',
    apiSymbol: 'XAG',
    purities: [
      MetalPurity('999', 0.999),
      MetalPurity('925', 0.925),
      MetalPurity('900', 0.9),
      MetalPurity('800', 0.8),
    ],
    color: Color(0xFFA8A8A8),
    bgColor: Color(0xFFF5F5F5),
    borderColor: Color(0xFFC0C0C0),
    textColor: Color(0xFF374151),
    emoji: '🥈',
  ),
  MetalDefinition(
    id: 'platinum',
    name: 'Platinum',
    nameAr: 'بلاتين',
    apiSymbol: 'XPT',
    purities: [MetalPurity('950', 0.95), MetalPurity('900', 0.9), MetalPurity('850', 0.85)],
    color: Color(0xFF7B8FA1),
    bgColor: Color(0xFFEFF3F7),
    borderColor: Color(0xFFB0C4D8),
    textColor: Color(0xFF2C3E50),
    emoji: '⬜',
  ),
  MetalDefinition(
    id: 'palladium',
    name: 'Palladium',
    nameAr: 'بلاديوم',
    apiSymbol: 'XPD',
    purities: [MetalPurity('999.5', 0.9995), MetalPurity('950', 0.95), MetalPurity('500', 0.5)],
    color: Color(0xFF9C8D7B),
    bgColor: Color(0xFFF5F0EB),
    borderColor: Color(0xFFC4B5A7),
    textColor: Color(0xFF4A3728),
    emoji: '🔘',
  ),
];

MetalDefinition? metalById(String id) => defaultMetals.where((m) => m.id == id).firstOrNull;

const weightUnits = ['grams', 'tolas', 'ounces', 'mithqal'];
const assetCategories = ['ring', 'bracelet', 'necklace', 'earring', 'bar', 'coin'];
const goldKarats = [24, 22, 21, 18, 14];
const silverPurities = [999, 925, 900, 800];

const categoryEmoji = {
  'ring': '💍',
  'bracelet': '🔗',
  'necklace': '📿',
  'earring': '💎',
  'bar': '🟨',
  'coin': '🪙',
};

/// Spot prices keyed by API symbol, USD per troy ounce.
class SpotPrices {
  const SpotPrices(this.prices, this.fetchedAt);
  final Map<String, double> prices;
  final DateTime fetchedAt;

  Map<String, dynamic> toJson() => {'prices': prices, 'fetchedAt': fetchedAt.toIso8601String()};
  factory SpotPrices.fromJson(Map<String, dynamic> m) => SpotPrices(
        {for (final e in asMap(m['prices']).entries) if (asDouble(e.value) != null) e.key: asDouble(e.value)!},
        DateTime.tryParse(asString(m['fetchedAt'])) ?? DateTime.now(),
      );

  bool get isStale => DateTime.now().difference(fetchedAt) > const Duration(minutes: 10);
}

class PortfolioAsset {
  PortfolioAsset({
    required this.id,
    required this.metalType,
    required this.name,
    this.nameAr,
    required this.category,
    required this.weightValue,
    required this.weightUnit,
    required this.purityLabel,
    required this.purityFactor,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.makingCharges,
    required this.vatAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.karat,
    this.silverPurity,
  });

  final String id;
  final String metalType;
  final String name;
  final String? nameAr;
  final String category;
  final double weightValue;
  final String weightUnit;
  final String purityLabel;
  final double purityFactor;
  final double purchasePrice;
  final String purchaseDate;
  final double makingCharges;
  final double vatAmount;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final int? karat;
  final int? silverPurity;

  double get totalCost => purchasePrice + makingCharges + vatAmount;
  double get weightGrams => weightInGrams(weightValue, weightUnit);
  bool get isServerRow => id.startsWith('passet_');

  String displayName(String lang) => lang == 'ar' && (nameAr ?? '').isNotEmpty ? nameAr! : name;

  PortfolioAsset copyWith({String? id, String? createdAt, String? updatedAt}) => PortfolioAsset(
        id: id ?? this.id,
        metalType: metalType,
        name: name,
        nameAr: nameAr,
        category: category,
        weightValue: weightValue,
        weightUnit: weightUnit,
        purityLabel: purityLabel,
        purityFactor: purityFactor,
        purchasePrice: purchasePrice,
        purchaseDate: purchaseDate,
        makingCharges: makingCharges,
        vatAmount: vatAmount,
        notes: notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        karat: karat,
        silverPurity: silverPurity,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'metalType': metalType,
        'name': name,
        'nameAr': nameAr,
        'category': category,
        'weightValue': weightValue,
        'weightUnit': weightUnit,
        'purityLabel': purityLabel,
        'purityFactor': purityFactor,
        'purchasePrice': purchasePrice,
        'purchaseDate': purchaseDate,
        'makingCharges': makingCharges,
        'vatAmount': vatAmount,
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'karat': karat,
        'silverPurity': silverPurity,
      };

  /// Body for `/store/portfolio-assets` (snake_case).
  Map<String, dynamic> toApiBody() => {
        'metal_type': metalType,
        'name': name,
        'name_ar': nameAr,
        'category': category,
        'weight_value': weightValue,
        'weight_unit': weightUnit,
        'purity_label': purityLabel,
        'purity_factor': purityFactor,
        'purchase_price': purchasePrice,
        'purchase_date': purchaseDate,
        'making_charges': makingCharges,
        'vat_amount': vatAmount,
        'notes': notes,
      };

  /// Reads both the local camelCase shape and the API's snake_case one, and
  /// migrates assets stored before `purityFactor` existed.
  factory PortfolioAsset.fromJson(Map<String, dynamic> m) {
    Object? pick(String camel, String snake) => m.containsKey(camel) ? m[camel] : m[snake];
    final metalType = asString(pick('metalType', 'metal_type'), 'gold');
    final karat = asInt(m['karat']);
    final silver = asInt(pick('silverPurity', 'silver_purity'));
    var label = asStringOrNull(pick('purityLabel', 'purity_label'));
    var factor = asDouble(pick('purityFactor', 'purity_factor'));
    if (label == null || factor == null) {
      final resolved = resolvePurity(metalType, karat, silver);
      label = resolved.label;
      factor = resolved.factor;
    }
    final now = DateTime.now().toIso8601String();
    return PortfolioAsset(
      id: asString(m['id']),
      metalType: metalType,
      name: asString(m['name']),
      nameAr: asStringOrNull(pick('nameAr', 'name_ar')),
      category: asString(m['category'], 'ring'),
      weightValue: asDouble(pick('weightValue', 'weight_value')) ?? 0,
      weightUnit: asString(pick('weightUnit', 'weight_unit'), 'grams'),
      purityLabel: label,
      purityFactor: factor,
      purchasePrice: asDouble(pick('purchasePrice', 'purchase_price')) ?? 0,
      purchaseDate: asString(pick('purchaseDate', 'purchase_date'), now.substring(0, 10)),
      makingCharges: asDouble(pick('makingCharges', 'making_charges')) ?? 0,
      vatAmount: asDouble(pick('vatAmount', 'vat_amount')) ?? 0,
      notes: asStringOrNull(m['notes']),
      createdAt: asString(pick('createdAt', 'created_at'), now),
      updatedAt: asString(pick('updatedAt', 'updated_at'), now),
      karat: karat,
      silverPurity: silver,
    );
  }
}

MetalPurity resolvePurity(String metalType, int? karat, int? fineness) {
  if (metalType == 'gold' && karat != null && karat > 0) return MetalPurity('${karat}K', karat / 24);
  if (fineness != null && fineness > 0) return MetalPurity('$fineness', fineness / 1000);
  return const MetalPurity('Fine', 1);
}

// --- Weight & price math (port of portfolio-utils.ts) ------------------------

const gramsPerTola = 11.664;
const gramsPerMithqal = 4.25;
const nisabGoldGrams = 85.0;

double weightInGrams(double value, String unit) => switch (unit) {
      'tolas' => value * gramsPerTola,
      'ounces' => value * gramsPerOz,
      'mithqal' => value * gramsPerMithqal,
      _ => value,
    };

double convertWeight(double value, String from, String to) {
  final g = weightInGrams(value, from);
  return switch (to) {
    'tolas' => g / gramsPerTola,
    'ounces' => g / gramsPerOz,
    'mithqal' => g / gramsPerMithqal,
    _ => g,
  };
}

/// Pure (factor 1) price per gram in SAR for an API symbol.
double purePerGramSar(SpotPrices spot, String symbol) => ((spot.prices[symbol] ?? 0) * usdToSar) / gramsPerOz;

double currentValueSar(PortfolioAsset asset, SpotPrices spot) {
  final metal = metalById(asset.metalType);
  if (metal == null || metal.apiSymbol.isEmpty) return 0;
  return asset.weightGrams * purePerGramSar(spot, metal.apiSymbol) * asset.purityFactor;
}

class PnL {
  const PnL({
    required this.currentValue,
    required this.totalCost,
    required this.gainLoss,
    required this.percentReturn,
    required this.annualizedReturn,
    required this.holdingDays,
  });
  final double currentValue;
  final double totalCost;
  final double gainLoss;
  final double percentReturn;
  final double annualizedReturn;
  final int holdingDays;
}

PnL calculatePnL(PortfolioAsset asset, SpotPrices spot) {
  final current = currentValueSar(asset, spot);
  final cost = asset.totalCost;
  final purchase = DateTime.tryParse(asset.purchaseDate) ?? DateTime.now();
  final days = math.max(1, DateTime.now().difference(purchase).inDays);
  final annualized = cost > 0 && current > 0 ? (math.pow(current / cost, 365 / days) - 1) * 100 : 0.0;
  return PnL(
    currentValue: current,
    totalCost: cost,
    gainLoss: current - cost,
    percentReturn: cost > 0 ? (current - cost) / cost * 100 : 0,
    annualizedReturn: annualized.toDouble(),
    holdingDays: days,
  );
}

class ZakatResult {
  const ZakatResult(this.totalZakatableValue, this.nisabThresholdSar, this.isAboveNisab, this.zakatDue);
  final double totalZakatableValue;
  final double nisabThresholdSar;
  final bool isAboveNisab;
  final double zakatDue;
}

ZakatResult calculateZakat(List<PortfolioAsset> assets, SpotPrices spot) {
  final nisab = nisabGoldGrams * purePerGramSar(spot, 'XAU');
  final total = assets.fold<double>(0, (s, a) => s + currentValueSar(a, spot));
  final above = total >= nisab && nisab > 0;
  return ZakatResult(total, nisab, above, above ? total * 0.025 : 0);
}
