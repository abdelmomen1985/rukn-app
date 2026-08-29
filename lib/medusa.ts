/**
 * Medusa storefront client for the app.
 *
 * Talks to the same backend as rukn-site (rukn-admin, Medusa v2):
 *   - catalog (products / categories, SAR pricing)
 *   - customer auth (email + password, JWT in SecureStore)
 *   - checkout (cart → address → shipping → manual payment → order)
 *   - order history
 *
 * Base URL / publishable key come from EXPO_PUBLIC_MEDUSA_URL and
 * EXPO_PUBLIC_MEDUSA_PUBLISHABLE_KEY (see .env), with the deployed backend
 * as default.
 */

import { Platform } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as SecureStore from "expo-secure-store";
import type { Product, Category } from "@/data/products";
import type { Order, OrderStatus } from "@/data/orders";

const BASE_URL = (
  process.env.EXPO_PUBLIC_MEDUSA_URL || "https://rknadmin.kayanprojects.online"
).replace(/\/+$/, "");

const PUBLISHABLE_KEY =
  process.env.EXPO_PUBLIC_MEDUSA_PUBLISHABLE_KEY ||
  "pk_375af1650d3fc81e3b35342130536b67fb37aba13f384f16bd3e1319e67cbaa1";

// ---------------------------------------------------------------------------
// Customer token storage (SecureStore on native, AsyncStorage on web)
// ---------------------------------------------------------------------------

const TOKEN_KEY = "medusa_customer_token";

export async function getCustomerToken(): Promise<string | null> {
  try {
    if (Platform.OS === "web") return await AsyncStorage.getItem(TOKEN_KEY);
    return await SecureStore.getItemAsync(TOKEN_KEY);
  } catch {
    return null;
  }
}

async function setCustomerToken(token: string): Promise<void> {
  if (Platform.OS === "web") await AsyncStorage.setItem(TOKEN_KEY, token);
  else await SecureStore.setItemAsync(TOKEN_KEY, token);
}

export async function clearCustomerToken(): Promise<void> {
  try {
    if (Platform.OS === "web") await AsyncStorage.removeItem(TOKEN_KEY);
    else await SecureStore.deleteItemAsync(TOKEN_KEY);
  } catch {
    // best-effort
  }
}

// ---------------------------------------------------------------------------
// Fetch helper
// ---------------------------------------------------------------------------

export class MedusaError extends Error {
  status: number;
  body: unknown;

  constructor(message: string, status: number, body: unknown) {
    super(message);
    this.name = "MedusaError";
    this.status = status;
    this.body = body;
  }
}

export async function medusaFetch<T>(
  path: string,
  options: Omit<RequestInit, "headers"> & { headers?: Record<string, string> } = {},
): Promise<T> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "x-publishable-api-key": PUBLISHABLE_KEY,
    ...options.headers,
  };
  if (!headers["Authorization"]) {
    const token = await getCustomerToken();
    if (token) headers["Authorization"] = `Bearer ${token}`;
  }

  const response = await fetch(`${BASE_URL}${path}`, { ...options, headers });
  if (!response.ok) {
    let body: unknown = null;
    try {
      body = await response.json();
    } catch {
      // non-JSON error body
    }
    throw new MedusaError(
      `Medusa request failed: ${response.status}`,
      response.status,
      body,
    );
  }
  return (await response.json()) as T;
}

// ---------------------------------------------------------------------------
// Region (SAR)
// ---------------------------------------------------------------------------

let regionPromise: Promise<{ id: string }> | null = null;

export function getSarRegion(): Promise<{ id: string }> {
  if (!regionPromise) {
    regionPromise = medusaFetch<{
      regions: { id: string; currency_code: string }[];
    }>("/store/regions")
      .then(({ regions }) => {
        const region =
          regions.find((r) => r.currency_code === "sar") ?? regions[0];
        if (!region) throw new Error("No region configured in Medusa");
        return region;
      })
      .catch((err) => {
        regionPromise = null;
        throw err;
      });
  }
  return regionPromise;
}

// ---------------------------------------------------------------------------
// Catalog
// ---------------------------------------------------------------------------

interface MedusaVariant {
  id: string;
  calculated_price?: { calculated_amount?: number | null } | null;
}

interface MedusaProduct {
  id: string;
  title?: string | null;
  description?: string | null;
  thumbnail?: string | null;
  metadata?: Record<string, unknown> | null;
  images?: { url?: string | null }[] | null;
  categories?: { id: string; name?: string | null }[] | null;
  variants?: MedusaVariant[] | null;
}

const PRODUCT_FIELDS = [
  "id",
  "title",
  "description",
  "thumbnail",
  "metadata",
  "*images",
  "*categories",
  "*variants",
  "*variants.calculated_price",
].join(",");

const FALLBACK_IMAGE =
  "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800&q=80";

function cheapestVariant(product: MedusaProduct): MedusaVariant | undefined {
  const variants = product.variants ?? [];
  const priced = variants
    .filter((v) => typeof v.calculated_price?.calculated_amount === "number")
    .sort(
      (a, b) =>
        (a.calculated_price?.calculated_amount ?? 0) -
        (b.calculated_price?.calculated_amount ?? 0),
    );
  return priced[0] ?? variants[0];
}

function mapProduct(p: MedusaProduct): Product {
  const variant = cheapestVariant(p);
  const fromPrice = parseFloat(String(p.metadata?.["from_price"] ?? ""));
  const price =
    variant?.calculated_price?.calculated_amount ??
    (Number.isFinite(fromPrice) ? fromPrice : 0);
  const title = p.title ?? "";
  return {
    id: p.id,
    name: title,
    nameAr: title,
    price,
    image: { uri: p.thumbnail || p.images?.[0]?.url || FALLBACK_IMAGE },
    category: p.categories?.[0]?.id ?? "all",
    description: p.description ?? undefined,
    descriptionAr: p.description ?? undefined,
    variantId: variant?.id,
    currency: "SAR",
  };
}

export async function listStoreProducts(): Promise<Product[]> {
  const region = await getSarRegion();
  const { products } = await medusaFetch<{ products: MedusaProduct[] }>(
    `/store/products?region_id=${region.id}&limit=100&fields=${PRODUCT_FIELDS}`,
  );
  return (products ?? []).map(mapProduct);
}

export async function getStoreProduct(id: string): Promise<Product | null> {
  const region = await getSarRegion();
  const { products } = await medusaFetch<{ products: MedusaProduct[] }>(
    `/store/products?id=${encodeURIComponent(id)}&region_id=${region.id}&fields=${PRODUCT_FIELDS}`,
  );
  return products?.length ? mapProduct(products[0]) : null;
}

export async function listStoreCategories(): Promise<Category[]> {
  const { product_categories } = await medusaFetch<{
    product_categories: { id: string; name?: string | null }[];
  }>("/store/product-categories?limit=100");
  return (product_categories ?? []).map((c) => ({
    id: c.id,
    title: c.name ?? "",
    description: "",
  }));
}

// ---------------------------------------------------------------------------
// Customer auth
// ---------------------------------------------------------------------------

export interface Customer {
  id: string;
  email: string;
  first_name?: string | null;
  last_name?: string | null;
  phone?: string | null;
}

export async function login(email: string, password: string): Promise<Customer> {
  const { token } = await medusaFetch<{ token: string }>(
    "/auth/customer/emailpass",
    { method: "POST", body: JSON.stringify({ email, password }) },
  );
  await setCustomerToken(token);
  return getMe();
}

export async function register(input: {
  email: string;
  password: string;
  firstName?: string;
  lastName?: string;
  phone?: string;
}): Promise<Customer> {
  const { token: registrationToken } = await medusaFetch<{ token: string }>(
    "/auth/customer/emailpass/register",
    {
      method: "POST",
      body: JSON.stringify({ email: input.email, password: input.password }),
    },
  );
  await medusaFetch("/store/customers", {
    method: "POST",
    headers: { Authorization: `Bearer ${registrationToken}` },
    body: JSON.stringify({
      email: input.email,
      first_name: input.firstName,
      last_name: input.lastName,
      phone: input.phone,
    }),
  });
  // Exchange the registration token for a regular session token.
  return login(input.email, input.password);
}

export async function getMe(): Promise<Customer> {
  const { customer } = await medusaFetch<{ customer: Customer }>(
    "/store/customers/me",
  );
  return customer;
}

export async function logout(): Promise<void> {
  await clearCustomerToken();
}

/**
 * Hard-delete the signed-in customer (App Store Guideline 5.1.1(v) / Play
 * account-deletion policy).
 *
 * Medusa v2 exposes DELETE /store/customers/me; older builds or restricted
 * setups answer 404/405, which we surface as `unsupported` so the UI can offer
 * the web deletion page instead of pretending the account is gone.
 */
export async function deleteAccount(): Promise<{
  status: "deleted" | "unsupported" | "unauthorized" | "error";
}> {
  try {
    await medusaFetch("/store/customers/me", { method: "DELETE" });
    await clearCustomerToken();
    return { status: "deleted" };
  } catch (error) {
    const status = error instanceof MedusaError ? error.status : 0;
    if (status === 401 || status === 403) {
      // The token is no longer usable, so drop it — but the account still
      // exists, so this is NOT a successful deletion.
      await clearCustomerToken();
      return { status: "unauthorized" };
    }
    // Keep the session: the account was not deleted, and signing the user out
    // here would leave them unable to retry from inside the app.
    if (status === 404 || status === 405) return { status: "unsupported" };
    return { status: "error" };
  }
}

// ---------------------------------------------------------------------------
// Checkout (local cart items → real Medusa order)
// ---------------------------------------------------------------------------

export interface CheckoutItem {
  variantId: string;
  quantity: number;
}

export interface CheckoutForm {
  name: string;
  email: string;
  phone: string;
  city: string;
  address: string;
}

export async function placeOrder(
  items: CheckoutItem[],
  form: CheckoutForm,
): Promise<{ id: string; displayId: number | string }> {
  if (!items.length) throw new Error("cart_is_empty");
  const region = await getSarRegion();

  const { cart } = await medusaFetch<{ cart: { id: string } }>("/store/carts", {
    method: "POST",
    body: JSON.stringify({ region_id: region.id, email: form.email }),
  });

  for (const item of items) {
    await medusaFetch(`/store/carts/${cart.id}/line-items`, {
      method: "POST",
      body: JSON.stringify({
        variant_id: item.variantId,
        quantity: item.quantity,
      }),
    });
  }

  const [firstName, ...rest] = form.name.trim().split(/\s+/);
  await medusaFetch(`/store/carts/${cart.id}`, {
    method: "POST",
    body: JSON.stringify({
      shipping_address: {
        first_name: firstName || form.name,
        last_name: rest.join(" ") || "-",
        phone: form.phone,
        address_1: form.address,
        city: form.city,
        country_code: "sa",
      },
    }),
  });

  const { shipping_options } = await medusaFetch<{
    shipping_options: { id: string }[];
  }>(`/store/shipping-options?cart_id=${cart.id}`);
  if (!shipping_options?.length) throw new Error("no_shipping_options");
  await medusaFetch(`/store/carts/${cart.id}/shipping-methods`, {
    method: "POST",
    body: JSON.stringify({ option_id: shipping_options[0].id }),
  });

  const { payment_collection } = await medusaFetch<{
    payment_collection: { id: string };
  }>("/store/payment-collections", {
    method: "POST",
    body: JSON.stringify({ cart_id: cart.id }),
  });
  await medusaFetch(
    `/store/payment-collections/${payment_collection.id}/payment-sessions`,
    { method: "POST", body: JSON.stringify({ provider_id: "pp_system_default" }) },
  );

  const completed = await medusaFetch<{
    type: string;
    order?: { id: string; display_id?: number };
    error?: { message?: string };
  }>(`/store/carts/${cart.id}/complete`, { method: "POST" });

  if (completed.type !== "order" || !completed.order) {
    throw new Error(completed.error?.message || "cart_completion_failed");
  }
  return {
    id: completed.order.id,
    displayId: completed.order.display_id ?? completed.order.id,
  };
}

// ---------------------------------------------------------------------------
// Order history (mapped to the app's Order shape from data/orders.ts)
// ---------------------------------------------------------------------------

interface MedusaOrder {
  id: string;
  display_id?: number;
  status?: string;
  created_at: string;
  total?: number;
  currency_code?: string;
  items?: {
    title?: string | null;
    quantity: number;
    thumbnail?: string | null;
    unit_price?: number;
  }[];
  shipping_address?: { address_1?: string | null; city?: string | null } | null;
}

function mapOrderStatus(status?: string): OrderStatus {
  switch (status) {
    case "completed":
      return "delivered";
    case "canceled":
    case "cancelled":
      return "cancelled";
    case "pending":
      return "pending";
    default:
      return "processing";
  }
}

export async function listOrders(): Promise<Order[]> {
  const { orders } = await medusaFetch<{ orders: MedusaOrder[] }>(
    "/store/orders?order=-created_at&limit=25&fields=*items,*shipping_address",
  );
  return (orders ?? []).map((o) => ({
    id: o.id,
    orderNumber: `#${o.display_id ?? o.id}`,
    date: o.created_at,
    status: mapOrderStatus(o.status),
    total: o.total ?? 0,
    address: [o.shipping_address?.city, o.shipping_address?.address_1]
      .filter(Boolean)
      .join("، "),
    items: (o.items ?? []).map((item) => ({
      productId: "",
      name: item.title ?? "",
      price: item.unit_price ?? 0,
      quantity: item.quantity,
      image: { uri: item.thumbnail || FALLBACK_IMAGE },
    })),
  }));
}
