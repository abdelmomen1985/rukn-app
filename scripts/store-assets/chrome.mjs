/**
 * Headless-Chromium renderer.
 *
 * The Playwright browser that ships in this image is driven directly through its
 * CLI screenshot mode, so the pipeline needs no puppeteer/playwright dependency.
 * Pages are written next to `.fonts/` so the stylesheet resolves relatively and
 * the 2.6 MB of inlined webfonts is parsed from disk instead of being duplicated
 * into every page.
 */
import { execFile } from "node:child_process";
import { mkdir, writeFile, rm } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import { homedir } from "node:os";

const execFileAsync = promisify(execFile);
const HERE = dirname(fileURLToPath(import.meta.url));
const WORK = join(HERE, ".render");

const CANDIDATES = [
  join(homedir(), ".cache/ms-playwright/chromium-1243/chrome-linux64/chrome"),
  join(homedir(), ".cache/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell"),
  "/usr/bin/chromium",
  "/usr/bin/google-chrome",
];

function findChrome() {
  const found = CANDIDATES.find((p) => existsSync(p));
  if (!found) {
    throw new Error(
      "No Chromium binary found. Install one, or run `npx playwright install chromium`.",
    );
  }
  return found;
}

const CHROME = findChrome();
let seq = 0;

/**
 * Render `html` at exactly `width`×`height` device pixels into `outPath`.
 */
export async function shoot(html, { width, height, outPath }) {
  await mkdir(WORK, { recursive: true });
  await mkdir(dirname(outPath), { recursive: true });

  const pagePath = join(WORK, `page-${String(seq++).padStart(3, "0")}.html`);
  await writeFile(pagePath, html);

  await execFileAsync(
    CHROME,
    [
      "--headless",
      "--no-sandbox",
      "--disable-gpu",
      "--disable-lcd-text",              // grayscale AA: no colour fringing on export
      "--font-render-hinting=none",
      "--hide-scrollbars",
      "--force-device-scale-factor=1",
      "--allow-file-access-from-files",
      "--virtual-time-budget=4000",      // let webfonts and images settle
      `--window-size=${width},${height}`,
      `--screenshot=${outPath}`,
      pagePath,
    ],
    { timeout: 120_000, maxBuffer: 1 << 24 },
  );

  return outPath;
}

export async function cleanup() {
  await rm(WORK, { recursive: true, force: true });
}
