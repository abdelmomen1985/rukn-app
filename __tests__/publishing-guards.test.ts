import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Regression guards for the things that get a build rejected by Google Play or
 * the App Store. They read the real source files, so re-introducing a sandbox
 * bundle id, a demo catalog, a fake payment form or a missing Arabic string
 * fails `pnpm test` instead of failing a store review two weeks later.
 *
 * Context: docs/PUBLISHING.md §1.
 */

const ROOT = join(__dirname, "..");

function filesIn(absDir: string, ext = /\.(ts|tsx)$/): string[] {
  const out: string[] = [];
  for (const entry of readdirSync(absDir)) {
    const full = join(absDir, entry);
    if (statSync(full).isDirectory()) out.push(...filesIn(full, ext));
    else if (ext.test(entry)) out.push(full);
  }
  return out;
}

const sourceFiles = ["app", "components", "lib", "hooks", "data", "server"].map((dir) =>
  filesIn(join(ROOT, dir)),
).flat();

const read = (rel: string) => readFileSync(join(ROOT, rel), "utf8");

describe("store identity", () => {
  const config = read("app.config.ts");

  it("does not ship a sandbox/manus bundle identifier", () => {
    // Check the actual default value, not documentation comments that warn about it.
    const bundleDefault = config.match(/EXPO_PUBLIC_APP_ID \?\? "([^"]+)"/)?.[1] ?? "";
    expect(bundleDefault).not.toMatch(/space\.manus/i);
    expect(bundleDefault).not.toMatch(/t20\d{12}/); // timestamped placeholder ids
  });

  it("uses a reverse-DNS id with a real domain segment", () => {
    const raw = config.match(/EXPO_PUBLIC_APP_ID \?\? "([^"]+)"/)?.[1];
    expect(raw).toBeTruthy();
    expect(raw).toMatch(/^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*){2,}$/);
    expect(raw).not.toMatch(/^(com\.example|io\.expo|host\.exp)/);
  });

  it("declares a stable deep-link scheme instead of a generated one", () => {
    expect(config).toMatch(/const scheme = "[a-z][a-z0-9]+";/);
    expect(config).not.toMatch(/manus\$\{/);
  });

  it("refuses to produce a production build with placeholder store URLs", () => {
    // A shipped `https://REPLACE-WEB-ORIGIN/privacy` is a guaranteed rejection,
    // so the failure has to happen at build time, not as a dev-only console.warn.
    expect(config).toMatch(/EAS_BUILD_PROFILE === "production"/);
    expect(config).toMatch(/EXPO_PUBLIC_WEB_ORIGIN/);
    expect(config).toMatch(/EXPO_PUBLIC_SUPPORT_EMAIL/);
    expect(config).toMatch(/throw new Error\(/);
    expect(read("lib/brand.ts")).toMatch(/isConfigured/);
  });

  it("does not autoVerify an intent filter that has no https data element", () => {
    // autoVerify is App Links only; on a custom-scheme filter it triggers a
    // domain verification that can never succeed.
    expect(config).not.toMatch(/autoVerify:\s*true/);
  });

  it("requests no microphone or notification permissions", () => {
    expect(config).not.toMatch(/permissions:\s*\[[^\]]*POST_NOTIFICATIONS/);
    expect(config).toMatch(/"android\.permission\.POST_NOTIFICATIONS"/); // blocked list
    expect(config).toMatch(/"android\.permission\.RECORD_AUDIO"/);
  });
});

describe("no demo data in release code", () => {
  const banned: [string, RegExp][] = [
    ["seeded portfolio assets", /mockPortfolioAssets/],
    ["seeded orders", /mockOrders/],
    ["mock data provider", /MockDataProvider|mock-data-provider/],
    [
      "value import of the seeded catalog (type-only imports are fine)",
      /^\s*import\s+(?!type\s)[^;\n]*from "@\/data\/products"/m,
    ],
  ];

  it.each(banned)("does not use %s", (_label, pattern) => {
    const hits = sourceFiles
      .filter((f) => pattern.test(readFileSync(f, "utf8")))
      .map((f) => f.replace(ROOT, ""));
    expect(hits).toEqual([]);
  });

  it("surfaces an error state when the catalog cannot be loaded", () => {
    const hook = read("hooks/use-store-catalog.ts");
    expect(hook).toMatch(/error/);
    expect(hook).toMatch(/refetch/);
    expect(hook).not.toMatch(/mockProducts/);
  });
});

describe("payments and claims", () => {
  it("collects no card credentials anywhere in the app", () => {
    const hits = sourceFiles
      .filter((f) => /cvv|cardNumber|cardHolder|creditcard.*TextInput/i.test(readFileSync(f, "utf8")))
      .map((f) => f.replace(ROOT, ""));
    expect(hits).toEqual([]);
  });

  it("sends consultation requests to the server instead of faking success", () => {
    const screen = read("app/invest/consultation.tsx");
    expect(screen).toMatch(/trpc\.consultation\.request\.useMutation/);
    expect(screen).not.toMatch(/setTimeout\([\s\S]{0,120}(confirmed|success)/i);
    expect(screen).not.toMatch(/\brating\s*:/i); // no fabricated social proof
    expect(screen).not.toMatch(/\breviews\s*:/i);
  });

  it("does not erase local data when account deletion failed", () => {
    // Wiping the device on a failed delete destroys the user's portfolio while
    // their account and orders still exist on the backend.
    const profile = read("app/(tabs)/profile.tsx");
    expect(profile).toMatch(/serverSideDone/);
    expect(profile).not.toMatch(/const result = customer[\s\S]{0,120}await wipeDeviceData\(\);/);
  });

  it("does not hard-code an invented specialist identity", () => {
    // A named advisor with credentials is a factual claim both stores check.
    const screen = read("app/invest/consultation.tsx");
    expect(screen).toMatch(/EXPO_PUBLIC_CONSULTANT_NAME/);
    expect(screen).toMatch(/consultationSpecialistGeneric/);
    expect(screen).not.toMatch(/name:\s*"[A-Z][a-z]+[ -][A-Z]/);
  });

  it("keeps account deletion reachable from the app", () => {
    const profile = read("app/(tabs)/profile.tsx");
    expect(profile).toMatch(/deleteAccount/);
    expect(profile).toMatch(/wipeDeviceData/);
    expect(read("lib/local-data.ts")).toMatch(/portfolio_assets/);
    expect(read("lib/medusa.ts")).toMatch(/customers\/me", \{ method: "DELETE"/);
  });
});

describe("localisation", () => {
  const i18n = read("lib/i18n.tsx");

  function localeBlock(locale: "en" | "ar"): string {
    const head = `  ${locale}: {`;
    const start = i18n.indexOf(head);
    expect(start).toBeGreaterThan(-1);
    let depth = 0;
    for (let i = start + head.length - 1; i < i18n.length; i += 1) {
      if (i18n[i] === "{") depth += 1;
      else if (i18n[i] === "}") {
        depth -= 1;
        if (depth === 0) return i18n.slice(start, i + 1);
      }
    }
    throw new Error(`unbalanced ${locale} block`);
  }

  const entries = (block: string) =>
    [...block.matchAll(/^ {4}([A-Za-z0-9_]+):\s*"((?:[^"\\]|\\.)*)",?$/gm)].map((m) => [m[1], m[2]] as const);

  it("Arabic exposes exactly the same keys as English", () => {
    const en = new Set(entries(localeBlock("en")).map(([k]) => k));
    const ar = new Set(entries(localeBlock("ar")).map(([k]) => k));
    expect([...en].filter((k) => !ar.has(k))).toEqual([]);
    expect([...ar].filter((k) => !en.has(k))).toEqual([]);
    expect(en.size).toBeGreaterThan(100);
  });

  it("Arabic values contain Arabic script (placeholders excepted)", () => {
    const allow = new Set(["0.0", "YYYY-MM-DD", "+9665XXXXXXXX", "name@domain.com"]);
    const untranslated = entries(localeBlock("ar"))
      .filter(([, v]) => v.length > 0 && !allow.has(v) && !/[\u0600-\u06FF]/.test(v))
      .map(([k, v]) => `${k} = ${v}`);
    expect(untranslated).toEqual([]);
  });
});
