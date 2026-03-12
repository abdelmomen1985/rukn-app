import AsyncStorage from "@react-native-async-storage/async-storage";
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import type { MetalDefinition, PortfolioAsset, SpotPrices } from "@/data/portfolio";
import { defaultMetals, migrateAsset, mockPortfolioAssets } from "@/data/portfolio";
import { fetchSpotPrices } from "@/lib/gold-price-service";
import { getCurrentValueSAR, getWeightInGrams } from "@/lib/portfolio-utils";

const ASSETS_KEY = "portfolio_assets";
const METALS_KEY = "portfolio_metals";
const PRICE_POLL_INTERVAL = 60_000;

export interface PortfolioSummary {
  totalValue: number;
  totalCost: number;
  gainLoss: number;
  gainLossPercent: number;
  /** Value per metal id, e.g. { gold: 15000, silver: 800, platinum: 3200 } */
  metalValues: Record<string, number>;
  assetCount: number;
}

type PortfolioContextValue = {
  assets: PortfolioAsset[];
  metals: MetalDefinition[];
  spotPrices: SpotPrices | null;
  isLoadingPrices: boolean;
  isOffline: boolean;
  // Assets CRUD
  addAsset: (asset: Omit<PortfolioAsset, "id" | "createdAt" | "updatedAt">) => Promise<void>;
  updateAsset: (id: string, updates: Partial<PortfolioAsset>) => Promise<void>;
  deleteAsset: (id: string) => Promise<void>;
  // Metals CRUD
  addMetal: (metal: Omit<MetalDefinition, "isBuiltIn">) => Promise<void>;
  updateMetal: (id: string, updates: Partial<MetalDefinition>) => Promise<void>;
  deleteMetal: (id: string) => Promise<void>;
  // Prices
  refreshPrices: () => Promise<void>;
  // Helpers
  getAssetCurrentValue: (asset: PortfolioAsset) => number;
  getMetalById: (id: string) => MetalDefinition | undefined;
  getSummary: () => PortfolioSummary;
};

const PortfolioContext = createContext<PortfolioContextValue | null>(null);

export function PortfolioProvider({ children }: { children: React.ReactNode }) {
  const [assets, setAssets] = useState<PortfolioAsset[]>([]);
  const [metals, setMetals] = useState<MetalDefinition[]>(defaultMetals);
  const [spotPrices, setSpotPrices] = useState<SpotPrices | null>(null);
  const [isLoadingPrices, setIsLoadingPrices] = useState(true);
  const [isOffline, setIsOffline] = useState(false);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const metalsRef = useRef<MetalDefinition[]>(defaultMetals);

  // Keep ref in sync so refreshPrices always sees the latest metals
  useEffect(() => { metalsRef.current = metals; }, [metals]);

  // Load metals from AsyncStorage
  useEffect(() => {
    const loadMetals = async () => {
      try {
        const raw = await AsyncStorage.getItem(METALS_KEY);
        if (raw) {
          const stored: MetalDefinition[] = JSON.parse(raw);
          // Merge: always keep built-ins fresh from defaultMetals, append custom ones
          const custom = stored.filter((m) => !m.isBuiltIn);
          setMetals([...defaultMetals, ...custom]);
        }
      } catch {}
    };
    loadMetals();
  }, []);

  // Load assets from AsyncStorage, applying migration
  useEffect(() => {
    const loadAssets = async () => {
      try {
        const raw = await AsyncStorage.getItem(ASSETS_KEY);
        if (raw) {
          const parsed: any[] = JSON.parse(raw);
          setAssets(parsed.map(migrateAsset));
        } else {
          setAssets(mockPortfolioAssets);
          await AsyncStorage.setItem(ASSETS_KEY, JSON.stringify(mockPortfolioAssets));
        }
      } catch {
        setAssets(mockPortfolioAssets);
      }
    };
    loadAssets();
  }, []);

  const refreshPrices = useCallback(async () => {
    setIsLoadingPrices(true);
    try {
      const symbols = [...new Set(metalsRef.current.map((m) => m.apiSymbol).filter(Boolean))];
      const prices = await fetchSpotPrices(symbols);
      setSpotPrices(prices);
      const age = Date.now() - new Date(prices.fetchedAt).getTime();
      setIsOffline(age > 10 * 60 * 1000);
    } catch {
      setIsOffline(true);
    } finally {
      setIsLoadingPrices(false);
    }
  }, []);

  useEffect(() => {
    refreshPrices();
    pollRef.current = setInterval(refreshPrices, PRICE_POLL_INTERVAL);
    return () => { if (pollRef.current) clearInterval(pollRef.current); };
  }, [refreshPrices]);

  // --- Assets CRUD ---

  const saveAssets = useCallback(async (updated: PortfolioAsset[]) => {
    setAssets(updated);
    try { await AsyncStorage.setItem(ASSETS_KEY, JSON.stringify(updated)); } catch {}
  }, []);

  const addAsset = useCallback(
    async (asset: Omit<PortfolioAsset, "id" | "createdAt" | "updatedAt">) => {
      const now = new Date().toISOString();
      await saveAssets([...assets, { ...asset, id: `asset-${Date.now()}`, createdAt: now, updatedAt: now }]);
    },
    [assets, saveAssets],
  );

  const updateAsset = useCallback(
    async (id: string, updates: Partial<PortfolioAsset>) => {
      await saveAssets(
        assets.map((a) => (a.id === id ? { ...a, ...updates, updatedAt: new Date().toISOString() } : a)),
      );
    },
    [assets, saveAssets],
  );

  const deleteAsset = useCallback(
    async (id: string) => { await saveAssets(assets.filter((a) => a.id !== id)); },
    [assets, saveAssets],
  );

  // --- Metals CRUD ---

  const saveMetals = useCallback(async (updated: MetalDefinition[]) => {
    setMetals(updated);
    metalsRef.current = updated;
    try { await AsyncStorage.setItem(METALS_KEY, JSON.stringify(updated)); } catch {}
  }, []);

  const addMetal = useCallback(
    async (metal: Omit<MetalDefinition, "isBuiltIn">) => {
      if (metals.some((m) => m.id === metal.id)) return; // no duplicates
      await saveMetals([...metals, { ...metal, isBuiltIn: false }]);
      // Immediately fetch price for the new symbol if provided
      if (metal.apiSymbol) refreshPrices();
    },
    [metals, saveMetals, refreshPrices],
  );

  const updateMetal = useCallback(
    async (id: string, updates: Partial<MetalDefinition>) => {
      await saveMetals(metals.map((m) => (m.id === id ? { ...m, ...updates } : m)));
    },
    [metals, saveMetals],
  );

  const deleteMetal = useCallback(
    async (id: string) => {
      const metal = metals.find((m) => m.id === id);
      if (!metal || metal.isBuiltIn) return; // cannot delete built-ins
      await saveMetals(metals.filter((m) => m.id !== id));
    },
    [metals, saveMetals],
  );

  // --- Helpers ---

  const getMetalById = useCallback(
    (id: string) => metals.find((m) => m.id === id),
    [metals],
  );

  const getAssetCurrentValue = useCallback(
    (asset: PortfolioAsset): number => {
      if (!spotPrices) return 0;
      const metal = metals.find((m) => m.id === asset.metalType);
      if (!metal) return 0;
      return getCurrentValueSAR(asset, spotPrices, metal);
    },
    [spotPrices, metals],
  );

  const getSummary = useCallback((): PortfolioSummary => {
    const metalValues: Record<string, number> = {};
    let totalValue = 0;
    let totalCost = 0;

    for (const asset of assets) {
      const val = spotPrices ? getAssetCurrentValue(asset) : 0;
      totalValue += val;
      totalCost += asset.purchasePrice + asset.makingCharges + asset.vatAmount;
      metalValues[asset.metalType] = (metalValues[asset.metalType] ?? 0) + val;
    }

    const gainLoss = totalValue - totalCost;
    const gainLossPercent = totalCost > 0 ? (gainLoss / totalCost) * 100 : 0;

    return { totalValue, totalCost, gainLoss, gainLossPercent, metalValues, assetCount: assets.length };
  }, [assets, spotPrices, getAssetCurrentValue]);

  const value = useMemo(
    () => ({
      assets, metals, spotPrices, isLoadingPrices, isOffline,
      addAsset, updateAsset, deleteAsset,
      addMetal, updateMetal, deleteMetal,
      refreshPrices, getAssetCurrentValue, getMetalById, getSummary,
    }),
    [assets, metals, spotPrices, isLoadingPrices, isOffline,
      addAsset, updateAsset, deleteAsset,
      addMetal, updateMetal, deleteMetal,
      refreshPrices, getAssetCurrentValue, getMetalById, getSummary],
  );

  return <PortfolioContext.Provider value={value}>{children}</PortfolioContext.Provider>;
}

export function usePortfolio(): PortfolioContextValue {
  const ctx = useContext(PortfolioContext);
  if (!ctx) throw new Error("usePortfolio must be used within PortfolioProvider");
  return ctx;
}
