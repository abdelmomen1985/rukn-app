# store-assets/play

Everything the Google Play **Main store listing** form asks for, in English and
Arabic. Start with [`STORE-LISTING.md`](./STORE-LISTING.md) — it maps each form
field to the file or string that belongs in it.

```
icon/                 512 and 1024 px store icons + a launcher-size contact sheet
feature-graphic/      1024×500, one per locale
phone-screenshots/    en-US/ and ar/, 8 shots each, 1080×1920
tablet-screenshots/   en-US/, 7-inch (1200×1920) and 10-inch (1600×2560)
text/                 one .txt per form field, ready to paste
```

## Regenerating

```bash
pnpm store:assets
```

The generator renders the screens as HTML in headless Chromium (the Playwright
browser already in this image; no npm dependency), so Arabic shaping, RTL layout
and the icon set come from the browser rather than from hand-placed pixels. It
also rewrites the in-binary icons — `assets/images/icon.png`, `favicon.png`,
`splash-icon.png` and the Android adaptive trio — so the AAB and the listing
always show the same mark (`docs/PUBLISHING.md` §1.3).

Screen content mirrors the real components (`components/title-bar.tsx`,
`components/portfolio/*`, `components/invest-bottom-nav.tsx`,
`app/(tabs)/_layout.tsx`, `app/invest/*`) and every label is the app's own
string from `lib/i18n.tsx`. The numbers come from one dataset in
`scripts/store-assets/data.mjs`, so the portfolio total, the zakat base and the
asset detail always agree.

Fonts are fetched once into `scripts/store-assets/.fonts/` (gitignored) and
inlined, so later runs need no network.
