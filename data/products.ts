export interface Product {
  id: string;
  name: string;
  nameAr?: string;
  price: number;
  image: any;
  category: string;
  description?: string;
  descriptionAr?: string;
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
    nameAr: "سوار ذهب 21 قيراط",
    price: 4308.57,
    image: require("@/assets/rknthmin-images/bracelets.webp"),
    category: "bracelets",
    description: "Elegant 21K gold bracelet with intricate design",
    descriptionAr: "سوار ذهب 21 قيراط بتصميم أنيق ومتقن الصنع",
  },
  {
    id: "2",
    name: "Gold Investment Bracelet",
    nameAr: "سوار ذهب استثماري",
    price: 606429.9,
    image: require("@/assets/rknthmin-images/product-1.webp"),
    category: "bracelets",
    description: "Premium investment-grade gold bracelet",
    descriptionAr: "سوار ذهب عالي الجودة مناسب للاستثمار",
  },
  {
    id: "3",
    name: "Classic Gold Bangle",
    nameAr: "إسورة ذهب كلاسيكية",
    price: 3500,
    image: require("@/assets/rknthmin-images/bracelets.webp"),
    category: "bracelets",
    description: "Timeless classic gold bangle",
    descriptionAr: "إسورة ذهب كلاسيكية خالدة لكل المناسبات",
  },
  {
    id: "4",
    name: "Modern Gold Bracelet",
    nameAr: "سوار ذهب عصري",
    price: 4200,
    image: require("@/assets/rknthmin-images/product-2.webp"),
    category: "bracelets",
    description: "Contemporary design gold bracelet",
    descriptionAr: "سوار ذهب بتصميم معاصر وعصري",
  },

  // Necklaces
  {
    id: "5",
    name: "Gold Chain Necklace",
    nameAr: "قلادة ذهب بسلسلة",
    price: 5200,
    image: require("@/assets/rknthmin-images/necklaces.webp"),
    category: "necklaces",
    description: "Elegant gold chain necklace",
    descriptionAr: "قلادة ذهب أنيقة بسلسلة رفيعة",
  },
  {
    id: "6",
    name: "Pendant Gold Necklace",
    nameAr: "قلادة ذهب بمعلقة",
    price: 6800,
    image: require("@/assets/rknthmin-images/pendants.webp"),
    category: "pendants",
    description: "Beautiful pendant gold necklace",
    descriptionAr: "قلادة ذهب جميلة مع معلقة مزخرفة",
  },
  {
    id: "7",
    name: "Statement Gold Necklace",
    nameAr: "قلادة ذهب جريئة",
    price: 7500,
    image: require("@/assets/rknthmin-images/necklaces.webp"),
    category: "necklaces",
    description: "Bold statement gold necklace",
    descriptionAr: "قلادة ذهب جريئة ولافتة للنظر",
  },
  {
    id: "8",
    name: "Delicate Gold Necklace",
    nameAr: "قلادة ذهب رقيقة",
    price: 4500,
    image: require("@/assets/rknthmin-images/product-3.webp"),
    category: "necklaces",
    description: "Delicate and refined gold necklace",
    descriptionAr: "قلادة ذهب رقيقة وراقية بخطوط ناعمة",
  },

  // Rings
  {
    id: "9",
    name: "Gold Wedding Ring",
    nameAr: "خاتم ذهب للزفاف",
    price: 8900,
    image: require("@/assets/rknthmin-images/rings.webp"),
    category: "rings",
    description: "Elegant wedding gold ring",
    descriptionAr: "خاتم ذهب أنيق مخصص لمناسبات الزفاف",
  },
  {
    id: "10",
    name: "Diamond Gold Ring",
    nameAr: "خاتم ذهب بالماس",
    price: 12500,
    image: require("@/assets/rknthmin-images/product-1.webp"),
    category: "rings",
    description: "Gold ring with diamond stone",
    descriptionAr: "خاتم ذهب مرصع بحجر الماس الفاخر",
  },
  {
    id: "11",
    name: "Classic Gold Ring",
    nameAr: "خاتم ذهب كلاسيكي",
    price: 5800,
    image: require("@/assets/rknthmin-images/rings.webp"),
    category: "rings",
    description: "Classic design gold ring",
    descriptionAr: "خاتم ذهب بتصميم كلاسيكي راقٍ",
  },
  {
    id: "12",
    name: "Modern Gold Ring",
    nameAr: "خاتم ذهب عصري",
    price: 6500,
    image: require("@/assets/rknthmin-images/product-2.webp"),
    category: "rings",
    description: "Contemporary gold ring",
    descriptionAr: "خاتم ذهب بتصميم معاصر وأنيق",
  },

  // Earrings
  {
    id: "13",
    name: "Gold Stud Earrings",
    nameAr: "أقراط ذهب صغيرة",
    price: 3200,
    image: require("@/assets/rknthmin-images/earrings.webp"),
    category: "earrings",
    description: "Simple gold stud earrings",
    descriptionAr: "أقراط ذهب صغيرة بسيطة وأنيقة",
  },
  {
    id: "14",
    name: "Gold Drop Earrings",
    nameAr: "أقراط ذهب متدلية",
    price: 4100,
    image: require("@/assets/rknthmin-images/product-3.webp"),
    category: "earrings",
    description: "Elegant gold drop earrings",
    descriptionAr: "أقراط ذهب متدلية بتصميم أنيق",
  },
  {
    id: "15",
    name: "Gold Hoop Earrings",
    nameAr: "أقراط ذهب دائرية",
    price: 3800,
    image: require("@/assets/rknthmin-images/earrings.webp"),
    category: "earrings",
    description: "Classic gold hoop earrings",
    descriptionAr: "أقراط ذهب دائرية كلاسيكية",
  },
  {
    id: "16",
    name: "Gold Chandelier Earrings",
    nameAr: "أقراط ذهب ثريا",
    price: 5200,
    image: require("@/assets/rknthmin-images/product-1.webp"),
    category: "earrings",
    description: "Luxurious chandelier earrings",
    descriptionAr: "أقراط ذهب فاخرة على شكل ثريا مضيئة",
  },

  // Chains
  {
    id: "17",
    name: "Gold Chain 21K",
    nameAr: "سلسلة ذهب 21 قيراط",
    price: 5500,
    image: require("@/assets/rknthmin-images/chains.webp"),
    category: "chains",
    description: "Premium 21K gold chain",
    descriptionAr: "سلسلة ذهب فاخرة من عيار 21 قيراط",
  },
  {
    id: "18",
    name: "Classic Gold Chain",
    nameAr: "سلسلة ذهب كلاسيكية",
    price: 4200,
    image: require("@/assets/rknthmin-images/chains.webp"),
    category: "chains",
    description: "Timeless classic gold chain",
    descriptionAr: "سلسلة ذهب كلاسيكية خالدة الأناقة",
  },
  {
    id: "19",
    name: "Modern Gold Chain",
    nameAr: "سلسلة ذهب عصرية",
    price: 4800,
    image: require("@/assets/rknthmin-images/product-2.webp"),
    category: "chains",
    description: "Contemporary gold chain design",
    descriptionAr: "سلسلة ذهب بتصميم عصري ومتميز",
  },

  // Anklets
  {
    id: "20",
    name: "Gold Anklet 21K",
    nameAr: "خلخال ذهب 21 قيراط",
    price: 2800,
    image: require("@/assets/rknthmin-images/anklets.webp"),
    category: "anklets",
    description: "Elegant 21K gold anklet",
    descriptionAr: "خلخال ذهب أنيق من عيار 21 قيراط",
  },
  {
    id: "21",
    name: "Traditional Anklet",
    nameAr: "خلخال تقليدي",
    price: 3200,
    image: require("@/assets/rknthmin-images/anklets.webp"),
    category: "anklets",
    description: "Traditional gold anklet design",
    descriptionAr: "خلخال ذهب بتصميم تقليدي أصيل",
  },

  // Sets
  {
    id: "22",
    name: "Gold Jewelry Set",
    nameAr: "طقم مجوهرات ذهب",
    price: 18500,
    image: require("@/assets/rknthmin-images/sets.webp"),
    category: "sets",
    description: "Complete gold jewelry set",
    descriptionAr: "طقم مجوهرات ذهب متكامل لكل المناسبات",
  },
  {
    id: "23",
    name: "Bridal Jewelry Set",
    nameAr: "طقم مجوهرات عروس",
    price: 22000,
    image: require("@/assets/rknthmin-images/product-3.webp"),
    category: "sets",
    description: "Elegant bridal jewelry set",
    descriptionAr: "طقم مجوهرات عروس فاخر وأنيق",
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
