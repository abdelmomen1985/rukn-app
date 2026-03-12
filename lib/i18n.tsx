import AsyncStorage from "@react-native-async-storage/async-storage";
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { I18nManager } from "react-native";

export type Lang = "en" | "ar";

const translations = {
  en: {
    // Header
    search: "Search",
    // Hero
    heroTitle: "Experience the Brilliance of Gold",
    heroSubtitle: "Discover timeless elegance in every piece. Crafted with precision, designed for eternity.",
    // Home section
    newArrivals: "New Arrivals",
    viewAll: "View all →",
    noProductsFound: "No products found",
    // Categories
    all: "All",
    necklaces: "Necklaces",
    rings: "Rings",
    bracelets: "Bracelets",
    earrings: "Earrings",
    // Tabs
    tabHome: "Home",
    tabWishlist: "Wishlist",
    tabCart: "Cart",
    tabProfile: "Profile",
    // Wishlist
    myWishlist: "My Wishlist",
    wishlistEmpty: "Your wishlist is empty",
    wishlistEmptySubtitle: "Start adding items you love to your wishlist",
    // Cart
    myCart: "My Cart",
    cartEmpty: "Your cart is empty",
    cartEmptySubtitle: "Add items from the catalog to get started",
    cartTotal: "Total",
    checkout: "Checkout",
    continueShopping: "Continue Shopping",
    removeFromCart: "Remove from cart",
    // Profile
    profile: "Profile",
    guestUser: "Guest User",
    signInSubtitle: "Sign in to access all features",
    signIn: "Sign In",
    accountSettings: "Account Settings",
    accountSettingsSubtitle: "Manage your account details",
    orderHistory: "Order History",
    orderHistorySubtitle: "View your past orders",
    savedAddresses: "Saved Addresses",
    savedAddressesSubtitle: "Manage delivery addresses",
    paymentMethods: "Payment Methods",
    paymentMethodsSubtitle: "Manage payment options",
    notifications: "Notifications",
    notificationsSubtitle: "Manage notification preferences",
    helpSupport: "Help & Support",
    helpSupportSubtitle: "Get help with your orders",
    language: "Language",
    version: "Version 1.0.0",
    copyright: "© 2026 Gold Jewelry. All rights reserved.",
    // Portfolio tab
    tabPortfolio: "Portfolio",
    portfolioTitle: "My Portfolio",
    totalValue: "Total Value",
    gainLoss: "Gain / Loss",
    addAsset: "Add Asset",
    goldPrice: "Gold",
    silverPrice: "Silver",
    perGram: "/ g",
    lastUpdated: "Updated",
    noAssets: "No assets yet",
    noAssetsSubtitle: "Add your first gold or silver piece to track its value",
    // Asset form
    metalType: "Metal Type",
    gold: "Gold",
    silver: "Silver",
    weight: "Weight",
    karat: "Karat",
    purity: "Purity",
    purchasePrice: "Purchase Price (SAR)",
    purchaseDate: "Purchase Date",
    makingCharges: "Making Charges (SAR)",
    vatAmount: "VAT Amount (SAR)",
    saveAsset: "Save Asset",
    editAsset: "Edit Asset",
    deleteAsset: "Delete Asset",
    assetName: "Asset Name",
    category: "Category",
    notes: "Notes (optional)",
    // Placeholders
    assetNamePlaceholder: "e.g. Gold Wedding Ring",
    weightPlaceholder: "0.0",
    datePlaceholder: "YYYY-MM-DD",
    amountPlaceholder: "Enter amount",
    weightInputPlaceholder: "Weight",
    notesPlaceholder: "Optional notes…",
    // Weight units
    grams: "grams",
    tolas: "tolas",
    ounces: "ounces",
    mithqal: "mithqal",
    // Converter
    weightConverter: "Weight Converter",
    goldValueCalculator: "Gold Value Calculator",
    silverValueCalculator: "Silver Value Calculator",
    unit: "Unit",
    loadingPrices: "Loading prices…",
    ofGold: "of gold",
    ofSilver: "of silver",
    // Zakat
    belowNisab: "Portfolio is below Nisab threshold",
    zakatObligatory: "Zakat is obligatory on wealth held for one lunar year (Hawl)",
    nisabCalculation: "Nisab Calculation",
    goldPerGram24K: "24K Gold per gram",
    nisabEquals85g: "Nisab = 85g of 24K Gold",
    zakatDue25: "Zakat Due (2.5%)",
    assetBreakdown: "Asset Breakdown",
    noAssetsInPortfolio: "No assets in portfolio",
    disclaimer: "This is a simplified Zakat estimate based on current spot prices. Consult a qualified Islamic scholar for a complete Zakat assessment including Hawl (one lunar year) requirements.",
    // P&L
    currentValue: "Current Value",
    purchaseCost: "Purchase Cost",
    returnPercent: "Return",
    annualizedReturn: "Annualized",
    totalCost: "Total Cost",
    // Converter
    converter: "Converter",
    convertFrom: "From",
    convertTo: "To",
    value: "Value",
    // Zakat
    zakat: "Zakat",
    nisabAlert: "Your portfolio is above the Nisab threshold",
    zakatDue: "Zakat Due",
    nisabThreshold: "Nisab Threshold",
    zakatableValue: "Zakatable Value",
    // Allocation
    allocation: "Allocation",
    assets: "Assets",
    // Metals
    platinum: "Platinum",
    palladium: "Palladium",
    // Categories
    ring: "Ring",
    bracelet: "Bracelet",
    necklace: "Necklace",
    earring: "Earring",
    bar: "Bar",
    coin: "Coin",
    // Common
    cancel: "Cancel",
    deleteConfirm: "Are you sure you want to delete",
    assetNotFound: "Asset not found",
    // Details
    details: "Details",
    loadingPriceData: "Loading price data…",
  },
  ar: {
    // Header
    search: "بحث",
    // Hero
    heroTitle: "اكتشف بريق الذهب الخالص",
    heroSubtitle: "أناقة خالدة في كل قطعة. مصنوعة بدقة، مصممة للأبد.",
    // Home section
    newArrivals: "وصل حديثاً",
    viewAll: "← عرض الكل",
    noProductsFound: "لا توجد منتجات",
    // Categories
    all: "الكل",
    necklaces: "القلائد",
    rings: "الخواتم",
    bracelets: "الأساور",
    earrings: "الأقراط",
    // Tabs
    tabHome: "الرئيسية",
    tabWishlist: "المفضلة",
    tabCart: "السلة",
    tabProfile: "الملف",
    // Wishlist
    myWishlist: "المفضلة الخاصة بي",
    wishlistEmpty: "المفضلة فارغة",
    wishlistEmptySubtitle: "ابدأ بإضافة العناصر التي تحبها إلى المفضلة",
    // Cart
    myCart: "السلة الخاصة بي",
    cartEmpty: "السلة فارغة",
    cartEmptySubtitle: "أضف عناصر من الكتالوج للبدء",
    cartTotal: "الإجمالي",
    checkout: "إتمام الشراء",
    continueShopping: "متابعة التسوق",
    removeFromCart: "إزالة من السلة",
    // Profile
    profile: "الملف الشخصي",
    guestUser: "زائر",
    signInSubtitle: "سجل دخولك للوصول إلى جميع المميزات",
    signIn: "تسجيل الدخول",
    accountSettings: "إعدادات الحساب",
    accountSettingsSubtitle: "إدارة تفاصيل حسابك",
    orderHistory: "سجل الطلبات",
    orderHistorySubtitle: "عرض طلباتك السابقة",
    savedAddresses: "العناوين المحفوظة",
    savedAddressesSubtitle: "إدارة عناوين التوصيل",
    paymentMethods: "طرق الدفع",
    paymentMethodsSubtitle: "إدارة خيارات الدفع",
    notifications: "الإشعارات",
    notificationsSubtitle: "إدارة تفضيلات الإشعارات",
    helpSupport: "المساعدة والدعم",
    helpSupportSubtitle: "احصل على مساعدة مع طلباتك",
    language: "اللغة",
    version: "الإصدار 1.0.0",
    copyright: "© 2026 مجوهرات الذهب. جميع الحقوق محفوظة.",
    // Portfolio tab
    tabPortfolio: "المحفظة",
    portfolioTitle: "محفظتي",
    totalValue: "إجمالي القيمة",
    gainLoss: "الربح / الخسارة",
    addAsset: "إضافة أصل",
    goldPrice: "الذهب",
    silverPrice: "الفضة",
    perGram: "/ غ",
    lastUpdated: "آخر تحديث",
    noAssets: "لا توجد أصول بعد",
    noAssetsSubtitle: "أضف أول قطعة ذهب أو فضة لتتبع قيمتها",
    // Asset form
    metalType: "نوع المعدن",
    gold: "ذهب",
    silver: "فضة",
    weight: "الوزن",
    karat: "العيار",
    purity: "النقاء",
    purchasePrice: "سعر الشراء (ر.س)",
    purchaseDate: "تاريخ الشراء",
    makingCharges: "أجرة الصنعة (ر.س)",
    vatAmount: "قيمة الضريبة (ر.س)",
    saveAsset: "حفظ الأصل",
    editAsset: "تعديل الأصل",
    deleteAsset: "حذف الأصل",
    assetName: "اسم الأصل",
    category: "الفئة",
    notes: "ملاحظات (اختياري)",
    // Placeholders
    assetNamePlaceholder: "مثال: خاتم ذهبي للزفاف",
    weightPlaceholder: "0.0",
    datePlaceholder: "YYYY-MM-DD",
    amountPlaceholder: "أدخل المبلغ",
    weightInputPlaceholder: "الوزن",
    notesPlaceholder: "ملاحظات اختيارية…",
    // Weight units
    grams: "غرام",
    tolas: "تولة",
    ounces: "أونصة",
    mithqal: "مثقال",
    // Converter
    weightConverter: "محول الوزن",
    goldValueCalculator: "حاسب قيمة الذهب",
    silverValueCalculator: "حاسب قيمة الفضة",
    unit: "الوحدة",
    loadingPrices: "جارٍ تحميل الأسعار…",
    ofGold: "من الذهب",
    ofSilver: "من الفضة",
    // Zakat
    belowNisab: "المحفظة أقل من حد النصاب",
    zakatObligatory: "الزكاة واجبة على الثروة المحفوظة لسنة قمرية (حول)",
    nisabCalculation: "حساب النصاب",
    goldPerGram24K: "ذهب 24ق لكل غرام",
    nisabEquals85g: "النصاب = 85غ من الذهب 24ق",
    zakatDue25: "الزكاة المستحقة (2.5%)",
    assetBreakdown: "تفصيل الأصول",
    noAssetsInPortfolio: "لا توجد أصول في المحفظة",
    disclaimer: "هذا تقدير مبسط للزكاة بناء على أسعار السوق الحالية. راجع من عالم إسلامي مؤهل لإكمال تقييم الزكاة بما في ذلك شروط الحول (سنة قمرية).",
    // P&L
    currentValue: "القيمة الحالية",
    purchaseCost: "تكلفة الشراء",
    returnPercent: "العائد",
    annualizedReturn: "العائد السنوي",
    totalCost: "التكلفة الإجمالية",
    // Converter
    converter: "المحول",
    convertFrom: "من",
    convertTo: "إلى",
    value: "القيمة",
    // Zakat
    zakat: "الزكاة",
    nisabAlert: "محفظتك تتجاوز حد النصاب",
    zakatDue: "الزكاة المستحقة",
    nisabThreshold: "حد النصاب",
    zakatableValue: "القيمة الخاضعة للزكاة",
    // Allocation
    allocation: "التوزيع",
    assets: "الأصول",
    // Metals
    platinum: "بلاتين",
    palladium: "بلاديوم",
    // Categories
    ring: "خاتم",
    bracelet: "سوار",
    necklace: "قلادة",
    earring: "قرط",
    bar: "سبائك",
    coin: "عملة",
    // Common
    cancel: "Cancel",
    deleteConfirm: "Are you sure you want to delete",
    assetNotFound: "Asset not found",
    // Details
    details: "Details",
    loadingPriceData: "Loading price data…",
  },
} as const;

export type TranslationKey = keyof typeof translations.en;

type I18nContextValue = {
  lang: Lang;
  isRTL: boolean;
  setLang: (lang: Lang) => void;
  t: (key: TranslationKey) => string;
};

const I18nContext = createContext<I18nContextValue | null>(null);

const STORAGE_KEY = "app_language";

const FONT_STYLE_ID = "__app-font-override";

function applyLang(lang: Lang) {
  const isAr = lang === "ar";

  // Native: set a global variable read by the Text patch in patch-text-font.ts
  (globalThis as any).__currentAppFont = isAr ? "Cairo" : "Inter";

  // Web: inject a <style> tag overriding React Native Web's default font-family
  if (typeof document === "undefined") return;

  document.documentElement.lang = lang;
  document.documentElement.dir = isAr ? "rtl" : "ltr";

  const font = isAr ? "'Cairo', sans-serif" : "'Inter', sans-serif";
  let styleEl = document.getElementById(FONT_STYLE_ID) as HTMLStyleElement | null;
  if (!styleEl) {
    styleEl = document.createElement("style");
    styleEl.id = FONT_STYLE_ID;
    document.head.appendChild(styleEl);
  }
  styleEl.textContent = `* { font-family: ${font} !important; }`;
}

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [lang, setLangState] = useState<Lang>("en");

  useEffect(() => {
    applyLang("en"); // apply default immediately
    AsyncStorage.getItem(STORAGE_KEY).then((stored) => {
      if (stored === "en" || stored === "ar") {
        setLangState(stored);
        I18nManager.forceRTL(stored === "ar");
        applyLang(stored);
      }
    });
  }, []);

  const setLang = useCallback((newLang: Lang) => {
    setLangState(newLang);
    AsyncStorage.setItem(STORAGE_KEY, newLang);
    I18nManager.forceRTL(newLang === "ar");
    applyLang(newLang);
  }, []);

  const isRTL = lang === "ar";

  const t = useCallback(
    (key: TranslationKey): string => translations[lang][key],
    [lang],
  );

  const value = useMemo(() => ({ lang, isRTL, setLang, t }), [lang, isRTL, setLang, t]);

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

export function useI18n(): I18nContextValue {
  const ctx = useContext(I18nContext);
  if (!ctx) throw new Error("useI18n must be used within I18nProvider");
  return ctx;
}
