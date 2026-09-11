/**
 * Google-font cache.
 *
 * Fetches the woff2 subsets once, inlines them as data: URIs and caches the
 * resulting stylesheet in `.fonts/fonts.css`, so a re-run is deterministic and
 * works with no network. If the very first fetch fails we fall back to the Noto
 * families that ship with the image — Arabic still shapes correctly, it just
 * looks less like the app.
 */
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const CACHE_DIR = join(HERE, ".fonts");
const CACHE_FILE = join(CACHE_DIR, "fonts.css");

// A browser UA is required or Google serves the ttf stylesheet instead of woff2.
const UA =
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

const FAMILIES = [
  "Cairo:wght@400;500;600;700;900",
  "Inter:wght@400;500;600;700;800;900",
  "Cormorant+Garamond:wght@600;700",
];

const FALLBACK_CSS = `
/* Network was unavailable when the cache was built — using system Noto. */
:root { --font-latin: "DejaVu Sans", sans-serif; --font-arabic: "Noto Sans Arabic", sans-serif;
        --font-display: "DejaVu Serif", serif; }
`;

async function inlineOne(spec) {
  const url = `https://fonts.googleapis.com/css2?family=${spec}&display=swap`;
  const res = await fetch(url, { headers: { "User-Agent": UA } });
  if (!res.ok) throw new Error(`${spec}: HTTP ${res.status}`);
  let css = await res.text();

  const urls = [...new Set(css.match(/https:\/\/fonts\.gstatic\.com\/[^)]+\.woff2/g) ?? [])];
  for (const fontUrl of urls) {
    const bin = await fetch(fontUrl);
    if (!bin.ok) throw new Error(`${fontUrl}: HTTP ${bin.status}`);
    const b64 = Buffer.from(await bin.arrayBuffer()).toString("base64");
    css = css.split(fontUrl).join(`data:font/woff2;base64,${b64}`);
  }
  return css;
}

export async function getFontCss() {
  if (existsSync(CACHE_FILE)) return readFile(CACHE_FILE, "utf8");

  await mkdir(CACHE_DIR, { recursive: true });
  try {
    const parts = [];
    for (const spec of FAMILIES) {
      process.stdout.write(`  fetching ${spec.split(":")[0].replace("+", " ")}…\n`);
      parts.push(await inlineOne(spec));
    }
    const css =
      parts.join("\n") +
      `\n:root { --font-latin: Inter, sans-serif; --font-arabic: Cairo, "Noto Sans Arabic", sans-serif;
        --font-display: "Cormorant Garamond", serif; }\n`;
    await writeFile(CACHE_FILE, css);
    return css;
  } catch (err) {
    console.warn(`  ⚠ font fetch failed (${err.message}) — falling back to system fonts`);
    return FALLBACK_CSS;
  }
}
