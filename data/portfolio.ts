export type WeightUnit = "grams" | "tolas" | "ounces" | "mithqal";

// --- Metal definitions ---

export interface MetalPurity {
  label: string;   // "24K", "950", "Fine (99.9%)"
  factor: number;  // 0.0–1.0 fraction of pure metal
}

export interface MetalDefinition {
  id: string;          // "gold" | "silver" | "platinum" | "palladium" | custom uuid
  name: string;        // English display name
  nameAr: string;      // Arabic display name
  apiSymbol: string;   // "XAU", "XAG", "XPT", "XPD" — empty = no live price
  purities: MetalPurity[];
  color: string;       // chart / accent color
  bgColor: string;     // card background
  borderColor: string; // card border
  textColor: string;   // text on bgColor
  emoji: string;
  isBuiltIn: boolean;  // built-ins cannot be deleted
}

export const defaultMetals: MetalDefinition[] = [
  {
    id: "gold",
    name: "Gold",
    nameAr: "ذهب",
    apiSymbol: "XAU",
    purities: [
      { label: "24K", factor: 1.0 },
      { label: "22K", factor: 22 / 24 },
      { label: "21K", factor: 21 / 24 },
      { label: "18K", factor: 18 / 24 },
      { label: "14K", factor: 14 / 24 },
    ],
    color: "#D4AF37",
    bgColor: "#FFF9E6",
    borderColor: "#F5D766",
    textColor: "#5A460A",
    emoji: "🥇",
    isBuiltIn: true,
  },
  {
    id: "silver",
    name: "Silver",
    nameAr: "فضة",
    apiSymbol: "XAG",
    purities: [
      { label: "999", factor: 0.999 },
      { label: "925", factor: 0.925 },
      { label: "900", factor: 0.9 },
      { label: "800", factor: 0.8 },
    ],
    color: "#A8A8A8",
    bgColor: "#F5F5F5",
    borderColor: "#C0C0C0",
    textColor: "#374151",
    emoji: "🥈",
    isBuiltIn: true,
  },
  {
    id: "platinum",
    name: "Platinum",
    nameAr: "بلاتين",
    apiSymbol: "XPT",
    purities: [
      { label: "950", factor: 0.95 },
      { label: "900", factor: 0.9 },
      { label: "850", factor: 0.85 },
    ],
    color: "#7B8FA1",
    bgColor: "#EFF3F7",
    borderColor: "#B0C4D8",
    textColor: "#2C3E50",
    emoji: "⬜",
    isBuiltIn: true,
  },
  {
    id: "palladium",
    name: "Palladium",
    nameAr: "بلاديوم",
    apiSymbol: "XPD",
    purities: [
      { label: "999.5", factor: 0.9995 },
      { label: "950",   factor: 0.95 },
      { label: "500",   factor: 0.5 },
    ],
    color: "#9C8D7B",
    bgColor: "#F5F0EB",
    borderColor: "#C4B5A7",
    textColor: "#4A3728",
    emoji: "🔘",
    isBuiltIn: true,
  },
];

// --- Spot prices ---

export interface SpotPrices {
  /** Prices keyed by API symbol, e.g. { XAU: 3300, XAG: 33, XPT: 960 } (USD / troy oz) */
  prices: Record<string, number>;
  fetchedAt: string;
}

// --- Portfolio asset ---

export interface PortfolioAsset {
  id: string;
  metalType: string;       // references MetalDefinition.id
  name: string;
  nameAr?: string;         // Arabic name
  category: string;
  imageUrl?: string;      // Image URL for the asset
  weightValue: number;
  weightUnit: WeightUnit;
  purityLabel: string;     // display label, e.g. "21K", "950", "Fine"
  purityFactor: number;    // 0.0–1.0 used in calculations
  purchasePrice: number;   // SAR
  purchaseDate: string;    // ISO date
  makingCharges: number;   // SAR
  vatAmount: number;       // SAR
  notes?: string;
  createdAt: string;
  updatedAt: string;
  // Legacy fields – kept for assets stored before the migration
  karat?: number | null;
  silverPurity?: number | null;
}

// --- Purity inputs used by the add-asset / converter screens ---

export type MetalType = "gold" | "silver" | "platinum";
export type GoldKarat = 24 | 22 | 21 | 18 | 14;
export type SilverPurity = 999 | 925 | 900 | 800;

export const GOLD_KARATS: GoldKarat[] = [24, 22, 21, 18, 14];
export const SILVER_PURITIES: SilverPurity[] = [999, 925, 900, 800];

/**
 * Turn the purity a customer picked into the two fields every calculation needs.
 * Assets are valued through `purityFactor`, so anything written to storage must
 * carry it — an asset saved without it silently evaluates to NaN.
 */
export function resolvePurity(
  metalType: string,
  karat?: number | null,
  fineness?: number | null,
): { purityLabel: string; purityFactor: number } {
  if (metalType === "gold" && karat) {
    return { purityLabel: `${karat}K`, purityFactor: karat / 24 };
  }
  if (fineness) {
    return { purityLabel: String(fineness), purityFactor: fineness / 1000 };
  }
  return { purityLabel: "Fine", purityFactor: 1 };
}

// Migrate an asset loaded from old AsyncStorage format
export function migrateAsset(raw: any): PortfolioAsset {
  if (raw?.purityFactor !== undefined && raw?.purityLabel !== undefined) return raw as PortfolioAsset;
  const { purityLabel, purityFactor } = resolvePurity(raw?.metalType, raw?.karat, raw?.silverPurity);
  return { ...raw, purityFactor, purityLabel };
}
