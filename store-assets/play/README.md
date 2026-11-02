# store-assets/play

Everything the Google Play **Main store listing** form asks for, in English and
Arabic. Start with [`STORE-LISTING.md`](./STORE-LISTING.md) — it maps each form
field to the file or string that belongs in it.

```
icon/                 512 and 1024 px store icons + a launcher-size contact sheet
feature-graphic/      1024×500, one per locale
phone-screenshots/          en-US/ and ar/, 8 shots each, 1080×1920
tablet-7in-screenshots/     en-US/ and ar/, 1200×1920
tablet-10in-screenshots/    en-US/ and ar/, 1600×2560
text/                 one .txt per form field, ready to paste
```

## Regenerating

Screenshots come from the real Flutter app (`rukn_flutter/`), not from a redraw:

```bash
cd rukn_flutter
flutter build web --release
node ~/.claude/skills/flutter-store-screenshots/scripts/shoot.mjs \
  --config scripts/store-assets/shots.config.mjs --devices phone,tablet7,tablet10
```

The run is a guest session against the live store. The portfolio and the shopping trip are
seeded into on-device storage from `shots.config.mjs`.

The icon set and feature graphic still come from the older HTML generator (`pnpm store:assets`
in the repo root); its screen redraws are of the retired Expo UI, so don't use its screenshots.
