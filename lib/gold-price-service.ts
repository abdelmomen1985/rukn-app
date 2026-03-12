import AsyncStorage from "@react-native-async-storage/async-storage";
import type { SpotPrices } from "@/data/portfolio";

const CACHE_KEY = "spot_prices_cache";
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

// Fallback prices (USD / troy oz) for when the API is unreachable
const FALLBACK_PRICES: Record<string, number> = {
  XAU: 3300,
  XAG: 33,
  XPT: 960,
  XPD: 1080,
};

async function fetchSymbol(symbol: string): Promise<number> {
  const res = await fetch(`https://api.gold-api.com/price/${symbol}`);
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${symbol}`);
  const json = await res.json();
  return json.price as number;
}

async function fetchFromAPI(symbols: string[]): Promise<SpotPrices> {
  const results = await Promise.allSettled(symbols.map((s) => fetchSymbol(s)));
  const prices: Record<string, number> = {};
  results.forEach((r, i) => {
    if (r.status === "fulfilled") {
      prices[symbols[i]] = r.value;
    }
  });
  if (Object.keys(prices).length === 0) throw new Error("All symbol fetches failed");
  return { prices, fetchedAt: new Date().toISOString() };
}

async function getCache(): Promise<SpotPrices | null> {
  try {
    const raw = await AsyncStorage.getItem(CACHE_KEY);
    if (!raw) return null;
    const cached: SpotPrices = JSON.parse(raw);
    const age = Date.now() - new Date(cached.fetchedAt).getTime();
    if (age > CACHE_TTL_MS) return null;
    return cached;
  } catch {
    return null;
  }
}

async function setCache(prices: SpotPrices): Promise<void> {
  try {
    await AsyncStorage.setItem(CACHE_KEY, JSON.stringify(prices));
  } catch {}
}

/**
 * Fetch live spot prices for the given API symbols (e.g. ["XAU","XAG","XPT"]).
 * Falls back to stale cache, then to built-in fallback prices on network failure.
 */
export async function fetchSpotPrices(symbols: string[]): Promise<SpotPrices> {
  // Return fresh cache if still valid (all requested symbols present)
  const cached = await getCache();
  if (cached && symbols.every((s) => s in cached.prices)) return cached;

  try {
    // Only fetch symbols not yet in cache (or re-fetch all if cache expired)
    const symbolsToFetch = cached
      ? symbols.filter((s) => !(s in cached.prices))
      : symbols;

    const fresh = await fetchFromAPI(symbolsToFetch);
    // Merge with cached prices (keep stale prices for symbols not re-fetched)
    const merged: SpotPrices = {
      prices: { ...(cached?.prices ?? {}), ...fresh.prices },
      fetchedAt: fresh.fetchedAt,
    };
    await setCache(merged);
    return merged;
  } catch {
    // Network failure: return stale cache with whatever prices we have
    if (cached) return cached;
    // Last resort: hardcoded fallbacks
    const fallback: SpotPrices = {
      prices: Object.fromEntries(symbols.map((s) => [s, FALLBACK_PRICES[s] ?? 0])),
      fetchedAt: new Date().toISOString(),
    };
    return fallback;
  }
}

export async function getCachedPrices(): Promise<SpotPrices | null> {
  try {
    const raw = await AsyncStorage.getItem(CACHE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function isStaleCache(prices: SpotPrices): boolean {
  return Date.now() - new Date(prices.fetchedAt).getTime() > CACHE_TTL_MS;
}
