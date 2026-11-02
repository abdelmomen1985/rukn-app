# Publishing Guide — Google Play & App Store

**App:** Rukn Thamin (bilingual AR/EN gold jewelry store + gold/silver investment toolkit)
**Repo:** `rukn-app` · Expo SDK 54 · React Native 0.81 · expo-router · Medusa backend
**Last reviewed:** against the repo at `c4e0645`.

> **How to use this file**
> - §1 = code changes you **must** make before any store submission (read first — the repo is not publishable as-is).
> - §4 / §5 = field-by-field Play Console and App Store Connect walkthroughs with **copy-paste-ready text**.
> - §9 = the exact recommended answers to every questionnaire (data safety, ratings, export compliance, ads/IAP).
> - Appendix A = privacy policy you can deploy. Appendix B = printable checklist.
> - Items marked ⚠️ **VERIFY** are time-sensitive policy numbers — confirm them on the linked policy page the day you submit.

---

## 0. Canonical app facts (answer once, reuse everywhere)

Fill these in before you start; every screen in both consoles asks for some of them.

| Field | Value for this app | Notes |
|---|---|---|
| Store name (EN) | `Rukn Thamin: Gold & Jewelry` | 27/30 chars — both stores cap at 30 |
| Store name (AR) | `ركن ثمين: ذهب ومجوهرات` | Arabic storefronts are separate listings, not translations of the EN title |
| Subtitle / tagline (EN) | `Live gold price, Zakat & shop` | App Store subtitle (29/30 chars) |
| Developer / vendor | legal entity name as on your D-U-N-S / Play org | must match the privacy policy footer |
| Primary category | **Shopping** | Play: Shopping. App Store: Shopping (primary) + Finance (secondary) |
| Default language | English (US) `en-US` | then add Arabic (Saudi Arabia) `ar-SA` |
| Store countries | Saudi Arabia, UAE, Kuwait, Qatar, Bahrain, Oman, Egypt + Rest of World | Medusa shipping zones must match, else users order to unsupported regions |
| Content rating | 3+ (PEGI/Apple 4+) | no violence, UGC, or graphic content |
| Ads | **No ads** | declared in both consoles |
| In-app purchases | **No IAP** | see §1.6 for why your payment flows are exempt but the card form is not |
| Privacy policy URL | `https://<your-domain>/privacy` | **required** by both stores; must be live + reachable |
| Support URL / email | `support@<your-domain>` | Play also needs a phone number for org accounts |
| Target audience | 18+ primary (buyers/investors), not children | declare "not directed to children" |
| Bundle id / package | `com.ruknthamin.app` (reverse-DNS of a domain you own) | ✅ resolved — set via `EXPO_PUBLIC_APP_ID` env var |
| iOS min OS | 16.4 (Expo 54 default; verify per `expo-build-properties`) | ⚠️ VERIFY in `eas build` output |
| Android minSdk / targetSdk | minSdk 24 (set in `app.config.ts`), target ⚠️ VERIFY current Play minimum | §1.8 |

---

## 1. Pre-flight: code blockers in this repo

Do these **before** your first build. Skipping them causes instant rejection or, worse, an unfixable release.

> **Status (current HEAD):** §1.1–§1.7 are resolved in code **except §1.3 (the app icon is effectively blank — read it before you build)**. The remaining items are deployment steps (hosting URLs, filling `eas.json` credentials, verifying policy numbers). Run `pnpm test` — the `publishing-guards` suite catches regressions.

### 1.1 Bundle identifier (critical)

~~`app.config.ts` currently derives its ids from a generated sandbox value:~~

~~```ts
const rawBundleId = "space.manus.gold.jewelry.app.t20260219133945"; // ❌
```~~

~~Consequences: the Play package name is **permanent** (you cannot change it after the first release — you'd have to create a new app listing), and `space.manus.*` looks like an unpublished placeholder to reviewers.~~

**✅ RESOLVED.** `app.config.ts` now reads `EXPO_PUBLIC_APP_ID` (default `com.ruknthamin.app`), uses a fixed `scheme: "ruknthamin"`, and the `publishing-guards` test suite asserts no `space.manus` or timestamped ids remain. The deep-link scheme is stable. The intent filter declares the `ruknthamin://` custom scheme only, so `autoVerify` was removed — it applies to http/https App Links, and on a custom-scheme filter it starts a domain verification that can never pass. You only need `assetlinks.json` (§1.9) if you later add an `https://<domain>` intent filter.

### 1.2 App name / slug placeholders

~~- `env.appName: "Gold Jewelry"` → generic, and Play rejects names that are a generic product category ("Gold Jewelry", "Best Shop"). Use the brand + a qualifier: `Rukn Thamin: Gold & Jewelry`.~~
~~- `appSlug: "{{project_name}}"` → must be a real slug (`ruknthamin-app`); it ends up in EAS project URLs and `expo-constants`.~~
~~- `lib/i18n.tsx` → `copyright: "© 2026 Gold Jewelry. All rights reserved."` and `version: "Version 1.0.0"` are shown **inside** the app; both consoles check that in-app branding matches the listing. Update to the real legal entity.~~

**✅ RESOLVED.** `app.config.ts` now sets `appName: "Rukn Thamin"`, `appSlug: "ruknthamin-app"`. Version and copyright in `lib/i18n.tsx` are driven by `lib/brand.ts` (`APP_VERSION`, `BRAND.nameAr`, `COPYRIGHT`). Fill `EXPO_PUBLIC_LEGAL_ENTITY` in `.env` / `eas.json` production profile with the real legal entity name.

### 1.3 Logo URL is a signed, expiring CDN link

~~`logoUrl` points at a `manuscdn.com` presigned URL with `Expires=1798761600`. If it lapses, the app icon reverts to the template default between builds.~~

**⚠️ PARTLY RESOLVED — still a blocker.** The `logoUrl` field was removed from `app.config.ts`, so the icon now comes from `assets/images/icon.png`.

**That file is not usable as a store icon.** It is a 1024×1024 RGBA PNG whose artwork is a near-white outline "G" on white with a fully transparent centre (alpha extrema `0..255`, centre pixel `rgba(0,0,0,0)`). Expo flattens the alpha to white when it generates the iOS `AppIcon` set, so the shipped icon is an all-but-blank white square. `favicon.png` and `splash-icon.png` are byte-identical copies of the same file.

**Action before the first build:** replace `assets/images/icon.png` (and `favicon.png`, `splash-icon.png`, `android-icon-foreground.png`) with the real Rukn Thamin mark:
- 1024×1024 PNG, **no alpha channel**, no rounded corners, no drop shadow (Apple applies the mask itself).
- Full-bleed background — Apple rejects icons that are mostly transparent or blank.
- The Android adaptive foreground needs its content inside the safe zone (centre ~66% of the canvas).

### 1.4 Demo/mock data must be gone or labelled

~~Reviewers test the happy path of the advertised feature. This repo still mixes mock and live data:~~

~~| File | Risk | Action |
|---|---|---|
| `hooks/use-store-catalog.ts:25-29` — `products: isLive ? productsQuery.data! : mockProducts` | If Medusa is unreachable the shop silently renders the **USD mock catalog from `data/products.ts`**. Reviewers seeing fake prices/fake SKUs = Apple **4.2.2** (broken/misleading) and Play metadata-policy risk | return `isLive` + an error/empty state with a retry button; never show seeded products in a production build |
| `data/products.ts`, `data/orders.ts` (`mockOrders`), `lib/mock-data-provider.tsx` (mounted in `app/_layout.tsx:23`, no consumers) | dead demo data still in the binary; a future screen can wire it up by accident, and Play's APK scan may flag shipped fake content | delete the demo datasets and the provider before the release build |
| `lib/portfolio-provider.tsx:83-88` — first run seeds `mockPortfolioAssets` into AsyncStorage | the "portfolio" opens pre-populated with fake bars/rings and fake purchase prices → every ROI and zakat number is fiction in a reviewer's screenshots | start empty; the "No assets yet" state already exists (`noAssets` / `noAssetsSubtitle`) |
| `lib/i18n.tsx` `demoItemsInCart: "Some items in your cart are demo products and can't be ordered."` | the string itself announces an unfinished app | delete once demo SKUs are gone |

Set `EXPO_PUBLIC_MEDUSA_URL` to the **production** Medusa instance in the release profile (`.env` still points at the local `rukn-admin` backend) and confirm no UI path can reach `localhost:9000`.

**✅ RESOLVED.** All seeded data removed:
- `data/products.ts` / `data/orders.ts` — demo arrays deleted, types kept.
- `lib/mock-data-provider.tsx` — deleted; unmounted from `app/_layout.tsx`.
- `lib/portfolio-provider.tsx` — starts empty (no `mockPortfolioAssets` seeding).
- `hooks/use-store-catalog.ts` — no mock fallback; surfaces `error`/`isEmpty`/`refetch`.
- `components/catalog-state.tsx` — shared loading/error/empty component wired into index, cart, wishlist, product detail.
- `lib/i18n.tsx` — `demoItemsInCart` replaced by `productUnavailable` (for the rare case where a saved variant id no longer exists).
- `publishing-guards` test asserts no mock imports remain.

**⚠️ REMAINING:** Set `EXPO_PUBLIC_MEDUSA_URL` to the production Medusa URL in `eas.json` → `build.production.env` (already templated).

### 1.5 Unused permissions: notifications & microphone

~~`android.permissions: ["POST_NOTIFICATIONS"]` exists, `expo-notifications` is a dependency, and `plugins` sets `microphonePermission` for `expo-audio` — but **nothing in `app/`, `components/`, or `lib/` calls either API** (no `scheduleNotificationAsync`, no recording hook; `server/_core/voiceTranscription.ts` is only a helper with a commented-out example import).~~

~~Both stores cross-check declared permissions against observed behaviour: Play's *Unused permissions* policy refuses permissions with no user-visible feature, and Apple 5.1.1(ii) does the same for `NSMicrophoneUsageDescription`.~~

~~Do one of these:~~
~~- **Wire it up** (recommended for notifications — `server/_core/notification.ts` already exists): order-status push, plus a consultation reminder (the copy is already written: `consultationConfirmationNote: "A reminder will be sent 1 hour before your session"` — so reviewers *expect* it). Needs `google-services.json` / APNs key in EAS credentials, and the permission prompt must appear in context, not at launch.~~
~~- **Remove** `POST_NOTIFICATIONS` from `android.permissions`, drop `expo-notifications` / `expo-audio` from the app, and delete the `microphonePermission` string so the usage description never ships.~~

**✅ RESOLVED.** `app.config.ts` now sets `android.permissions: []` and `android.blockedPermissions` strips `POST_NOTIFICATIONS`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, and `RECEIVE_BOOT_COMPLETED` via `tools:node="remove"`. The `expo-audio` and `expo-video` plugins were removed. The packages remain in `package.json` (offline lockfile constraint) but contribute no manifest entries. The `publishing-guards` test asserts the blocked-permission list is present.

### 1.6 Consultation payment form (highest-risk item)

~~`app/invest/consultation.tsx` renders a manual card-entry flow (`consultationCardHolder`, `consultationCardNumber`, expiry, CVV) labelled "CREDIT / DEBIT CARD" with the line "Payments are encrypted and processed securely", and `handlePay` at `app/invest/consultation.tsx:146-157` is a **mock**: it only checks string lengths, then `setTimeout(..., 1800)` flips to `step: "confirmed"` and shows "Booking Confirmed!". No charge is taken. That combination — fake success plus a security claim — is precisely what Apple 2.5.2 and Play's deceptive-design policy reject, so it must be genuinely fixed, not explained away in the review notes.~~

~~- Never parse or store a PAN client-side — that is a PCI-DSS problem, and Apple's review does ask about it.~~
~~- For production, integrate a PSP (Moyasar, HyperPay, Amazon Payment Services, or Stripe) with their SDK — or a payment sheet the PSP renders — and keep raw card numbers out of your server.~~

~~Good news on policy: **your monetization is exempt from store billing.** Physical goods (Play Store Listing & In-app Billing policy) and real-world services (a 45-minute human video consultation, Apple 3.1.1) are paid with your own processor — Play Billing / Apple IAP are **not** required. Answer "No" to both "in-app purchases" questions (§9). If you later sell digital content (e.g. a paid research newsletter inside the app), that flips to mandatory IAP.~~

**✅ RESOLVED.** The card form, fake payment, and fake confirmation are gone. The screen now:
1. Shows the specialist profile (name, title, price, specialties — **no fabricated rating/reviews**).
2. Lets the customer pick a preferred date and one or more preferred time slots.
3. Collects name, email/phone, and optional notes.
4. Submits via `trpc.consultation.request.useMutation()` → server endpoint persists to MySQL (if `DATABASE_URL` is set) and attempts owner notification.
5. On success: shows a confirmation screen with a reference number and honest copy (“Our specialist will contact you within one business day to confirm the time and how to pay.”).
6. On failure: shows an inline error with retry + direct contact fallback (mailto / WhatsApp) — the form data is preserved so the user doesn't lose their input.

**No payment is collected in-app.** The session fee is communicated as a fact (“{fee} SAR session fee”) and collected off-platform after the specialist confirms. This is the correct policy position: physical goods + real-world human services are exempt from both Play Billing and Apple IAP (Apple 3.1.1(e), Play physical-goods exemption). Answer “No” to both “in-app purchases” questions (§9).

**Server endpoint:** `server/consultationRouter.ts` — validates with zod, rate-limits per IP, persists to `consultationRequests` table (drizzle schema + migration), and calls `notifyOwner` best-effort. Returns `{ received: boolean, reference?: string }`. When `DATABASE_URL` is not configured, returns `{ received: false }` honestly.

**✅ RESOLVED (identity).** The invented advisor ("Ahmed Al-Rashidi, Gold & Silver Market Advisor") is no longer hard-coded. `CONSULTANT` in `app/invest/consultation.tsx` now reads the real person from the environment and, until they are supplied, the card shows the generic, truthful `consultationSpecialistGeneric` label ("Rukn Thamin gold specialist" / "أخصائي الذهب في ركن ثمين") with no title and no credential claim:

```
EXPO_PUBLIC_CONSULTANT_NAME=…        EXPO_PUBLIC_CONSULTANT_NAME_AR=…
EXPO_PUBLIC_CONSULTANT_TITLE=…       EXPO_PUBLIC_CONSULTANT_TITLE_AR=…
EXPO_PUBLIC_CONSULTATION_FEE_SAR=350
```

**⚠️ REMAINING:** set those vars to the person who actually runs the session, and replace the `💼` avatar emoji with a photo the business has the rights to. Fabricated credentials = App Store 2.3.1 / 4.2 and Play misleading metadata.

### 1.7 Account creation ⇒ account **deletion** is mandatory

~~`app/auth.tsx` + `lib/medusa.ts` create customer accounts. Both stores now require deletion:~~

~~- **Play:** in-app **and** on a public web page (Settings → "Delete account" plus a documented URL). Since 2024 this applies to all apps with account signup, not just social apps.~~
~~- **App Store:** Apple 5.1.1(v) — in-app delete button, no support-ticket-only flows, no "contact us" as the only path.~~

~~Implement against Medusa (`/store/customers/{id}/delete` or an admin route) before submission; put the delete path on Profile → Account Settings. Also honour data export/portability requests in your policy text.~~

**✅ RESOLVED.** `app/(tabs)/profile.tsx` now has a destructive "Delete account" row that opens a confirmation modal. The flow:
1. If signed in: calls `deleteAccount()` in `lib/medusa.ts` → `DELETE /store/customers/me` → clears the Medusa token.
2. **Only when the server side actually succeeded** (or there was no session): calls `wipeDeviceData()` in `lib/local-data.ts` → clears AsyncStorage keys (portfolio, wishlist, cart, trips, spot prices cache) + SecureStore keys (session token, Manus user info). A failed delete leaves both the session and the local data intact so the user can retry — wiping there would destroy their portfolio while the account still exists.
3. On success: shows `deleteAccountDone` alert.
4. On failure (404/405 = Medusa doesn't support deletion yet, or a network error): keeps the session and shows a fallback alert — Cancel, Email support (`mailto:`), and Open web deletion page (only when `WEB.isConfigured`). A 401/403 clears the stale token but is *not* reported as a deletion.
5. If not signed in: the same row offers `wipeDeviceData` only ("Erase device data"), and reports it as `deviceDataWiped`, not as an account deletion.

**⚠️ REMAINING:**
- Host `<domain>/delete-account` with a web form that calls Medusa admin API (or a serverless function). Both stores require this URL to be live.
- Confirm the deployed Medusa build actually implements `DELETE /store/customers/me`. If it answers 404/405, the in-app button can only hand the user off to the web page — Apple 5.1.1(v) wants the in-app path to work.
- Fill the release env vars (below) in the `eas.json` production profile with real values.

### 1.7b Release env vars are enforced at build time

`lib/brand.ts` falls back to `https://REPLACE-WEB-ORIGIN`, `REPLACE@support.example` and `966000000000` so `pnpm dev` keeps working. Shipping those means the Profile → Privacy Policy row opens a dead URL — an instant Apple 5.1.1 / Play "policy URL not reachable" rejection.

Two guards now exist:

| Guard | Where | What it does |
|---|---|---|
| Build gate | `app.config.ts` | When `EAS_BUILD=true` **and** `EAS_BUILD_PROFILE=production`, it **throws** if `EXPO_PUBLIC_WEB_ORIGIN`, `EXPO_PUBLIC_SUPPORT_EMAIL`, `EXPO_PUBLIC_PRIVACY_EMAIL`, `EXPO_PUBLIC_LEGAL_ENTITY` or `EXPO_PUBLIC_WHATSAPP` is unset or still a placeholder. The build fails instead of the review. |
| Runtime fallback | `lib/brand.ts` → `WEB.isConfigured` | Dev/preview builds hide the Privacy Policy row and the "Open deletion page" button rather than rendering a broken link; `assertPublishableBranding()` (called from `app/_layout.tsx`) logs a warning. |

So before the first production build, replace every `REPLACE…` in the `eas.json` `production` profile:

```jsonc
"production": {
  "autoIncrement": true,
  "env": {
    "EXPO_PUBLIC_MEDUSA_URL": "https://rknadmin.kayanprojects.online",
    "EXPO_PUBLIC_MEDUSA_PUBLISHABLE_KEY": "pk_…",   // set explicitly; don't rely on .env
    "EXPO_PUBLIC_WEB_ORIGIN": "https://ruknthamin.com",
    "EXPO_PUBLIC_SUPPORT_EMAIL": "support@ruknthamin.com",
    "EXPO_PUBLIC_PRIVACY_EMAIL": "privacy@ruknthamin.com",
    "EXPO_PUBLIC_LEGAL_ENTITY": "<legal entity exactly as on the Play/ASC account>",
    "EXPO_PUBLIC_WHATSAPP": "9665XXXXXXXX"
  }
}
```

The `submit.production` block still holds `REPLACE@apple.example`, `REPLACE_ASC_APP_ID` and `REPLACE_TEAM_ID`; `eas submit` fails on those, which is safe (nothing ships), but fill them at the same time.

### 1.8 Target API level & build config

⚠️ **VERIFY** the current Play minimum at <https://developer.android.com/distribute/best-practices/develop/target-sdk> before you upload — a build below the minimum is *refused*, not warned.

Expo 54 / RN 0.81 already satisfies recent requirements, but check:

```ts
// app.config.ts
android: {
  adaptiveIcon: { /* keep — required look on Android 8+ */ },
  edgeToEdgeEnabled: true,        // ✅ keep, required by Android 15/16 look
},
plugins: [[ "expo-build-properties", { android: { buildArchs: ["armeabi-v7a","arm64-v8a"], minSdkVersion: 24 } }]]
```

- `buildArchs` omits `x86_64`. Fine for the store (devices only) — but your Play **pre-launch / Vitals** report will be thinner and Android emulator CI can't run x86. Add `"x86_64"` for internal test builds.
- Release Android as **AAB** (Play requires AAB for new apps) — EAS does this by default for `--profile production`.

### 1.9 Files you must host (not code)

| Path | Used by | Purpose |
|---|---|---|
| `https://<domain>/.well-known/assetlinks.json` | Android App Links — **only if** you add an `https` intent filter with `autoVerify: true` (the app currently ships a custom scheme only) | SHA-256 of your **upload** and **signing** cert |
| `https://<domain>/.well-known/apple-app-site-association` | Universal Links / deep links | `appID` = `<TeamID>.<bundleId>`, paths array |
| `https://<domain>/privacy` | both consoles | Appendix A |
| `https://<domain>/delete-account` | Play (web deletion URL) | Appendix A.5 |

`assetlinks.json` template:

```json
[{ "relation": ["delegate_permission/common.handle_all_urls"],
   "target": { "namespace": "android_app",
     "package_name": "com.ruknthamin.app",
     "signing_key_fingerprint_hashes": [
       "<64-hex from Play Console > Setup > App signing (both upload and app key)>",
       "<SHA-256 from: keytool -list -v -keystore upload.jks -alias upload>"]}}]
```

### 1.10 Export compliance (mostly already done)

`ios.infoPlist.ITSAppUsesNonExemptEncryption = false` ✅ — that is the correct declaration (TLS only, no custom crypto) and saves you the Apple export-compliance interview. If you add Firebase Auth, RevenueCat, or any SDK that ships its own crypto, flip the value / re-answer the questionnaire. On Play, answer the export-compliance questions consistently with this (§9.4).

---

## 2. Accounts, fees, and lead times

| Item | Google Play | Apple App Store |
|---|---|---|
| Account | Play Console, **$25 one-time** | Apple Developer Program, **$99/year** |
| Individual vs org | org account needs Google paid verification (2–5 days) + a D-U-N-S number | org account needs D-B-A / D-U-N-S (2–4 weeks for a brand-new company) — start this first |
| Test requirement ⚠️ VERIFY | new personal accounts must run a **14-day closed test with ≥12 testers** before production | TestFlight: up to 10,000 external testers, metadata review for external builds (usually <24h) |
| First-review duration | 1–7 days (longer for Finance/Shopping + org verification) | 24–48h typical; 3–5 days if 4.x or 5.x flags |
| Re-review after rejection | 1–3 days | 24h typical |
| Key contacts | add a phone number the day you create the account | add App Store Review contact info + demo account |

**Recommended sequencing:** legal entity + D-U-N-S → both dev accounts → Apple Certificates/EAS credentials (longest pole) → §1 code fixes → internal test builds → 1-week soak → staged production.

---

## 3. Build & ship commands (Expo / EAS)

```bash
# one-time
npm i -g eas-cli@latest          # or: pnpm dlx eas-cli
npx expo install expo-updates    # optional, for OTA JS fixes
eas login                         # same account as your Expo/EAS project
npx expo prebuild --clean        # sanity-check the generated native projects
eas build:configure               # creates eas.json
eas credentials                  # Android Keystore + APNs key (EAS-managed is fine)

# eas.json — production profiles that match the store requirements
cat > eas.json <<'JSON'
{
  "cli": { "version": ">= 12.0.0", "appVersionSource": "remote" },
  "build": {
    "development": { "developmentClient": true, "distribution": "internal" },
    "preview":     { "distribution": "internal", "channel": "preview" },
    "production":  { "autoIncrement": true, "channel": "production",
                     "env": { "NODE_ENV": "production",
                              "EXPO_PUBLIC_MEDUSA_URL": "https://api.<your-domain>" } }
  },
  "submit": {
    "production": {
      "android": { "serviceAccountKeyPath": "./pc-api-key.json", "track": "internal", "releaseStatus": "draft" },
      "ios":     { "appleId": "dev@<your-domain>", "ascAppId": "<App Store Connect App ID>", "teamId": "<TEAMID>" }
    }
  }
}
JSON

eas build -p android --profile production      # produces the .aab Play requires
eas build -p ios     --profile production      # produces the .ipa
eas submit -p android --profile production     # pushes to the internal track
eas submit -p ios     --profile production     # pushes to App Store Connect
eas update --channel production --rollout 1.0  # optional OTA JS-only fix
eas channel:promote production --platform all  # promote a preview build to production
```

**Versioning rules** (both stores are strict):
- `version` in `app.config.ts` (`1.0.0`) is user-facing and must match what you enter in the consoles.
- `buildNumber` (iOS) and `versionCode` (Android) must **increase monotonically**; `autoIncrement: true` handles it.
- Never submit two different binaries with the same `version` + `buildNumber`.

---

## 4. Google Play Console — step by step

**Path:** Play Console → *Create app* → fill **App information** → *Core developer target* → then, per release, the four left-nav tabs: **Main store listing · Store settings · Category · Policy** · then **Testing → Production → Create release**.

### 4.1 App information

| Field | Recommended input |
|---|---|
| App name | `Rukn Thamin: Gold & Jewelry` |
| Default language | English (United States) |
| Package name | `com.ruknthamin.app` — **chosen once from a dropdown on the first upload, never editable.** Select it in *App information* only after your first AAB exists; the console derives it from the bundle. |
| User-facing question: "Is your app a government app?" | No |
| Category | **Shopping** (Play allows 1 primary + up to 5 additional categories via *App categories* — add Shopping, Finance) |
| Tags ⚠️ VERIFY availability | `gold price saudi arabia`, `jewelry shopping`, `gold investment`, `zakat calculator`, `21k gold rate` |

### 4.2 Store listing — copy-paste text

**App name (≤30):** `Rukn Thamin: Gold & Jewelry`

**Short description (≤80):** *(73 chars — Play counts the spaces)*
```
Live gold rates in SAR, zakat calculator, quote comparison, jewelry shop.
```

**Full description (≤4,000):**
```
Rukn Thamin is the gold companion for Saudi buyers — real-time prices, honest numbers, and certified jewelry in one bilingual (Arabic/English, RTL-ready) app.

■ LIVE GOLD & SILVER PRICES
Track 24K, 22K, 21K, 18K gold plus silver, platinum and palladium in Saudi Riyals per gram, updated from live spot data. Switch freely between grams, tolas, ounces and mithqal, and see exactly when a quote was refreshed.

■ PRICE A PIECE IN SECONDS
The gold value calculator turns weight + karat + making charges + VAT into what a piece should actually cost. The weight converter handles grams, tolas, ounces and mithqal in one tap.

■ MY INVESTMENTS
Add every gold bar, coin and piece of jewelry you own — purchase price, making charges and VAT included. Rukn Thamin revalues the whole portfolio at today's spot price and shows current value, gain/loss, percentage and annualized return, plus an allocation chart by metal. Pull to refresh at any time.

■ SHOPPING TRIPS (جولات التسوق)
Going jeweller-hopping? Plan a trip, log each store's quote — price, weight, karat, VAT included or not, local or imported workmanship — and let the app flag each quote as excellent, fair or high against the live market reference. Compare side by side, add notes, then close the trip with the best deal in hand.

■ ZAKAT CALCULATOR
Automatic nisab check against 85 g of 24K gold, zakatable value and 2.5% due calculated from your live portfolio, with a per-asset breakdown. A simplified estimate — consult a qualified scholar for your final assessment.

■ THE SHOP
Necklaces, rings, bangles and bars in certified gold, priced live from the 21K rate, with special offers and curated collections. Search, save to your wishlist and check out in the app: home delivery, branch pickup or safekeeping in the branch vault; pay by bank transfer or mada/card. Follow each order's progress, download tax invoices and verify bar certificates.

■ EXPERT CONSULTATION
Book a private session with a market specialist for buy/sell and diversification guidance, at a time that suits you. Paid sessions are settled on a secure hosted checkout.

■ BUILT FOR THE KINGDOM
Arabic and English throughout with full right-to-left layout, Saudi Riyal pricing, VAT-aware calculations and 21K as a first-class karat. Works on phones and tablets.

As a guest, your portfolio, wishlist and trip notes stay on your device; sign in with your phone number to sync your portfolio to your account. No ads, no data resale.

Questions, wholesale orders or custom pieces: support@<your-domain>
```

**Release notes / What's new (≤500):**
```
First public release.
• Live gold, silver, platinum & palladium rates in SAR/gram (24K–18K)
• Portfolio tracker: value, gain/loss, annualized return, allocation by metal
• Shopping trips: log store quotes and compare against the market reference
• Zakat calculator with automatic nisab check (85 g of 24K gold)
• Gold value calculator & weight converter (g, tola, ounce, mithqal)
• Jewelry shop: search, wishlist, cart, checkout, order history
• Consultation booking
• Arabic + English, full RTL
```
*495 chars — Play caps release notes at 500; keep future notes shorter.*

### 4.3 Store settings

- **Email / phone / website:** reachable, matching the privacy policy.
- **Privacy policy:** `https://<domain>/privacy`
- **Ads: No** (no ad SDKs in this project — verified: no `react-native-firebase` ads, no AdMob).
- **In-app purchases: No.** Explanation for the reviewer when asked: *"Jewelry is physical goods; consultations are real-world services. Both are paid through our own PSP and are outside the scope of Play Billing."*
- **Access required:** turn **On** and paste §9.6 credentials so the reviewer can sign in.

### 4.4 Content rating (IARC) — recommended answers

| Question | Answer |
|---|---|
| Nudity / sexual content | None |
| Violence | None |
| Profane or crude language | None |
| Drugs / tobacco / alcohol references | None |
| Horror / fear themes | None |
| Gambling / simulated gambling | None |
| Location sharing | None |
| User-generated content | None |
| Messaging / chat / comments | None |
| Personal info displayed publicly | None (order data is private to the account) |
| **Digital purchases (IARC question: in-app purchases of digital content)** | **No** — nothing digital is sold; goods are physical and consultations are human services |
| Monetization questionnaire (separate from IARC) | "In-app purchases of physical goods / real-world services: Yes" |
| Target audience | 13+ / 18+ only — uncheck under 13 |
| Theme (visual) | uncheck "cartoon-style" if it would skew child-directed |

Result: **Everyone / 3+**. Keep "Not directed to children" — jewelry buying and zakat math are adult features, and that declaration is what exempts you from the Families policy.

### 4.5 Data safety — exact declarations

Play cross-checks this against your privacy policy and an actual APK scan. Declare what the code does, nothing more.

| Data type | Collected? | Purpose | Shared? | Encryption in transit | User can delete |
|---|---|---|---|---|---|
| Name, email, phone (account signup) | Yes | Account management, order fulfilment | No (payment processor sees what it needs) | Yes (TLS) | Yes |
| Delivery address | Yes | App functionality (shipping) | No | Yes | Yes |
| Purchase/order history | Yes | App functionality, developer analytics | No | Yes | Yes |
| Wishlist / cart contents | Yes (device storage; also server when signed in) | App functionality | No | Yes | Yes |
| Portfolio assets, quotes, trip notes | Yes (AsyncStorage on device) | App functionality | No | Yes | Yes |
| Credentials (Medusa token) | Yes — `expo-secure-store`, **not shared**, ephemeral | Account authentication | No | Yes | Yes |
| Approximate device/location | **No** — no location SDK | — | — | — | — |
| Advertising ID / device ID | **No** — no analytics, crash-reporting or ad SDK in `package.json` | — | — | — | — |
| Diagnostics / crash logs | Only server request logs (IP, user id, route, timestamp) | App functionality / security | No | Yes | Yes (retention ≤30 days) |

Also declare **Data retention** ("we delete on account deletion, server logs within 30 days") and **"Encrypted in transit: Yes"** and **"Deletable on user request: Yes"** — that last one requires §1.7 to actually be implemented.

If asked "Is this app for children under 13?" → **No.**
If asked about **financial/banking features** — Play's sensitive-permissions form: your app is an investment *tracker*, it does not move money and holds no bank credentials. State that in the permission/access justification.

### 4.6 Testing tracks (do not skip the ladder)

```
Internal testing (≤100 testers, no review wait)
   → Closed testing  ⚠️ VERIFY minimum 12 testers × 14 days for your account type
   → Open testing (optional, public opt-in URL — good for the 21K/quote features)
   → Production, staged rollout 5 → 20 → 50 → 100%
```

Before production, run **Pre-launch report** and fix anything red; check *Android Vitals* (ANR < 0.47%, crash rate < 1.09% thresholds) — with the New Architecture (`newArchEnabled: true`) plus Reanimated 4/worklets, watch for gesture-handler init crashes on low-end armeabi-v7a devices.

---

## 5. App Store Connect — step by step

**Path:** App Store Connect → *My Apps* → **+** → *New App* → *App Information* · then **iOS App** in the left nav → *Prepare for Submission*.

### 5.1 Create the record

| Field | Recommended input |
|---|---|
| Language | English (U.S.) |
| Name | `Rukn Thamin: Gold & Jewelry` (≤30) |
| Subtitle | `Live Gold Price, Zakat & Shop` (29/30) — fallback: `Live Gold Rates & Zakat` (23/30) |
| Bundle ID | select `com.ruknthamin.app` from the list (register in *Idents & Profiles* or let EAS create it) |
| SKU | `rukn-thamin-ios-1` |
| User access | Full access |

### 5.2 Pricing & Availability
- Pricing: **Free** (the app itself costs nothing; purchases are physical goods/services).
- Availability: countries from §0. Schedule a release (**Manually release this version** for the first launch, so you control the moment).
- **Rights to develop the app:** tick the confirmation.

### 5.3 App Information
- Primary **Shopping**, Secondary **Finance**.
- Demo URL: your production web storefront (if any). Privacy Policy URL, Support URL.
- Age Rating → start questionnaire (§9.2). Content Rights: no third-party characters.

### 5.4 Version release — the text fields

**Promotional text (≤170) — editable without review, use it for offers:**
```
Live SAR gold rates, zakat calculator and shopping-trip quote comparison — plus certified 21K pieces. Arabic & English.
```

**Description (≤4,000):**
```
Real-time gold prices in Saudi Riyals, an honest way to value the jewelry you already own, and a shop for certified pieces — all in one bilingual app.

WHAT YOU CAN DO

LIVE RATES
Gold at 24K, 22K, 21K and 18K, plus silver, platinum and palladium, in SAR per gram, refreshed from live spot data with a visible update time.

PORTFOLIO TRACKER
Add each bar, coin, or piece with its weight, karat, purchase price, making charges and VAT. See total value at today's price, gain and loss per asset and overall, percentage and annualized return, plus allocation by metal in one chart. Pull to refresh.

SHOPPING TRIPS
Comparing jewellers in Riyadh or Jeddah? Create a trip, then record each store's quote — total price, weight, karat, whether VAT is included, local or imported workmanship. Each quote is graded excellent, fair or high against the market reference, so you know the best stop before you buy.

GOLD VALUE CALCULATOR
Weight plus karat plus making charges plus VAT equals what a piece should cost. The converter switches between grams, tolas, ounces and mithqal.

ZAKAT CALCULATOR
Automatic nisab check against 85 g of 24K gold, your zakatable value and the 2.5% due, broken down by asset. A simplified estimate based on current spot prices — please consult a qualified scholar for a full assessment, including Hawl.

THE SHOP
Browse necklaces, rings, bracelets and earrings, search and filter by category, save favourites to your wishlist, and check out. We confirm delivery and payment directly, and you can follow every order in your order history.

CONSULTATIONS
Request a private 45-minute video session with a market specialist — personalized analysis of your portfolio, advice on buying, selling and diversification. Our team replies to confirm the time and how to pay.

ARABIC AND ENGLISH
Full right-to-left layout, Saudi Riyals, VAT-aware math and 21K treated as a first-class karat. Works on iPhone and iPad.

PRIVACY
Your portfolio, wishlist and shopping-trip notes live on your device. Sign in only if you want to place an order. No ads, no trackers, no data resale. Deletion takes one tap in Settings.

Support: support@<your-domain> · Privacy: https://<your-domain>/privacy
```

**Keywords (≤100, comma-separated, no repeats of words already in name/subtitle):**
```
gold rate,21k,silver,zakat,nisab,converter,jewelry,portfolio,saudi,سعر الذهب,زكاة,مجوهرات
```
*89/100 chars. No spaces after commas, no words already in the name/subtitle, no competitor names.*

> ⚠️ Every sentence above is a **claim the reviewer will test**. "Deletion takes one tap in Settings" is only publishable after §1.7 is built; "no trackers" is only true while no analytics SDK is added; "updated from live spot data" is only true once `EXPO_PUBLIC_MEDUSA_URL`/price feed point at production. Trim the description to what the shipped binary actually does.

**What's New (≤4,000 — reuse Play text from §4.2).**

**Screenshot captions (optional, Apple only — 170 chars, shown under each image):**
```
1. Live gold rates in SAR — 24K to 18K, updated seconds ago
2. Your portfolio revalued at today's spot price, with gain and annualized return
3. Log each store's quote and see instantly which one is fair
4. Nisab check and 2.5% zakat due, calculated from your own holdings
5. Weight and karat to real value, with making charges and VAT
6. Certified pieces, wishlist, cart and order history in one place
```

**Review Notes (§9.6) + Contact info + Attachment:** "Demo" test account credentials, plus one line explaining payment: *"Physical jewelry is paid on delivery confirmation and consultations are real-world services, so no in-app purchases are offered; both fall outside IAP under Guidelines 3.1.1 and 3.1.3(e)."*

### 5.5 App Review / compliance questions on this screen
- **Encryption (Export Compliance):** already answered `No` via `ITSAppUsesNonExemptEncryption=false`. If you removed that key, answer the questionnaire or the build is blocked from testing.
- **Content rights / third-party marks:** none. Confirm no real jeweller brands are named in the catalog imagery.
- **Attribution for price data:** gold-api.com spot feed — add "Prices from <provider>" in your privacy/about screen if their licence requires it; Apple 5.2.x expects accurate data provenance.
- **Microphone / notifications:** see §1.5 — if you keep `expo-audio`'s `microphonePermission`, there must be a visible feature that records (e.g. voice search), and `NSMicrophoneUsageDescription` must say why in plain language. Apple 5.1.1(ii) rejects permissions without matching functionality, and a launch-time prompt without context invites 5.1.1(i).
- **IDFA / Tracking:** no SDK requires it → App Tracking Transparency prompt not needed; declare "does not track" in App Privacy.

### 5.6 Screenshots
⚠️ **VERIFY** the required device set for the current Xcode/iOS cycle in App Store Connect — the required sizes change with each new flagship.
- iPhone: **6.9″ 1320×2868** (mandatory) and/or 6.7″ 1290×2796 + **13″ iPad 2064×2752** because `supportsTablet: true`. If you cannot make the iPad layout look right, set `supportsTablet: false` and skip the iPad set (that also avoids 4.x iPad-clipping rejections).
- 3–10 images per size class, JPG/PNG, no status-bar junk, no "best app" claims, no pricing in images, and the same UI as the shipped build.
- Generate every size from one source with a small script (e.g. add `scripts/generate_screens.mjs` alongside the existing `scripts/generate_qr.mjs`) — don't upscale.

### 5.7 Build + TestFlight + submit
```
eas build -p ios --profile production   # or --platform all
eas submit -p ios --profile production
# in App Store Connect: TestFlight → process → add review notes → Internal Testing → then Submit for Review
```

---

## 6. Arabic (ar-SA) storefront — copy-paste

Add both stores' localized listings explicitly; the App Store and Play use the localized text for Arabic-device users.

**Play short description (≤80):** *(75 chars)*
```
أسعار الذهب بالريال لحظياً، حاسبة زكاة، مقارنة عروض المحلات، ومتجر مجوهرات.
```

**Play/App Store full description (AR):**
```
ركن ثمين هو رفيقك في الذهب داخل السعودية: أسعار لحظية، وأرقام واضحة، ومجوهرات معتمدة، في تطبيق واحد يدعم العربية والإنجليزية واتجاه من اليمين إلى اليسار.

■ أسعار مباشرة
أسعار الذهب عيار 24 و22 و21 و18، إضافة إلى الفضة والبلاتين والبلاديوم، بالريال السعودي للجرام، محدّثة من السعر الفوري مع بيان وقت آخر تحديث.

■ احسب قيمة أي قطعة
تحوّل حاسبة قيمة الذهب الوزن والعيار وأجرة الصياغة وضريبة القيمة المضافة إلى السعر العادل للقطعة، مع محوّل أوزان بين الجرام والتولة والأونصة والمثقال.

■ استثماراتي
أضف كل ما تملكه من سبائك وعملات ومشغولات مع سعر الشراء وأجرة الصياغة والضريبة، ثم شاهد القيمة الحالية للمحفظة، والربح والخسارة، ونسبة العائد، والعائد السنوي، وتوزيع المعادن في رسم واحد. اسحب للتحديث في أي وقت.

■ جولات التسوق
خطّط جولتك قبل الشراء، وسجّل عرض كل محل: السعر الإجمالي، والوزن، والعيار، وهل يشمل الضريبة، مع بيان إن كانت الصياغة محلية أو مستوردة. يصنّف التطبيق كل عرض بين ممتاز وعادل ومرتفع مقارنة بسعر السوق المرجعي، لتقارن بين المحلات في مكان واحد وتختار الأفضل.

■ حاسبة الزكاة
فحص تلقائي للنصاب (85 جراماً من ذهب عيار 24)، مع حساب المال الزكوي والواجب 2.5% وتفصيل الأصول. تقدير مبسّط يعتمد على الأسعار الحالية، ويُرجى مراجعة أحد المتخصصين في أحكام الزكاة لشروط الحول ونحوها.

■ المتجر
قلائد وخواتم وبناجر وسبائك من الذهب المعتمد، بأسعار تتبع سعر عيار 21 لحظياً، مع العروض الخاصة والتشكيلات المختارة. ابحث وأضف إلى المفضلة وأكمل الشراء داخل التطبيق: توصيل منزلي أو استلام من الفرع أو حفظ في خزنة الفرع، والدفع بالتحويل البنكي أو مدى/البطاقة. تابع مراحل كل طلب، وحمّل الفواتير الضريبية، وتحقق من شهادات السبائك.

■ استشارة متخصصة
احجز جلسة خاصة مع متخصص في السوق في الوقت المناسب لك: تحليل لمحفظتك، ونصائح للشراء والبيع والتنويع. تُدفع الجلسات المدفوعة عبر صفحة دفع آمنة.

■ مصمَّم للسعودية
لغتان كاملتان مع اتجاه من اليمين إلى اليسار، وأسعار بالريال السعودي، وحسابات تراعي ضريبة القيمة المضافة، وعيار 21 معاملة أساسية. يعمل على الجوال والتابلت.

كزائر، تبقى محفظتك ومفضلتك وجولاتك على جهازك؛ سجّل الدخول برقم جوالك لمزامنة المحفظة مع حسابك. بدون إعلانات ولا بيع للبيانات.

للاستفسار والطلبات الخاصة: support@<your-domain>
```

**Release notes (AR, ≤500):**
```
الإصدار الأول.
• أسعار مباشرة للذهب والفضة والبلاتين والبلاديوم بالريال للجرام
• متابعة المحفظة: القيمة الحالية والربح والخسارة والعائد السنوي وتوزيع المعادن
• جولات التسوق: سجّل عروض المحلات وقارنها بالسعر المرجعي
• حاسبة الزكاة مع فحص النصاب (85 جراماً من عيار 24)
• حاسبة قيمة الذهب ومحوّل الأوزان (جرام وتولة وأونصة ومثقال)
• المتجر: بحث ومفضلة وسلّة ودفع وسجل الطلبات
• حجز الاستشارات
• العربية والإنجليزية مع دعم كامل للاتجاه من اليمين إلى اليسار
```

---

## 7. Creative assets — specs & shot list

| Asset | Specs | Notes |
|---|---|---|
| Play app icon | 512×512 PNG, ≤1MB | square, no rounded mask baked in (Play applies the circle) |
| Play **feature graphic** | 1024×500 PNG/JPG ≤15MB | brand + one line + one product photo; no badge/price claims |
| Play screenshots (phone) | 1080×1920 (ratio 9:16–16:9), 2–8 images | portrait, real UI, no device frames |
| Play screenshots (7″/10″) | required only if you publish tablet builds | you do (`supportsTablet`) — but tablet sets are Play-optional for phones; provide if cheap |
| Promo video | YouTube link, 30–60s, no claims | highest-converting asset; show the trips comparison screen |
| App Store icon | 1024×1024, no alpha, no transparency | comes from `assets/images/icon.png` via EAS |
| iPhone screenshots | 1320×2868 (6.9″) [+ 2064×2752 iPad] | 3–10 per size |
| iPad screenshots | 2064×2752 | only if `supportsTablet: true` stays |
| App Privacy "nutrition labels" | from §4.5 table | must match Play data safety |

**Shot list (in this order — tells the buying story):**
1. Invest tab with a populated portfolio + spot ticker (top of screen shows live gold/SAR/g).
2. Asset detail: current value, gain/loss, annualized return.
3. Shopping trips: two stops side by side, one `fair`, one `high`.
4. Zakat screen: nisab + 2.5% due + breakdown.
5. Home shop grid, Arabic UI (proves RTL quality — reviewers in KSA care).
6. Weight converter / value calculator with a real number in.
7. Wishlist or cart with checkout CTA.

Rules for every screenshot: real data (no "test test"), Arabic screenshots for the Arabic listing, no status bar clutter (use a simulator with clean clock/battery), no superlatives ("أفضل تطبيق") which both stores reject as unverifiable claims. Where §1.4 makes the app start empty, **enter realistic data by hand** for the capture (your own weights, karats, SAR prices) — that satisfies both rules: no seeded demo data in the binary, no fake numbers on the storefront.

---

## 8. Submission sequence (recommended, both stores in parallel)

| Day | Action |
|---|---|
| D-21 | Legal entity + D-U-N-S requested; dev accounts opened; domain + privacy page live |
| D-14 | §1 code fixes merged; production Medusa reachable; store icons/screens generated |
| D-10 | `eas build` production → internal track (Play) / TestFlight internal (Apple) |
| D-9 | Smoke test on a physical Android 15/16 phone + iPhone; verify order placement end-to-end |
| D-8 → D-3 | Closed test ≥12 testers ⚠️ VERIFY duration; watch Vitals and server logs |
| D-3 | Submit metadata-only for Apple review first (fast feedback) or attach to the build |
| D-1 | Play production release as **Draft** + Apple submit for review |
| D-Day | Approve → staged rollout 5% (Play) / manual release (Apple) → announce |
| D+7 | Roll Play to 100%, review ratings, hot-fix JS with `eas update` (no store review needed) |

---

## 9. Questionnaire answer sheet (identical answers, both consoles)

⚠️ **VERIFY** each form's current wording — these change quarterly. The *facts* below are what your code supports; answer from them, not from memory.

### 9.1 Ads & monetization
- Ads shown / ad SDKs: **No.**
- In-app purchases: **No** (physical goods + real-world services → exempt).
- Subscriptions: **No.**
- External purchase links: allowed in KSA storefronts for physical goods; if you add "Order on our website", keep it about physical products only.

### 9.2 Age rating
| Question | Answer |
|---|---|
| Profanity | None |
| Sexual content/nudity | None |
| Violence, weapons | None |
| Drugs/tobacco/alcohol | None |
| Gambling | None |
| Real-money transactions | **Yes, for goods and services** (this is the key one for both stores) |
| User-generated content | None |
| Chat/messaging/forums | None |
| Locations / contact info sharing | None |
| Medical/health info | None |
| Mature/explicit thematic elements | None |

→ Apple **4+**, Play **Everyone / 3+**.

### 9.3 Target audience & children's policies
- Do **not** check "includes children as an intended age range" / do not select ages 2–12. Selecting them drags you into Play Families policies (extra attestations, no personalized ads, more data-safety detail) and Apple Kids-review scrutiny. Your Zakat/ROI features are adult features.
- Declare your app's data as belonging to users 13+/18+.

### 9.4 Encryption & export compliance
- Uses only TLS/HTTPS (Medusa + gold-api + tRPC over HTTPS) and `expo-secure-store` (Keychain/Keystore): **No non-exempt encryption.**
- Apple: `ITSAppUsesNonExemptEncryption = NO` ✅ already in `app.config.ts`.
- Play ⚠️ VERIFY: the console asks whether your app "uses encryption or otherwise falls under US export laws". Because TLS is used, answer **Yes** to the technical question and then select the **Exception** (mass-market / publicly available / TLS-only) so the app is not treated as needing a CCATS submission. Keep the answer identical between Play and Apple — inconsistency triggers a hold on both.

### 9.5 Financial-app specifics (why Shopping is the safer primary category)
Rukn Thamin computes values and estimates zakat but never moves money, holds funds, or offers brokerage. Put that sentence in both consoles' notes:
> *"The app displays publicly available metal spot prices and user-entered holdings for personal record-keeping and zakat estimation. It does not execute trades, custody funds, or provide regulated investment advice; a disclaimer directs users to a qualified scholar for zakat and does not substitute financial advice."*

Keep the in-app disclaimer on the zakat screen (already present: `disclaimer:` in `lib/i18n.tsx`). Also add a one-line "not investment advice" disclaimer wherever annualized return is shown — Apple and Play both push back on implied-return features in finance-labelled apps.

### 9.6 Access / demo credentials (paste into Play *Reviewer access* and Apple *App Review Notes*)
```
Test account: reviewer@<your-domain> / <password ≥12 chars, no rotation>
The app works signed-out: prices, portfolio, calculator, zakat and trips are all
available without an account. Sign-in is required only to place an order.
Payment: jewelry orders are confirmed by phone/email for cash-on-delivery or bank
transfer (physical goods, outside Play Billing / IAP). The consultation session is a
real-world 45-minute video service, also outside IAP.
Production backend: https://api.<your-domain> (Medusa). Live catalog, SAR prices.
Delete account: Profile → Account settings → Delete account, or
https://<your-domain>/delete-account
Region note: Arabic is the default for ar-SA devices; all screens are RTL.
```
Create that reviewer account on **production** Medusa and never delete it while a release is pending.

---

## 10. Rejection playbook (the ones that will bite this app)

| Code | Likely cause here | Fix |
|---|---|---|
| Apple **4.2.2 / 2.1** minimum functionality or broken | ~~mock catalog fallback renders if Medusa is unreachable (§1.4)~~ | ✅ resolved — real data + explicit error/empty state with retry |
| Apple **2.5.2** misleading / fake flow | ~~consultation card form that isn't wired to a real PSP (§1.6)~~ | ✅ resolved — card form removed; consultation is a booking request, no payment collected in-app |
| Apple **3.1.1** billing | reviewer believes consultations are "digital services" | note in review comments + label "real-world service, performed by a human specialist" |
| Apple **5.1.1(v)** account deletion | ~~not implemented (§1.7)~~ | ✅ resolved — in-app delete + fallback to web deletion page + email |
| Apple **5.1.1(ii)** permission mismatch | ~~microphone/notification permission unused (§1.5)~~ | ✅ resolved — permissions stripped from manifest |
| Apple **2.3.x** inaccurate metadata | generic name "Gold Jewelry", placeholder screenshots, mock prices in shots | ✅ name resolved; screenshots must use real data (§5.1) |
| Play **Impersonation / metadata policy** | ~~`space.manus.*` package + template branding (§1.1)~~ | ✅ resolved — `com.ruknthamin.app` + "Rukn Thamin" branding |
| Play **Data safety mismatch** | declaring data you don't collect (or omitting Medusa tokens) | §4.5 table, then re-scan with Play's data-safety "verify access" report |
| Play **Unused permissions declaration** | ~~`POST_NOTIFICATIONS` or microphone in the manifest with no user-visible feature (§1.5)~~ | ✅ resolved — blocked via `android.blockedPermissions` |
| Play **Under 13 / Families** | accidentally ticked child ages | uncheck, re-submit policy |
| Build refused: **target API** | below current minimum (§1.8) | bump `targetSdkVersion` via `expo-build-properties` |
| App Links dead after install | missing `assetlinks.json` (§1.9) | host it publicly, no redirects/auth, served as `application/assetlinks+json` (some hosts need `application/json`) with both cert fingerprints |

**When rejected:** reply in the console with (a) the specific fix, (b) a screen recording if it's a behaviour claim, (c) the updated build, (d) a requested callback via *App Review > Contact Us*. Do not resubmit blindly — the second rejection is longer.

---

## 11. Post-launch

- **Phased rollout:** Play staged rollout (5/20/50/100%) + keep the previous build rollback-ready. Apple: manual release, monitor the first 48h.
- **OTA for JS-only fixes:** `eas update` on the `production` channel — fixes typos, i18n gaps, and non-native bugs without a store cycle. Never OTA a change that alters store-declared behaviour (data collection, permissions, IAP) without resubmitting metadata.
- **Vitals to watch weekly:** Play Android Vitals (ANR/crash), Apple → *App Analysis* → crashes & installations. New Architecture + Reanimated 4 regressions usually surface on Android Go devices first.
- **Ratings:** both stores now weight reviewer sentiment heavily; reply to every 1–3★ review in KSA/GCC within 48h — Shopping listings are ranked partly on reply rate.
- **Next-release hygiene:** bump `version`, let `autoIncrement` handle `buildNumber`/`versionCode`, re-answer export-compliance/data-safety (Play re-prompts), regenerate screenshots if the UI changed.

---

## Appendix A — Privacy policy template

⚠️ Fill every `<...>` and have counsel/you own the result. Both stores require: what is collected, purpose, sharing, retention, deletion contact, jurisdiction, children's clause, and (Apple) a link reachable from the listing; (Play) the same content as declared in Data safety.

### A.1 Who we are
`<Legal entity>`, registered in `<jurisdiction>`, operates Rukn Thamin (`com.ruknthamin.app`) at `https://<domain>`. Contact for privacy: `privacy@<domain>`.

### A.2 What we collect
| Category | Examples | Why | Basis / storage |
|---|---|---|---|
| Account | name, email, phone | create & secure your account, order support | consent; Medusa server |
| Orders | items, amounts, delivery address | fulfilment, returns, order history | contract; Medusa + shipping partners |
| Payment | provider-issued tokens; **we do not store card numbers** | taking payment for orders and consultations | contract; PSP records |
| Personal gold data | your holdings, wishlist, cart, shopping-trip quotes, notes | the features you use | your device (AsyncStorage/SecureStore); synced only when signed in |
| Technical | server request logs (IP, timestamp, user id, route) | security & debugging | legitimate interest; retained ≤30 days |
| Push tokens | if you allow notifications | order status alerts | consent; FCM/APNs |

**Not collected:** contacts, photos, camera, precise location, advertising ID. **No ad networks, no analytics SDKs, no data sale** — therefore no Do Not Sell/Share or ATT/SDK-disclosure table is required. If that changes, update this section, Data safety, and App Privacy **in the same release**.

### A.3 Who we share with
Medusa hosting/infrastructure; payment providers (for orders and consultation fees); couriers (for delivery); Google Play / Apple (purchase, crash and TestFlight telemetry under their own policies); government authorities where legally required. Never for advertising.

### A.4 Legal bases, retention, transfers
Retention: account & order data while the account exists and thereafter as tax/commercial law in `<KSA>` requires; server logs 30 days; crash logs 90 days. Cross-border transfers: `<list regions of your hosting>` with `<SCCs / adequacy / KPDPA-aligned safeguards — state truthfully>`.

### A.5 Your rights (and how to exercise them)
Access, correction, export (`privacy@<domain>` within 30 days), and **deletion**: Profile → Account settings → Delete account, or `https://<domain>/delete-account`. Deletion removes the Medusa customer and derived personal records; anonymized order totals may remain for accounting obligations. Device-local data (portfolio, wishlist, trips) is deleted by uninstalling or by the in-app reset.

### A.6 Children
Not directed to anyone under 13 (18 where local law requires); we do not knowingly collect their data and delete it on notice.

### A.7 Changes, complaints, security
Material changes are announced in-app and dated at the top of this page. Security: TLS 1.2+ everywhere, Keychain/Keystore for session tokens, no plaintext credentials, staff access on least privilege. Complaints: contact us first, then your local regulator (`SDPR`/`PDPL` authority in Saudi Arabia if applicable — ⚠️ VERIFY the correct reference at publication).

### A.8 Arabic summary block (put under the EN version)
```
ملخص بالعربية: نجمع الاسم والبريد الإلكتروني والهاتف وعنوان التوصيل وتاريخ الطلبات
لإتمام البيع والشحن، ولا نخزّن أرقام البطاقات. بياناتك عن الذهب (المحفظة، المفضلة،
السلّة، جولات التسوق) تبقى على جهازك ولا تُزامَن إلا إذا سجّلت الدخول. نستخدم HTTPS،
ولا نبيع بياناتك ولا نعرض إعلانات. لحذف حسابك: الملف الشخصي ← إعدادات الحساب ← حذف
الحساب، أو عبر الموقع.
```

---

## Appendix B — Printable checklist

**Code**
- [x] Real bundle id / package (owns the domain) — not `space.manus.*` (§1.1) ✅
- [x] `appName`, `appSlug`, deep-link `scheme` no longer placeholders (§1.1, §1.2) ✅
- [x] In-app branding, copyright and version string match the listing (§1.2) ✅
- [x] Logo/splash assets committed; no expiring CDN URL (§1.3) ✅
- [x] All demo/mock catalog, orders and seeded portfolio removed or unreachable (§1.4) ✅
- [x] Notification & microphone permissions: used or removed (§1.5) ✅
- [x] Consultation payment = real PSP or hidden (§1.6) ✅ — booking request, no in-app payment
- [x] Account deletion in-app + web URL (§1.7) ✅ — in-app done; web URL needs hosting
- [ ] `targetSdk` meets current Play minimum ⚠️ VERIFY (§1.8)
- [ ] `assetlinks.json` + `apple-app-site-association` live (§1.9 — only needed once you add https deep links)
- [x] `ITSAppUsesNonExemptEncryption` present (§1.10) ✅
- [x] "Not investment advice" + zakat disclaimer visible (§9.5) ✅ — `consultationPriceDisclaimer` + zakat `disclaimer`
- [ ] `eas build -p android/ios --profile production` succeeds; AAB + IPA validated; no signing warnings

**Store setup**
- [ ] Privacy policy at `<domain>/privacy` (matches declarations exactly)
- [ ] `delete-account` URL live
- [ ] Support email/phone monitored
- [ ] Reviewer test account created on production
- [ ] Play: content rating form saved → 3+/Everyone; Families → not applicable
- [ ] Play: Data safety table complete + consistent with policy + verified in *Data safety* report
- [ ] Play: Ads No, IAP No, category Shopping, tags & title within limits
- [ ] Apple: App Privacy labels from the same table; "does not track"; age 4+
- [ ] Apple: subtitle ≤30, keywords ≤100, promo text ≤170, description ≤4,000
- [ ] Apple: screenshots for all required size classes (incl. iPad if `supportsTablet`)
- [ ] Apple: review notes with payment-exemption explanation + demo creds
- [ ] Localized listings (ar-SA) added on both stores (§6)
- [ ] Feature graphic 1024×500 + 512 icon + screenshots uploaded (Play)
- [ ] Internal/closed test completed; Vitals clean
- [ ] Staged rollout plan + `eas update` channel ready
- [ ] Version, `buildNumber`, `versionCode` all bumped and documented

---

## Appendix C — Official sources (read the live page before every submission)

- Play policy hub: <https://developer.android.com/distribute/best-practices/launch/launch-checklist>
- Target API levels: <https://developer.android.com/distribute/best-practices/develop/target-sdk>
- Data safety: <https://support.google.com/googleplay/android-developer/answer/10787469>
- Account deletion: <https://support.google.com/googleplay/android-developer/answer/13801070>
- Payments/billing scope (physical goods & real-world services): <https://support.google.com/googleplay/android-developer/answer/140504>
- App-size & graphic specs: <https://developer.android.com/distribute/best-practices/launch/store-listing>
- Apple review guidelines: <https://developer.apple.com/app-store/review/guidelines/> (3.1.1, 4.2, 5.1.1)
- App Store Connect HIG/asset specs: <https://developer.apple.com/help/app-store-connect/>
- Expo EAS build/submit: <https://docs.expo.dev/build/introduction/> · <https://docs.expo.dev/submit/introduction/>
- Apple export compliance: <https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations>
