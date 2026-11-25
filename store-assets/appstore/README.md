# store-assets/appstore

App Store Connect screenshots, from the real Flutter app (web build), 8 shots per set,
JPEG without alpha.

```
en-US/iphone-6.9in-1320x2868/   iPhone 6.9" (Apple scales it down for smaller iPhones)
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
```

Shots, routes, captions and the seeded guest data are shared with the Play set in
`scripts/store-assets/shots.config.mjs`.
