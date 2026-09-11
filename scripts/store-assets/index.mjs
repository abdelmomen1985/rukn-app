#!/usr/bin/env node
/**
 * Builds every asset and every string the Google Play "Main store listing" form
 * asks for, in English and Arabic.
 *
 *   node scripts/store-assets/index.mjs      (or: pnpm store:assets)
 *
 * Screens are HTML rendered by headless Chromium — see `screens.mjs` for why —
 * and each output is validated against the console's upload rules before the
 * run is allowed to succeed.
 */
import { execFile } from "node:child_process";
import { mkdir, rm, writeFile } from "node:fs/promises";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

import { shoot, cleanup } from "./chrome.mjs";
import { getFontCss } from "./fonts.mjs";
import { captionedPage, featurePage } from "./frames.mjs";
import { SCREENS, SHOT_ORDER } from "./screens.mjs";
import { captions, LOCALES } from "./copy.mjs";
import { loadListing, count, LIMITS, DOMAIN, SUPPORT_EMAIL, PRIVACY_URL, DELETION_URL, WEBSITE } from "./listing.mjs";
import { check, fmtBytes } from "./validate.mjs";
import { REPO_ROOT } from "./theme.mjs";

const execFileAsync = promisify(execFile);
const HERE = dirname(fileURLToPath(import.meta.url));
const OUT = join(REPO_ROOT, "store-assets", "play");
const FONT_HREF = "../.fonts/fonts.css";   // relative to chrome.mjs's .render dir

/** Caption band takes just under a fifth of the frame at every size. */
const capHeight = (h) => Math.round(h * 0.198);

const DEVICES = {
  phone:    { width: 1080, height: 1920, uiWidth: 432 },
  tablet7:  { width: 1200, height: 1920, uiWidth: 480 },
  tablet10: { width: 1600, height: 2560, uiWidth: 600 },
};

/** Which screens carry the story on a tablet, where Play shows fewer images. */
const TABLET_SHOTS = ["01-live-prices", "03-trips", "06-shop"];

const results = [];
const record = async (path, kind, expected) => {
  const { info, fail } = await check(path, kind, expected);
  results.push({ path: relative(OUT, path), kind, info, fail });
  return fail;
};

async function renderShot({ locale, key, device, outPath }) {
  const [title, sub] = captions[locale][key];
  const html = captionedPage({
    locale,
    width: device.width,
    height: device.height,
    capHeight: capHeight(device.height),
    uiWidth: device.uiWidth,
    title, sub,
    screenHtml: SCREENS[key](locale),
    fontCssHref: FONT_HREF,
  });
  await shoot(html, { width: device.width, height: device.height, outPath });
}

async function main() {
  console.log("Rukn Thamin — Google Play store assets\n");

  // Text first: a limit violation should stop the run before it renders 22 pages.
  console.log("→ Store listing text");
  const listing = await loadListing();
  for (const locale of LOCALES) {
    for (const [field, value] of Object.entries(listing[locale])) {
      if (value == null) continue;
      console.log(`  ${locale.padEnd(6)} ${field.padEnd(17)} ${String(count(value)).padStart(4)} / ${LIMITS[field]}`);
    }
  }

  await rm(OUT, { recursive: true, force: true });
  await mkdir(OUT, { recursive: true });

  console.log("\n→ Fonts");
  await getFontCss();

  console.log("\n→ Icons");
  const { stdout } = await execFileAsync("python3", [join(HERE, "icons.py"), OUT]);
  process.stdout.write(stdout);
  await record(join(OUT, "icon", "app-icon-512.png"), "icon");

  console.log("\n→ Feature graphics");
  for (const locale of LOCALES) {
    const file = join(OUT, "feature-graphic", `feature-graphic-1024x500.${locale}.png`);
    await shoot(featurePage({ locale, fontCssHref: FONT_HREF }), { width: 1024, height: 500, outPath: file });
    await record(file, "feature");
    console.log(`  ${locale}`);
  }

  console.log("\n→ Phone screenshots");
  for (const locale of LOCALES) {
    for (const key of SHOT_ORDER) {
      const file = join(OUT, "phone-screenshots", locale, `phone-${key}.png`);
      await renderShot({ locale, key, device: DEVICES.phone, outPath: file });
      await record(file, "screenshot", DEVICES.phone);
    }
    console.log(`  ${locale}  ${SHOT_ORDER.length} shots`);
  }

  console.log("\n→ Tablet screenshots");
  for (const [name, device] of [["7in", DEVICES.tablet7], ["10in", DEVICES.tablet10]]) {
    for (const key of TABLET_SHOTS) {
      const file = join(OUT, "tablet-screenshots", "en-US", `tablet-${name}-${key}.png`);
      await renderShot({ locale: "en-US", key, device, outPath: file });
      await record(file, "screenshot", device);
    }
    console.log(`  ${name}  ${TABLET_SHOTS.length} shots`);
  }

  console.log("\n→ Paste-ready text files");
  for (const locale of LOCALES) {
    for (const [field, value] of Object.entries(listing[locale])) {
      if (value == null) continue;
      const name = field.replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`);
      const file = join(OUT, "text", locale, `${name}.txt`);
      await mkdir(dirname(file), { recursive: true });
      await writeFile(file, `${value}\n`);
    }
  }

  await writeFile(join(OUT, "STORE-LISTING.md"), sheet(listing));
  await writeFile(join(OUT, "README.md"), readme());
  await cleanup();

  // ---- report ----
  console.log("\n→ Validation");
  const failures = results.filter((r) => r.fail.length);
  const pad = Math.max(...results.map((r) => r.path.length));
  for (const r of results) {
    const mark = r.fail.length ? "✗" : "✓";
    console.log(`  ${mark} ${r.path.padEnd(pad)}  ${r.info.width}×${r.info.height}  ${fmtBytes(r.info.bytes).padStart(7)}`);
    for (const f of r.fail) console.log(`      ${f}`);
  }

  if (failures.length) {
    console.error(`\n${failures.length} asset(s) would be rejected by Play. Nothing was uploaded.`);
    process.exitCode = 1;
    return;
  }
  console.log(`\n${results.length} assets OK → ${relative(REPO_ROOT, OUT)}`);
  console.log("Field-by-field paste sheet: store-assets/play/STORE-LISTING.md");
}

// ---------------------------------------------------------------------------

const fence = (s) => "```\n" + s + "\n```";

function sheet(listing) {
  const en = listing["en-US"];
  const ar = listing.ar;
  const c = (v, f) => `${count(v)} / ${LIMITS[f]}`;

  return `# Google Play — Main store listing, field by field

Generated by \`scripts/store-assets/index.mjs\`. The text is read from
\`docs/PUBLISHING.md\` (§4.2 English, §6 Arabic) with \`${DOMAIN}\` filled in, so
edit the guide — not this file — to change what gets pasted.

> **Blocker before you can submit.** Play refuses a listing whose privacy-policy
> URL does not resolve. \`${PRIVACY_URL}\` and \`${DELETION_URL}\` are not live yet
> (the \`rukn-site\` repo has no privacy page), and \`.env\` has no
> \`EXPO_PUBLIC_WEB_ORIGIN\`. Publish both pages, then set the release env vars —
> \`app.config.ts\` refuses to build a production binary until you do.

## Assets step

| Form field | File | Spec |
|---|---|---|
| App icon | \`icon/app-icon-512.png\` | 512×512, PNG, no alpha, ≤1 MB |
| Feature graphic | \`feature-graphic/feature-graphic-1024x500.en-US.png\` | 1024×500 PNG |
| Phone screenshots (2–8) | \`phone-screenshots/en-US/\` — all 8, in filename order | 1080×1920 PNG |
| 7-inch tablet screenshots | \`tablet-screenshots/en-US/tablet-7in-*.png\` | 1200×1920 PNG |
| 10-inch tablet screenshots | \`tablet-screenshots/en-US/tablet-10in-*.png\` | 1600×2560 PNG |
| Video | *leave empty* | a YouTube URL is optional |

For the Arabic (\`ar\`) localisation use \`feature-graphic-1024x500.ar.png\` and
\`phone-screenshots/ar/\`. Play falls back to the default language's graphics for
any localisation you leave empty.

## Text — English (United States), the default listing

**App name** — ${c(en.appName, "appName")}
${fence(en.appName)}

**Short description** — ${c(en.shortDescription, "shortDescription")}
${fence(en.shortDescription)}

**Full description** — ${c(en.fullDescription, "fullDescription")}
${fence(en.fullDescription)}

**Release notes / What's new** (Production → Create release) — ${c(en.releaseNotes, "releaseNotes")}
${fence(en.releaseNotes)}

## Text — Arabic (\`ar\`)

The app name is inherited from the default listing so the brand stays searchable
under one string; add a localised name only if you want the Arabic wordmark.

**Short description** — ${c(ar.shortDescription, "shortDescription")}
${fence(ar.shortDescription)}

**Full description** — ${c(ar.fullDescription, "fullDescription")}
${fence(ar.fullDescription)}

**Release notes** — ${c(ar.releaseNotes, "releaseNotes")}
${fence(ar.releaseNotes)}

## Store settings (the tab next to the listing)

| Field | Value |
|---|---|
| App category | Shopping (primary); add Finance under *App categories* |
| Email address | \`${SUPPORT_EMAIL}\` |
| Website | \`${WEBSITE}\` |
| Privacy policy | \`${PRIVACY_URL}\` |
| Account deletion URL (Data safety) | \`${DELETION_URL}\` |
| Contains ads | **No** — no ad SDK in the project |
| In-app purchases | **No** — physical goods and real-world services; see \`docs/PUBLISHING.md\` §4.3 |
| Reviewer access | **On**, with the credentials in \`docs/PUBLISHING.md\` §9.6 |

Content rating (IARC), Data safety and Target audience answers are in
\`docs/PUBLISHING.md\` §4.4, §4.5 and §9.

## Screenshot order

${SHOT_ORDER.map((k, i) => `${i + 1}. \`phone-${k}.png\` — ${captions["en-US"][k][0]}`).join("\n")}
`;
}

function readme() {
  return `# store-assets/play

Everything the Google Play **Main store listing** form asks for, in English and
Arabic. Start with [\`STORE-LISTING.md\`](./STORE-LISTING.md) — it maps each form
field to the file or string that belongs in it.

\`\`\`
icon/                 512 and 1024 px store icons + a launcher-size contact sheet
feature-graphic/      1024×500, one per locale
phone-screenshots/    en-US/ and ar/, 8 shots each, 1080×1920
tablet-screenshots/   en-US/, 7-inch (1200×1920) and 10-inch (1600×2560)
text/                 one .txt per form field, ready to paste
\`\`\`

## Regenerating

\`\`\`bash
pnpm store:assets
\`\`\`

The generator renders the screens as HTML in headless Chromium (the Playwright
browser already in this image; no npm dependency), so Arabic shaping, RTL layout
and the icon set come from the browser rather than from hand-placed pixels. It
also rewrites the in-binary icons — \`assets/images/icon.png\`, \`favicon.png\`,
\`splash-icon.png\` and the Android adaptive trio — so the AAB and the listing
always show the same mark (\`docs/PUBLISHING.md\` §1.3).

Screen content mirrors the real components (\`components/title-bar.tsx\`,
\`components/portfolio/*\`, \`components/invest-bottom-nav.tsx\`,
\`app/(tabs)/_layout.tsx\`, \`app/invest/*\`) and every label is the app's own
string from \`lib/i18n.tsx\`. The numbers come from one dataset in
\`scripts/store-assets/data.mjs\`, so the portfolio total, the zakat base and the
asset detail always agree.

Fonts are fetched once into \`scripts/store-assets/.fonts/\` (gitignored) and
inlined, so later runs need no network.
`;
}

main().catch((err) => {
  console.error(`\n${err.message}`);
  process.exit(1);
});
