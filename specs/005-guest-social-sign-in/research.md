# Research: S005 — Google / Apple Sign-in + WhatsApp Phone Confirmation

**Date**: 2026-11-13 · **Spec**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md)

Every item from the plan's Technical Context is settled here. Nothing is left as NEEDS
CLARIFICATION. Items marked **verify on Staging** are behaviours of external services that the
first remote run must confirm. They do not change the design.

---

## R1 — Google sign-in on Android and iOS

- **Decision**: use `google_sign_in` (current major, Credential Manager on Android, GIDSignIn on
  iOS) and send the resulting **ID token** to `supabase.auth.signInWithIdToken(provider:
  OAuthProvider.google, idToken: …, accessToken: …)`.
  - `serverClientId` is the **Web** OAuth client ID that Supabase's Google provider trusts.
  - iOS also needs `GIDClientID` plus the reversed client ID URL scheme in `Info.plist`.
  - Both IDs are public, so they go in `env/*.json` as `GOOGLE_SERVER_CLIENT_ID` and
    `GOOGLE_IOS_CLIENT_ID`.
- **Rationale**: a native sheet, no browser hop, and no deep-link dependency. The constitution
  (IV) forbids embedded web sign-in. The Supabase session works like today's email session, so
  refresh, sign-out and RLS are unchanged.
- **Nonce**: Supabase verifies a Google nonce only when one is present. If the iOS SDK embeds a
  nonce the app cannot read, the backend enables **"Skip nonce check"** for the Google provider
  (backend A1). **Verify on Staging.**
- **Cancel**: the SDK's cancel exception maps to `SocialSignInCancelled`. The cubit returns to its
  previous state and shows no message (FR-005).
- **Alternatives rejected**:
  - Supabase `signInWithOAuth` in a browser: needs a verified return link, has worse UX, and the
    session lands via deep link.
  - Firebase Auth: a second identity system next to Supabase.

## R2 — Apple sign-in on iOS only

- **Decision**: use `sign_in_with_apple` on iOS. For each attempt:
  1. Generate a 32-byte random `rawNonce`.
  2. Send `sha256(rawNonce)` (hex, via `crypto`) to Apple.
  3. Pass `rawNonce` with the `identityToken` to `signInWithIdToken(provider:
     OAuthProvider.apple, …)`.

  Request scopes `email` and `fullName`. Apple returns the name **only on the first
  authorization**, so the cubit keeps it in memory and pre-fills «أكّد رقمك». It reaches the server
  only through `common_start_phone_verification(full_name)`.
- **Android**: the button is not rendered (clarified 2026-11-13). An Apple user who moves to
  Android signs in with Google using the same email, or adds a password through «نسيت كلمة المرور»
  (FR-041).
- **Rationale**: Apple requires Sign in with Apple when other third-party sign-in is offered on iOS.
  The nonce binds the token to this attempt.
- **Alternatives rejected**: Apple through a web flow on Android (out of scope by clarification).

## R3 — App attestation for code sends

- **Decision**: use `firebase_app_check` in both Firebase projects:
  - Android: **Play Integrity** provider.
  - iOS: **App Attest**, with a DeviceCheck fallback.
  - Debug builds use the debug provider with tokens registered in each console.

  Before each `/v1/otp/send` the app calls `getLimitedUseToken()` and sends it as
  `X-Firebase-AppCheck`. The Worker verifies the JWT:
  - RS256 against `https://firebaseappcheck.googleapis.com/v1/jwks`;
  - `iss = https://firebaseappcheck.googleapis.com/<project_number>`;
  - `aud` contains `projects/<project_number>`;
  - expiry checked.

  Optional replay consumption is backend item A8.
- **Failure UX**: `APP_ATTESTATION_FAILED` says «مش قادرين نتأكد إن التطبيق أصلي. حدّث التطبيق
  من المتجر وجرّب تاني». Devices without Google Play services fall here.
- **Rationale**: the device key (R4) is client-supplied. Attestation makes scripted or modified
  clients unable to call the send endpoint, so device keys cannot be rotated freely (constitution
  IV).
- **Alternatives rejected**:
  - CAPTCHA: poor UX, and the constitution forbids bypassing bot checks rather than adding them
    to every guest.
  - Attestation on every request: unnecessary cost and latency. Only the paid send needs it.

## R4 — Reinstall-stable device key

- **Decision**: a `DeviceIdentity` interface in `lib/core/device/`:
  - **iOS**: on first use, create a random UUID v4 and store it with `flutter_secure_storage`
    (Keychain, `KeychainAccessibility.first_unlock_this_device`, `synchronizable: false`). Keychain
    items survive app deletion, so a reinstall reads the same value.
  - **Android**: read `Settings.Secure.ANDROID_ID` through a new MethodChannel
    `on_air/device_identity` in `MainActivity.kt` (same pattern as the existing
    `on_air/secure_screen`).
    - Since Android 8 it is scoped to app-signing key + user and survives reinstall; it changes
      only on factory reset.
    - API 24–25 returns a per-device value, which is also stable.
  - The value is sent **only** as `X-Device-Id` on `/v1/otp/send` by `OtpSendInterceptor`. The
    server stores `HMAC-SHA256(OTP_HASH_KEY, platform + ':' + id)` only.
- **Rationale**: meets FR-027 (survives reinstall and account switch) with no new package and no
  hardware identifiers.
- **Alternatives rejected**:
  - Firebase Installation ID: reset on reinstall.
  - `identifierForVendor`: reset when all vendor apps are removed.
  - Advertising ID: tracking, consent-bound.
  - IMEI or serial: not permitted.
  - `device_info_plus`: no longer exposes `ANDROID_ID`.
- **Privacy**: disclosed in the privacy policy, Data safety and Privacy manifest (manual step). It
  is never logged and never put in crash reports.

## R5 — Account completeness as a server state

- **Decision**: `GuestAccount` gains `status` (`incomplete` | `active` | other server values),
  `authProviders` and `hasPassword`, read from `common_get_my_context()` (backend A4).
  - `isComplete` becomes `status == active`. The local "name + terms version" rule and
    `ProfileRepository.completeProfile` (`complete_guest_profile`, removed in the backend) are
    deleted.
  - A Terms-version change for an active account is still enforced by the server at booking
    (`TERMS_CHANGED`) as today, so it no longer blocks the whole app.
- **Rationale**: Constitution II (v2.1.0) makes completeness a server decision. The existing
  redirect rule (`SignedIn && !isComplete → /auth/complete-profile`) needs no change.
- **Alternatives rejected**: deriving completeness from `phone != null` on the client (diverges
  from the server for legacy and edge cases).

## R6 — One «أكّد رقمك» screen with two steps, shared with change-number

- **Decision**: `ConfirmPhoneScreen` + screen-scoped `PhoneVerificationCubit(purpose: register |
  change)`, with steps `form → code`.
  - `/auth/complete-profile` uses `register`.
  - `/account/phone` (new) uses `change`.
  - On `register` success the cubit calls `AuthCubit.refreshAccount()`. The status becomes
    `active` and the router releases the guest to `from`.
  - On `change` success it pops with a confirmation snackbar.
- **Rationale**: one implementation of the ladder, block, delivery status and errors (FR-016 to
  FR-032), and FR-036 parity. Keeping the WhatsApp flow out of `AuthCubit` avoids widening the
  global auth state machine, which already drives redirects.
- **Alternatives rejected**: reusing `OtpScreen` via a new `VerificationChannel.whatsapp`
  (couples the email-only screen to challenge IDs, delivery status and block states).

## R7 — Delivery status without Realtime

- **Decision**: after a successful send, poll `common_get_otp_status(challenge_id)` every 5 s for
  at most 60 s, or until the status is `delivered` / `read` / `failed`. Stop on dispose or on step
  change. `failed` with reason `not_on_whatsapp` shows the FR-020 notice. No status after 60 s
  keeps the normal resend path and shows no warning (edge case).
- **Rationale**: Constitution VIII allows Realtime only for payment verification and open booking
  details. The window is short and bounded.
- **Alternatives rejected**: Realtime on `otp_challenges` (a private table, and a constitution
  limit).

## R8 — Countdown and block display from server time

- **Decision**: every send, status and verify response carries `server_time` plus `next_send_at` /
  `blocked_until` (UTC). The app keeps `clockOffset = server_time − deviceNow` per response:
  - the countdown uses `deviceNow + offset`;
  - waits under 1 h show `mm:ss`;
  - waits of 1 h or more show plain hours/minutes («بعد ساعة», «بعد 23 ساعة و10 دقايق»);
  - the block end shows as a Cairo date-time.
- **Rationale**: FR-032 and the edge case "device clock is wrong". The app never computes the
  ladder.
- **Alternatives rejected**: local countdown from a fixed ladder table (duplicates a server rule
  and breaks when settings change).

## R9 — Routing on `PROFILE_INCOMPLETE` / `PHONE_NOT_VERIFIED`

- **Decision**: `ErrorMapper` maps both codes to a new `ErrorCode.profileIncomplete` /
  `phoneNotVerified`. Repositories that receive them call a shared
  `ProfileGate.onIncomplete()`, implemented by `AuthCubit.refreshAccount()`.
  - The refreshed status (`incomplete`) triggers the existing redirect, which carries the current
    location as `from`.
  - The booking `VerifyIdentityCubit`'s `VerifyPhoneStep` now just navigates to
    `/auth/complete-profile?from=<booking route>`.
- **Rationale**: one path for server-driven gating (FR-037). There are no per-screen special cases.

## R10 — Removing the SMS path

- **Decision**: delete the following:
  - `requestPhoneCode` / `verifyPhoneCode` (repository, cubit, Supabase client);
  - `VerificationChannel.sms`;
  - `LoginScreen.phoneAuthEnabled` and the phone tab/fields;
  - `SmsCodeReader` / `AndroidSmsCodeReader`, and the `smart_auth` dependency;
  - `integration_test/phone_sign_in_test.dart`.

  The routes already pass `phoneAuthEnabled: false`, so no visible behaviour is lost.
- **Rationale**: dead code tied to a cancelled channel (no SMS, Guest Plan §6.2). It shrinks the
  app and removes a permission-adjacent dependency.

## R11 — Email registration without phone

- **Decision**: `signUpEmail(name, email, password, termsVersion)` sends `data: {full_name,
  accepted_terms_version, locale}`. Backend A3 makes `handle_new_user` create an `incomplete`
  profile without a phone. After `verifyEmailCode` the account is `incomplete`, and the router
  opens «أكّد رقمك», which shows the number field only. Existing accounts keep `active`
  (clarified).
- **Rationale**: FR-033–FR-035. Phone ownership is proven only on the phone itself.

## R12 — Social button design

- **Decision**: follow the current concept login capture (README row 5), which shows circular
  icon buttons at the bottom of the login screen. Build one `SocialSignInButton`:
  - 56dp circle, Social Fill token surface, quiet border;
  - centred official logo asset: Google "G" in full colour; Apple logo black in light and white in
    dark;
  - Semantics label «المتابعة بـ Google» / «المتابعة بـ Apple»;
  - in-place loader while busy, disabled when any sign-in is in flight.

  Order is Apple then Google in RTL on iOS, and Google alone on Android. They sit under an «أو»
  divider on login and registration.
- **Rationale**: both providers allow logo-only buttons when the official mark is used unmodified
  and the control is labelled. This matches the newest design reference
  (`docs/design_reference/README.md` rule 2).
- **Alternatives rejected**: full-width text buttons (heavier, not in the current concept).

## R13 — Sign-out and keys

- **Decision**: the existing `SignOutService` also calls `GoogleSignIn.signOut()` (FR-044).
  `device_install_id` is **kept**, because abuse keys must outlive sessions (FR-027). Apple has no
  local sign-out.

## R14 — Mock backend

- **Decision**: add `MockOtpServer` (in `features/auth/phone_verification/data/`):
  - in-memory send records per account, phone and device key, with the same ladder, 10-send cap,
    7-day block and 7-day idle reset as the server settings;
  - an injectable clock (`fake_async` in tests);
  - the existing `MockBackend.verificationCode` (`123456`);
  - phone numbers ending `0000` are "not on WhatsApp" (status `failed` after 2 s);
  - a toggle for attestation failure.

  `MockAuthRepository` gains Google/Apple scenarios:
  - new user;
  - returning incomplete user;
  - complete user;
  - legacy email-confirmed user;
  - unconfirmed-email collision;
  - cancel.

  A "reinstall" in tests recreates the cubits and repositories but keeps the same mock device key.
- **Rationale**: Guest Plan §2.6 and FR-047. Every story is testable before A1–A9 ship.

## R15 — Account linking and the unconfirmed-email collision

- **Decision**: rely on Supabase **automatic identity linking** for confirmed emails (FR-039).
  For an email + password user whose email was never confirmed, the backend makes the provider
  sign-in replace that unconfirmed identity and clear its password (backend A2, matching the
  clarified FR-040). This is Supabase's documented protection against pre-account takeover.
  **Verify on Staging**, and add a migration-level guard if the hosted behaviour differs.
- **Rationale**: one person, one account (Master Plan §2.2). A confirmed provider email outranks
  an unproven claim.
