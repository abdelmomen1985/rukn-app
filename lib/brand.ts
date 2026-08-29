/**
 * Single source of truth for everything that must be identical in the app, the
 * store listings and the privacy policy.
 *
 * ⚠️ These values ship in the binary and are checked by store reviewers against
 * the listing text — change them together with docs/PUBLISHING.md.
 */
import Constants from "expo-constants";

export const BRAND = {
  /** Legal / store-facing name (Google Play + App Store name is longer, see the guide). */
  name: "Rukn Thamin",
  nameAr: "ركن ثمين",
  /** Must match the footer of the hosted privacy policy. */
  legalEntity: process.env.EXPO_PUBLIC_LEGAL_ENTITY ?? "Rukn Thamin Trading",
  /** Reverse-DNS app id — permanent on Google Play, mirrors app.config.ts. */
  appId: process.env.EXPO_PUBLIC_APP_ID ?? "com.ruknthamin.app",
};

/**
 * Owned domain. Both stores require the privacy + account-deletion pages to be
 * live before submission, so override these in `.env` / the EAS production
 * profile with the real domain — the defaults are placeholders that will fail
 * a reviewer's link check.
 *
 *   EXPO_PUBLIC_WEB_ORIGIN=https://ruknthamin.com
 *   EXPO_PUBLIC_SUPPORT_EMAIL=support@ruknthamin.com
 *   EXPO_PUBLIC_WHATSAPP=966500000000
 */
const ORIGIN = (process.env.EXPO_PUBLIC_WEB_ORIGIN ?? "https://REPLACE-WEB-ORIGIN").replace(/\/+$/, "");

const SUPPORT_EMAIL = process.env.EXPO_PUBLIC_SUPPORT_EMAIL ?? "REPLACE@support.example";

export const WEB = {
  origin: ORIGIN,
  privacyPolicy: `${ORIGIN}/privacy`,
  accountDeletion: `${ORIGIN}/delete-account`,
  support: SUPPORT_EMAIL,
  privacy: process.env.EXPO_PUBLIC_PRIVACY_EMAIL ?? "REPLACE@privacy.example",
  /** WhatsApp Business number, international format, digits only. */
  whatsapp: process.env.EXPO_PUBLIC_WHATSAPP ?? "966000000000",
  /**
   * False while the placeholders above are still in place. Screens use it to
   * hide links that would open a dead URL — a production build can never see
   * `false` because app.config.ts refuses to build one, but a dev/preview build
   * should degrade quietly instead of shipping a broken button.
   */
  isConfigured: !ORIGIN.includes("REPLACE") && !SUPPORT_EMAIL.includes("REPLACE"),
};

/** Warns in dev builds when the operator has not filled in the real domain. */
export function assertPublishableBranding(): void {
  if (__DEV__ && !WEB.isConfigured) {
    console.warn(
      "[brand] EXPO_PUBLIC_WEB_ORIGIN / EXPO_PUBLIC_SUPPORT_EMAIL are placeholders. " +
        "Store listings require real, reachable privacy-policy and support URLs, and " +
        "`eas build --profile production` will refuse to build until they are set.",
    );
  }
}

export const APP_VERSION: string =
  Constants.expoConfig?.version ?? "1.0.0";

export const COPYRIGHT = `© ${new Date().getFullYear()} ${BRAND.legalEntity}. All rights reserved.`;
