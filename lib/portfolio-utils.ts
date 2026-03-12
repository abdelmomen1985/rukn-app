import type { MetalDefinition, PortfolioAsset, SpotPrices, WeightUnit } from "@/data/portfolio";

// Weight conversion constants
const GRAMS_PER_TOLA = 11.664;
const GRAMS_PER_OZ = 31.1035;
const GRAMS_PER_MITHQAL = 4.25;
const USD_TO_SAR = 3.75;

// Nisab: 85 grams of pure (24K) gold
const NISAB_GOLD_GRAMS = 85;

// --- Weight helpers ---

export function getWeightInGrams(value: number, unit: WeightUnit): number {
  switch (unit) {
    case "grams":   return value;
    case "tolas":   return value * GRAMS_PER_TOLA;
    case "ounces":  return value * GRAMS_PER_OZ;
    case "mithqal": return value * GRAMS_PER_MITHQAL;
  }
}

export function convertWeight(value: number, fromUnit: WeightUnit, toUnit: WeightUnit): number {
  const grams = getWeightInGrams(value, fromUnit);
  switch (toUnit) {
    case "grams":   return grams;
    case "tolas":   return grams / GRAMS_PER_TOLA;
    case "ounces":  return grams / GRAMS_PER_OZ;
    case "mithqal": return grams / GRAMS_PER_MITHQAL;
  }
}

// --- Price per gram helpers ---

/** Pure (factor=1) price per gram for a given API symbol, in SAR */
export function getPurePerGramSAR(spotPrices: SpotPrices, apiSymbol: string): number {
  const pricePerOzUSD = spotPrices.prices[apiSymbol] ?? 0;
  return (pricePerOzUSD * USD_TO_SAR) / GRAMS_PER_OZ;
}

/** Backward-compat: gold per gram at a given karat */
export function getGoldPerGramSAR(spotPrices: SpotPrices, karat: number): number {
  return getPurePerGramSAR(spotPrices, "XAU") * (karat / 24);
}

/** Backward-compat: silver per gram at a given purity (e.g. 925) */
export function getSilverPerGramSAR(spotPrices: SpotPrices, purity: number): number {
  return getPurePerGramSAR(spotPrices, "XAG") * (purity / 1000);
}

// --- Asset value ---

/**
 * Returns the current SAR value of an asset.
 * Requires the matching MetalDefinition so we can look up the API symbol.
 */
export function getCurrentValueSAR(
  asset: PortfolioAsset,
  spotPrices: SpotPrices,
  metal: MetalDefinition,
): number {
  if (!metal.apiSymbol) return 0;
  const grams = getWeightInGrams(asset.weightValue, asset.weightUnit);
  const purePerGramSAR = getPurePerGramSAR(spotPrices, metal.apiSymbol);
  return grams * purePerGramSAR * asset.purityFactor;
}

// --- P&L ---

export interface PnLResult {
  currentValue: number;
  totalCost: number;
  absoluteGainLoss: number;
  percentReturn: number;
  annualizedReturn: number;
  holdingDays: number;
}

export function calculatePnL(
  asset: PortfolioAsset,
  spotPrices: SpotPrices,
  metal: MetalDefinition,
): PnLResult {
  const currentValue = getCurrentValueSAR(asset, spotPrices, metal);
  const totalCost = asset.purchasePrice + asset.makingCharges + asset.vatAmount;
  const absoluteGainLoss = currentValue - totalCost;
  const percentReturn = totalCost > 0 ? ((currentValue - totalCost) / totalCost) * 100 : 0;

  const purchaseDate = new Date(asset.purchaseDate);
  const holdingDays = Math.max(
    1,
    Math.floor((Date.now() - purchaseDate.getTime()) / (1000 * 60 * 60 * 24)),
  );

  let annualizedReturn = 0;
  if (totalCost > 0) {
    annualizedReturn = (Math.pow(currentValue / totalCost, 365 / holdingDays) - 1) * 100;
  }

  return { currentValue, totalCost, absoluteGainLoss, percentReturn, annualizedReturn, holdingDays };
}

// --- Zakat ---

export interface ZakatResult {
  totalZakatableValue: number;
  nisabThresholdSAR: number;
  isAboveNisab: boolean;
  zakatDue: number;
}

export function calculateZakat(
  assets: PortfolioAsset[],
  spotPrices: SpotPrices,
  metals: MetalDefinition[],
): ZakatResult {
  // Nisab based on 85g of pure gold
  const nisabThresholdSAR = NISAB_GOLD_GRAMS * getPurePerGramSAR(spotPrices, "XAU");

  const totalZakatableValue = assets.reduce((sum, asset) => {
    const metal = metals.find((m) => m.id === asset.metalType);
    if (!metal) return sum;
    return sum + getCurrentValueSAR(asset, spotPrices, metal);
  }, 0);

  const isAboveNisab = totalZakatableValue >= nisabThresholdSAR;
  const zakatDue = isAboveNisab ? totalZakatableValue * 0.025 : 0;

  return { totalZakatableValue, nisabThresholdSAR, isAboveNisab, zakatDue };
}

// --- Formatting ---

export function formatSAR(amount: number, lang: "en" | "ar" = "en"): string {
  const formatted = amount.toLocaleString(lang === "ar" ? "ar-SA" : "en-SA", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  });
  return lang === "ar" ? `${formatted} ر.س` : `SAR ${formatted}`;
}

export function formatSARCompact(amount: number): string {
  if (amount >= 1_000_000) return `SAR ${(amount / 1_000_000).toFixed(1)}M`;
  if (amount >= 1_000) return `SAR ${(amount / 1_000).toFixed(1)}K`;
  return `SAR ${amount.toFixed(0)}`;
}

export function getWeightUnitLabel(unit: WeightUnit, lang: "en" | "ar" = "en"): string {
  const labels: Record<WeightUnit, { en: string; ar: string }> = {
    grams:   { en: "g",       ar: "غرام"   },
    tolas:   { en: "tola",    ar: "تولا"   },
    ounces:  { en: "oz",      ar: "أوقية"  },
    mithqal: { en: "mithqal", ar: "مثقال"  },
  };
  return labels[unit][lang];
}
