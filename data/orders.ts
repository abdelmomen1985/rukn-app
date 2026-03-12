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

export const mockOrders: Order[] = [
  {
    id: "ord-001",
    orderNumber: "#ORD-2026-001",
    date: "2026-03-10",
    status: "delivered",
    address: "123 Al Olaya St, Riyadh, Saudi Arabia",
    items: [
      {
        productId: "1",
        name: "Gold Bracelet 21K",
        price: 4308.57,
        quantity: 1,
        image: require("@/assets/figma-assets/1586-4296.webp"),
      },
      {
        productId: "9",
        name: "Gold Wedding Ring",
        price: 8900,
        quantity: 1,
        image: require("@/assets/figma-assets/1588-3919.webp"),
      },
    ],
    total: 13208.57,
  },
  {
    id: "ord-002",
    orderNumber: "#ORD-2026-002",
    date: "2026-03-05",
    status: "shipped",
    address: "456 King Fahd Rd, Jeddah, Saudi Arabia",
    items: [
      {
        productId: "5",
        name: "Gold Chain Necklace",
        price: 5200,
        quantity: 2,
        image: require("@/assets/figma-assets/1586-4300.webp"),
      },
    ],
    total: 10400,
  },
  {
    id: "ord-003",
    orderNumber: "#ORD-2026-003",
    date: "2026-02-28",
    status: "processing",
    address: "789 Tahlia St, Riyadh, Saudi Arabia",
    items: [
      {
        productId: "13",
        name: "Gold Stud Earrings",
        price: 3200,
        quantity: 1,
        image: require("@/assets/figma-assets/1586-4297.webp"),
      },
      {
        productId: "10",
        name: "Diamond Gold Ring",
        price: 12500,
        quantity: 1,
        image: require("@/assets/figma-assets/1588-3920.webp"),
      },
      {
        productId: "3",
        name: "Classic Gold Bangle",
        price: 3500,
        quantity: 2,
        image: require("@/assets/figma-assets/1586-4298.webp"),
      },
    ],
    total: 22700,
  },
  {
    id: "ord-004",
    orderNumber: "#ORD-2026-004",
    date: "2026-02-14",
    status: "pending",
    address: "321 Prince Mohammed Rd, Dammam, Saudi Arabia",
    items: [
      {
        productId: "17",
        name: "Exclusive Gold Bracelet",
        price: 15000,
        quantity: 1,
        image: require("@/assets/figma-assets/1586-4301.webp"),
      },
    ],
    total: 15000,
  },
  {
    id: "ord-005",
    orderNumber: "#ORD-2026-005",
    date: "2026-01-20",
    status: "cancelled",
    address: "654 Al Hamra St, Riyadh, Saudi Arabia",
    items: [
      {
        productId: "6",
        name: "Pendant Gold Necklace",
        price: 6800,
        quantity: 1,
        image: require("@/assets/figma-assets/1586-4301.webp"),
      },
      {
        productId: "15",
        name: "Gold Hoop Earrings",
        price: 3800,
        quantity: 1,
        image: require("@/assets/figma-assets/1586-4299.webp"),
      },
    ],
    total: 10600,
  },
];
