# store-assets/appstore

App Store Connect screenshots, from the real Flutter app (web build), 7 shots per set (the consultation shot is Play-only: the iOS app has no consultations),
JPEG without alpha.

```
en-US/iphone-6.9in-1320x2868/   iPhone 6.9" (large Dynamic Island slot)
en-US/iphone-6.3in-1206x2622/   iPhone 6.1"/6.3" (medium Dynamic Island slot, required by App Store Connect)
en-US/ipad-13in-2064x2752/      iPad 13" (required because the app supports iPad)
ar/...                          the same sets for the Arabic localization
```

The app icon comes from the build itself, so App Store Connect doesn't ask for one.

## Regenerating

```bash
cd rukn_flutter
flutter build web --release
(cd build/web && python3 -m http.server 8021 --bind 127.0.0.1) &   # the origin the backend allows for CORS
# needs puppeteer-core (npm i puppeteer-core) and Google Chrome
node scripts/store-assets/appstore/capture.mjs scripts/store-assets/shots.config.mjs /tmp/raw
node scripts/store-assets/appstore/compose.mjs scripts/store-assets/shots.config.mjs /tmp/raw ../store-assets/appstore
python3 scripts/store-assets/appstore/derive-6.3.py   # 6.3" set from the 6.9" set (needs Pillow)
```

Shots, routes, captions and the seeded guest data are shared with the Play set in
`scripts/store-assets/shots.config.mjs`.

## Header and search-results artwork (`header/`)

Optional creative assets: version page → Product Page Information → **Header and Search Results**
(or Asset Library). Specs from Apple's "Creative assets specifications" page:

```
header/universal-16x9-5244x2950.png   PNG, safe area 1402×962 at (1921, 660); header + search results
header/header-21x9-3840x1646.png      PNG, safe area 1646×661 at (1097, 493); header only
header/review/*-safe-area.png         same art with the safe area outlined: never upload
```

No text, logo or alpha. The necklace fills the safe area; outside it is only velvet and pattern,
which devices crop away.

```bash
cd rukn_flutter && node scripts/store-assets/appstore/header.mjs   # needs Google Chrome
```
