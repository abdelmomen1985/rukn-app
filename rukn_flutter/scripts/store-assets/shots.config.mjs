// Store screenshots of the real Flutter app (flutter-store-screenshots skill).
//
//   flutter build web --release
//   node ~/.claude/skills/flutter-store-screenshots/scripts/shoot.mjs \
//     --config scripts/store-assets/shots.config.mjs --devices phone,tablet7,tablet10
//
// Runs as a guest: the portfolio and the shopping trip are seeded into the guest's on-device
// storage (the same plausible holdings the old listing used), everything else is the live store.
// Port 8021 is the origin the backend allows for CORS (see README.md).

const prefs = (obj) =>
  Object.fromEntries(Object.entries(obj).map(([k, v]) => [`flutter.${k}`, JSON.stringify(v)]));

const PRODUCT_ID = 'prod_01M40S397RG7MVW8G77J1M4WCG'; // a bangle with a three-photo gallery
const NOW = '2026-11-01T09:00:00.000Z';

const asset = (o) => {
  const vat = Math.round((o.price + o.making) * 0.15 * 100) / 100;
  return {
    id: o.id, metalType: o.metal, name: o.en, nameAr: o.ar, category: o.category,
    weightValue: o.grams, weightUnit: 'grams', purityLabel: o.purity, purityFactor: o.factor,
    purchasePrice: o.price, purchaseDate: o.date, makingCharges: o.making, vatAmount: vat,
    notes: null, createdAt: NOW, updatedAt: NOW, karat: o.karat ?? null, silverPurity: o.silver ?? null,
  };
};

const assets = [
  asset({ id: 'bar-61', metal: 'gold', en: 'Gold bar 24K', ar: 'سبيكة ذهب عيار 24', category: 'bar', grams: 61, purity: '24K', factor: 1, karat: 24, price: 14305, making: 0, date: '2024-03-11' }),
  asset({ id: 'brc-32', metal: 'gold', en: '24K bracelet', ar: 'إسورة عيار 24', category: 'bracelet', grams: 32, purity: '24K', factor: 1, karat: 24, price: 7387, making: 320, date: '2024-08-02' }),
  asset({ id: 'bng-24', metal: 'gold', en: '22K bangle set', ar: 'طقم غوايش عيار 22', category: 'bracelet', grams: 24.6, purity: '22K', factor: 22 / 24, karat: 22, price: 5173, making: 410, date: '2025-01-19' }),
  asset({ id: 'nck-19', metal: 'gold', en: '21K necklace', ar: 'قلادة عيار 21', category: 'necklace', grams: 19.3, purity: '21K', factor: 21 / 24, karat: 21, price: 4010, making: 290, date: '2025-05-04' }),
  asset({ id: 'plt-08', metal: 'platinum', en: 'Platinum ring', ar: 'خاتم بلاتين', category: 'ring', grams: 8.5, purity: '950', factor: 0.95, price: 763, making: 120, date: '2025-02-27' }),
  asset({ id: 'slv-120', metal: 'silver', en: 'Silver coins 999', ar: 'عملات فضة 999', category: 'coin', grams: 120, purity: '999', factor: 0.999, silver: 999, price: 394, making: 0, date: '2025-06-15' }),
];

const stop = (id, store, location, total, making, verdict) => ({
  id, storeName: store, location, totalPriceSAR: total, weightGrams: 12, purityLabel: '21K', purityFactor: 21 / 24,
  vatIncluded: true, origin: 'local', notes: null, visitedAt: NOW, verdict, makingPerGramSAR: making,
  marketReferencePerGramSAR: null,
});

const trip = (name, city, stops) => [{
  id: 'trip-1', name, city, goal: 'compare', category: 'necklace', purityLabel: '21K',
  purityFactor: 21 / 24, weightGrams: 12, status: 'active', createdAt: NOW, updatedAt: NOW,
  stops: stops.map(([store, location, total, making, verdict], i) => stop(`s${i + 1}`, store, location, total, making, verdict)),
}];

const trips = {
  ar: trip('طقم الزفاف', 'الرياض', [
    ['سوق الذهب بالبطحاء', 'البطحاء', 5390, 35, 'excellent'],
    ['مجوهرات العليا', 'العليا', 5720, 62, 'fair'],
    ['بوتيك برج المملكة', 'العليا', 6210, 103, 'high'],
  ]),
  en: trip('Wedding set', 'Riyadh', [
    ['Al-Batha Gold Souq', 'Al-Batha', 5390, 35, 'excellent'],
    ['Olaya Jewellers', 'Olaya', 5720, 62, 'fair'],
    ['Kingdom Centre boutique', 'Al-Olaya', 6210, 103, 'high'],
  ]),
};

const guest = (lang) =>
  prefs({ 'portfolio:guest': JSON.stringify(assets), market_trips: JSON.stringify(trips[lang]), app_language: lang });

export default {
  appRoot: '../..',
  outDir: '../../../store-assets/play',
  port: 8021,
  urlStrategy: 'hash',
  bootRoute: '/',
  bootWait: 9000,
  navWait: 7000,
  deviceList: ['phone', 'tablet7', 'tablet10'],

  brand: {
    font: '../../../node_modules/@expo-google-fonts/cairo/Cairo_700Bold.ttf',
    mark: '../../assets/icon/android-icon-foreground.png',
    name: 'Rukn Thamin · ركن ثمين',
    colors: { from: '#0b4a3b', via: '#07352B', to: '#041d18', title: '#ffffff', sub: '#F3E3B0', rule: '#D4AF37' },
  },

  locales: {
    ar: { dir: 'rtl', localStorage: guest('ar') },
    'en-US': { dir: 'ltr', localStorage: guest('en') },
  },

  shots: () => [
    {
      name: '01-shop', route: '/', wait: 9000,
      caption: {
        ar: { title: 'تسوّق مجوهرات الذهب', sub: 'تشكيلات مختارة وعروض خاصة بأسعار محدّثة لحظياً' },
        'en-US': { title: 'Shop gold jewellery', sub: 'Curated collections and offers, priced live' },
      },
    },
    {
      name: '02-product', route: `/product/${PRODUCT_ID}`, wait: 9000,
      caption: {
        ar: { title: 'كل التفاصيل قبل الشراء', sub: 'صور القطعة والوزن والعيار والسعر شامل الضريبة' },
        'en-US': { title: 'Every detail before you buy', sub: 'Photos, weight, karat and VAT-inclusive price' },
      },
    },
    {
      name: '03-live-prices', route: '/pricing',
      caption: {
        ar: { title: 'أسعار الذهب بالريال لحظياً', sub: 'كل العيارات والفضة بسعر الجرام' },
        'en-US': { title: 'Live gold rates in SAR', sub: 'Every karat and silver, priced per gram' },
      },
    },
    {
      name: '04-portfolio', route: '/invest',
      caption: {
        ar: { title: 'اعرف قيمة ذهبك اليوم', sub: 'القيمة الحالية والربح والخسارة وتوزيع المعادن' },
        'en-US': { title: 'See what your gold is worth', sub: 'Current value, gain or loss, allocation by metal' },
      },
    },
    {
      name: '05-asset-detail', route: '/invest/asset/bar-61',
      caption: {
        ar: { title: 'تابع كل جرام تملكه', sub: 'سعر الشراء مقابل قيمة اليوم والعائد السنوي' },
        'en-US': { title: 'Follow every gram you own', sub: "Purchase price versus today's value" },
      },
    },
    {
      name: '06-trips', route: '/invest/trips/trip-1',
      caption: {
        ar: { title: 'قارن عروض المحلات قبل الشراء', sub: 'سجّل سعر كل محل وقارنه بسعر السوق' },
        'en-US': { title: "Compare every jeweller's quote", sub: 'Log each store and check it against the market' },
      },
    },
    {
      name: '07-zakat', route: '/invest/zakat',
      caption: {
        ar: { title: 'حاسبة الزكاة وفحص النصاب', sub: 'فحص تلقائي لنصاب 85 جراماً من عيار 24' },
        'en-US': { title: 'Zakat and nisab, calculated', sub: 'Automatic 85 g nisab check' },
      },
    },
    {
      name: '08-consultation', route: '/invest/consultation',
      caption: {
        ar: { title: 'تحدّث مع أخصائي ذهب', sub: 'احجز جلسة خاصة في الوقت المناسب لك' },
        'en-US': { title: 'Talk to a gold specialist', sub: 'Book a private session at a time that suits you' },
      },
    },
  ],
};
