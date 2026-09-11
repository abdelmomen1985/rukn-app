/**
 * Asset validation against the Play upload rules, read straight from the PNG
 * header so it needs no image library. A failure here is a hard stop: shipping a
 * file the console will reject wastes a submission slot.
 */
import { readFile, stat } from "node:fs/promises";

const MB = 1024 * 1024;

/** width, height and colour type from the IHDR chunk. */
export async function pngInfo(path) {
  const buf = await readFile(path);
  if (buf.readUInt32BE(0) !== 0x89504e47) throw new Error(`${path}: not a PNG`);
  return {
    width: buf.readUInt32BE(16),
    height: buf.readUInt32BE(20),
    colorType: buf[25],            // 2 = RGB, 6 = RGBA
    bytes: buf.length,
  };
}

export const RULES = {
  icon: { width: 512, height: 512, maxBytes: 1 * MB, noAlpha: true },
  feature: { width: 1024, height: 500, maxBytes: 15 * MB },
  screenshot: { minSide: 320, maxSide: 3840, maxBytes: 8 * MB, minLongSide: 1080, ratio: [9 / 16, 16 / 9] },
};

export async function check(path, kind, expected = {}) {
  const info = await pngInfo(path);
  const r = RULES[kind];
  const fail = [];

  const w = expected.width ?? r.width;
  const h = expected.height ?? r.height;
  if (w && info.width !== w) fail.push(`width ${info.width}, expected ${w}`);
  if (h && info.height !== h) fail.push(`height ${info.height}, expected ${h}`);
  if (r.maxBytes && info.bytes > r.maxBytes) fail.push(`${(info.bytes / MB).toFixed(2)} MB exceeds ${r.maxBytes / MB} MB`);
  if (r.noAlpha && info.colorType === 6) fail.push("has an alpha channel; Play requires an opaque icon");

  if (kind === "screenshot") {
    const short = Math.min(info.width, info.height);
    const long = Math.max(info.width, info.height);
    const ratio = info.width / info.height;
    if (short < r.minSide || long > r.maxSide) fail.push(`sides ${info.width}×${info.height} outside ${r.minSide}–${r.maxSide} px`);
    if (long < r.minLongSide) fail.push(`long side ${long} px is under ${r.minLongSide} px (not promotable)`);
    if (ratio < r.ratio[0] - 1e-6 || ratio > r.ratio[1] + 1e-6) fail.push(`aspect ${ratio.toFixed(3)} outside 9:16–16:9`);
  }

  return { info, fail };
}

export const fmtBytes = (n) => (n < MB ? `${Math.round(n / 1024)} KB` : `${(n / MB).toFixed(1)} MB`);
export { stat };
