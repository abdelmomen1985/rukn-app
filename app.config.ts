// Load environment variables with proper priority (system > .env)
import "./scripts/load-env.js";
import type { ExpoConfig } from "expo/config";

// ---------------------------------------------------------------------------
// Store identity — these ship in the binary and are what both stores key on.
//   • The Android package name is PERMANENT after the first Play upload.
//   • The iOS bundle id must match App Store Connect + the AASA file.
// Override with EXPO_PUBLIC_APP_ID if you own a different reverse-DNS id.
// Never publish with a `space.manus.*` sandbox id — see docs/PUBLISHING.md §1.1.
// ---------------------------------------------------------------------------
const rawBundleId = process.env.EXPO_PUBLIC_APP_ID ?? "com.ruknthamin.app";
const bundleId =
  rawBundleId
    .replace(/[-_]/g, ".") // Replace hyphens/underscores with dots
    .replace(/[^a-zA-Z0-9.]/g, "") // Remove invalid chars
    .replace(/\.+/g, ".") // Collapse consecutive dots
    .replace(/^\.+|\.+$/g, "") // Trim leading/trailing dots
    .toLowerCase()
    .split(".")
    .map((segment) => {
      // Android requires each segment to start with a letter
      // Prefix with 'x' if segment starts with a digit
      return /^[a-zA-Z]/.test(segment) ? segment : "x" + segment;
    })
    .join(".") || "com.ruknthamin.app";

// Custom URL scheme for deep links. Must stay stable — it is baked into the
// intent filter and any Universal Link hand-off.
const scheme = "ruknthamin";

// ---------------------------------------------------------------------------
// Release gate. lib/brand.ts falls back to "https://REPLACE-WEB-ORIGIN" and
// friends so `pnpm dev` keeps working, but a production binary that ships those
// puts a dead Privacy Policy link in the Profile screen — an instant Apple
// 5.1.1 / Play "policy URL not reachable" rejection. Fail the BUILD instead.
// ---------------------------------------------------------------------------
const REQUIRED_RELEASE_ENV = [
  "EXPO_PUBLIC_WEB_ORIGIN",
  "EXPO_PUBLIC_SUPPORT_EMAIL",
  "EXPO_PUBLIC_PRIVACY_EMAIL",
  "EXPO_PUBLIC_LEGAL_ENTITY",
  "EXPO_PUBLIC_WHATSAPP",
] as const;

const isReleaseBuild =
  process.env.EAS_BUILD === "true" && process.env.EAS_BUILD_PROFILE === "production";

if (isReleaseBuild) {
  const unset = REQUIRED_RELEASE_ENV.filter((key) => {
    const value = process.env[key];
    // "966000000000" is the placeholder WhatsApp number in lib/brand.ts.
    return !value || /REPLACE/i.test(value) || value === "966000000000";
  });
  if (unset.length > 0) {
    throw new Error(
      `[app.config] Production build blocked: ${unset.join(", ")} still hold placeholder ` +
        `values. Set them in the eas.json "production" profile (or EAS secrets) with the ` +
        `real domain, support/privacy mailboxes, legal entity and WhatsApp number — the ` +
        `stores check every one of these links. See docs/PUBLISHING.md §1.9.`,
    );
  }
}

const env = {
  // App branding - update these values directly (do not use env vars)
  appName: "Rukn Thamin",
  appSlug: "ruknthamin-app",
  scheme,
  iosBundleId: bundleId,
  androidPackage: bundleId,
};

const config: ExpoConfig = {
  name: env.appName,
  slug: env.appSlug,
  version: "1.0.0",
  orientation: "portrait",
  icon: "./assets/images/icon.png",
  scheme: env.scheme,
  userInterfaceStyle: "automatic",
  newArchEnabled: true,
  ios: {
    supportsTablet: true,
    bundleIdentifier: env.iosBundleId,
    "infoPlist": {
        "ITSAppUsesNonExemptEncryption": false
      }
  },
  android: {
    adaptiveIcon: {
      backgroundColor: "#E6F4FE",
      foregroundImage: "./assets/images/android-icon-foreground.png",
      backgroundImage: "./assets/images/android-icon-background.png",
      monochromeImage: "./assets/images/android-icon-monochrome.png",
    },
    edgeToEdgeEnabled: true,
    predictiveBackGestureEnabled: false,
    package: env.androidPackage,
    // Nothing in the app posts notifications or records audio. Permissions that
    // autolinked libraries declare in their own manifests are stripped below,
    // because Play rejects "unused permissions" (§1.5 of docs/PUBLISHING.md).
    permissions: [],
    blockedPermissions: [
      "android.permission.POST_NOTIFICATIONS",
      "android.permission.RECORD_AUDIO",
      "android.permission.MODIFY_AUDIO_SETTINGS",
      "android.permission.FOREGROUND_SERVICE",
      "android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK",
      "android.permission.RECEIVE_BOOT_COMPLETED",
      "android.permission.READ_EXTERNAL_STORAGE",
      "android.permission.WRITE_EXTERNAL_STORAGE",
    ],
    intentFilters: [
      {
        // `autoVerify` only applies to http/https App Links, which this app does
        // not declare; leaving it on a custom-scheme filter makes Android run a
        // domain verification that can never pass and needs no assetlinks.json.
        action: "VIEW",
        data: [
          {
            scheme: env.scheme,
            host: "*",
          },
        ],
        category: ["BROWSABLE", "DEFAULT"],
      },
    ],
  },
  web: {
    bundler: "metro",
    output: "static",
    favicon: "./assets/images/favicon.png",
  },
  plugins: [
    "expo-router",
    [
      "expo-splash-screen",
      {
        image: "./assets/images/splash-icon.png",
        imageWidth: 200,
        resizeMode: "contain",
        backgroundColor: "#ffffff",
        dark: {
          backgroundColor: "#000000",
        },
      },
    ],
    [
      "expo-build-properties",
      {
        android: {
          buildArchs: ["armeabi-v7a", "arm64-v8a"],
          minSdkVersion: 24,
        },
      },
    ],
  ],
  experiments: {
    typedRoutes: true,
    reactCompiler: true,
  },
};

export default config;
