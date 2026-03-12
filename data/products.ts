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
    image: require("@/assets/rknthmin-images/bracelets.webp"),
    category: "bracelets",
    description: "Elegant 21K gold bracelet with intricate design",
  },
  {
    id: "2",
    name: "Gold Investment Bracelet",
    price: 606429.9,
    image: require("@/assets/rknthmin-images/product-1.webp"),
    category: "bracelets",
    description: "Premium investment-grade gold bracelet",
  },
  {
    id: "3",
    name: "Classic Gold Bangle",
    price: 3500,
    image: require("@/assets/rknthmin-images/bracelets.webp"),
    category: "bracelets",
    description: "Timeless classic gold bangle",
  },
  {
    id: "4",
    name: "Modern Gold Bracelet",
    price: 4200,
    image: require("@/assets/rknthmin-images/product-2.webp"),
    category: "bracelets",
    description: "Contemporary design gold bracelet",
  },

  // Necklaces
  {
    id: "5",
    name: "Gold Chain Necklace",
    price: 5200,
    image: require("@/assets/rknthmin-images/necklaces.webp"),
    category: "necklaces",
    description: "Elegant gold chain necklace",
  },
  {
    id: "6",
    name: "Pendant Gold Necklace",
    price: 6800,
    image: require("@/assets/rknthmin-images/pendants.webp"),
    category: "pendants",
    description: "Beautiful pendant gold necklace",
  },
  {
    id: "7",
    name: "Statement Gold Necklace",
    price: 7500,
    image: require("@/assets/rknthmin-images/necklaces.webp"),
    category: "necklaces",
    description: "Bold statement gold necklace",
  },
  {
    id: "8",
    name: "Delicate Gold Necklace",
    price: 4500,
    image: require("@/assets/rknthmin-images/product-3.webp"),
    category: "necklaces",
    description: "Delicate and refined gold necklace",
  },

  // Rings
  {
    id: "9",
    name: "Gold Wedding Ring",
    price: 8900,
    image: require("@/assets/rknthmin-images/rings.webp"),
    category: "rings",
    description: "Elegant wedding gold ring",
  },
  {
    id: "10",
    name: "Diamond Gold Ring",
    price: 12500,
    image: require("@/assets/rknthmin-images/product-1.webp"),
    category: "rings",
    description: "Gold ring with diamond stone",
  },
  {
    id: "11",
    name: "Classic Gold Ring",
    price: 5800,
    image: require("@/assets/rknthmin-images/rings.webp"),
    category: "rings",
    description: "Classic design gold ring",
  },
  {
    id: "12",
    name: "Modern Gold Ring",
    price: 6500,
    image: require("@/assets/rknthmin-images/product-2.webp"),
    category: "rings",
    description: "Contemporary gold ring",
  },

  // Earrings
  {
    id: "13",
    name: "Gold Stud Earrings",
    price: 3200,
    image: require("@/assets/rknthmin-images/earrings.webp"),
    category: "earrings",
    description: "Simple gold stud earrings",
  },
  {
    id: "14",
    name: "Gold Drop Earrings",
    price: 4100,
    image: require("@/assets/rknthmin-images/product-3.webp"),
    category: "earrings",
    description: "Elegant gold drop earrings",
  },
  {
    id: "15",
    name: "Gold Hoop Earrings",
    price: 3800,
    image: require("@/assets/rknthmin-images/earrings.webp"),
    category: "earrings",
    description: "Classic gold hoop earrings",
  },
  {
    id: "16",
    name: "Gold Chandelier Earrings",
    price: 5200,
    image: require("@/assets/rknthmin-images/product-1.webp"),
    category: "earrings",
    description: "Luxurious chandelier earrings",
  },

  // Chains
  {
    id: "17",
    name: "Gold Chain 21K",
    price: 5500,
    image: require("@/assets/rknthmin-images/chains.webp"),
    category: "chains",
    description: "Premium 21K gold chain",
  },
  {
    id: "18",
    name: "Classic Gold Chain",
    price: 4200,
    image: require("@/assets/rknthmin-images/chains.webp"),
    category: "chains",
    description: "Timeless classic gold chain",
  },
  {
    id: "19",
    name: "Modern Gold Chain",
    price: 4800,
    image: require("@/assets/rknthmin-images/product-2.webp"),
    category: "chains",
    description: "Contemporary gold chain design",
  },

  // Anklets
  {
    id: "20",
    name: "Gold Anklet 21K",
    price: 2800,
    image: require("@/assets/rknthmin-images/anklets.webp"),
    category: "anklets",
    description: "Elegant 21K gold anklet",
  },
  {
    id: "21",
    name: "Traditional Anklet",
    price: 3200,
    image: require("@/assets/rknthmin-images/anklets.webp"),
    category: "anklets",
    description: "Traditional gold anklet design",
  },

  // Sets
  {
    id: "22",
    name: "Gold Jewelry Set",
    price: 18500,
    image: require("@/assets/rknthmin-images/sets.webp"),
    category: "sets",
    description: "Complete gold jewelry set",
  },
  {
    id: "23",
    name: "Bridal Jewelry Set",
    price: 22000,
    image: require("@/assets/rknthmin-images/product-3.webp"),
    category: "sets",
    description: "Elegant bridal jewelry set",
  },
];

export const categories: Category[] = [
  {
    id: "necklaces",
    title: "Necklaces",
    description: "Timeless gold necklaces crafted to elevate your everyday elegance.",
    image: require("@/assets/rknthmin-images/necklaces.webp"),
  },
  {
    id: "rings",
    title: "Rings",
    description: "Exquisite gold rings for every occasion and celebration.",
    image: require("@/assets/rknthmin-images/rings.webp"),
  },
  {
    id: "bracelets",
    title: "Bracelets",
    description: "Stunning gold bracelets that complement your style.",
    image: require("@/assets/rknthmin-images/bracelets.webp"),
  },
  {
    id: "earrings",
    title: "Earrings",
    description: "Elegant gold earrings for a touch of sophistication.",
    image: require("@/assets/rknthmin-images/earrings.webp"),
  },
  {
    id: "chains",
    title: "Chains",
    description: "Premium gold chains in various lengths and designs.",
    image: require("@/assets/rknthmin-images/chains.webp"),
  },
  {
    id: "anklets",
    title: "Anklets",
    description: "Beautiful gold anklets for traditional elegance.",
    image: require("@/assets/rknthmin-images/anklets.webp"),
  },
  {
    id: "pendants",
    title: "Pendants",
    description: "Exquisite gold pendants to enhance any necklace.",
    image: require("@/assets/rknthmin-images/pendants.webp"),
  },
  {
    id: "sets",
    title: "Jewelry Sets",
    description: "Complete matching jewelry sets for special occasions.",
    image: require("@/assets/rknthmin-images/sets.webp"),
  },
];
