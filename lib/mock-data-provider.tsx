import { createContext, useContext, useMemo } from "react";
import { mockOrders, type Order } from "@/data/orders";

type MockDataContextValue = {
  orders: Order[];
  getOrderById: (id: string) => Order | undefined;
};

const MockDataContext = createContext<MockDataContextValue | null>(null);

export function MockDataProvider({ children }: { children: React.ReactNode }) {
  const getOrderById = useMemo(
    () => (id: string) => mockOrders.find((o) => o.id === id),
    [],
  );

  const value = useMemo(
    () => ({ orders: mockOrders, getOrderById }),
    [getOrderById],
  );

  return <MockDataContext.Provider value={value}>{children}</MockDataContext.Provider>;
}

export function useMockData(): MockDataContextValue {
  const ctx = useContext(MockDataContext);
  if (!ctx) throw new Error("useMockData must be used within MockDataProvider");
  return ctx;
}
