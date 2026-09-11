/**
 * Store-listing text.
 *
 * The copy lives in `docs/PUBLISHING.md` (§4.2 English, §6 Arabic) and is read
 * out of it rather than duplicated here, so editing the guide is the only way to
 * change what gets pasted into Play — the two can't drift apart. Placeholders
 * for the owned domain are substituted, and every string is measured against the
 * Play limit before anything is written.
 */
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { REPO_ROOT } from "./theme.mjs";

export const DOMAIN = "rknthmin.com.sa";
export const SUPPORT_EMAIL = `support@${DOMAIN}`;
export const PRIVACY_URL = `https://${DOMAIN}/privacy`;
export const DELETION_URL = `https://${DOMAIN}/delete-account`;
export const WEBSITE = `https://${DOMAIN}`;

/** Play's hard character limits for the Main store listing form. */
export const LIMITS = {
  appName: 30,
  shortDescription: 80,
  fullDescription: 4000,
  releaseNotes: 500,
};

const fill = (s) =>
  s
    .replace(/support@<your-domain>/g, SUPPORT_EMAIL)
    .replace(/https:\/\/<domain>\/privacy/g, PRIVACY_URL)
    .replace(/https:\/\/<domain>\/delete-account/g, DELETION_URL)
    .replace(/<your-domain>/g, DOMAIN)
    .replace(/<domain>/g, DOMAIN)
    .trim();

/** First fenced block after `label`; `inline` reads a `backticked` value instead. */
function block(md, label, { inline = false } = {}) {
  const at = md.indexOf(label);
  if (at === -1) throw new Error(`docs/PUBLISHING.md: label not found — ${label}`);
  if (inline) {
    const m = /`([^`]+)`/.exec(md.slice(at, at + 400));
    if (!m) throw new Error(`docs/PUBLISHING.md: no inline value after ${label}`);
    return fill(m[1]);
  }
  const open = md.indexOf("```", at);
  const close = md.indexOf("```", open + 3);
  if (open === -1 || close === -1) throw new Error(`docs/PUBLISHING.md: no code block after ${label}`);
  return fill(md.slice(open + 3, close).replace(/^[a-z]*\n/, ""));
}

export async function loadListing() {
  const md = await readFile(join(REPO_ROOT, "docs", "PUBLISHING.md"), "utf8");

  const listing = {
    "en-US": {
      appName: block(md, "**App name (≤30):**", { inline: true }),
      shortDescription: block(md, "**Short description (≤80):**"),
      fullDescription: block(md, "**Full description (≤4,000):**"),
      releaseNotes: block(md, "**Release notes / What's new (≤500):**"),
    },
    ar: {
      // Play keeps the app name from the default listing unless a localised one
      // is supplied; the Arabic listing reuses it so the brand stays searchable.
      appName: null,
      shortDescription: block(md, "**Play short description (≤80):**"),
      fullDescription: block(md, "**Play/App Store full description (AR):**"),
      releaseNotes: block(md, "**Release notes (AR, ≤500):**"),
    },
  };

  const problems = [];
  for (const [locale, fields] of Object.entries(listing)) {
    for (const [field, value] of Object.entries(fields)) {
      if (value == null) continue;
      if (/REPLACE|<your-domain>|<domain>/.test(value)) {
        problems.push(`${locale}/${field}: unresolved placeholder`);
      }
      if ([...value].length > LIMITS[field]) {
        problems.push(`${locale}/${field}: ${[...value].length} chars, limit ${LIMITS[field]}`);
      }
    }
  }
  if (problems.length) {
    throw new Error(`Store listing text is not submittable:\n  - ${problems.join("\n  - ")}`);
  }
  return listing;
}

export const count = (s) => (s == null ? 0 : [...s].length);
