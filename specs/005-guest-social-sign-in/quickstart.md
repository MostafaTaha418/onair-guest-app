# Quickstart & validation: S005 — Google / Apple sign-in + WhatsApp phone confirmation

This file is a guide for running and checking the feature. It has no implementation code. For
the details, see the contracts ([supabase-auth.md](contracts/supabase-auth.md),
[node-otp.md](contracts/node-otp.md), [app-routes.md](contracts/app-routes.md) and
[ui-screens.md](contracts/ui-screens.md)) and [data-model.md](data-model.md).

## 1. Manual setup (account owners, not code)

**Mock mode needs none of this.** Remote mode needs all of it for **each** environment (Staging,
then Production).

| # | Where | What | Output to hand over |
|---|---|---|---|
| M1 | Meta Business (business.facebook.com) | Business Portfolio and **Business Verification**. It can take days, so start first. Until it is done, use Meta's free **test number**, which sends to up to 5 registered recipients. | — |
| M2 | developers.facebook.com | Create an app of type Business, add the **WhatsApp** product, and note the **App Secret**. | App Secret → Worker secret |
| M3 | WhatsApp Manager | Get a WABA and a dedicated sender number. The number must not be active on the WhatsApp or WhatsApp Business app. Get the display name «OnAir» approved and set a two-step PIN. | `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_WABA_ID` → Worker vars |
| M4 | WhatsApp Manager → Templates | Create an **Authentication** template in Arabic and English with a "Copy code" button, the security recommendation, and a 10-minute expiry. Wait for approval. | template name → `WHATSAPP_OTP_TEMPLATE` |
| M5 | Business Settings → System Users | Create a System User and generate a **permanent token** with `whatsapp_business_messaging` and `whatsapp_business_management`, with the WABA assigned. | token → Worker secret |
| M6 | WhatsApp Manager → Payment | Add a payment method. Authentication messages are billed per delivered message. | — |
| M7 | Meta app → WhatsApp → Configuration | Webhook callback `https://api.on-air.website/v1/webhooks/whatsapp`, a verify token you choose, and a subscription to `messages`. | verify token → Worker secret |
| M8 | Cloudflare (Worker `onair-api`) | From `services/integrations` in `onair-backend`, run `npx wrangler secret put` for `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_APP_SECRET`, `WHATSAPP_WEBHOOK_VERIFY_TOKEN` and `OTP_HASH_KEY`. The vars from M3/M4 and `FIREBASE_PROJECT_NUMBER` go in `wrangler.onair-api.jsonc` through the backend PR. **No new Worker.** | — |
| M9 | Cloudflare → Security → WAF | Rate-limiting rule on `/v1/otp/send`: 20 requests / 10 min per IP → block for 10 min. | — |
| M10 | Firebase (both projects) | **App Check**: Play Integrity for Android (link Play Console, SHA-256) and App Attest (+ DeviceCheck) for iOS. Register debug tokens for emulators and test devices. | project numbers |
| M11 | Google Cloud Console | OAuth clients per flavor: Web (Supabase audience), Android (package + SHA-1/SHA-256), iOS (bundle). | Web + iOS client IDs → `env/*.json`; IDs + secret → Supabase |
| M12 | Apple Developer | Enable the **Sign in with Apple** capability on both bundle IDs. Create a Services ID and a Sign in with Apple **key (.p8)**. Register `on-air.website` in **Private Email Relay**. | Team/Key/Services IDs + .p8 → Supabase |
| M13 | Supabase dashboard (each project) | Enable the Google and Apple providers with the M11/M12 values (backend A1). Renew the Apple secret every 6 months. | — |
| M14 | Legal / stores | Update the privacy policy, Data safety and Privacy manifest: the phone is shared with Meta for codes, and a hashed device identifier is kept for abuse prevention. | — |

`env/staging.json` / `env/production.json` gain the public values `GOOGLE_SERVER_CLIENT_ID` and
`GOOGLE_IOS_CLIENT_ID`. These files stay out of Git (CI secrets).

## 2. Run

```bash
flutter pub get
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

Mock mode (no backend or Meta needed): set `"BACKEND_MODE": "mock"` in your local
`env/staging.json`, then:

```bash
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=env/staging.json
```

Mock conventions (research R14):
- the WhatsApp code is always `123456` (`MockBackend.verificationCode`);
- numbers ending `0000` are "not on WhatsApp";
- the clock and ladder follow the server settings;
- Google/Apple are simulated with a scenario picker in debug builds.

## 3. Automated checks

```bash
flutter analyze
```

```bash
flutter test
```

```bash
flutter test integration_test/social_sign_in_mock_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

```bash
flutter test integration_test/phone_otp_limits_mock_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

```bash
flutter test integration_test/email_register_phone_mock_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

## 4. Validation scenarios

| # | Scenario | Expected | Covers |
|---|---|---|---|
| V1 | Visitor opens an apartment → «احجز الآن» → login → Google (new user) | «أكّد رقمك» opens with the email shown. Booking, favorites and account are unreachable. Home, search and the apartment still work. | US1, US3, FR-009–FR-011 |
| V2 | V1 → enter `01012345678` → «متابعة» → code `123456` | The account becomes complete, the toast shows, and the guest lands on the same apartment with the same dates. | US4, FR-021, FR-008 |
| V3 | V1 → wrong code, then close the app, reopen | Still on «أكّد رقمك» with an empty number. The account context shows no phone. | FR-015, FR-022, SC-005 |
| V4 | Code step: request a resend repeatedly (mock clock) | Countdowns are 30 s → 5 min → 1 h → 24 h → 1 h → 24 h → 1 h → 24 h → 1 h. The 11th request shows the 7-day block with a Cairo date. | US5, FR-024, FR-025 |
| V5 | V4 blocked → "reinstall" (restart with the same device key) / sign in with another Google account / use the same number on another mock device | The block still applies in each case. | FR-026, FR-027, SC-006 |
| V6 | Mock attestation failure on | Send refused, update notice shown, nothing counted. | FR-028, SC-007 |
| V7 | Number `01000000000` | After about 2 s: "not on WhatsApp" notice with «تعديل الرقم» and «كلّم الدعم». | FR-020 |
| V8 | iOS: Apple, hide email, no name shared | The form asks for the name and shows the relay email. | US2 |
| V9 | Android | Only the Google button is shown. | FR-001 |
| V10 | Register with email → email code | «أكّد رقمك» asks for the number only. Then the WhatsApp code completes the account. | US6, FR-033, FR-034 |
| V11 | Legacy mock account (phone confirmed by email) signs in | No «أكّد رقمك»; it books normally. | FR-035 |
| V12 | Account → «تغيير» number → code | The old number stays until success, then the new one is shown with a snackbar. | FR-036 |
| V13 | Mock existing confirmed email account → Google with the same email | Same account, bookings visible, no completion step. | US7, FR-039 |
| V14 | Mock unconfirmed email signup → Google with the same email | Provider sign-in wins, the old password fails, and the flow continues to «أكّد رقمك». | FR-040 |
| V15 | Double-tap every primary/resend/social button | Exactly one request each (inspect the mock call log). | FR-007, FR-022, SC-009 |
| V16 | Cancel the Google sheet | Same screen, no message. | FR-005, SC-009 |
| V17 | Each new screen at 1.3× text, 320dp, keyboard open, dark, English | No clipped or hidden controls (goldens + manual). | FR-045, SC-010 |

**Staging (after A1–A9 and M1–M13):**
- repeat V1–V2, V4 (first 3 steps only), V7, V8 and V10–V14 with real providers;
- check that the WhatsApp message arrives in Arabic with «نسخ الكود»;
- check that the Worker logs contain no code, phone number or device ID;
- check that a crafted RPC from an incomplete account returns `PROFILE_INCOMPLETE`;
- check that `curl` to `/v1/otp/send` without App Check returns `APP_ATTESTATION_FAILED` and sends
  nothing (SC-004, SC-007).
