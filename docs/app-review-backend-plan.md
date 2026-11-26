# rukn-admin: backend work for the App Store resubmission (Guideline 2.1)

Companion to the iOS rejection fix. The app side is done in `rukn_flutter` (reviews hidden on iOS, build `2.0.0+101`).
This file covers what `rukn-admin` needs so the reviewer can sign in and delete an account.

> **Start from `origin/master`, not local `master`.** Local `master` (`f9d42f3`) is 96 commits behind
> and has no OTP code at all. `origin/master` (`6eb2234`, 2026-11-26) has `/store/otp/*`,
> `/store/auth/otp/*`, BeOn and the portfolio subscription. Your untracked `AGENTS.md` differs from the one on
> `origin/master`, so `git merge --ff-only` aborts. Move it aside (or commit it) first, or branch off in a worktree:
> `git worktree add ../rukn-admin-appreview -b fix/app-review-access origin/master`.

## Status on origin/master

| Need | Status |
|---|---|
| Reviewer can sign in without receiving SMS | ❌ missing: there's no allow-list, and every number goes through BeOn plus the throttles |
| `DELETE /store/customers/me` (the app calls it from Profile → Delete account) | ❌ missing: the app currently gets 404, shows "couldn't delete" and offers an email fallback |
| Website `/delete-account` form | ❌ `rukn-site/src/lib/accountDeletion.ts` is still a TODO that drops the request |
| Portfolio subscription sold through Paymob | ⚠️ currently off in production (`paid:false`), but it's a 3.1.1 risk if turned on (see §4) |

---

## 1. Reviewer phone with a fixed OTP

**Design.** Two env vars. For a listed number, `/store/otp/send` sends no message, skips the throttles,
and issues the fixed code through the **normal** challenge. So `/store/otp/verify`, `/store/auth/otp/login|register`,
the attempt cap and the single-use token all stay unchanged. Nothing else changes for any other number.

```
APP_REVIEW_PHONES=+966500000000          # comma list, any form normalizeOtpPhone accepts
APP_REVIEW_OTP=4821                      # digits, must equal beon_setting.otp_length (default 4)
```

The app sizes its OTP field from the backend's `otp_length`, so the code has to match that length.
On a mismatch the number falls back to a normal SMS and an error is logged.

Pick a number that **can't** belong to a real customer (it still has to pass `normalizeOtpPhone`, which means a Saudi mobile
`05xxxxxxxx`). Use a number the company owns, or one from a range nobody can be assigned. Don't use the WhatsApp line.

### 1a. New file `src/utils/app-review-access.ts`

```ts
import { normalizeOtpPhone } from "./beon-phone"

/**
 * Store-review access: lets Apple / Google reviewers sign in with phone OTP without receiving SMS.
 * Both env vars must be set; unset either to turn it off.
 *   APP_REVIEW_PHONES=+966500000000,+966500000001
 *   APP_REVIEW_OTP=4821   (same length as otp_length)
 */
export interface AppReviewAccess {
  phones: ReadonlySet<string>
  code: string
}

export function readAppReviewAccess(env: NodeJS.ProcessEnv = process.env): AppReviewAccess | null {
  const code = String(env.APP_REVIEW_OTP ?? "").trim()
  const phones = new Set(
    String(env.APP_REVIEW_PHONES ?? "")
      .split(",")
      .map((p) => normalizeOtpPhone(p.trim()))
      .filter((p): p is string => !!p)
  )
  if (!/^\d+$/.test(code) || phones.size === 0) return null
  return { phones, code }
}

export type ReviewerCode =
  | { kind: "none" }
  | { kind: "code"; code: string }
  | { kind: "misconfigured"; expectedLength: number; actualLength: number }

/** The fixed code for this (already normalised) number, if it is a reviewer number. */
export function reviewerCodeFor(
  phone: string,
  otpLength: number,
  access: AppReviewAccess | null = readAppReviewAccess()
): ReviewerCode {
  if (!access || !access.phones.has(phone)) return { kind: "none" }
  if (access.code.length !== otpLength) {
    return { kind: "misconfigured", expectedLength: otpLength, actualLength: access.code.length }
  }
  return { kind: "code", code: access.code }
}
```

### 1b. `src/utils/beon-otp.ts` → `issueChallenge` takes an optional preset code

```diff
 export async function issueChallenge(
   cache: OtpCacheLike,
-  input: SendGuardInput
+  input: SendGuardInput & {
+    /** A preset code instead of a random one. Only for store-review numbers (`app-review-access.ts`). */
+    fixedCode?: string
+  }
 ): Promise<IssuedChallenge> {
   const now = input.now ?? Date.now()
   const { policy, phone } = input

-  const code = generateCode(policy.otp_length)
+  const code = input.fixedCode ?? generateCode(policy.otp_length)
```

The hash, salt, TTL and attempt counter work as before. Only the hash of the code is stored, even for the fixed code.

### 1c. `src/api/store/otp/send/route.ts`

```diff
+import { reviewerCodeFor } from "../../../../utils/app-review-access"
 ...
   const policy = toOtpPolicy(settings)
   const ip = clientIpOf(req)

-  const guard = await checkSendAllowed(cache, { phone, ip, policy })
+  // App Store / Play reviewers: a configured number gets a fixed code and no message. The
+  // throttles are skipped too, so a reviewer retrying the flow is never locked out.
+  const reviewer = reviewerCodeFor(phone, policy.otp_length)
+  if (reviewer.kind === "misconfigured") {
+    logger.error(
+      `[app-review] APP_REVIEW_OTP has ${reviewer.actualLength} digits but otp_length is ` +
+        `${reviewer.expectedLength}; ${maskPhone(phone)} gets a normal SMS code instead`
+    )
+  }
+  const fixedCode = reviewer.kind === "code" ? reviewer.code : undefined
+
+  const guard: SendGuardResult = fixedCode
+    ? { allowed: true }
+    : await checkSendAllowed(cache, { phone, ip, policy })
   if (!guard.allowed) {
   ...
   // (the existing purpose === "login" | "register" checks stay BEFORE the branch below,
   //  so the app's "no account → register" / "already registered → sign in" flow works for reviewers too)
   ...
+  if (fixedCode) {
+    const issued = await issueChallenge(cache, { phone, ip: null, policy, fixedCode })
+    logger.info(`[app-review] fixed OTP issued to review number ${maskPhone(phone)}, no message sent`)
+    return res.json({ sent: true, expires_in: issued.expiresIn, resend_after: issued.resendAfter })
+  }
+
   const issued = await issueChallenge(cache, { phone, ip, policy })
```

(Import `type SendGuardResult` from `beon-otp`.) Put the reviewer branch **after** the BeOn `enabled` / `isConfigured` /
template kill switches if you want "OTP off" to block reviewers too. If you'd rather reviewers can still sign in during
a BeOn outage, move the branch above them. I'd go with **above**: a BeOn credit outage during review would
otherwise get the app rejected again.

### 1d. Tests

- `src/utils/__tests__/app-review-access.unit.spec.ts`: unset vars → `null`; non-digit code → `null`;
  `0500000000` and `+966500000000` both match; an unlisted number → `none`; a length mismatch → `misconfigured`.
- `src/utils/__tests__/beon-otp.unit.spec.ts`: `issueChallenge` with `fixedCode` → `verifyChallenge` accepts that
  code and rejects any other; the attempt cap still destroys the challenge.
- `integration-tests/http/beon-otp.spec.ts`: set the env in the test, then send twice back to back for the reviewer number
  → both 200 (no cooldown 429). Verify with the fixed code → `verification_token`. A **non-listed** number
  still gets 429 on the second send.

---

## 2. `DELETE /store/customers/me`

The app (`rukn_flutter/lib/services/account_service.dart:deleteAccount`) sends `DELETE /store/customers/me` with the
customer bearer token. It treats 2xx as deleted, 401/403 as signed out, and 404/405 as "unsupported" (which falls back to email).

### 2a. Route file `src/api/store/customers/me/route.ts` (export **only** `DELETE`)

Medusa registers custom routes per HTTP method, so exporting only `DELETE` leaves core `GET`/`POST /store/customers/me`
as they are. **Verify that** after adding it: the app's profile load (`GET`) and name edit (`POST`) must still work.
Core already applies `authenticate("customer", ["session","bearer"])` to `/store/customers/me*` (the existing
`me/phone` route relies on this), so no middleware entry is needed.

What to remove. Saudi law (ZATCA e-invoicing, Commercial Book Law) requires keeping invoices and orders, so **orders are kept**,
and `lib/data/legal.dart` already tells users this:

| Data | Action |
|---|---|
| `phone-otp` / `emailpass` provider identities + the auth identity (`auth_identity_id` from the token) | **delete**, so the login is gone and the number can register fresh |
| Customer addresses | delete |
| Customer row | first **anonymise** (`first_name: "Deleted"`, `last_name: null`, `phone: null`, `email: deleted+<id>@invalid`, `metadata: null`), then `deleteCustomers` (soft delete) |
| `portfolio_asset` (`customer_id`) | delete |
| `portfolio_subscription` (`customer_id`) | keep (it's a payment record), no PII beyond the id |
| `consultation` (`customer_id`, `full_name`, `email`, `phone`) | null `customer_id` and blank the contact fields on **closed** ones. See the open-items rule below for open ones |
| `analytics_event` (`customer_id`) | null `customer_id` |
| Orders | keep for legal retention. They keep their own email and shipping address, as the privacy policy says |

Why anonymise before the soft delete: `/store/auth/otp/register` signs a verified number into "exactly one
pre-OTP account with that phone" (`findLegacyCustomersByPhone`). If a soft-deleted row ever showed up in that lookup, the
reviewer's re-registration would land in the deleted account. Blanking `phone`/`email` rules that out whichever
way `withDeleted` behaves.

**Open items rule** (terms §: "open orders and items held in our vault must be settled or collected first").
Refuse with `409 { code: "OPEN_ITEMS", message: <Arabic + English> }` when the customer has an order that isn't
completed or canceled, or vault-held items. Apple accepts this kind of business restriction as long as the app explains it. **The app
doesn't handle 409 yet**: it maps it to `'error'` and shows the generic failure dialog. Either add an `'open_items'` case
in `account_service.dart` + `profile_screen.dart` (one string), or skip this rule for v1. Make sure the reviewer
account never has an open order when you hand it over. A Paymob-cancelled order counts as canceled.

Sketch:

```ts
import { AuthenticatedMedusaRequest, MedusaResponse } from "@medusajs/framework/http"
import { ContainerRegistrationKeys, Modules } from "@medusajs/framework/utils"

/**
 * DELETE /store/customers/me — the signed-in customer deletes their own account
 * (App Store 5.1.1(v), Play account-deletion policy). Orders are kept for legal retention.
 */
export async function DELETE(req: AuthenticatedMedusaRequest, res: MedusaResponse) {
  const customerId = req.auth_context?.actor_id
  const authIdentityId = req.auth_context?.auth_identity_id
  if (!customerId || !authIdentityId || req.auth_context?.actor_type !== "customer") {
    return res.status(401).json({ message: "Unauthorized" })
  }
  const logger = req.scope.resolve(ContainerRegistrationKeys.LOGGER)
  const customers = req.scope.resolve(Modules.CUSTOMER)
  const auth = req.scope.resolve(Modules.AUTH)

  // 1. (optional) open orders / vault items → 409 OPEN_ITEMS
  // 2. custom modules: portfolio assets, consultations, analytics events (resolve each module service)
  // 3. addresses
  const addresses = await customers.listCustomerAddresses({ customer_id: customerId })
  if (addresses.length) await customers.deleteCustomerAddresses(addresses.map((a) => a.id))
  // 4. anonymise, then soft-delete the customer
  await customers.updateCustomers(customerId, {
    first_name: "Deleted", last_name: null, phone: null,
    email: `deleted+${customerId}@invalid`, metadata: null,
  })
  await customers.deleteCustomers([customerId])
  // 5. the login: provider identities go with the auth identity
  await auth.deleteAuthIdentities([authIdentityId])

  logger.info(`[account-deletion] customer ${customerId} deleted their account`)
  res.status(200).json({ id: customerId, object: "customer", deleted: true })
}
```

Run steps 2–5 in a workflow (`createWorkflow` + steps with compensation) if you want it to be all-or-nothing. If you don't,
order them as above so a half-finished run still leaves the account unusable (identity deleted last means a retry
with the same token still works). Also check for an emailpass identity on a **different** auth identity for the same
customer (`customer.email`, as `customer-otp-auth.ts:97` does) and delete it too.

Issued JWTs stay valid until they expire. That's fine, because the app clears its token. A later `GET /store/customers/me`
with an old token should return 401/404, not a deleted profile. Check this in the test.

### 2b. Tests (`integration-tests/http/customer-profile.spec.ts` or a new `customer-deletion.spec.ts`)

1. Register by OTP → add an address and a portfolio asset → `DELETE /store/customers/me` → 200.
2. `GET /store/customers/me` with the same token → not 200.
3. `POST /store/otp/send {purpose:"login"}` for that phone → 404 `NO_ACCOUNT`.
4. Register again with the same phone → a **new** customer id, with no addresses and no portfolio.
5. An order placed before deletion still exists in admin, with its email and address.
6. No token → 401.

---

## 3. Reviewer account and keeping it working

- Register the reviewer number through the app once, with name "App Review", email `appreview@<your domain>`, and
  a saved Saudi National Address in a UPS-covered area, so checkout gets to the payment choice straight away.
- The reviewer **will** delete it (Apple asked to see deletion), and that's fine: they can register again with the same
  number, since the fixed OTP works for both login and register. Tell them so in the notes: *"If you delete the
  account, sign up again with the same number and code."*
- If there are portfolio assets or orders you want the reviewer to see, add a small script
  `src/scripts/seed-app-review-account.ts` (`npx medusa exec`) that recreates the customer, phone-otp identity
  (`ensurePhoneIdentity`), address and one sample portfolio asset. Run it before each submission.
- After approval you can leave the env vars set for future updates (Apple reviews every version) or unset them.
  The number can only sign in to its own demo account.

## 4. Portfolio subscription vs. Apple 3.1.1 (decide before turning `paid` on)

`portfolio_subscription` sells **access to an in-app feature** (the investment portfolio) through Paymob. For digital
features Apple requires In-App Purchase. The physical-goods (3.1.3(e)) and person-to-person service (3.1.3(d)) exemptions
cover the jewellery and the consultations, but not this. It's safe today only because production returns
`{"paid":false}`, so the app never shows the paywall. If an admin flips it on while the iOS app is live, the next
update can be rejected, or the live app can be pulled.

Options, from lightest to heaviest:
1. **Keep `paid` off** while the iOS app is on the store (business decision). Add a warning in the admin
   setting screen.
2. **Exempt iOS on the server.** The app sends a platform header (add `X-Client-Platform: ios` in `rukn_flutter/lib/core/api.dart`).
   `resolvePortfolioAccess` returns `allowed` for iOS clients, and the app hides the paywall on iOS. Simple, but iOS
   users get it for free.
3. **Sell it through IAP on iOS.** StoreKit products, receipt validation, and Apple's commission. A real project.

Recommendation: option 1 now, and revisit if the subscription becomes important.

## 5. Website `/delete-account` (rukn-site)

`rukn-site/src/lib/accountDeletion.ts` validates the request and then drops it. Apple doesn't test it (the in-app flow
is what counts), but the privacy policy and Play's "Delete account URL" link to it. The simplest honest version: add
`POST /store/account-deletion-requests` (phone + OTP `verification_token` → find the customer → run the same
deletion as §2, or record a request row and email support). Then make the site page do OTP → submit.

## 6. Deploy and verify on production

1. Set `APP_REVIEW_PHONES` and `APP_REVIEW_OTP` in the production env and deploy.
2. On the TestFlight build: sign in with the reviewer number and the fixed code. No SMS arrives, and the BeOn balance stays the same.
3. Send twice quickly → no cooldown. A wrong code fails. A real number still gets a real SMS.
4. Profile → Delete account → success snackbar → signed out → sign in again → "no account" → register again → works.
5. Put the number and code in App Store Connect → App Review Information (Sign-in required ✔, User name = number,
   Password = code) and in the Notes.
