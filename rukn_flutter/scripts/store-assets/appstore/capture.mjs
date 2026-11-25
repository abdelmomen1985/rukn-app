// Captures raw app screens from the Flutter web build at App Store sizes.
// usage: node capture.mjs <configPath> <outDir> [device] [shotName]
import puppeteer from 'puppeteer-core';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [, , configPath, outDir, onlyDevice, onlyShot] = process.argv;
const config = (await import(pathToFileURL(path.resolve(configPath)).href)).default;

// Raw screen area = full canvas minus the caption band (see compose.mjs).
export const DEVICES = {
  iphone69: { w: 440, h: 790, dpr: 3, mobile: true },  // 1320×2370 inside 1320×2868
  ipad13: { w: 800, h: 797, dpr: 2.58, mobile: true },  // 2064×2056 inside 2064×2752, zoomed for legibility
};

const origin = `http://127.0.0.1:${config.port}`;
const browser = await puppeteer.launch({
  executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  headless: true,
  args: ['--hide-scrollbars', '--lang=en-US'],
});

const shots = config.shots().filter((s) => !onlyShot || s.name === onlyShot);
for (const [devName, dev] of Object.entries(DEVICES)) {
  if (onlyDevice && onlyDevice !== devName) continue;
  for (const [locale, loc] of Object.entries(config.locales)) {
    for (const shot of shots) {
      const page = await browser.newPage();
      await page.setViewport({ width: dev.w, height: dev.h, deviceScaleFactor: dev.dpr, isMobile: dev.mobile, hasTouch: true });
      await page.setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1');
      await page.evaluateOnNewDocument((ls) => {
        for (const [k, v] of Object.entries(ls)) localStorage.setItem(k, v);
      }, loc.localStorage);
      await page.goto(`${origin}/#${shot.route}`, { waitUntil: 'load', timeout: 60000 }).catch(() => {});
      await new Promise((r) => setTimeout(r, Math.max(12000, shot.wait ?? config.navWait)));
      const dir = path.join(outDir, locale, devName);
      fs.mkdirSync(dir, { recursive: true });
      await page.screenshot({ path: path.join(dir, `${shot.name}.png`) });
      console.log('captured', locale, devName, shot.name);
      await page.close();
    }
  }
}
await browser.close();
