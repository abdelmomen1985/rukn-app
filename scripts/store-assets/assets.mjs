/**
 * Image embedding. Everything a page references is inlined as a data: URI so a
 * render depends on nothing but the HTML file itself.
 */
import { readFileSync } from "node:fs";
import { extname, join } from "node:path";
import { REPO_ROOT } from "./theme.mjs";

const MIME = { ".webp": "image/webp", ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".svg": "image/svg+xml" };
const cache = new Map();

/** `dataUri("assets/rknthmin-images/rings.webp")` — path is repo-relative. */
export function dataUri(relPath) {
  if (cache.has(relPath)) return cache.get(relPath);
  const abs = relPath.startsWith("/") ? relPath : join(REPO_ROOT, relPath);
  const mime = MIME[extname(abs).toLowerCase()];
  if (!mime) throw new Error(`dataUri(): unsupported file type for ${relPath}`);
  const uri = `data:${mime};base64,${readFileSync(abs).toString("base64")}`;
  cache.set(relPath, uri);
  return uri;
}

export const IMG = {
  logoMark: "/root/rukn-site/public/logo-sq.png",
  logoWide: "/root/rukn-site/public/logo.png",
  appLogo: "assets/figma-assets/1593-8372.webp",   // the mark the TitleBar renders
  // A clean product photograph: 1586-4213 has marketing copy baked into it,
  // which would double up with the hero text the screen draws.
  hero: "assets/figma-assets/1586-4250.webp",
  product: (file) => `assets/rknthmin-images/${file}`,
};
