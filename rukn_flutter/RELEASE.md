# Releasing Rukn Thamin 2.0 (Flutter) to Google Play and the App Store

This app ships as an **update** to the published Expo app: same `com.ruknthamin.app` id on both
stores. The long-form console walkthroughs, questionnaires and listing copy are in
`../docs/PUBLISHING.md`. They still apply, with the Flutter-specific differences below.

## Done in the code

| Item | Where |
|---|---|
| App id `com.ruknthamin.app` (Android + iOS) | `android/app/build.gradle.kts`, `ios/Runner.xcodeproj` |
| Live backend `https://admin.rknthmin.com.sa` (the old `rknadmin.kayanprojects.online` no longer resolves) | `lib/core/config.dart` |
| Version `2.0.0+100` | `pubspec.yaml` |
| Target SDK 36, min SDK 24, AAB release build verified (`flutter build appbundle --release`) | Flutter defaults |
| Release manifest permissions: `INTERNET` only (no camera/storage/notification permissions) | merged manifest checked |
| Branded launch screen (gold mark on `#07352B`, Android 12+ splash API included) | `flutter_native_splash` in `pubspec.yaml` |
| App icons: 1024 px, no alpha; Android adaptive + monochrome | `flutter_launcher_icons` |
| iOS `ITSAppUsesNonExemptEncryption = false` (no export-compliance prompt) | `ios/Runner/Info.plist` |
| iOS privacy manifest (no tracking; collected data types; UserDefaults reason `CA92.1`) | `ios/Runner/PrivacyInfo.xcprivacy` |
| Camera / photo-library usage strings (bank-receipt upload) | `ios/Runner/Info.plist` |
| iPhone portrait-only; tablets keep all orientations | `Info.plist`, `lib/main.dart` |
| In-app account deletion (Profile → Delete account), falls back to an email to support | `lib/screens/profile_screen.dart` |
| In-app Privacy Policy and Terms (`/privacy`, `/terms`) + website links | `lib/screens/legal_screen.dart` |
| Web build never sends analytics (screenshots/dev only) | `lib/services/site_analytics.dart` |
| Release notes (en-US / ar, < 500 chars) | `../store-assets/play/text/*/release-notes.txt` |
| Screenshots from the real Flutter UI (phone, 7", 10"; en-US + ar) | `scripts/store-assets/shots.config.mjs` → `../store-assets/play` |

## You must do (cannot be done from the repo)

1. **Android signing.** A new upload key was created on 2026-11-02: `android/upload-keystore.jks`
   (alias `upload`), with its passwords in `android/key.properties`. Both are git-ignored, so
   **back them up now** (password manager plus an offline copy). Losing them blocks every future
   update until Google resets the key.
   - The Play listing exists already (the Expo app, signed with the EAS upload key), so Play
     refuses this bundle until it accepts the new key: Play Console → Test and release →
     App integrity → App signing → *Request upload key reset*, and attach
     `android/upload_certificate.pem`. Google usually approves within about 2 days.
   - Upload certificate SHA-256:
     `73:62:AE:C8:36:66:55:1F:BE:29:AF:E6:38:E2:01:6B:CF:48:6D:5C:64:F6:95:B1:12:F1:3B:DC:9A:BD:C4:B9`
2. **Version codes.** EAS kept versionCode / buildNumber remotely (`appVersionSource: remote`).
   Check the last uploaded values in Play Console / App Store Connect. `+100` must be higher. Raise it if not.
3. **iOS build.** Needs a Mac with Xcode: `flutter build ipa`, set the team in
   `ios/Runner.xcworkspace` (Signing & Capabilities), and upload with Transporter or Xcode.
4. **Account deletion on the server.** Confirm production implements
   `DELETE /store/customers/me` (the app calls it; the August `rukn-admin` copy has no such route).
   The website's `/delete-account` form is **not wired to anything** (`rukn-site/src/lib/accountDeletion.ts`,
   TODO). Play's "Delete account URL" must lead to a working request, so wire it before submitting.
5. **Analytics `platform`.** The app sends `android` / `ios` to `/store/analytics/collect`. Confirm
   the backend accepts those values (the site sends `web`).
6. **Reviewer access.** Sign-in is phone OTP only. Give App Review / Play a test phone number with
   a fixed OTP (or a backend allow-listed number) in the review notes, or reviewers can't reach
   checkout, orders or account deletion.

## Store forms: what changed since the Expo listing

**Play Data safety** (update §4.5 of `../docs/PUBLISHING.md`):

| Data type | Collected | Purpose |
|---|---|---|
| Name, email, phone | Yes | Account management |
| Address | Yes | App functionality (delivery) |
| Purchase history | Yes | App functionality, analytics |
| Photos (bank-transfer receipt, only when the customer attaches one) | Yes | App functionality |
| Other financial info (portfolio holdings, synced when signed in) | Yes | App functionality |
| App interactions, in-app search history | Yes | Analytics (first-party, not shared) |
| Device or other IDs (a random app-install id for analytics) | Yes | Analytics |
| Location, advertising id, contacts | No | — |

Payments: card details are entered on Paymob's hosted page, not in the app. Declare "Encrypted in
transit: Yes" and "Users can request deletion: Yes".

**App Store App Privacy**: the same types, all "not used for tracking". It must match
`PrivacyInfo.xcprivacy`.

**Release notes**: tell users to sign in again. Guest data saved by the Expo app (cart, wishlist,
local portfolio, trips) doesn't carry over to the Flutter storage.

## Build commands

```bash
flutter test && flutter analyze
flutter build appbundle --release      # build/app/outputs/bundle/release/app-release.aab
flutter build ipa                      # on a Mac
# screenshots (serves on localhost:8021, the origin the backend allows for CORS)
flutter build web --release
node ~/.claude/skills/flutter-store-screenshots/scripts/shoot.mjs \
  --config scripts/store-assets/shots.config.mjs --devices phone,tablet7,tablet10
```
