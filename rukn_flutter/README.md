# Rukn Thamin — Flutter app

Flutter rewrite of the Expo / React Native app in the repository root, brought
up to date with the features that shipped on the website (`rukn-site`). It talks
to the same Medusa backend (rukn-admin) as the site.

## Run

```bash
cd rukn_flutter
flutter pub get
flutter run                      # live backend: https://admin.rknthmin.com.sa
flutter test                     # business-logic + translation-coverage tests
```

Configuration is compile-time (`lib/core/config.dart`), overridable with `--dart-define`:

| Define | Default |
|---|---|
| `MEDUSA_URL` | `https://admin.rknthmin.com.sa` (local backend from an emulator: `http://10.0.2.2:9000`) |
| `MEDUSA_PUBLISHABLE_KEY` | the store's publishable key |
| `WEB_ORIGIN` | `https://rknthmin.com.sa` (privacy policy fallback link) |
| `SUPPORT_EMAIL` / `WHATSAPP` | same contacts as the website |

The web build is for development only. Its image renderer needs CORS headers the
image host doesn't send, so web falls back to `<img>` elements. The payment
WebView is mobile-only (on web, checkout opens in a new tab). The backend only
allows CORS from known origins, so serve a web build on `localhost:8021`.

## Structure

```
lib/
  core/       config, Medusa API client (+ secure token storage), theme, formatting
  l10n/       I18n (ar default, RTL) — strings_base.dart = Expo app strings, strings_extra.dart = new
  models/     product mapping, gold prices, portfolio math, trips, price alerts, customer/orders
  services/   catalog, account/OTP, checkout, loyalty, national address, invest (portfolio sync,
              consultations, subscriptions), content (blog, certificates), store settings
  state/      ChangeNotifiers: auth, cart, wishlist, live gold ticker, portfolio, trips, alerts
  screens/    one file per area; invest/ holds the investment tools
  widgets/    shared UI (price with SAR glyph, cards, pills, product card, national address form)
```

## What changed vs. the Expo app

Ported 1:1: tabs (home / wishlist / cart / invest / profile), product page, portfolio
(assets, P&L, allocation, nisab and zakat, converter), shopping trips with
fair-price verdicts, consultation booking, account deletion, ar/en with RTL.

Brought over from the website:

- **Phone OTP sign-in/registration.** The live backend has `password_enabled: false`,
  so the Expo app's email/password login no longer works against production.
  Email/password still shows if the admin turns it back on.
- **Live gold ticker** from `/store/gold-prices` (karats, silver, ounce, market open/closed).
  Product and cart prices follow the 21K catalogue rate. The cart is repriced from the
  real variant prices every 30 s and again before payment.
- **Real checkout.** Cart quantities, variant/size pickers, UPS delivery with a free-shipping
  threshold, branch pickup, the branch vault («خزنة الفرع»), and a National Address lookup.
  Payment is bank transfer with receipt upload, Paymob card/mada (card fee, in-app hosted
  checkout, the backend is polled for the result), or COD when enabled. The checkout also
  respects ordering-closed status, VAT lines, and branch-exclusive cart rules.
- **Account:** edit name/email, change phone via OTP, address book, loyalty tier/points,
  order detail with tax invoice, vault shipping request, and bar certificates.
- **Bar certificate verification**, **price alerts** (fire once per crossing, checked on every tick
  while the app is open), **articles** (CMS blog; the privacy policy is the `policy` article),
  **announcement bar**, **exclusive products**, **reviews**, **search**.
- **Portfolio sync:** signed-in customers' assets live in `/store/portfolio-assets`; guests stay
  on-device. There is also a subscription paywall, which stays open while the backend has `paid: false`.
- **Consultations** now go to Medusa `/store/consultations` (paid sessions via hosted checkout)
  instead of the Expo app's own tRPC/MySQL server.

Synced with the site's October 2026 changes (plan: `../docs/plans/2026-11-02-rukn-site-sync.md`;
strings in `lib/l10n/site_sync/`):

- **Home from the admin:** category rails (`/store/home-categories`, circles/cards, hero/body) and
  product sections (`/store/product-sections`) replacing the fixed exclusive rail. An outage keeps
  the built-in home.
- **Special offers** (`/store/special-offers`): text-only labels in the admin's colours on product
  cards, the product page and a category banner.
- **Product page:** photo gallery with thumbnails and auto-advance; clearer weight/size tiles.
- **Checkout:** UPS coverage check (`/store/ups-coverage`) with SMSA delivery where UPS does not reach.
- **Orders:** operator status wording (`/store/order-statuses`) and the order-stage timeline.
- **Category paging** (100 per page, «load more» by `count`) and **search** that also matches
  categories and articles with Arabic normalisation.
- **Privacy policy and terms** in-app (`/privacy`, `/terms`), ported from the site's legal pages.
- **First-party analytics** to `/store/analytics/collect` (page views, product views, cart,
  checkout, search). Payload `platform` is `android`/`ios`.

Deliberately not ported: the site's candlestick chart (it's generated client-side, so it isn't
real market history), the hiring page, GTM/ad-pixel tracking, SEO meta, the web delete-account form (the app deletes in-app) and the footer SBC seal.

## Releasing

- **Identity:** the `applicationId` / bundle id is `com.ruknthamin.app`, the same as the
  published Expo app, so this ships as an update to it.
- **Signing (Android):** the upload key is `android/upload-keystore.jks` (alias `upload`), described
  by `android/key.properties`. Both are gitignored, so keep backups. It replaces the EAS upload key,
  so Play must accept it once through an upload-key reset; see `RELEASE.md`.
- **Version:** `pubspec.yaml` is `2.0.0+100`. The build number must be higher than the last
  `versionCode` / `buildNumber` EAS uploaded (EAS kept it remotely), so check Play Console /
  App Store Connect and raise it if needed.
- `flutter build appbundle` and `flutter build ipa`. iOS needs a Mac with Xcode; set the team in
  `ios/Runner.xcworkspace`.
- **Device data from the Expo build does not carry over.** AsyncStorage and Flutter's
  shared_preferences are different stores, so a guest's local portfolio, trips, cart and
  wishlist start empty after the update, and everyone has to sign in again. Signed-in
  portfolios are fine because they live on the server. Mention this in the release notes.
- Store listing assets and the privacy/data-safety answers in `../store-assets` and
  `../docs/PUBLISHING.md` still apply. Data collected is the same, plus the bank-receipt upload
  (photos/files, sent only at checkout).
