// App Store creative assets: the product-page header (and search-results) artwork.
//
// App Store Connect → version → Product Page Information → Header and Search Results.
// Specs (developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications):
//   universal 16:9  5244×2950 PNG, art safe area 1402×962 at (1921, 660); also usable in search results
//   header    21:9  3840×1646 PNG, art safe area 1646×661 at (1097, 493)
//   no alpha. Key art (the necklace) must sit inside the safe area; everything outside it is
//   "auxiliary" atmosphere that devices crop away. No text or logo: Apple sets the title and icon.
//
// usage (from rukn_flutter/): node scripts/store-assets/appstore/header.mjs [outDir]
// default outDir: ../store-assets/appstore/header
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../../..');
const outDir = path.resolve(process.argv[2] ?? path.join(repo, 'store-assets/appstore/header'));

const CHROME = [
  process.env.CHROME,
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
].find((p) => p && fs.existsSync(p));
if (!CHROME) throw new Error('No Chrome found; set CHROME=/path/to/chrome');

const SIZES = [
  { name: 'universal-16x9', W: 5244, H: 2950, safe: { x: 1921, y: 660, w: 1402, h: 962 } },
  { name: 'header-21x9', W: 3840, H: 1646, safe: { x: 1097, y: 493, w: 1646, h: 661 } },
];

const HERO = pathToFileURL(path.join(repo, 'assets/figma-assets/1586-4250.webp')).href;
// Where the necklace sits inside that 1920×1364 photo, as fractions of the photo box.
const SUBJECT = { w: 0.84, h: 0.81, cy: 0.445 };
const PHOTO_RATIO = 1920 / 1364;
const C = { green: '#07352B', deep: '#041d18', gold: '#D4AF37', goldSoft: '#EBCF6E' };

const hex = `data:image/svg+xml;utf8,${encodeURIComponent(
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 230"><g fill="none" stroke="#D4AF37" stroke-width="2.2">' +
    '<path d="M100 4 196 59v112l-96 55-96-55V59Z"/><path d="M100 22 180 68v94l-80 46-80-46V68Z"/></g></svg>',
)}`;

// Gold dust: deterministic so re-runs are byte-stable.
function dust(n, W, H, k) {
  let s = 7;
  const r = () => ((s = (s * 16807) % 2147483647) / 2147483647);
  return Array.from({ length: n }, () => {
    const x = r() * W, y = r() * H, d = (2 + r() * 5) * k, o = 0.15 + r() * 0.45;
    return `<i style="left:${x | 0}px;top:${y | 0}px;width:${d.toFixed(1)}px;height:${d.toFixed(1)}px;opacity:${o.toFixed(2)}"></i>`;
  }).join('');
}

const headerHtml = ({ W, H, safe }, guides) => {
  // Size the photo so the necklace fills the safe area, centred on it.
  const pw = Math.min(safe.w / SUBJECT.w, (safe.h / SUBJECT.h) * PHOTO_RATIO);
  const ph = pw / PHOTO_RATIO;
  const cx = safe.x + safe.w / 2;
  const cy = safe.y + safe.h / 2;
  const left = cx - pw / 2;
  const top = cy - SUBJECT.cy * ph;
  const k = ph / 1000; // decoration scale follows the subject size
  const hexes = [
    { dx: 0.72, dy: -0.05, s: 1.0, o: 0.16, r: 8 },
    { dx: 0.98, dy: 0.32, s: 0.42, o: 0.12, r: -12 },
    { dx: 1.25, dy: -0.42, s: 0.42, o: 0.08, r: 0 },
  ].flatMap(({ dx, dy, s, o, r }) => [-1, 1].map((side) => {
    const w = 700 * k * s, h = w * 1.15;
    const x = cx + side * dx * pw - w / 2, y = cy + dy * ph - h / 2;
    return `<div class="hex" style="left:${x | 0}px;top:${y | 0}px;width:${w | 0}px;height:${h | 0}px;opacity:${o};transform:rotate(${side * r}deg)"></div>`;
  })).join('');
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { width:${W}px; height:${H}px; overflow:hidden; background:${C.deep}; }
  .art { position:absolute; inset:0; overflow:hidden; background:${C.green}; }
  /* a velvet-only corner of the photo, enlarged and blurred, as the auxiliary-area fabric */
  .backdrop { position:absolute; inset:-${(80 * k) | 0}px; background:url("${HERO}") 0% 100%/520% auto no-repeat;
    filter: blur(${(30 * k) | 0}px) brightness(.8) saturate(1.05); transform:scaleX(-1); }
  .tint { position:absolute; inset:0;
    background: radial-gradient(${(pw * 0.9) | 0}px ${(ph * 0.75) | 0}px at ${cx}px ${cy}px, rgba(4,29,24,0), rgba(4,29,24,.55) 100%); }
  .photo { position:absolute; left:${left | 0}px; top:${top | 0}px; width:${pw | 0}px; height:${ph | 0}px;
    background:url("${HERO}") center/cover no-repeat;
    -webkit-mask-image: radial-gradient(closest-side, #000 74%, rgba(0,0,0,.45) 90%, transparent 100%); }
  .glow { position:absolute; left:${(cx - pw * 0.6) | 0}px; top:${(cy - ph * 0.42) | 0}px; width:${(pw * 1.2) | 0}px; height:${(ph * 0.84) | 0}px;
    border-radius:50%; filter:blur(${(60 * k) | 0}px); background:radial-gradient(circle, rgba(212,175,55,.26), rgba(212,175,55,0) 70%); }
  .hex { position:absolute; background:url("${hex}") center/contain no-repeat; }
  .dust i { position:absolute; border-radius:50%; background:${C.goldSoft}; box-shadow:0 0 ${(8 * k) | 0}px ${C.gold}; }
  .guide { position:absolute; left:${safe.x}px; top:${safe.y}px; width:${safe.w}px; height:${safe.h}px;
    outline:${Math.max(4, (6 * k) | 0)}px dashed #ff3b6b; }
</style></head><body><div class="art">
  <div class="backdrop"></div><div class="tint"></div><div class="glow"></div>${hexes}
  <div class="photo"></div>
  <div class="dust">${dust(Math.round((W * H) / 30000), W, H, k)}</div>
  ${guides ? '<div class="guide"></div>' : ''}
</div></body></html>`;
};

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'rukn-header-'));
function shoot(html, w, h, out) {
  const page = path.join(tmp, `${path.basename(out)}.html`);
  fs.writeFileSync(page, html);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  execFileSync(CHROME, [
    '--headless', '--no-sandbox', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
    '--allow-file-access-from-files', '--virtual-time-budget=5000',
    `--window-size=${w},${h}`, `--screenshot=${out}`, pathToFileURL(page).href,
  ], { stdio: 'ignore' });
  console.log('  ', path.relative(repo, out));
}

console.log('App Store header artwork →', path.relative(repo, outDir));
for (const size of SIZES) {
  const { name, W, H } = size;
  shoot(headerHtml(size, false), W, H, path.join(outDir, `${name}-${W}x${H}.png`));
  shoot(headerHtml(size, true), W, H, path.join(outDir, 'review', `${name}-${W}x${H}-safe-area.png`));
}
fs.rmSync(tmp, { recursive: true, force: true });
