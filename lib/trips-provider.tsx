import AsyncStorage from "@react-native-async-storage/async-storage";
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { MarketTrip, TripStop } from "@/data/market-trips";

const TRIPS_KEY = "market_trips";

type TripsContextValue = {
  trips: MarketTrip[];
  isLoaded: boolean;
  // Trip CRUD
  addTrip: (
    trip: Omit<MarketTrip, "id" | "createdAt" | "updatedAt" | "stops" | "status">,
  ) => Promise<MarketTrip>;
  updateTrip: (id: string, updates: Partial<MarketTrip>) => Promise<void>;
  deleteTrip: (id: string) => Promise<void>;
  // Stop CRUD
  addStop: (tripId: string, stop: Omit<TripStop, "id">) => Promise<TripStop | undefined>;
  updateStop: (tripId: string, stopId: string, updates: Partial<TripStop>) => Promise<void>;
  deleteStop: (tripId: string, stopId: string) => Promise<void>;
  // Helpers
  getTripById: (id: string) => MarketTrip | undefined;
};

const TripsContext = createContext<TripsContextValue | null>(null);

export function TripsProvider({ children }: { children: React.ReactNode }) {
  const [trips, setTrips] = useState<MarketTrip[]>([]);
  const [isLoaded, setIsLoaded] = useState(false);

  // Load trips from AsyncStorage
  useEffect(() => {
    const load = async () => {
      try {
        const raw = await AsyncStorage.getItem(TRIPS_KEY);
        if (raw) {
          const parsed: MarketTrip[] = JSON.parse(raw);
          setTrips(parsed);
        }
      } catch {
        // ignore - start with empty list
      } finally {
        setIsLoaded(true);
      }
    };
    load();
  }, []);

  const persist = useCallback(async (updated: MarketTrip[]) => {
    setTrips(updated);
    try {
      await AsyncStorage.setItem(TRIPS_KEY, JSON.stringify(updated));
    } catch {
      // best-effort persistence
    }
  }, []);

  const addTrip = useCallback<TripsContextValue["addTrip"]>(
    async (trip) => {
      const now = new Date().toISOString();
      const created: MarketTrip = {
        ...trip,
        id: `trip-${Date.now()}`,
        stops: [],
        status: "active",
        createdAt: now,
        updatedAt: now,
      };
      await persist([created, ...trips]);
      return created;
    },
    [trips, persist],
  );

  const updateTrip = useCallback<TripsContextValue["updateTrip"]>(
    async (id, updates) => {
      const now = new Date().toISOString();
      await persist(
        trips.map((t) => (t.id === id ? { ...t, ...updates, updatedAt: now } : t)),
      );
    },
    [trips, persist],
  );

  const deleteTrip = useCallback<TripsContextValue["deleteTrip"]>(
    async (id) => {
      await persist(trips.filter((t) => t.id !== id));
    },
    [trips, persist],
  );

  const addStop = useCallback<TripsContextValue["addStop"]>(
    async (tripId, stop) => {
      const now = new Date().toISOString();
      const id = `stop-${Date.now()}`;
      const newStop: TripStop = { ...stop, id };
      let inserted: TripStop | undefined;
      const updated = trips.map((t) => {
        if (t.id !== tripId) return t;
        inserted = newStop;
        return { ...t, stops: [...t.stops, newStop], updatedAt: now };
      });
      await persist(updated);
      return inserted;
    },
    [trips, persist],
  );

  const updateStop = useCallback<TripsContextValue["updateStop"]>(
    async (tripId, stopId, updates) => {
      const now = new Date().toISOString();
      await persist(
        trips.map((t) =>
          t.id === tripId
            ? {
                ...t,
                stops: t.stops.map((s) => (s.id === stopId ? { ...s, ...updates } : s)),
                updatedAt: now,
              }
            : t,
        ),
      );
    },
    [trips, persist],
  );

  const deleteStop = useCallback<TripsContextValue["deleteStop"]>(
    async (tripId, stopId) => {
      const now = new Date().toISOString();
      await persist(
        trips.map((t) =>
          t.id === tripId
            ? { ...t, stops: t.stops.filter((s) => s.id !== stopId), updatedAt: now }
            : t,
        ),
      );
    },
    [trips, persist],
  );

  const getTripById = useCallback(
    (id: string) => trips.find((t) => t.id === id),
    [trips],
  );

  const value = useMemo(
    () => ({
      trips,
      isLoaded,
      addTrip,
      updateTrip,
      deleteTrip,
      addStop,
      updateStop,
      deleteStop,
      getTripById,
    }),
    [trips, isLoaded, addTrip, updateTrip, deleteTrip, addStop, updateStop, deleteStop, getTripById],
  );

  return <TripsContext.Provider value={value}>{children}</TripsContext.Provider>;
}

export function useTrips(): TripsContextValue {
  const ctx = useContext(TripsContext);
  if (!ctx) throw new Error("useTrips must be used within TripsProvider");
  return ctx;
}
