export interface Product {
  id: string;
  name: string;
  price: number;
  image: any;
  category: string;
  description?: string;
}

export interface Category {
  id: string;
  title: string;
  description: string;
  image?: any;
}

// Updated product data with more realistic jewelry items
export const products: Product[] = [
  // Bracelets
  {
    id: "1",
    name: "Gold Bracelet 21K",
    price: 4308.57,
    image: require("@/assets/figma-assets/1586-4296.webp"),
    category: "bracelets",
    description: "Elegant 21K gold bracelet with intricate design",
  },
  {
    id: "2",
    name: "Gold Investment Bracelet",
    price: 606429.9,
    image: require("@/assets/figma-assets/1586-4297.webp"),
    category: "bracelets",
    description: "Premium investment-grade gold bracelet",
  },
  {
    id: "3",
    name: "Classic Gold Bangle",
    price: 3500,
    image: require("@/assets/figma-assets/1586-4298.webp"),
    category: "bracelets",
    description: "Timeless classic gold bangle",
  },
  {
    id: "4",
    name: "Modern Gold Bracelet",
    price: 4200,
    image: require("@/assets/figma-assets/1586-4299.webp"),
    category: "bracelets",
    description: "Contemporary design gold bracelet",
  },

  // Necklaces
  {
    id: "5",
    name: "Gold Chain Necklace",
    price: 5200,
    image: require("@/assets/figma-assets/1586-4300.webp"),
    category: "necklaces",
    description: "Elegant gold chain necklace",
  },
  {
    id: "6",
    name: "Pendant Gold Necklace",
    price: 6800,
    image: require("@/assets/figma-assets/1586-4301.webp"),
    category: "necklaces",
    description: "Beautiful pendant gold necklace",
  },
  {
    id: "7",
    name: "Statement Gold Necklace",
    price: 7500,
    image: require("@/assets/figma-assets/1586-4302.webp"),
    category: "necklaces",
    description: "Bold statement gold necklace",
  },
  {
    id: "8",
    name: "Delicate Gold Necklace",
    price: 4500,
    image: require("@/assets/figma-assets/1588-3918.webp"),
    category: "necklaces",
    description: "Delicate and refined gold necklace",
  },

  // Rings
  {
    id: "9",
    name: "Gold Wedding Ring",
    price: 8900,
    image: require("@/assets/figma-assets/1588-3919.webp"),
    category: "rings",
    description: "Elegant wedding gold ring",
  },
  {
    id: "10",
    name: "Diamond Gold Ring",
    price: 12500,
    image: require("@/assets/figma-assets/1588-3920.webp"),
    category: "rings",
    description: "Gold ring with diamond stone",
  },
  {
    id: "11",
    name: "Classic Gold Ring",
    price: 5800,
    image: require("@/assets/figma-assets/1588-3921.webp"),
    category: "rings",
    description: "Classic design gold ring",
  },
  {
    id: "12",
    name: "Modern Gold Ring",
    price: 6500,
    image: require("@/assets/figma-assets/1586-4296.webp"),
    category: "rings",
    description: "Contemporary gold ring",
  },

  // Earrings
  {
    id: "13",
    name: "Gold Stud Earrings",
    price: 3200,
    image: require("@/assets/figma-assets/1586-4297.webp"),
    category: "earrings",
    description: "Simple gold stud earrings",
  },
  {
    id: "14",
    name: "Gold Drop Earrings",
    price: 4100,
    image: require("@/assets/figma-assets/1586-4298.webp"),
    category: "earrings",
    description: "Elegant gold drop earrings",
  },
  {
    id: "15",
    name: "Gold Hoop Earrings",
    price: 3800,
    image: require("@/assets/figma-assets/1586-4299.webp"),
    category: "earrings",
    description: "Classic gold hoop earrings",
  },
  {
    id: "16",
    name: "Gold Chandelier Earrings",
    price: 5200,
    image: require("@/assets/figma-assets/1586-4300.webp"),
    category: "earrings",
    description: "Luxurious chandelier earrings",
  },

  // Exclusive & Limited
  {
    id: "17",
    name: "Exclusive Gold Bracelet",
    price: 15000,
    image: require("@/assets/figma-assets/1586-4301.webp"),
    category: "exclusive",
    description: "Limited edition exclusive bracelet",
  },
  {
    id: "18",
    name: "Limited Edition Necklace",
    price: 18500,
    image: require("@/assets/figma-assets/1586-4302.webp"),
    category: "limited",
    description: "One of a kind limited edition necklace",
  },
];

export const categories: Category[] = [
  {
    id: "necklaces",
    title: "Necklaces",
    description: "Timeless gold necklaces crafted to elevate your everyday elegance.",
    image: require("@/assets/figma-assets/1588-3918.webp"),
  },
  {
    id: "rings",
    title: "Rings",
    description: "Exquisite gold rings for every occasion and celebration.",
    image: require("@/assets/figma-assets/1588-3919.webp"),
  },
  {
    id: "bracelets",
    title: "Bracelets",
    description: "Stunning gold bracelets that complement your style.",
    image: require("@/assets/figma-assets/1588-3920.webp"),
  },
  {
    id: "earrings",
    title: "Earrings",
    description: "Elegant gold earrings for a touch of sophistication.",
    image: require("@/assets/figma-assets/1588-3921.webp"),
  },
];
