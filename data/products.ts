/**
 * Catalog contracts shared by the Medusa client (lib/medusa.ts) and the UI.
 *
 * There is deliberately no seeded product data in this file: a store build must
 * never render fake SKUs or fake prices (Apple 4.2.2 / Play metadata policy).
 * The live catalog is loaded through hooks/use-store-catalog.ts, which surfaces
 * an explicit error state instead of a fallback. See docs/PUBLISHING.md §1.4.
 */

export interface Product {
  id: string;
  name: string;
  nameAr?: string;
  price: number;
  image: any;
  category: string;
  description?: string;
  descriptionAr?: string;
  /** Medusa variant id — required to add the product to a real order. */
  variantId?: string;
  /** Display currency from the backend region (SAR for the Saudi storefront). */
  currency?: "USD" | "SAR";
}

export interface Category {
  id: string;
  title: string;
  description: string;
  image?: any;
}
