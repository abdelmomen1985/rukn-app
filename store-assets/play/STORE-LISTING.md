# Google Play — Main store listing, field by field

Originally generated from `docs/PUBLISHING.md`; updated by hand for the Flutter 2.0 release.

> Privacy policy, terms and account-deletion pages are live at `https://rknthmin.com.sa/privacy`,
> `/terms` and `/delete-account`. The deletion form does not reach the team yet — see
> `rukn_flutter/RELEASE.md` → "You must do".

## Assets step

| Form field | File | Spec |
|---|---|---|
| App icon | `icon/app-icon-512.png` | 512×512, PNG, no alpha, ≤1 MB |
| Feature graphic | `feature-graphic/feature-graphic-1024x500.en-US.png` | 1024×500 PNG |
| Phone screenshots (2–8) | `phone-screenshots/en-US/` — all 8, in filename order | 1080×1920 PNG |
| 7-inch tablet screenshots | `tablet-7in-screenshots/en-US/` | 1200×1920 PNG |
| 10-inch tablet screenshots | `tablet-10in-screenshots/en-US/` | 1600×2560 PNG |
| Video | *leave empty* | a YouTube URL is optional |

For the Arabic (`ar`) localisation use `feature-graphic-1024x500.ar.png` and
`phone-screenshots/ar/` (and `tablet-*-screenshots/ar/`). Play falls back to the default language's graphics for
any localisation you leave empty.

## Text — English (United States), the default listing

**App name** — 27 / 30
```
Rukn Thamin: Gold & Jewelry
```

**Short description** — 73 / 80
```
Live gold rates in SAR, zakat calculator, quote comparison, jewelry shop.
```

**Full description** — 2388 / 4000
```
Rukn Thamin is the gold companion for Saudi buyers — real-time prices, honest numbers, and certified jewelry in one bilingual (Arabic/English, RTL-ready) app.

■ LIVE GOLD & SILVER PRICES
Track 24K, 22K, 21K, 18K gold plus silver, platinum and palladium in Saudi Riyals per gram, updated from live spot data. Switch freely between grams, tolas, ounces and mithqal, and see exactly when a quote was refreshed.

■ PRICE A PIECE IN SECONDS
The gold value calculator turns weight + karat + making charges + VAT into what a piece should actually cost. The weight converter handles grams, tolas, ounces and mithqal in one tap.

■ MY INVESTMENTS
Add every gold bar, coin and piece of jewelry you own — purchase price, making charges and VAT included. Rukn Thamin revalues the whole portfolio at today's spot price and shows current value, gain/loss, percentage and annualized return, plus an allocation chart by metal. Pull to refresh at any time.

■ SHOPPING TRIPS (جولات التسوق)
Going jeweller-hopping? Plan a trip, log each store's quote — price, weight, karat, VAT included or not, local or imported workmanship — and let the app flag each quote as excellent, fair or high against the live market reference. Compare side by side, add notes, then close the trip with the best deal in hand.

■ ZAKAT CALCULATOR
Automatic nisab check against 85 g of 24K gold, zakatable value and 2.5% due calculated from your live portfolio, with a per-asset breakdown. A simplified estimate — consult a qualified scholar for your final assessment.

■ THE SHOP
Necklaces, rings, bangles and bars in certified gold, priced live from the 21K rate, with special offers and curated collections. Search, save to your wishlist and check out in the app: home delivery, branch pickup or safekeeping in the branch vault; pay by bank transfer or mada/card. Follow each order's progress, download tax invoices and verify bar certificates.

■ EXPERT CONSULTATION
Book a private session with a market specialist for buy/sell and diversification guidance, at a time that suits you. Paid sessions are settled on a secure hosted checkout.

■ BUILT FOR THE KINGDOM
Arabic and English throughout with full right-to-left layout, Saudi Riyal pricing, VAT-aware calculations and 21K as a first-class karat. Works on phones and tablets.

As a guest, your portfolio, wishlist and trip notes stay on your device; sign in with your phone number to sync your portfolio to your account. No ads, no data resale.

Questions, wholesale orders or custom pieces: info@alruknalthamin.com
```

**Release notes / What's new** (Production → Create release) — 495 / 500
```
First public release.
• Live gold, silver, platinum & palladium rates in SAR/gram (24K–18K)
• Portfolio tracker: value, gain/loss, annualized return, allocation by metal
• Shopping trips: log store quotes and compare against the market reference
• Zakat calculator with automatic nisab check (85 g of 24K gold)
• Gold value calculator & weight converter (g, tola, ounce, mithqal)
• Jewelry shop: search, wishlist, cart, checkout, order history
• Consultation booking
• Arabic + English, full RTL
```

## Text — Arabic (`ar`)

The app name is inherited from the default listing so the brand stays searchable
under one string; add a localised name only if you want the Arabic wordmark.

**Short description** — 75 / 80
```
أسعار الذهب بالريال لحظياً، حاسبة زكاة، مقارنة عروض المحلات، ومتجر مجوهرات.
```

**Full description** — 1932 / 4000
```
ركن ثمين هو رفيقك في الذهب داخل السعودية: أسعار لحظية، وأرقام واضحة، ومجوهرات معتمدة، في تطبيق واحد يدعم العربية والإنجليزية واتجاه من اليمين إلى اليسار.

■ أسعار مباشرة
أسعار الذهب عيار 24 و22 و21 و18، إضافة إلى الفضة والبلاتين والبلاديوم، بالريال السعودي للجرام، محدّثة من السعر الفوري مع بيان وقت آخر تحديث.

■ احسب قيمة أي قطعة
تحوّل حاسبة قيمة الذهب الوزن والعيار وأجرة الصياغة وضريبة القيمة المضافة إلى السعر العادل للقطعة، مع محوّل أوزان بين الجرام والتولة والأونصة والمثقال.

■ استثماراتي
أضف كل ما تملكه من سبائك وعملات ومشغولات مع سعر الشراء وأجرة الصياغة والضريبة، ثم شاهد القيمة الحالية للمحفظة، والربح والخسارة، ونسبة العائد، والعائد السنوي، وتوزيع المعادن في رسم واحد. اسحب للتحديث في أي وقت.

■ جولات التسوق
خطّط جولتك قبل الشراء، وسجّل عرض كل محل: السعر الإجمالي، والوزن، والعيار، وهل يشمل الضريبة، مع بيان إن كانت الصياغة محلية أو مستوردة. يصنّف التطبيق كل عرض بين ممتاز وعادل ومرتفع مقارنة بسعر السوق المرجعي، لتقارن بين المحلات في مكان واحد وتختار الأفضل.

■ حاسبة الزكاة
فحص تلقائي للنصاب (85 جراماً من ذهب عيار 24)، مع حساب المال الزكوي والواجب 2.5% وتفصيل الأصول. تقدير مبسّط يعتمد على الأسعار الحالية، ويُرجى مراجعة أحد المتخصصين في أحكام الزكاة لشروط الحول ونحوها.

■ المتجر
قلائد وخواتم وبناجر وسبائك من الذهب المعتمد، بأسعار تتبع سعر عيار 21 لحظياً، مع العروض الخاصة والتشكيلات المختارة. ابحث وأضف إلى المفضلة وأكمل الشراء داخل التطبيق: توصيل منزلي أو استلام من الفرع أو حفظ في خزنة الفرع، والدفع بالتحويل البنكي أو مدى/البطاقة. تابع مراحل كل طلب، وحمّل الفواتير الضريبية، وتحقق من شهادات السبائك.

■ استشارة متخصصة
احجز جلسة خاصة مع متخصص في السوق في الوقت المناسب لك: تحليل لمحفظتك، ونصائح للشراء والبيع والتنويع. تُدفع الجلسات المدفوعة عبر صفحة دفع آمنة.

■ مصمَّم للسعودية
لغتان كاملتان مع اتجاه من اليمين إلى اليسار، وأسعار بالريال السعودي، وحسابات تراعي ضريبة القيمة المضافة، وعيار 21 معاملة أساسية. يعمل على الجوال والتابلت.

كزائر، تبقى محفظتك ومفضلتك وجولاتك على جهازك؛ سجّل الدخول برقم جوالك لمزامنة المحفظة مع حسابك. بدون إعلانات ولا بيع للبيانات.

للاستفسار والطلبات الخاصة: info@alruknalthamin.com
```

**Release notes** — 452 / 500
```
الإصدار الأول.
• أسعار مباشرة للذهب والفضة والبلاتين والبلاديوم بالريال للجرام
• متابعة المحفظة: القيمة الحالية والربح والخسارة والعائد السنوي وتوزيع المعادن
• جولات التسوق: سجّل عروض المحلات وقارنها بالسعر المرجعي
• حاسبة الزكاة مع فحص النصاب (85 جراماً من عيار 24)
• حاسبة قيمة الذهب ومحوّل الأوزان (جرام وتولة وأونصة ومثقال)
• المتجر: بحث ومفضلة وسلّة ودفع وسجل الطلبات
• حجز الاستشارات
• العربية والإنجليزية مع دعم كامل للاتجاه من اليمين إلى اليسار
```

## Store settings (the tab next to the listing)

| Field | Value |
|---|---|
| App category | Shopping (primary); add Finance under *App categories* |
| Email address | `info@alruknalthamin.com` |
| Website | `https://rknthmin.com.sa` |
| Privacy policy | `https://rknthmin.com.sa/privacy` |
| Account deletion URL (Data safety) | `https://rknthmin.com.sa/delete-account` |
| Contains ads | **No** — no ad SDK in the project |
| In-app purchases | **No** — physical goods and real-world services; see `docs/PUBLISHING.md` §4.3 |
| Reviewer access | **On**, with the credentials in `docs/PUBLISHING.md` §9.6 |

Content rating (IARC), Data safety and Target audience answers are in
`docs/PUBLISHING.md` §4.4, §4.5 and §9.

## Screenshot order

Captured from the real Flutter app (`rukn_flutter/scripts/store-assets/shots.config.mjs`), same
order and names for phone and both tablet sizes:

1. `01-shop` — Shop gold jewellery
2. `02-product` — Every detail before you buy
3. `03-live-prices` — Live gold rates in SAR
4. `04-portfolio` — See what your gold is worth
5. `05-asset-detail` — Follow every gram you own
6. `06-trips` — Compare every jeweller's quote
7. `07-zakat` — Zakat and nisab, calculated
8. `08-consultation` — Talk to a gold specialist
