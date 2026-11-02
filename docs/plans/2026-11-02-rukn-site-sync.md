# Plan — bring `rukn_flutter` up to date with `rukn-site` (2026-11-02)

The Flutter app (`rukn_flutter/`) was last synced with the site around 2026-10-04 (site commit
`46c028d`: branches, sizes, vault). This plan covers every site commit since then.

## Triage of site commits after 2026-10-04

| Site commit | What | Decision |
|---|---|---|
| `0e57c04` | Mobile nav drawer portal | Web-only — skip |
| `a38d3a5` | Product gallery: thumbnails + auto-advance | **WP2** |
| `f61ac9c` | Home category rails from `/store/home-categories` | **WP1** |
| `7b3869b` | Checkout: UPS coverage check (`/store/ups-coverage`) | **WP3** |
| `91006f5` | Product option buttons restyled; size-guide hidden | **WP2** |
| `d0d5e8e` | Search indexes live catalogue + blog (+ Arabic normalisation) | **WP5** |
| `f1f0b33`, `422fde8` | Special offers labels (`/store/special-offers`) with admin colours | **WP2** |
| `69ee574` | Ad pixels / GTM vocabulary, attribution | Skip (README: GTM deliberately not ported) |
| `e11edcf` | SEO meta | Web-only — skip |
| `3fa3616`, `fc6f789` | Product sections (`/store/product-sections`) replace exclusive rail; skip unavailable | **WP1** |
| `13ef4cb` | Legal pages /privacy, /terms; delete-account web form | **WP6** (app already has in-app deletion) |
| `090c42a` | Test domain fallback | Skip |
| `0b9eabc` | First-party analytics → `POST /store/analytics/collect` | **WP7** (wave 2) |
| `137f034`, `a633167` | Category: unique products, page size 100 + «عرض المزيد» via `count`; order stages + operator status labels | **WP5** (category), **WP4** (orders) |
| `54d8a0c` | SMSA delivery where UPS does not reach | **WP3** |
| `6e937ba`, `575606f` | Footer SBC seal (disabled) | Web-only — skip |

## Ground rules for every work package

- Work only in `/home/momen/dev/rukn-app/rukn_flutter`. The site at `/home/momen/dev/rukn-site/src` is the
  reference — read the named files there, port behaviour faithfully (same endpoints, same
  fallbacks: an outage never blanks a screen, failed fetch → built-in behaviour).
- `rukn_flutter` is **not in git** — never run git commands that touch it; never delete files you don't own.
- Strings: put new keys ONLY in your package's file `lib/l10n/site_sync/<pkg>.dart` (both `En` and `Ar`
  maps, same keys). Use `i18n.t('key')` and `i18n.pick(ar, en)` like the existing code.
- Only edit the files your package owns (listed below). If you truly need a one-line hook in a
  file owned by another package, don't — report it instead.
- Match the existing code style (services as static classes over `Api`, `asMap`/`asList` helpers,
  `AppColors`, `NetImage`, `StatusChip`, etc.). Pure parsing/logic goes in testable functions;
  add unit tests in a new `test/<pkg>_test.dart`.
- Done = `flutter analyze --no-pub` has no new errors/warnings and `flutter test` passes.

## Work packages — wave 1 (parallel)

**WP1 Home content** — owns `lib/screens/home_screen.dart`, new `lib/services/home_content_service.dart`,
new `lib/widgets/home_rails.dart`, `test/home_test.dart`, `l10n/site_sync/home.dart`.
Ref: `src/lib/homeCategories.ts`, `src/lib/productSections.ts`, `src/components/HomeCategoryRails.tsx`,
`CategoryStrip.tsx`, `CollectionsSection.tsx`, `ProductSections.tsx`, `src/hooks/useProductsByHandles.ts`.
- `/store/home-categories` → sections (circles/cards layout, hero/body placement, view-all, tile link
  vs category). Null → keep current built-in category UI; `[]` → render nothing.
- `/store/product-sections` → stacked product rails replacing the single exclusive rail; resolve
  handles via `CatalogService.getProductsByHandles`, skip unavailable products, badge/meta overlay.
  Null → keep the existing `/store/exclusive-products` rail.
- Tile links: `/…` site paths map to in-app routes where possible (category → `/category/:id`
  or whatever the router uses), http(s) → `url_launcher`.

**WP2 Product presentation** — owns `lib/screens/product_screen.dart`, `lib/widgets/product_widgets.dart`,
new `lib/services/special_offers.dart`, new `lib/widgets/offer_badge.dart`, `test/product_test.dart`,
`l10n/site_sync/product.dart`. Ref: `src/lib/specialOffers.ts`, `src/components/SpecialOfferBadge.tsx`,
`src/components/ProductGallery.tsx`, `src/pages/ItemDetailPage.tsx` (option buttons, `SHOW_SIZE_GUIDE`).
- Special offers: fetch once/cache, parse exactly like `toSpecialOffers`, `offersForProduct`
  (direct first), colour palettes. Badge on product cards, full offer text on the product page.
  Expose `offersForCategory` (used in wave 2). `Product.categoryIds` already exists — don't edit the model.
- Gallery: main image + thumbnail strip, auto-advance every 4.5 s that stops for good after the
  user swipes/taps a thumbnail; respect `MediaQuery.disableAnimations`; single image = no thumbs.
- Option buttons: brand-palette tiles per `optionButtonClass` (gold border when selected, dashed +
  struck-through when unavailable); hide any size-guide link.

**WP3 Checkout carriers** — owns `lib/screens/checkout_screen.dart`, `lib/services/checkout_service.dart`,
new `lib/services/ups_coverage.dart`, `test/checkout_test.dart`, `l10n/site_sync/checkout.dart`.
Ref: `src/lib/upsCoverage.ts`, `src/lib/checkout.ts`, `src/lib/checkoutState.ts`, `src/lib/branches.ts`,
`src/pages/CheckoutPage.tsx` (git show `7b3869b` and `54d8a0c` in rukn-site).
- `GET /store/ups-coverage?city&district` once the address has city/district (debounced); failure = covered.
- `delivery-options` gains `smsa` options; `deliveryCarrier()`: SMSA only where UPS not covered and
  fallback is `smsa` and SMSA offered. Delivery choice kind `'pickup'|'ups'|'smsa'`; auto-switch the
  choice to the right carrier both ways; uncovered with no SMSA → message + block continuing with UPS.
- Vault and fulfillment-branch logic: treat `smsa` like `ups` (`kind != 'pickup'`).

**WP4 Orders** — owns `lib/screens/orders_screens.dart`, `lib/models/customer.dart`, new
`lib/services/order_statuses.dart`, `test/orders_test.dart`, `l10n/site_sync/orders.dart`.
Ref: `src/lib/orderStatuses.ts`, `src/pages/AccountPage.tsx` (git show `a633167`).
- `/store/order-statuses` labels (scopes order/payment/fulfillment/carrier/vault) override built-in
  wording; tone palette for chips. Cache; retry after failure.
- Order detail: «مراحل الطلب» timeline from `/store/customers/me/orders/:id/stages` (progress,
  current, reached_at dates). Hidden when null.

**WP5 Category & search** — owns `lib/screens/product_list_screen.dart`, `lib/services/catalog_service.dart`,
new `lib/services/search_index.dart`, `test/search_test.dart`, `l10n/site_sync/search.dart`.
Ref: `src/lib/categoryProducts.ts`, `src/lib/store.ts` (`getCategoryProductsPage`), `src/hooks/useSearchIndex.ts`,
`src/pages/SearchResultsPage.tsx`, `src/pages/CategoryPage.tsx`.
- Category listing: page size 100, dedupe by id across pages, «load more» driven by Medusa `count`.
- Search: besides server product search, match categories and blog articles locally with the site's
  Arabic normalisation (diacritics, tatweel, alef/ya/ta-marbuta folding); show them as sections above
  products.

**WP6 Legal** — owns new `lib/data/legal.dart`, new `lib/screens/legal_screen.dart`, `lib/app_router.dart`,
`lib/screens/profile_screen.dart`, `lib/screens/auth_screen.dart`, `lib/core/config.dart`, `test/legal_test.dart`,
`l10n/site_sync/legal.dart`. Ref: `src/data/legal.ts`, `src/pages/LegalPage.tsx`, `src/utils/router.ts`.
- Port privacy + terms content verbatim (both languages) into Dart data; an in-app screen renders
  title, summary, updated date, clauses. Routes `/privacy`, `/terms`. Profile: privacy + terms entries;
  auth screen consent links to them. `Config.privacyPolicyUrl` → site `/{lang}/privacy`; add `termsUrl`.
- WP6 is the only package that may touch `app_router.dart`; register any route other packages need
  (none expected).

## Wave 2 (after wave 1 lands)

**WP7 Category offer banner + first-party analytics** — category page banner of special offers via
WP2's `offersForCategory` (in `product_list_screen.dart`); then analytics: new `lib/services/site_analytics.dart`, small hooks in router observer,
product screen (product_viewed), cart state (added_to_cart), checkout (checkout_started,
payment_info_submitted, checkout_completed), search. Ref: `src/lib/site-analytics.ts`, `src/lib/analytics.ts`.
Visitor id in shared_preferences, 30-min session rotation, batched flush every 5 s / 10 events /
app paused, never throws.

## Verification (orchestrator)

1. `flutter analyze --no-pub` + `flutter test` after each wave.
2. Review each package's diff against the baseline snapshot; check parsing against site semantics.
3. Update `rukn_flutter/README.md` "Brought over from the website" list.
