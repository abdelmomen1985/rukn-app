/**
 * The one dataset every screenshot draws from.
 *
 * Values are plausible holdings priced off a single spot snapshot, and each
 * screen derives its numbers here rather than hard-coding them — so the
 * portfolio total on shot 2, the zakat base on shot 4 and the asset detail on
 * shot 7 can never disagree with each other. `docs/PUBLISHING.md` §7 requires
 * realistic data in store screenshots and forbids seeded demo data in the app,
 * which is exactly what this file is for.
 */

/** Spot prices, SAR per gram of pure metal. */
export const spot = { XAU: 307.45, XAG: 4.12, XPT: 112.3, XPD: 98.4 };

/** Metal card styling, copied from `data/portfolio.ts`. */
export const metals = {
  XAU: { key: "gold",      emoji: "🥇", bg: "#FFF9E6", border: "#F5D766", text: "#5A460A" },
  XAG: { key: "silver",    emoji: "🥈", bg: "#F5F5F5", border: "#C0C0C0", text: "#374151" },
  XPT: { key: "platinum",  emoji: "⬜", bg: "#EFF3F7", border: "#B0C4D8", text: "#2C3E50" },
  XPD: { key: "palladium", emoji: "🔘", bg: "#F5F0EB", border: "#C4B5A7", text: "#4A3728" },
};

/** Karat → purity factor, matching `lib/portfolio-utils.ts`. */
export const karat = { 24: 1, 22: 22 / 24, 21: 21 / 24, 18: 18 / 24 };

export const goldPerGram = (k) => spot.XAU * karat[k];

/** Today, as the screenshots are dated. Fixed so re-runs are reproducible. */
export const AS_OF = new Date("2026-09-06T00:00:00Z");

const asset = (o) => {
  const perGram = o.metal === "XAU" ? goldPerGram(o.karat) : spot[o.metal] * (o.purity ?? 1);
  const currentValue = perGram * o.grams;
  // VAT is 15% of goods + workmanship, the way `add-asset` computes it.
  const vat = (o.purchasePrice + o.making) * 0.15;
  const cost = o.purchasePrice + o.making + vat;
  const years = (AS_OF - new Date(o.boughtAt)) / (365.25 * 24 * 3600 * 1000);
  const gain = currentValue - cost;
  return {
    ...o, perGram, currentValue, vat, cost, gain,
    gainPercent: (gain / cost) * 100,
    years,
    annualized: ((currentValue / cost) ** (1 / years) - 1) * 100,
  };
};

export const assets = [
  asset({ id: "bar-61", key: "goldBar", metal: "XAU", karat: 24, grams: 61,
          purchasePrice: 14_305, making: 0, boughtAt: "2024-03-11" }),
  asset({ id: "brc-32", key: "bracelet", metal: "XAU", karat: 24, grams: 32,
          purchasePrice: 7_387, making: 320, boughtAt: "2024-08-02" }),
  asset({ id: "bng-24", key: "bangles", metal: "XAU", karat: 22, grams: 24.6,
          purchasePrice: 5_173, making: 410, boughtAt: "2025-01-19" }),
  asset({ id: "nck-19", key: "necklace", metal: "XAU", karat: 21, grams: 19.3,
          purchasePrice: 4_010, making: 290, boughtAt: "2025-05-04" }),
  asset({ id: "plt-08", key: "platinumRing", metal: "XPT", grams: 8.5,
          purchasePrice: 763, making: 120, boughtAt: "2025-02-27" }),
  asset({ id: "slv-120", key: "silverCoins", metal: "XAG", purity: 0.999, grams: 120,
          purchasePrice: 394, making: 0, boughtAt: "2025-06-15" }),
];

export const assetNames = {
  "en-US": {
    goldBar: "Gold bar 24K", bracelet: "24K bracelet", bangles: "22K bangle set",
    necklace: "21K necklace", platinumRing: "Platinum ring", silverCoins: "Silver coins 999",
  },
  ar: {
    goldBar: "سبيكة ذهب عيار 24", bracelet: "إسورة عيار 24", bangles: "طقم غوايش عيار 22",
    necklace: "قلادة عيار 21", platinumRing: "خاتم بلاتين", silverCoins: "عملات فضة 999",
  },
};

const sum = (fn) => assets.reduce((n, a) => n + fn(a), 0);

export const portfolio = {
  totalValue: sum((a) => a.currentValue),
  totalCost: sum((a) => a.cost),
  get gainLoss() { return this.totalValue - this.totalCost; },
  get gainLossPercent() { return (this.gainLoss / this.totalCost) * 100; },
  assetCount: assets.length,
  /** Value per metal, for the allocation chart. */
  byMetal: ["XAU", "XPT", "XAG"].map((m) => ({
    metal: m,
    value: assets.filter((a) => a.metal === m).reduce((n, a) => n + a.currentValue, 0),
  })),
};

/** Zakat, computed the way `calculateZakat()` does: nisab = 85 g of 24K gold. */
export const zakat = {
  nisabGrams: 85,
  nisabValue: 85 * spot.XAU,
  zakatableValue: portfolio.totalValue,
  get isAboveNisab() { return this.zakatableValue >= this.nisabValue; },
  get due() { return this.zakatableValue * 0.025; },
};

/** Shopping trip: one goal, four stores, priced against the live reference. */
export const trip = {
  name: { "en-US": "Wedding set — Riyadh", ar: "طقم زواج — الرياض" },
  city: { "en-US": "Riyadh", ar: "الرياض" },
  goal: { "en-US": "21K necklace, about 30 g", ar: "قلادة عيار 21، نحو 30 غرام" },
  stops: [
    { store: { "en-US": "Al-Romaizan", ar: "الرميزان" },
      area: { "en-US": "Al-Batha", ar: "البطحاء" },
      grams: 29.4, purity: 21, total: 8_240, verdict: "excellent" },
    { store: { "en-US": "Souq Al-Zal", ar: "سوق الزل" },
      area: { "en-US": "Deira", ar: "الديرة" },
      grams: 30.1, purity: 21, total: 8_690, verdict: "fair" },
    { store: { "en-US": "Manal Goldsmiths", ar: "منال للمجوهرات" },
      area: { "en-US": "Olaya", ar: "العليا" },
      grams: 29.8, purity: 21, total: 9_310, verdict: "high" },
    { store: { "en-US": "Taiba Jewellery", ar: "مجوهرات طيبة" },
      area: { "en-US": "Al-Malaz", ar: "الملز" },
      grams: 30.6, purity: 21, total: 8_920, verdict: "fair" },
    { store: { "en-US": "Dar Al-Sagha", ar: "دار الصاغة" },
      area: { "en-US": "Al-Batha", ar: "البطحاء" },
      grams: 29.9, purity: 21, total: 8_410, verdict: "excellent" },
  ],
};
trip.stops.forEach((s) => { s.perGram = s.total / s.grams; });
trip.best = trip.stops.reduce((a, b) => (a.total <= b.total ? a : b));
trip.average = trip.stops.reduce((n, s) => n + s.total, 0) / trip.stops.length;
trip.savings = trip.average - trip.best.total;

/** Gold value calculator inputs shown on shot 5. */
export const calc = { grams: 24, karat: 21, making: 180, get metal() { return this.grams * goldPerGram(this.karat); } };
calc.vat = (calc.metal + calc.making) * 0.15;
calc.total = calc.metal + calc.making + calc.vat;

/** Consultation booking shown on shot 8. */
export const consultation = {
  feeSAR: 350,
  slots: [
    { day: { "en-US": "Sun", ar: "الأحد" }, date: 14, time: "10:00", picked: false },
    { day: { "en-US": "Mon", ar: "الاثنين" }, date: 15, time: "17:30", picked: true },
    { day: { "en-US": "Tue", ar: "الثلاثاء" }, date: 16, time: "12:00", picked: true },
    { day: { "en-US": "Wed", ar: "الأربعاء" }, date: 17, time: "20:00", picked: false },
  ],
};

/** Shop catalogue for shot 6 — real photography that ships in the repo. */
export const products = [
  { img: "necklaces.webp", karat: 21, grams: 8.4,  making: 210, wish: true,
    name: { "en-US": "Filigree pendant 21K", ar: "دلاية مشغولة عيار 21" } },
  { img: "rings.webp", karat: 22, grams: 4.2, making: 160, wish: false,
    name: { "en-US": "Classic band 22K", ar: "خاتم كلاسيكي عيار 22" } },
  { img: "bracelets.webp", karat: 21, grams: 12.6, making: 340, wish: false,
    name: { "en-US": "Woven bracelet 21K", ar: "إسورة مضفرة عيار 21" } },
  { img: "earrings.webp", karat: 18, grams: 5.1, making: 190, wish: true,
    name: { "en-US": "Drop earrings 18K", ar: "أقراط متدلية عيار 18" } },
  { img: "chains.webp", karat: 21, grams: 9.7, making: 260, wish: false,
    name: { "en-US": "Rope chain 21K", ar: "سلسلة حبل عيار 21" } },
  { img: "pendants.webp", karat: 22, grams: 6.3, making: 200, wish: false,
    name: { "en-US": "Heart pendant 22K", ar: "دلاية قلب عيار 22" } },
];
// Shelf price = metal at spot + workmanship, VAT included — the same build-up
// the in-app gold value calculator uses.
products.forEach((p) => { p.price = (p.grams * goldPerGram(p.karat) + p.making) * 1.15; });

/** Number formatting that mirrors `formatSAR()` / `Text` in the app. */
export const nf = (locale, n, digits = 0) =>
  n.toLocaleString(locale === "ar" ? "ar-SA" : "en-SA", {
    minimumFractionDigits: digits, maximumFractionDigits: digits,
  });

export const sar = (locale, n, digits = 0) =>
  locale === "ar" ? `${nf(locale, n, digits)} ر.س` : `SAR ${nf(locale, n, digits)}`;
