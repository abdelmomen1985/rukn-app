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
    // Invest tab
    tabInvest: "Invest",
    investTitle: "My Investments",
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
    // Consultation
    consultationTitle: "Consultation",
    consultationPerSession: "per session",
    consultationSelectDate: "Select Date",
    consultationSelectTime: "Select Time",
    consultationAvailable: "Available",
    consultationBooked: "Booked",
    consultationWhatToExpect: "What to Expect",
    consultationExpect1: "Personalized market analysis tailored to your gold portfolio",
    consultationExpect2: "Expert advice on buying, selling, and diversification strategies",
    consultationExpect3: "Confidential 45-minute one-on-one video session",
    consultationBookAndPay: "Book & Pay",
    consultationBookingSummary: "Booking Summary",
    consultationConsultant: "Consultant",
    consultationDate: "Date",
    consultationTime: "Time",
    consultationFee: "Session Fee",
    consultationPayment: "Payment",
    consultationCardDetails: "Card Details",
    consultationCard: "CREDIT / DEBIT CARD",
    consultationCardHolder: "Cardholder Name",
    consultationCardHolderPlaceholder: "YOUR NAME",
    consultationCardNumber: "Card Number",
    consultationSecurePayment: "Payments are encrypted and processed securely",
    consultationPay: "Pay",
    consultationProcessing: "Processing…",
    consultationPaymentError: "Incomplete Details",
    consultationPaymentErrorMsg: "Please fill in all card details before proceeding.",
    consultationConfirmedTitle: "Booking Confirmed!",
    consultationConfirmedSubtitle: "Your consultation has been booked. You will receive a calendar invite and meeting link by email.",
    consultationConfirmationNote: "A reminder will be sent 1 hour before your session.",
    consultationBackToPortfolio: "Back to Portfolio",
    // Product detail
    addToCart: "Add to Cart",
    addedToCart: "Added to Cart",
    productDetails: "Product Details",
    inCart: "In Cart",
    productNotFound: "Product not found",
    chains: "Chains",
    anklets: "Anklets",
    pendants: "Pendants",
    sets: "Sets",
    // Market trips (Shopping Tour)
    tripsTitle: "Shopping Trips",
    tripsSubtitle: "Compare stores side by side",
    tripsCardLabel: "Jewelry Trips",
    tripsCardHelper: "Track shopping rounds",
    tripsEmptyTitle: "No shopping trips yet",
    tripsEmptySubtitle: "Plan a new trip to compare several stores in one place",
    newTrip: "New Trip",
    startTrip: "Start Trip",
    tripName: "Trip Name",
    tripNamePlaceholder: "Search for a wedding ring",
    tripCity: "Select City",
    citySearchPlaceholder: "Search for a city…",
    tripGoal: "What is your goal?",
    goalCompare: "Compare prices",
    goalBuyToday: "Buy today",
    tripCategory: "Item Category",
    tripPurity: "Karat",
    tripExpectedWeight: "Expected Weight (g)",
    tripStatusActive: "Active",
    tripStatusCompleted: "Completed",
    markTripCompleted: "Mark as completed",
    reopenTrip: "Reopen trip",
    deleteTrip: "Delete trip",
    deleteTripConfirm: "Delete this trip and all its stops?",
    tripStops: "Stops",
    tripBestPrice: "Best price",
    tripAverage: "Average",
    tripSavings: "You save vs. average",
    addStop: "Add Stop",
    addStopTitle: "New Store Visit",
    storeName: "Store name",
    storeNamePlaceholder: "e.g. Al-Romaizan",
    storeLocation: "Location",
    storeLocationPlaceholder: "Mall / neighbourhood (optional)",
    storeQuotedPrice: "Quoted price (SAR)",
    storeWeight: "Weight (g)",
    storeMakingOrigin: "Workmanship origin",
    originLocal: "Local",
    originImported: "Imported",
    vatIncluded: "Price includes 15% VAT",
    saveStop: "Save Stop",
    addToTrip: "Add to Trip",
    fairPriceLabelExcellent: "Excellent deal",
    fairPriceLabelFair: "Fair price",
    fairPriceLabelHigh: "High price",
    excellentDealBanner: "Excellent deal!",
    fairDealBanner: "Fair price",
    highDealBanner: "High price",
    fairPriceHintExcellent: "Workmanship is below the typical band. Strong deal.",
    fairPriceHintFair: "Workmanship is within the typical band. Reasonable.",
    fairPriceHintHigh: "Workmanship is above the typical band. Try to negotiate.",
    breakdownGoldValue: "Gold value",
    breakdownMaking: "Workmanship",
    breakdownVAT: "VAT (15%)",
    breakdownStorePrice: "Store price",
    breakdownMakingPerGram: "Workmanship per gram",
    tryAnother: "Try another",
    close: "Close",
    bestStopBadge: "Best so far",
    noStopsYet: "Add the first store visit to start comparing",
    pickBestStop: "Pick this store",
    pickedStop: "Your pick",
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
    // Invest tab
    tabInvest: "استثمار",
    investTitle: "استثماراتي",
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
    // Consultation
    consultationTitle: "استشارة",
    consultationPerSession: "لكل جلسة",
    consultationSelectDate: "اختر التاريخ",
    consultationSelectTime: "اختر الوقت",
    consultationAvailable: "متاح",
    consultationBooked: "محجوز",
    consultationWhatToExpect: "ماذا تتوقع",
    consultationExpect1: "تحليل سوقي مخصص لمحفظتك من الذهب",
    consultationExpect2: "مشورة خبراء حول استراتيجيات الشراء والبيع والتنويع",
    consultationExpect3: "جلسة فيديو خاصة لمدة 45 دقيقة",
    consultationBookAndPay: "احجز وادفع",
    consultationBookingSummary: "ملخص الحجز",
    consultationConsultant: "المستشار",
    consultationDate: "التاريخ",
    consultationTime: "الوقت",
    consultationFee: "رسوم الجلسة",
    consultationPayment: "الدفع",
    consultationCardDetails: "بيانات البطاقة",
    consultationCard: "بطاقة ائتمان / بطاقة خصم",
    consultationCardHolder: "اسم حامل البطاقة",
    consultationCardHolderPlaceholder: "اسمك",
    consultationCardNumber: "رقم البطاقة",
    consultationSecurePayment: "يتم تشفير المدفوعات ومعالجتها بشكل آمن",
    consultationPay: "ادفع",
    consultationProcessing: "جارٍ المعالجة…",
    consultationPaymentError: "بيانات غير مكتملة",
    consultationPaymentErrorMsg: "يرجى ملء جميع بيانات البطاقة قبل المتابعة.",
    consultationConfirmedTitle: "تم تأكيد الحجز!",
    consultationConfirmedSubtitle: "تم حجز استشارتك. ستتلقى دعوة تقويم ورابط الاجتماع عبر البريد الإلكتروني.",
    consultationConfirmationNote: "سيتم إرسال تذكير قبل ساعة من موعد جلستك.",
    consultationBackToPortfolio: "العودة إلى المحفظة",
    // Product detail
    addToCart: "أضف إلى السلة",
    addedToCart: "تمت الإضافة",
    productDetails: "تفاصيل المنتج",
    inCart: "في السلة",
    productNotFound: "المنتج غير موجود",
    chains: "السلاسل",
    anklets: "الخلاخيل",
    pendants: "المعلقات",
    sets: "الأطقم",
    // Market trips (جولة تسوق)
    tripsTitle: "جولات التسوق",
    tripsSubtitle: "قارن بين المحلات في مكان واحد",
    tripsCardLabel: "رحلات المجوهرات",
    tripsCardHelper: "تتبع جولات التسوق",
    tripsEmptyTitle: "لا توجد جولات بعد",
    tripsEmptySubtitle: "ابدأ جولة جديدة لمقارنة عدة محلات في مكان واحد",
    newTrip: "رحلة جديدة",
    startTrip: "ابدأ الرحلة",
    tripName: "اسم الرحلة",
    tripNamePlaceholder: "البحث عن خاتم الزفاف",
    tripCity: "اختر المدينة",
    citySearchPlaceholder: "ابحث عن مدينة…",
    tripGoal: "ما هدفك؟",
    goalCompare: "مقارنة أسعار",
    goalBuyToday: "شراء اليوم",
    tripCategory: "نوع المجوهرات",
    tripPurity: "عيار الذهب",
    tripExpectedWeight: "الوزن المتوقع (غرام)",
    tripStatusActive: "نشطة",
    tripStatusCompleted: "مكتملة",
    markTripCompleted: "إنهاء الجولة",
    reopenTrip: "إعادة فتح الجولة",
    deleteTrip: "حذف الجولة",
    deleteTripConfirm: "هل تريد حذف هذه الجولة وكل محطاتها؟",
    tripStops: "المحطات",
    tripBestPrice: "أفضل سعر",
    tripAverage: "المتوسط",
    tripSavings: "توفر عن المتوسط",
    addStop: "أضف محطة",
    addStopTitle: "زيارة محل جديد",
    storeName: "اسم المحل",
    storeNamePlaceholder: "مثال: الرميزان",
    storeLocation: "الموقع",
    storeLocationPlaceholder: "السوق / الحي (اختياري)",
    storeQuotedPrice: "سعر المحل (ر.س)",
    storeWeight: "الوزن (غرام)",
    storeMakingOrigin: "منشأ المصنعية",
    originLocal: "محلي",
    originImported: "مستورد",
    vatIncluded: "السعر شامل الضريبة (15%)",
    saveStop: "حفظ المحطة",
    addToTrip: "أضف للرحلة",
    fairPriceLabelExcellent: "صفقة ممتازة",
    fairPriceLabelFair: "سعر عادل",
    fairPriceLabelHigh: "سعر مرتفع",
    excellentDealBanner: "صفقة ممتازة!",
    fairDealBanner: "سعر عادل",
    highDealBanner: "سعر مرتفع!",
    fairPriceHintExcellent: "المصنعية أقل من النطاق المعتاد. صفقة قوية.",
    fairPriceHintFair: "المصنعية ضمن النطاق المعتاد. سعر معقول.",
    fairPriceHintHigh: "المصنعية أعلى من المعتاد. حاول تتفاوض.",
    breakdownGoldValue: "قيمة الذهب",
    breakdownMaking: "المصنعية",
    breakdownVAT: "ضريبة (15%)",
    breakdownStorePrice: "سعر المحل",
    breakdownMakingPerGram: "المصنعية للغرام",
    tryAnother: "جرب آخر",
    close: "إغلاق",
    bestStopBadge: "الأفضل حتى الآن",
    noStopsYet: "أضف زيارة لأول محل لتبدأ المقارنة",
    pickBestStop: "اختر هذا المحل",
    pickedStop: "اختيارك",
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
