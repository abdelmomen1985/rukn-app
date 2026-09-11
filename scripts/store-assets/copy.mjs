/**
 * Strings for the store assets.
 *
 * `ui` is copied verbatim from `lib/i18n.tsx` so a screenshot can never show a
 * label the app does not use. `caption` is marketing copy written for the store
 * page: every line describes a capability that exists in `app/`, and none makes
 * a superlative, ranking or price claim (Play metadata policy; PUBLISHING.md §7).
 */

export const LOCALES = ["en-US", "ar"];
export const isRTL = (locale) => locale === "ar";

export const ui = {
  "en-US": {
    search: "Search",
    tabHome: "Home", tabWishlist: "Wishlist", tabCart: "Cart",
    tabProfile: "Profile", tabInvest: "Invest",
    all: "All",
    investTitle: "My Investments",
    totalValue: "Total Value", gainLoss: "Gain / Loss", assets: "Assets",
    lastUpdated: "Updated", perGram: "/ g", grams: "grams",
    gold: "Gold", silver: "Silver", platinum: "Platinum", palladium: "Palladium",
    allocation: "Allocation", currentValue: "Current Value", annualizedReturn: "Annualized",
    addAsset: "Add Asset", converter: "Converter", zakat: "Zakat",
    nisabAlert: "Your portfolio is above the Nisab threshold",
    zakatDue: "Zakat Due", nisabThreshold: "Nisab Threshold",
    zakatableValue: "Zakatable Value", nisabCalculation: "Nisab Calculation",
    zakatObligatory: "Zakat is obligatory on wealth held for one lunar year (Hawl)",
    weightConverter: "Weight Converter", goldValueCalculator: "Gold Value Calculator",
    karat: "Karat", unit: "Unit",
    tripsTitle: "Shopping Trips", tripsSubtitle: "Compare stores side by side",
    tripsCardLabel: "Jewelry Trips", newTrip: "New Trip",
    tripStops: "Stops", tripBestPrice: "Best price", tripAverage: "Average",
    tripSavings: "You save vs. average", bestStopBadge: "Best so far",
    fairExcellent: "Excellent deal", fairFair: "Fair price", fairHigh: "High price",
    consultationTitle: "Consultation",
    consultationSpecialistGeneric: "Rukn Thamin gold specialist",
    consultationPerSession: "per session",
    consultationPreferredTimes: "Preferred times",
    consultationPreferredTimesHint:
      "Pick one or more times that suit you. We'll confirm the exact slot with you.",
    consultationWhatToExpect: "What to Expect",
    consultationExpect1: "Personalized market analysis tailored to your gold portfolio",
    consultationExpect2: "Expert advice on buying, selling, and diversification strategies",
    consultationExpect3: "Confidential 45-minute one-on-one video session",
    consultationSubmit: "Send request",
    consultationFeeNote: "The 350 SAR session fee is collected only after we confirm a time with you.",
    heroTitle: "Experience the Brilliance of Gold",
    heroSubtitle: "Discover timeless elegance in every piece.",
    addToCart: "Add to Cart",
    sar: "SAR",
    // Screen-specific labels that exist in the app's own screens.
    goldSpot24: "24K gold, spot", weight: "Weight", makingCharges: "Making charges",
    purchasePriceShort: "Purchase price", purchaseCost: "Purchase Cost",
    totalCost: "Total Cost", returnPercent: "Return",
    costBreakdown: "Cost Breakdown", performance: "Performance",
    vat: "VAT (15%)", estimatedValue: "Estimated value",
    since: "Since", categories: ["All", "Necklaces", "Rings", "Bracelets", "Earrings"],
  },
  ar: {
    search: "بحث",
    tabHome: "الرئيسية", tabWishlist: "المفضلة", tabCart: "السلة",
    tabProfile: "الملف", tabInvest: "استثمار",
    all: "الكل",
    investTitle: "استثماراتي",
    totalValue: "إجمالي القيمة", gainLoss: "الربح / الخسارة", assets: "الأصول",
    lastUpdated: "آخر تحديث", perGram: "/ غ", grams: "غرام",
    gold: "ذهب", silver: "فضة", platinum: "بلاتين", palladium: "بلاديوم",
    allocation: "التوزيع", currentValue: "القيمة الحالية", annualizedReturn: "العائد السنوي",
    addAsset: "إضافة أصل", converter: "المحول", zakat: "الزكاة",
    nisabAlert: "محفظتك تتجاوز حد النصاب",
    zakatDue: "الزكاة المستحقة", nisabThreshold: "حد النصاب",
    zakatableValue: "القيمة الخاضعة للزكاة", nisabCalculation: "حساب النصاب",
    zakatObligatory: "الزكاة واجبة على الثروة المحفوظة لسنة قمرية (حول)",
    weightConverter: "محول الوزن", goldValueCalculator: "حاسب قيمة الذهب",
    karat: "العيار", unit: "الوحدة",
    tripsTitle: "جولات التسوق", tripsSubtitle: "قارن بين المحلات في مكان واحد",
    tripsCardLabel: "رحلات المجوهرات", newTrip: "رحلة جديدة",
    tripStops: "المحطات", tripBestPrice: "أفضل سعر", tripAverage: "المتوسط",
    tripSavings: "توفر عن المتوسط", bestStopBadge: "الأفضل حتى الآن",
    fairExcellent: "صفقة ممتازة", fairFair: "سعر عادل", fairHigh: "سعر مرتفع",
    consultationTitle: "استشارة",
    consultationSpecialistGeneric: "أخصائي الذهب في ركن ثمين",
    consultationPerSession: "لكل جلسة",
    consultationPreferredTimes: "الأوقات المناسبة لك",
    consultationPreferredTimesHint:
      "اختر وقتاً واحداً أو أكثر يناسبك، وسنتفق معك على الموعد النهائي.",
    consultationWhatToExpect: "ماذا تتوقع",
    consultationExpect1: "تحليل سوقي مخصص لمحفظتك من الذهب",
    consultationExpect2: "مشورة خبراء حول استراتيجيات الشراء والبيع والتنويع",
    consultationExpect3: "جلسة فيديو خاصة لمدة 45 دقيقة",
    consultationSubmit: "إرسال الطلب",
    consultationFeeNote: "رسوم الجلسة 350 ريال تُحصَّل فقط بعد الاتفاق معك على الموعد.",
    heroTitle: "اكتشف بريق الذهب الخالص",
    heroSubtitle: "أناقة خالدة في كل قطعة.",
    addToCart: "أضف إلى السلة",
    sar: "ر.س",
    goldSpot24: "ذهب عيار 24 · السعر الفوري", weight: "الوزن", makingCharges: "أجرة الصياغة",
    purchasePriceShort: "سعر الشراء", purchaseCost: "تكلفة الشراء",
    totalCost: "التكلفة الإجمالية", returnPercent: "العائد",
    costBreakdown: "تفصيل التكلفة", performance: "الأداء",
    vat: "ضريبة القيمة المضافة (15%)", estimatedValue: "القيمة التقديرية",
    since: "منذ", categories: ["الكل", "قلائد", "خواتم", "أساور", "أقراط"],
  },
};

/** Headline + supporting line printed in the caption band of each screenshot. */
export const captions = {
  "en-US": {
    "01-live-prices":  ["Live gold rates, in Saudi Riyals", "Gold, silver, platinum and palladium, priced per gram"],
    "02-portfolio":    ["See what your gold is worth today", "Current value, gain or loss, and allocation by metal"],
    "03-trips":        ["Compare every jeweller's quote", "Log each store's price and check it against the market"],
    "04-zakat":        ["Zakat and nisab, calculated for you", "Automatic 85 g nisab check and a per-asset breakdown"],
    "05-calculator":   ["Price a piece before you pay", "Weight, karat, making charges and VAT in one number"],
    "06-shop":         ["Shop certified gold jewelry", "Necklaces, rings, bracelets and earrings with live pricing"],
    "07-asset-detail": ["Follow every gram you own", "Purchase price versus today's value, and annualized return"],
    "08-consultation": ["Talk to a gold specialist", "Request a private session and we'll confirm the time"],
  },
  ar: {
    "01-live-prices":  ["أسعار الذهب بالريال لحظياً", "الذهب والفضة والبلاتين والبلاديوم بسعر الجرام"],
    "02-portfolio":    ["اعرف قيمة ذهبك اليوم", "القيمة الحالية والربح والخسارة وتوزيع المعادن"],
    "03-trips":        ["قارن عروض المحلات قبل الشراء", "سجّل سعر كل محل وقارنه بالسعر المرجعي للسوق"],
    "04-zakat":        ["حاسبة الزكاة وفحص النصاب", "فحص تلقائي لنصاب 85 جراماً مع تفصيل لكل أصل"],
    "05-calculator":   ["احسب سعر القطعة قبل الدفع", "الوزن والعيار وأجرة الصياغة والضريبة في رقم واحد"],
    "06-shop":         ["تسوّق مجوهرات ذهب معتمدة", "قلائد وخواتم وأساور وأقراط بأسعار محدّثة"],
    "07-asset-detail": ["تابع كل جرام تملكه", "سعر الشراء مقابل قيمة اليوم والعائد السنوي"],
    "08-consultation": ["تحدّث مع أخصائي ذهب", "اطلب جلسة خاصة وسنتفق معك على الموعد"],
  },
};

/** Feature-graphic copy (1024×500). One line, no claims. */
export const feature = {
  "en-US": {
    tagline: "Gold prices, portfolio and zakat",
    sub: "Live SAR rates · Shopping trips · Certified jewelry",
  },
  ar: {
    tagline: "أسعار الذهب والمحفظة والزكاة",
    sub: "أسعار لحظية بالريال · جولات التسوق · مجوهرات معتمدة",
  },
};

export const BRAND = { en: "Rukn Thamin", ar: "ركن ثمين" };
