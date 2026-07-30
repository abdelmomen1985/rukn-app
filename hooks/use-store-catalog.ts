import { useQuery } from "@tanstack/react-query";
import { listStoreCategories, listStoreProducts } from "@/lib/medusa";
import {
  categories as mockCategories,
  products as mockProducts,
} from "@/data/products";

/**
 * Catalog from Medusa with the bundled mock data as offline/error fallback.
 * `isLive` tells screens whether they are looking at real backend data.
 */
export function useStoreCatalog() {
  const productsQuery = useQuery({
    queryKey: ["medusa-products"],
    queryFn: listStoreProducts,
    staleTime: 60_000,
  });
  const categoriesQuery = useQuery({
    queryKey: ["medusa-categories"],
    queryFn: listStoreCategories,
    staleTime: 300_000,
  });

  const isLive = productsQuery.isSuccess && (productsQuery.data?.length ?? 0) > 0;

  return {
    products: isLive ? productsQuery.data! : mockProducts,
    categories:
      isLive && (categoriesQuery.data?.length ?? 0) > 0
        ? categoriesQuery.data!
        : mockCategories,
    isLive,
    isLoading: productsQuery.isLoading,
    refetch: productsQuery.refetch,
  };
}
