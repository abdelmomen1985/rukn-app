/**
 * Market-trip ("جولة تسوق") data model.
 *
 * A trip is a planning aid for a jewelry shopping trip across multiple stores.
 * Each stop captures a store's quoted price so the user can compare and pick
 * the best deal. The fair-price label is derived from the live spot price plus
 * a typical workmanship band, mirroring the calculator referenced in design.
 */

export type TripGoal = "compare" | "buy-today";

export type TripStatus = "active" | "completed";

export type FairnessVerdict = "excellent" | "fair" | "high";

/** Item / category the user is shopping for. */
export type JewelryCategory = "ring" | "bracelet" | "necklace" | "earring" | "bar" | "coin";

export type Origin = "local" | "imported";

/** A single store visit within a trip. */
export interface TripStop {
  id: string;
  storeName: string;
  /** Optional neighbourhood, mall, or short address note */
  location?: string;
  /** Total quoted price for the item, in SAR (the price the shop is asking). */
  totalPriceSAR: number;
  /** Weight in grams used for the quote. */
  weightGrams: number;
  /** Karat / purity label used for the quote, e.g. "21K". */
  purityLabel: string;
  /** 0..1 purity factor, e.g. 21/24. */
  purityFactor: number;
  /** Whether the quoted total already includes 15% VAT. */
  vatIncluded: boolean;
  /** Origin of the workmanship, captured separately from purity. */
  origin: Origin;
  /** Optional free-form note. */
  notes?: string;
  /** ISO timestamp when the stop was recorded. */
  visitedAt: string;
  /** Cached fair-price computation snapshot (so list views don't need spot data). */
  verdict: FairnessVerdict;
  /** Per-gram workmanship inferred from this quote, in SAR / g (excluding VAT and gold value). */
  makingPerGramSAR: number;
  /** The market-fair per-gram price used as the reference at time of capture, in SAR / g. */
  marketReferencePerGramSAR: number;
}

/** A planned shopping trip. */
export interface MarketTrip {
  id: string;
  name: string;
  city: string;
  goal: TripGoal;
  category: JewelryCategory;
  /** Default purity for new stops (can be overridden per-stop). */
  purityLabel: string;
  purityFactor: number;
  /** Optional expected weight to pre-fill new stops. */
  weightGrams?: number;
  status: TripStatus;
  stops: TripStop[];
  createdAt: string;
  updatedAt: string;
}

/** Popular Saudi cities listed in the new-trip mock. */
export const POPULAR_CITIES_AR: { id: string; nameAr: string; nameEn: string }[] = [
  { id: "riyadh", nameAr: "الرياض", nameEn: "Riyadh" },
  { id: "jeddah", nameAr: "جدة", nameEn: "Jeddah" },
  { id: "mecca", nameAr: "مكة المكرمة", nameEn: "Mecca" },
  { id: "medina", nameAr: "المدينة المنورة", nameEn: "Medina" },
  { id: "dammam", nameAr: "الدمام", nameEn: "Dammam" },
  { id: "khobar", nameAr: "الخبر", nameEn: "Al Khobar" },
  { id: "taif", nameAr: "الطائف", nameEn: "Taif" },
  { id: "abha", nameAr: "أبها", nameEn: "Abha" },
];

/** Default purities (mirrors gold purities used elsewhere in the portfolio). */
export const TRIP_PURITIES: { label: string; factor: number }[] = [
  { label: "24K", factor: 1.0 },
  { label: "22K", factor: 22 / 24 },
  { label: "21K", factor: 21 / 24 },
  { label: "18K", factor: 18 / 24 },
  { label: "14K", factor: 14 / 24 },
];

export const TRIP_CATEGORIES: JewelryCategory[] = ["ring", "bracelet", "necklace", "earring", "bar", "coin"];

/** VAT rate applied in KSA. */
export const VAT_RATE = 0.15;

/**
 * Per-gram workmanship band considered "fair" for a typical retail jewelry piece, in SAR / g.
 * If a store charges within this band on top of the pure gold value, the deal is fair.
 * Above the band → high (overpriced); at or below the lower bound → excellent.
 */
export const FAIR_MAKING_BAND_SAR_PER_GRAM = { low: 25, high: 45 } as const;

export interface FairPriceInput {
  /** Total quoted price in SAR (incl. or excl. VAT depending on `vatIncluded`). */
  totalPriceSAR: number;
  weightGrams: number;
  purityFactor: number;
  vatIncluded: boolean;
  /** Pure 24K gold per-gram price in SAR (from spot service). */
  purePerGramSAR: number;
}

export interface FairPriceResult {
  /** Quoted total stripped of VAT, in SAR. */
  preTaxTotalSAR: number;
  /** Inferred per-gram workmanship in SAR / g (preTaxTotal - goldValue) / weight. */
  makingPerGramSAR: number;
  /** Pure gold value of the piece at current spot, in SAR. */
  goldValueSAR: number;
  /** VAT amount included in the quote, in SAR. */
  vatAmountSAR: number;
  /** Suggested fair per-gram (gold-per-gram-at-purity + mid making band). */
  fairPerGramSAR: number;
  /** The market reference (in SAR / g) used to compare against. */
  marketReferencePerGramSAR: number;
  verdict: FairnessVerdict;
}

/**
 * Compute a fair-price verdict for a single quote.
 *
 *  pre-tax total = total / 1.15 if VAT is included, else total
 *  gold value    = grams * purity * purePerGramSAR
 *  making/g      = (pre-tax total - gold value) / grams
 *  market ref/g  = goldPerGramAtPurity + mid(making band)
 *  verdict       = excellent | fair | high based on making/g vs band
 */
export function evaluateFairPrice(input: FairPriceInput): FairPriceResult {
  const { totalPriceSAR, weightGrams, purityFactor, vatIncluded, purePerGramSAR } = input;
  const preTaxTotalSAR = vatIncluded ? totalPriceSAR / (1 + VAT_RATE) : totalPriceSAR;
  const vatAmountSAR = vatIncluded ? totalPriceSAR - preTaxTotalSAR : 0;
  const goldPerGramAtPurity = purePerGramSAR * purityFactor;
  const goldValueSAR = weightGrams * goldPerGramAtPurity;
  const makingPerGramSAR = weightGrams > 0 ? (preTaxTotalSAR - goldValueSAR) / weightGrams : 0;

  const midMaking = (FAIR_MAKING_BAND_SAR_PER_GRAM.low + FAIR_MAKING_BAND_SAR_PER_GRAM.high) / 2;
  const fairPerGramSAR = goldPerGramAtPurity + midMaking;
  const marketReferencePerGramSAR = fairPerGramSAR;

  let verdict: FairnessVerdict;
  if (makingPerGramSAR <= FAIR_MAKING_BAND_SAR_PER_GRAM.low) verdict = "excellent";
  else if (makingPerGramSAR <= FAIR_MAKING_BAND_SAR_PER_GRAM.high) verdict = "fair";
  else verdict = "high";

  return {
    preTaxTotalSAR,
    makingPerGramSAR,
    goldValueSAR,
    vatAmountSAR,
    fairPerGramSAR,
    marketReferencePerGramSAR,
    verdict,
  };
}

/** Returns the per-gram price implied by a stop's quoted total, including any VAT. */
export function stopPerGramSAR(stop: TripStop): number {
  if (stop.weightGrams <= 0) return 0;
  return stop.totalPriceSAR / stop.weightGrams;
}

/** Returns the trip stop with the lowest total price, or undefined if there are no stops. */
export function cheapestStop(stops: TripStop[]): TripStop | undefined {
  if (stops.length === 0) return undefined;
  return stops.reduce((best, s) => (s.totalPriceSAR < best.totalPriceSAR ? s : best), stops[0]);
}

/** Mean total price across stops; 0 if there are no stops. */
export function averageStopTotal(stops: TripStop[]): number {
  if (stops.length === 0) return 0;
  return stops.reduce((sum, s) => sum + s.totalPriceSAR, 0) / stops.length;
}
