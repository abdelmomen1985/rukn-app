// Frames raw screens with the brand caption band, at exact App Store sizes (JPEG, no alpha).
// usage: node compose.mjs <configPath> <rawDir> <outDir>
import puppeteer from 'puppeteer-core';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [, , configPath, rawDir, outDir] = process.argv;
const config = (await import(pathToFileURL(path.resolve(configPath)).href)).default;
const repo = '/Users/tratodev/dev/rukn-app';
const font = pathToFileURL(`${repo}/node_modules/@expo-google-fonts/cairo/Cairo_700Bold.ttf`).href;
const mark = pathToFileURL(`${repo}/rukn_flutter/assets/icon/android-icon-foreground.png`).href;
const c = config.brand.colors;

// Canvas, raw-screen height (from capture.mjs) and output folder per device.
const DEVICES = {
  iphone69: { W: 1320, H: 2868, screen: 2370, folder: 'iphone-6.9in-1320x2868' },
  ipad13: { W: 2064, H: 2752, screen: 2056, folder: 'ipad-13in-2064x2752' },
};

function page({ W, H, screen }, dir, title, sub, img) {
  const band = H - screen;
  const s = Math.min(W / 1080, band / 410);   // scale of the 1080-wide Play phone layout
  const near = dir === 'rtl' ? 'right' : 'left';
  const far = dir === 'rtl' ? 'left' : 'right';
  const cx = dir === 'rtl' ? 12 : 88;
  const px = (v) => `${(v * s).toFixed(1)}px`;
  return `<!doctype html><html dir="${dir}"><head><meta charset="utf-8"><style>
  @font-face { font-family: BrandFont; src: url("${font}"); }
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { width:${W}px; height:${H}px; overflow:hidden; }
  body { font-family: BrandFont, system-ui, sans-serif; background:${c.to}; position:relative; }
  .band { position:absolute; inset:0 0 auto 0; height:${band + 60 * s}px;
    background:
      radial-gradient(circle at ${cx}% 18%, rgba(255,255,255,.14) 0 ${px(140)}, transparent ${px(141)}),
      radial-gradient(circle at ${dir === 'rtl' ? 4 : 96}% 90%, rgba(255,255,255,.09) 0 ${px(90)}, transparent ${px(91)}),
      linear-gradient(135deg, ${c.from} 0%, ${c.via} 45%, ${c.to} 100%); }
  .deco { position:absolute; inset:0; height:${band}px; overflow:hidden; opacity:.12; }
  .deco img { position:absolute; filter:brightness(0) invert(1); }
  .brand { position:absolute; top:${px(70)}; ${near}:${px(72)}; display:flex; align-items:center; gap:${px(18)}; }
  .brand .mark { width:${px(54)}; height:${px(54)}; border-radius:50%; background:#fff; display:grid; place-items:center; }
  .brand .mark img { max-height:${px(38)}; max-width:${px(40)}; }
  .brand .name { color:${c.title}; font-size:${px(30)}; letter-spacing:.06em; }
  h1 { position:absolute; top:${px(150)}; left:${px(72)}; right:${px(72)}; color:${c.title};
       font-size:${px(74)}; line-height:1.25; font-weight:700; white-space:nowrap; }
  .rule { position:absolute; top:${px(262)}; ${near}:${px(72)}; width:${px(96)}; height:${px(6)}; border-radius:${px(3)}; background:${c.rule}; }
  p { position:absolute; top:${px(292)}; left:${px(72)}; right:${px(72)}; color:${c.sub}; font-size:${px(36)}; line-height:1.4; white-space:nowrap; }
  .screen { position:absolute; left:0; right:0; bottom:0; height:${screen}px;
            border-radius:${px(48)} ${px(48)} 0 0; overflow:hidden; background:#fff; box-shadow:0 -10px 40px rgba(0,0,0,.25); }
  .screen img { display:block; width:100%; height:100%; }
  </style></head><body>
  <div class="band"></div>
  <div class="deco">
    <img src="${mark}" style="${far}:${px(40)}; top:${px(40)}; height:${px(170)}; transform:rotate(-14deg)">
    <img src="${mark}" style="${far}:${px(230)}; top:${px(210)}; height:${px(90)}; transform:rotate(10deg)">
  </div>
  <div class="brand"><span class="mark"><img src="${mark}"></span><span class="name">${config.brand.name}</span></div>
  <h1>${title}</h1><div class="rule"></div><p>${sub}</p>
  <div class="screen"><img src="${img}"></div>
  </body></html>`;
}

const browser = await puppeteer.launch({
  executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  headless: true,
  args: ['--hide-scrollbars', '--allow-file-access-from-files'],
});
const htmlDir = path.join(path.dirname(rawDir), 'compose-html');
fs.mkdirSync(htmlDir, { recursive: true });
// Screens the iOS build leaves out (lib/core/platform_features.dart): the Play set keeps them.
const IOS_EXCLUDED = new Set(['08-consultation']);
let n = 0;
for (const [devName, dev] of Object.entries(DEVICES)) {
  for (const [locale, loc] of Object.entries(config.locales)) {
    for (const shot of config.shots()) {
      if (IOS_EXCLUDED.has(shot.name)) continue;
      const raw = path.join(rawDir, locale, devName, `${shot.name}.png`);
      if (!fs.existsSync(raw)) { console.log('missing', raw); continue; }
      const cap = shot.caption[locale];
      const htmlFile = path.join(htmlDir, `${locale}-${devName}-${shot.name}.html`);
      fs.writeFileSync(htmlFile, page(dev, loc.dir, cap.title, cap.sub, pathToFileURL(raw).href));
      const p = await browser.newPage();
      await p.setViewport({ width: dev.W, height: dev.H, deviceScaleFactor: 1 });
      await p.goto(pathToFileURL(htmlFile).href, { waitUntil: 'load' });
      await p.evaluate(() => document.fonts.ready);
      const dir = path.join(outDir, locale, dev.folder);
      fs.mkdirSync(dir, { recursive: true });
      await p.screenshot({ path: path.join(dir, `${shot.name}.jpg`), type: 'jpeg', quality: 94 });
      await p.close();
      n++;
    }
  }
}
await browser.close();
console.log('composed', n);
