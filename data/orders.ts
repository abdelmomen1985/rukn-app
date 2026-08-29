export type OrderStatus = "pending" | "processing" | "shipped" | "delivered" | "cancelled";

export interface OrderItem {
  productId: string;
  name: string;
  price: number;
  quantity: number;
  image: any;
}

export interface Order {
  id: string;
  orderNumber: string;
  date: string;
  status: OrderStatus;
  items: OrderItem[];
  total: number;
  address: string;
}

// Orders come from Medusa via listOrders() in lib/medusa.ts.
// The seeded order list was removed before launch — see docs/PUBLISHING.md §1.4.
