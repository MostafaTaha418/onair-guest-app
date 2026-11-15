# Implementation Plan: Guest Sign-in with Google / Apple + Mandatory Phone Confirmed on WhatsApp (S005)

**Branch**: `feature/005-guest-social-sign-in` (remote `origin/005-guest-social-sign-in`) | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-guest-social-sign-in/spec.md`

## Summary

Add one-tap Google (Android + iOS) and Apple (iOS) sign-in, and make a WhatsApp-confirmed Egyptian
phone the condition for every new account to become usable:

- **Social sign-in**: native `google_sign_in` / `sign_in_with_apple` sheets produce an ID token that
  goes to `supabase.auth.signInWithIdToken`. Logo-only circular buttons sit under the login form,
  as in the current concept screenshot (row 5 of `docs/design_reference/README.md`).
- **Account completeness becomes a server state**: `profiles.status = incomplete | active` (read
  through `common_get_my_context`). It replaces today's local "name + terms version" check.
  `SignedIn.isComplete` is now `status == active`, and the existing router rule (incomplete →
  `/auth/complete-profile`) keeps working with no new guard.
- **«أكّد رقمك»**: `/auth/complete-profile` is rebuilt as one screen with two steps:
  - a form step: number, plus name and Terms only when missing;
  - a WhatsApp code step: `OnAirOtpField`, «افتح واتساب», «تعديل الرقم», the server countdown,
    the delivery status and the block notice.

  A screen-scoped `PhoneVerificationCubit` drives the steps:
  1. `common_start_phone_verification` (or `common_request_phone_change`) returns a `challenge_id`;
  2. Node `POST /v1/otp/send` sends the code with App Check + `X-Device-Id`;
  3. `common_get_otp_status` polls the delivery for 60 s;
  4. `common_verify_otp` confirms the code.

  The same flow also serves a phone change (`purpose: change`).
- **Anti-spam lives on the server**: ladder 30 s → 5 min → 1 h → 24 h → (1 h ↔ 24 h), 10 sends,
  then a 7-day block keyed on account + phone + device. The app only renders `next_send_at` /
  `blocked_until`. It contributes a reinstall-stable device id (iOS Keychain UUID, Android
  `ANDROID_ID` over a small MethodChannel) and a Firebase App Check limited-use token, attached
  only to `/v1/otp/send` by a new Dio interceptor.
- **Email registration**: the email form loses phone and WhatsApp fields. `signUp` sends name,
  Terms and language only. After the email code the account is `incomplete`, so the router sends
  it to «أكّد رقمك».
- **Clean-up**:
  - remove the dead phone + SMS sign-in path (`requestPhoneCode` / `verifyPhoneCode`,
    `VerificationChannel.sms`, `phoneAuthEnabled`, `SmsCodeReader`, `smart_auth`);
  - remove the obsolete `complete_guest_profile` RPC call;
  - point the booking `VerifyPhoneStep` to «أكّد رقمك».

Design rule: every new surface is built from the existing auth look (`AuthFlowScaffold`,
`AuthBrandHeader`, pill fields, gradient button, `OnAirOtpField`, `CountdownText`, state views).
One new shared component is added: `SocialSignInButton`, a circular, logo-only button with an
accessible label. The screen map is in [contracts/ui-screens.md](contracts/ui-screens.md).

**Backend dependency:** as-built `onair-backend` has `common_verify_otp`,
`common_request_phone_change`, `private.otp_challenges`, and Node `POST /v1/otp/send` (email via
Resend) in the `onair-api` Worker. Still missing:
- the Google/Apple providers;
- the `incomplete` status;
- the WhatsApp channel, delivery webhook and send-limit table;
- App Check verification;
- the new and changed RPCs.

These are drafted as deltas A1–A9 in
[contracts/supabase-auth.md](contracts/supabase-auth.md) and
[contracts/node-otp.md](contracts/node-otp.md). They are implemented in `D:\flutter\onair-backend`
(never here, AGENTS.md). The app builds and tests every flow against the mock until they ship.

Details: [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/),
[quickstart.md](quickstart.md).

## Technical Context

**Language/Version**: Dart 3.12.2, Flutter 3.44.3 (stable). SDK constraint `^3.12.2`. Kotlin for
the small Android MethodChannel. No Swift changes beyond capabilities and plist entries.

**Primary Dependencies**:
- Existing stack: `flutter_bloc`, `go_router`, `supabase_flutter` (`signInWithIdToken`, RPC),
  `dio` + generated Node client, `flutter_secure_storage`, `firebase_core`, `url_launcher`,
  `intl`, `timezone`.
- **Added** (research R1–R3):
  - `google_sign_in` (native Google);
  - `sign_in_with_apple` (native Apple, iOS);
  - `crypto` (Apple nonce SHA-256);
  - `firebase_app_check` (Play Integrity / App Attest).
- **Removed**: `smart_auth` (SMS consent reader, dead after the SMS path removal).

**Storage**:
- Secure storage gets one new key, `device_install_id`: a random UUID that is the iOS device key.
  It lives in the Keychain with `first_unlock_this_device` and survives reinstall (R4).
- Android uses `ANDROID_ID` read live, so nothing is stored.
- The pending phone number is **never** persisted (FR-015). It lives only in
  `PhoneVerificationCubit` memory.
- Nothing new in `shared_preferences` or the JSON caches.
- Sign-out also calls `GoogleSignIn.signOut()`, but keeps `device_install_id`: abuse keys must
  outlive sessions.

**Testing**:
- `flutter_test`, `bloc_test`, `mocktail`, `fake_async` (ladder countdowns, delivery polling,
  block expiry).
- `alchemist` goldens for the new and changed screens:
  - login with social row;
  - email registration without phone;
  - «أكّد رقمك» form (full and number-only);
  - code step: counting, ready, not-on-WhatsApp, blocked.

  Each golden covers Light, Dark, RTL, LTR, 1.3× text, 320dp and 800dp widths, and keyboard open.
- `integration_test`:
  - `social_sign_in_mock_test.dart`: Google new user → «أكّد رقمك» → WhatsApp code → back to the
    apartment;
  - `phone_otp_limits_mock_test.dart`: full ladder, 11th request block, block survives a
    simulated reinstall and an account switch;
  - `email_register_phone_mock_test.dart`;
  - Staging variants once A1–A9 ship.
- The old `phone_sign_in_test.dart` is deleted.

**Target Platform**: Android 7.0+ (API 24) and iOS 15+. Two caveats: App Attest needs iOS 14+
(met), and Play Integrity needs Google Play services. A device without them gets
`APP_ATTESTATION_FAILED` and a clear message (R3).

**Project Type**: Mobile app (single Flutter project at repository root) + backend deltas in the
separate `onair-backend` repository.

**Performance Goals**:
- The native sign-in sheet opens on the first frame after the tap, and the in-button loader
  appears at once.
- «أكّد رقمك» shows within 1 frame of the redirect.
- Code-step countdowns rebuild only their text.
- Delivery polling runs every 5 s for at most 60 s, then stops (R7).
- No extra network call at app start beyond the existing context read.

**Constraints**:
- Constitution II: completeness, waits and blocks come from the server only.
- Constitution IV:
  - no identity or App Check token is stored or logged;
  - the device id is sent only on `/v1/otp/send`;
  - phone numbers are masked in logs and diagnostics;
  - only public OAuth client IDs live in `env/*.json`.
- Arabic RTL first with English LTR; text scale clamped at 1.3; Cairo time for block dates.
- Remote mode depends on backend deltas A1–A9 and the manual Meta / Firebase / Google / Apple setup
  listed in [quickstart.md](quickstart.md) §1.

**Scale/Scope**:
- **Screens:**
  - rebuilt: «أكّد رقمك» (form + code step);
  - changed: login (social row, phone tab removed), registration (phone fields removed), account
    placeholder (sign-in method, phone, change-number entry), booking verify step (redirect only);
  - new route: `/account/phone` (change number, reuses the «أكّد رقمك» steps).
- **New design-system component (1):** `SocialSignInButton`.
- **Backend calls:**
  - Auth: `signInWithIdToken`.
  - RPCs: `common_get_my_context` (+A4), `common_start_phone_verification` (A5),
    `common_request_phone_change` (A6), `common_get_otp_status` (A7), `common_verify_otp` (A5/A6).
  - Node: `POST /v1/otp/send` (A8).
- **Volume:** pilot-scale; at most 10 sends per key per cycle by design.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Checked against constitution **v2.1.0** (amended 2026-11-13 for D-002).

| Principle | How S005 complies | Status |
|---|---|---|
| I. Master Plan fidelity & scope | Implements Guest Plan §6.2.2–§6.2.9, §17 S005 and D-002 only. Social sign-in is Google + Apple only, Apple on iOS only (clarified). No SMS and no other phone-confirmation channel (clarified). The Social tokens drive only the two sign-in buttons. Account settings beyond the sign-in method, phone and change-number entry stay in G4. | PASS |
| II. Server is the authority | `profiles.status` decides completeness, and the router reads it from `common_get_my_context`. `next_send_at`, `blocked_until`, delivery status and code validity come from the server, and the app never computes the ladder. `PROFILE_INCOMPLETE` / `PHONE_NOT_VERIFIED` from any call route to «أكّد رقمك». | PASS |
| III. Payment integrity | Untouched. Booking still requires a confirmed phone server-side (AC-001). The booking verify step only redirects. | PASS |
| IV. Security & privacy | Native sheets only, with a fresh Apple nonce per attempt, and ID tokens are never stored or logged (R1/R2). The phone is not stored anywhere before the correct code (FR-022). App Check limited-use token + device id go on `/v1/otp/send` only (R3/R4). Phone numbers are masked in logs. Only public client IDs ship. The privacy-policy and store-form updates are listed as manual steps. | PASS |
| V. Design system | Reuses auth tokens and components. One new `SocialSignInButton` in `lib/design_system/components/`, with the official Google "G" and Apple logo assets and Social tokens for the circle. No hex or font-size literals. Screen map in `contracts/ui-screens.md`. | PASS |
| VI. Arabic-first, RTL & a11y | All new copy is in `.arb` (Egyptian Arabic + English). Logo-only buttons carry Semantics labels «المتابعة بـ Google/Apple». Countdown and block text are announced. Targets are ≥ 48dp (buttons 56dp). Directional layout. Goldens run at 1.3×. | PASS |
| VII. Layered, feature-first | Social sign-in sits in `features/auth` (domain interface, Supabase + mock data, presentation). Phone verification sits in `features/auth/phone_verification/` with its own repository interface and Remote/Mock implementations. Device identity and App Check go in `lib/core/device/` + a Dio interceptor in `lib/core/network/`. New error codes go through `ErrorMapper`. The added packages are on the v2.1.0 approved list. | PASS |
| State management | `AuthCubit` gains `signInWithGoogle` / `signInWithApple` and `refreshAccount`, and loses the SMS methods. One screen-scoped `PhoneVerificationCubit` per «أكّد رقمك» / change-number screen; `close()` cancels the countdown and polling timers. | PASS |
| VIII. UX states & performance | Every step has loading (in-button), error with reference, offline (send and confirm disabled with a banner), and success. Polling is bounded. No list changes. | PASS |
| IX. Test discipline | Test-first coverage for: the `isComplete` mapping from status, the redirect for incomplete accounts on every account route and deep link, ladder rendering from `next_send_at`, block rendering, delivery-status polling, purpose-specific success, the Apple nonce hashing, and the device-id provider (Keychain persistence, Android channel). Security tests: incomplete account calls rejected (mock + staging), no phone stored before the correct code, a block surviving reinstall/account switch (mock), no send without attestation (mock + staging). | PASS |
| Repository constraints | No backend code here (AGENTS.md). Deltas A1–A9 are drafted in `contracts/` for `onair-backend`, inside the existing `onair-api` Worker (no new Worker). | PASS |

No violations. Complexity Tracking is empty.

### Post-design re-check (after Phase 1)

The design artifacts keep every row above at PASS. Points checked specifically:

- **Server authority (II)**:
  - [data-model.md](data-model.md) §1: `GuestAccount.isComplete` is `status == active`; the old
    name/terms rule is gone.
  - §4: `SendWindow` stores server timestamps only, and the UI derives the remaining duration
    from them with the clock, display only.
- **Phone never stored early (IV)**:
  - [contracts/supabase-auth.md](contracts/supabase-auth.md) A5 keeps the number in the challenge
    payload and writes `profiles` only inside `common_verify_otp`.
  - [data-model.md](data-model.md) §3: `PhoneVerificationDraft` is memory-only and has no
    `toJson`.
- **Abuse keys (IV)**:
  - [contracts/node-otp.md](contracts/node-otp.md) A8: the strictest of three keys applies,
    failed deliveries count, and the device id is HMAC-ed before storage.
  - The app sends the device id on that route only (research R4).
- **Design (V)**: [contracts/ui-screens.md](contracts/ui-screens.md) maps each section to existing
  components. Only `SocialSignInButton` is new, with goldens.

## Project Structure

### Documentation (this feature)

```text
specs/005-guest-social-sign-in/
├── plan.md              # This file
├── research.md          # Phase 0: decisions R1–R12
├── data-model.md        # Phase 1: app-side models and states
├── quickstart.md        # Phase 1: setup (manual + local) and validation scenarios
├── contracts/
│   ├── supabase-auth.md # Backend deltas A1–A7 (Auth providers, profiles, RPCs)
│   ├── node-otp.md      # Backend deltas A8–A9 (WhatsApp send, limits, webhook, App Check)
│   ├── app-routes.md    # Route and redirect changes
│   └── ui-screens.md    # Screen → component map, copy keys, golden matrix
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 ($speckit-tasks; not created here)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── device/
│   │   ├── device_identity.dart          # NEW: DeviceIdentity interface + Keychain/ANDROID_ID impl
│   │   └── app_attestation.dart          # NEW: AppAttestation (Firebase App Check limited-use token)
│   ├── network/
│   │   └── otp_send_interceptor.dart     # NEW: adds X-Device-Id + X-Firebase-AppCheck on /v1/otp/send
│   ├── errors/error_mapper.dart          # + PROFILE_INCOMPLETE, PROFILE_ALREADY_COMPLETE,
│   │                                     #   OTP_SEND_BLOCKED, PHONE_NOT_ON_WHATSAPP,
│   │                                     #   APP_ATTESTATION_FAILED, OTP_TEMPORARILY_UNAVAILABLE
│   └── env/env_config.dart               # + GOOGLE_SERVER_CLIENT_ID, GOOGLE_IOS_CLIENT_ID (public)
├── design_system/components/
│   └── social_sign_in_button.dart        # NEW
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── auth_repository.dart      # + signInWithGoogle/Apple, refreshAccount; − SMS methods
│   │   │   ├── auth_state.dart           # − VerificationChannel.sms
│   │   │   ├── guest_account.dart        # + status, authProviders, hasPassword; phone nullable
│   │   │   └── social_identity.dart      # NEW: SocialProvider, SocialCredential, SocialSignInCancelled
│   │   ├── data/
│   │   │   ├── social_credential_source.dart   # NEW: GoogleSignIn / SignInWithApple wrappers
│   │   │   ├── supabase_auth_repository.dart   # + signInWithIdToken; signUp without phone
│   │   │   ├── profile_repository.dart         # reads common_get_my_context; − complete_guest_profile
│   │   │   └── mock_auth_repository.dart       # + social scenarios, incomplete accounts
│   │   ├── phone_verification/
│   │   │   ├── domain/phone_verification_repository.dart  # NEW interface + models
│   │   │   ├── data/supabase_phone_verification_repository.dart  # NEW (RPC + Node)
│   │   │   ├── data/mock_otp_server.dart                  # NEW: ladder, block, keys, delivery
│   │   │   └── presentation/
│   │   │       ├── phone_verification_cubit.dart          # NEW
│   │   │       ├── confirm_phone_screen.dart              # NEW (replaces complete_profile_screen)
│   │   │       └── widgets/{phone_form_step,whatsapp_code_step,send_window_notice}.dart
│   │   └── presentation/
│   │       ├── auth_cubit.dart           # + social sign-in, refreshAccount; − SMS
│   │       ├── login_screen.dart         # + social row; − phone tab/fields
│   │       ├── register_screen.dart      # − phoneAuthEnabled
│   │       ├── otp_screen.dart           # email-only; − SmsCodeReader
│   │       └── complete_profile_screen.dart   # DELETED (→ confirm_phone_screen.dart)
│   ├── account/presentation/account_placeholder_screen.dart  # + sign-in method, phone, change number
│   └── booking/presentation/verify_identity_cubit.dart       # phone step → redirect to «أكّد رقمك»
├── app/router/
│   ├── routes.dart                       # + accountPhone ('/account/phone')
│   ├── app_router.dart                   # wire ConfirmPhoneScreen for both routes
│   └── redirect.dart                     # unchanged rule; reads server isComplete
├── l10n/app_ar.arb, app_en.arb           # new keys (contracts/ui-screens.md §4)
└── bootstrap.dart                        # wire DeviceIdentity, AppAttestation, repositories, interceptor

android/app/src/main/kotlin/com/onair/guest/MainActivity.kt   # + on_air/device_identity channel
android/app/build.gradle(.kts)                                # (no change; Play Integrity via plugin)
ios/Runner/Runner.entitlements        # + com.apple.developer.applesignin, App Attest environment
ios/Runner/Info.plist                 # + Google reversed client ID URL scheme, GIDClientID
assets/images/social/                 # official Google "G" + Apple logo (SVG/PNG per guidelines)

test/
├── core/device/…                     # device id + attestation provider tests
├── features/auth/…                   # cubits, repositories, mock OTP server, goldens
└── app/router/redirect_test.dart     # incomplete-account cases

integration_test/
├── social_sign_in_mock_test.dart
├── phone_otp_limits_mock_test.dart
├── email_register_phone_mock_test.dart
└── phone_sign_in_test.dart           # DELETED
```

**Structure Decision**: Single Flutter project (existing feature-first layout). Phone verification
is a sub-module of `features/auth`, because both registration completion and the account's change
number use it, and it depends on auth session state. Device identity and attestation are core
infrastructure, because they are cross-cutting and future owner-facing codes may reuse them.
Backend work is specified as contracts only.

## Complexity Tracking

> No Constitution Check violations. Nothing to justify.
