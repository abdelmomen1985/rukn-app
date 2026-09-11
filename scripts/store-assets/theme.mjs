/**
 * Design tokens. `themeColors` is imported from the app's own theme config so a
 * palette change in the app can never silently desync from the store listing.
 */
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const { themeColors } = require(join(ROOT, "theme.config.js"));

const light = (key) => themeColors[key].light;

export const T = {
  gold: light("primary"),
  darkGreen: light("darkGreen"),
  cream: light("cream"),
  background: light("background"),
  surface: light("surface"),
  foreground: light("foreground"),
  muted: light("muted"),
  border: light("border"),
  success: light("success"),
  warning: light("warning"),
  error: light("error"),
  // Tints used by the real screens that are not in the shared palette.
  gainGreen: "#4ade80",
  lossRed: "#f87171",
  nisabAmber: "#FFFBEB",
  goldSoft: "#FDF6E3",
};

export const REPO_ROOT = ROOT;
