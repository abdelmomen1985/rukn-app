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

// Migrate an asset loaded from old AsyncStorage format
export function migrateAsset(raw: any): PortfolioAsset {
  if (raw.purityFactor !== undefined && raw.purityLabel !== undefined) return raw as PortfolioAsset;
  let purityFactor = 1;
  let purityLabel = "Fine";
  if (raw.metalType === "gold" && raw.karat) {
    purityFactor = raw.karat / 24;
    purityLabel = `${raw.karat}K`;
  } else if (raw.metalType === "silver" && raw.silverPurity) {
    purityFactor = raw.silverPurity / 1000;
    purityLabel = String(raw.silverPurity);
  }
  return { ...raw, purityFactor, purityLabel };
}

export const mockPortfolioAssets: PortfolioAsset[] = [
  {
    id: "asset-001",
    metalType: "gold",
    name: "Gold Wedding Ring",
    nameAr: "خاتم ذهبي للزفاف",
    category: "ring",
    weightValue: 5.2,
    weightUnit: "grams",
    purityLabel: "21K",
    purityFactor: 21 / 24,
    purchasePrice: 2800,
    purchaseDate: "2024-06-15",
    makingCharges: 350,
    vatAmount: 154.5,
    notes: "Wedding anniversary gift",
    createdAt: "2024-06-15T10:00:00Z",
    updatedAt: "2024-06-15T10:00:00Z",
  },
  {
    id: "asset-002",
    metalType: "gold",
    name: "Gold Chain Bracelet",
    nameAr: "سوار سلسلة ذهبية",
    category: "bracelet",
    weightValue: 12.5,
    weightUnit: "grams",
    purityLabel: "18K",
    purityFactor: 18 / 24,
    purchasePrice: 5200,
    purchaseDate: "2023-12-01",
    makingCharges: 650,
    vatAmount: 292.5,
    createdAt: "2023-12-01T10:00:00Z",
    updatedAt: "2023-12-01T10:00:00Z",
  },
  {
    id: "asset-003",
    metalType: "gold",
    name: "Gold Bar 10g",
    nameAr: "سبائك ذهبية 10غ",
    category: "bar",
    weightValue: 10,
    weightUnit: "grams",
    purityLabel: "24K",
    purityFactor: 1.0,
    purchasePrice: 4800,
    purchaseDate: "2025-01-20",
    makingCharges: 0,
    vatAmount: 240,
    createdAt: "2025-01-20T10:00:00Z",
    updatedAt: "2025-01-20T10:00:00Z",
  },
  {
    id: "asset-004",
    metalType: "silver",
    name: "Silver Necklace",
    nameAr: "قلادة فضية",
    category: "necklace",
    weightValue: 25,
    weightUnit: "grams",
    purityLabel: "925",
    purityFactor: 0.925,
    purchasePrice: 420,
    purchaseDate: "2025-03-10",
    makingCharges: 80,
    vatAmount: 25,
    createdAt: "2025-03-10T10:00:00Z",
    updatedAt: "2025-03-10T10:00:00Z",
  },
  {
    id: "asset-005",
    metalType: "platinum",
    name: "Platinum Ring",
    nameAr: "خاتم بلاتين",
    category: "ring",
    weightValue: 6,
    weightUnit: "grams",
    purityLabel: "950",
    purityFactor: 0.95,
    purchasePrice: 3200,
    purchaseDate: "2024-11-10",
    makingCharges: 500,
    vatAmount: 180,
    createdAt: "2024-11-10T10:00:00Z",
    updatedAt: "2024-11-10T10:00:00Z",
  },
];
