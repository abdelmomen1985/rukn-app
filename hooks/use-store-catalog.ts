import { useQuery } from "@tanstack/react-query";
import { listStoreCategories, listStoreProducts } from "@/lib/medusa";

/**
 * Live catalog from Medusa.
 *
 * There is no mock fallback: when the backend is unreachable the caller gets
 * `error` + `isEmpty` and must render an error/empty state with `refetch`.
 * Shipping a fake catalog to the stores is an Apple 4.2.2 / Play metadata
 * rejection waiting to happen (docs/PUBLISHING.md §1.4).
 */
export function useStoreCatalog() {
  const productsQuery = useQuery({
    queryKey: ["medusa-products"],
    queryFn: listStoreProducts,
    staleTime: 60_000,
    retry: 1,
  });
  const categoriesQuery = useQuery({
    queryKey: ["medusa-categories"],
    queryFn: listStoreCategories,
    staleTime: 300_000,
    retry: 1,
  });

  const products = productsQuery.data ?? [];
  const categories = categoriesQuery.data ?? [];
  const isLoading = productsQuery.isLoading || categoriesQuery.isLoading;
  const error = productsQuery.error ?? categoriesQuery.error;

  return {
    products,
    categories,
    /** True once the backend answered with at least one product. */
    isLive: products.length > 0,
    isLoading,
    /** Failed to load, or loaded successfully with zero products. */
    isEmpty: !isLoading && products.length === 0,
    error: error ? (error instanceof Error ? error.message : String(error)) : null,
    refetch: () => {
      void productsQuery.refetch();
      void categoriesQuery.refetch();
    },
  };
}
