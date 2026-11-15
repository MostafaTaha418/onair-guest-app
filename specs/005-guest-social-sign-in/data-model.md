# Data Model: S005 — Google / Apple Sign-in + WhatsApp Phone Confirmation

App-side models and states only. Server tables and RPCs are in
[contracts/supabase-auth.md](contracts/supabase-auth.md) and [contracts/node-otp.md](contracts/node-otp.md).

Conventions:
- Timestamps are UTC `DateTime` from server ISO-8601.
- Phone numbers are E.164 `+201[0125]XXXXXXXX` (`EgyptPhone`).
- Nothing in this file is computed by the app if the server provides it.

---

## 1. `GuestAccount` (changed — `features/auth/domain/guest_account.dart`)

| Field | Type | Source | Notes |
|---|---|---|---|
| `id` | `String` | session | unchanged |
| `email` | `String` (required now) | `common_get_my_context` | Every account has a confirmed email (clarified). Apple relay addresses allowed. |
| `emailVerified` | `bool` | context | `true` for Google/Apple |
| `fullName` | `String?` | context | 2–80 when present; may be null while `incomplete` |
| `phone` | `String?` | context | **null only while `status == incomplete`** |
| `phoneVerified` | `bool` | context | `phone_verified_at != null` |
| `status` | `AccountStatus` | context `profile_status` | **NEW** `incomplete` · `active` · `suspended` · `deleted` · `unknown` (forward-compatible) |
| `authProviders` | `Set<AuthProvider>` | context `auth_providers` | **NEW** `email` · `google` · `apple` |
| `hasPassword` | `bool` | context `has_password` | **NEW**; hides «تغيير كلمة المرور» when false |
| `acceptedTermsVersion`, `acceptedTermsAt` | as today | context | — |

- `bool get isComplete => status == AccountStatus.active;` replaces `isComplete(termsVersion)`.
- The constructor invariant changes from "phone or email" to "email required; phone required unless
  `incomplete`" (assert in debug, ignore in release to avoid crashing on new server states).
- Validation: phone regex as today. `fullName` length 2–80.

## 2. Social sign-in (new — `features/auth/domain/social_identity.dart`)

```text
enum SocialProvider { google, apple }

SocialCredential            // memory-only, never logged or persisted
  provider: SocialProvider
  idToken: String
  accessToken: String?      // Google only, when the SDK provides it
  rawNonce: String?         // Apple only (sha256(rawNonce) went to Apple)
  givenName / familyName: String?   // Apple first authorization only

SocialSignInCancelled       // exception: user closed the sheet → no message (FR-005)
SocialSignInUnavailable     // exception: platform/provider not available (e.g., Apple on Android)
```

`AuthRepository` (changed):

| Method | Change |
|---|---|
| `signInWithGoogle()` → `Future<SocialSignInResult>` | NEW |
| `signInWithApple()` → `Future<SocialSignInResult>` | NEW (iOS only) |
| `refreshAccount()` → `Future<GuestAccount?>` | NEW: re-reads `common_get_my_context` |
| `signUpEmail(name, email, password, termsVersion)` | `phone` parameter **removed** |
| `requestPhoneCode`, `verifyPhoneCode`, `completeProfile` | **removed** |

`SocialSignInResult { GuestAccount account; String? providerFullName; }`. `providerFullName` (Apple
first time, or Google display name) pre-fills «أكّد رقمك» and is held in `AuthCubit` memory until
completion or sign-out.

## 3. Phone verification (new — `features/auth/phone_verification/domain/`)

```text
enum PhoneVerificationPurpose { register, change }

PhoneVerificationDraft      // memory-only; no toJson (FR-015)
  phone: EgyptPhone
  fullName: String?         // only when the account lacks a name (register)
  acceptedTermsVersion: String?   // only when the account lacks accepted terms (register)
  locale: String            // 'ar' | 'en'

WhatsAppChallenge
  challengeId: String (UUID)
  maskedPhone: String       // from server, e.g. "+20 10•• ••• 678"
  expiresAt: DateTime
  window: SendWindow
  delivery: DeliveryStatus

SendWindow                  // server timestamps only (R8)
  serverTime: DateTime
  nextSendAt: DateTime?     // null = can send now
  blockedUntil: DateTime?   // non-null = blocked; overrides nextSendAt
  Duration remaining(DateTime deviceNow)   // display helper: (next − (deviceNow + offset)).clamp

enum DeliveryStatus { pending, sent, delivered, read, failed, unknown }
DeliveryFailure { notOnWhatsApp, other }   // only when status == failed
```

`PhoneVerificationRepository`:

| Method | Backend | Errors surfaced |
|---|---|---|
| `start(draft, purpose)` → `String challengeId` | `common_start_phone_verification` (register) / `common_request_phone_change` (change) | `PROFILE_ALREADY_COMPLETE`, `PHONE_COUNTRY_NOT_SUPPORTED`, `PHONE_ALREADY_USED`, `TERMS_CHANGED`, `VALIDATION_FAILED` |
| `send(challengeId)` → `WhatsAppChallenge` | Node `POST /v1/otp/send` (+ App Check, device id) | `RATE_LIMITED` (+ `next_send_at`), `OTP_SEND_BLOCKED` (+ `blocked_until`), `APP_ATTESTATION_FAILED`, `OTP_TEMPORARILY_UNAVAILABLE`, `NOT_FOUND` |
| `status(challengeId)` → `(DeliveryStatus, DeliveryFailure?, SendWindow)` | `common_get_otp_status` | `NOT_FOUND` |
| `verify(challengeId, code)` → `GuestAccount` | `common_verify_otp` | `OTP_INVALID`, `OTP_EXPIRED`, `OTP_SUPERSEDED`, `OTP_ATTEMPTS_EXCEEDED`, `PHONE_ALREADY_USED` |

"Resend" is `send(challengeId)` again on the same challenge. The server rotates the code and
invalidates the previous one (FR-018).

## 4. `PhoneVerificationCubit` states

```text
PvForm(draft?, fieldErrors, submitting: bool, error: ErrorCode?)
   │ submit (valid) → start() then send()
   ▼
PvCode(challenge, code: String, verifying: bool, resending: bool,
       error: ErrorCode?,            // OTP_INVALID / OTP_EXPIRED / OTP_SUPERSEDED / network
       notice: PvNotice?)            // notOnWhatsApp | attestationFailed | temporarilyUnavailable
   │ verify ok → PvDone(account, purpose)
   │ «تعديل الرقم» → PvForm(draft kept in memory)
   ▼
PvBlocked(blockedUntil, serverTime)  // from OTP_SEND_BLOCKED at start/send/resend; send/resend disabled
PvDone(account, purpose)
```

Transitions:

| From | Event | To | Rule |
|---|---|---|---|
| `PvForm` | submit, `start` fails `PHONE_ALREADY_USED` / `PHONE_COUNTRY_NOT_SUPPORTED` | `PvForm` + field error | no send happened |
| `PvForm` | submit, `TERMS_CHANGED` | `PvForm` + terms re-shown, checkbox cleared | FR-017 |
| `PvForm` | submit, `send` returns `RATE_LIMITED` | `PvCode` with `window.nextSendAt` | the challenge exists; the guest waits |
| any | `OTP_SEND_BLOCKED` | `PvBlocked` | shows Cairo date-time + «كلّم الدعم» |
| `PvCode` | resend tap while `remaining > 0` | ignored | button disabled anyway |
| `PvCode` | status poll `failed/notOnWhatsApp` | `PvCode(notice: notOnWhatsApp)` | stops polling (R7) |
| `PvCode` | verify `OTP_ATTEMPTS_EXCEEDED` | `PvCode(error)` + code field disabled until resend | FR-018 |
| `PvCode` | verify `PHONE_ALREADY_USED` | `PvForm` + field error | FR-023 |
| `PvCode` | verify ok (register) | `PvDone` → `AuthCubit.refreshAccount()` | router releases to `from` |
| `PvCode` | verify ok (change) | `PvDone` → pop + snackbar | FR-036 |

`close()` cancels the countdown ticker and the polling timer.

## 5. Auth state (changed — `features/auth/domain/auth_state.dart`)

- `VerificationChannel` becomes `{ emailSignup, emailRecovery }` (`sms` removed).
- `SignedIn(account, isComplete)`: `isComplete` now comes from `account.isComplete` (server status).
- `AuthCubit` additions:
  - `signInWithGoogle()`, `signInWithApple()`: busy flag exposed via a separate
    `SocialSignInStatus` stream/selector so the login screen can disable all sign-in buttons
    (FR-007);
  - `refreshAccount()`;
  - `providerFullName` getter (memory only).
- Removals: `requestPhoneCode`, `verifyPhoneCode`, `completeProfile`, `updateTermsVersion`
  (completeness no longer depends on the local terms version).

## 6. Device identity & attestation (new — `lib/core/device/`)

```text
DeviceIdentity
  Future<String> id()          // iOS: Keychain UUID (created once); Android: ANDROID_ID via channel
  // never logged; used only by OtpSendInterceptor

AppAttestation
  Future<String?> limitedUseToken()   // Firebase App Check; null → request still sent, server answers APP_ATTESTATION_FAILED
```

Secure-storage key: `device_install_id` (iOS only), Keychain `first_unlock_this_device`, not
synchronizable, **not** cleared at sign-out (R13).

`OtpSendInterceptor` (Dio, Node client only): for `POST /v1/otp/send` adds `X-Device-Id` and
`X-Firebase-AppCheck`. All other routes are untouched.

## 7. Error codes (added to `ErrorMapper` / `ErrorCode`)

| Code | Where | UI |
|---|---|---|
| `PROFILE_INCOMPLETE` | any account RPC/Node call | route to «أكّد رقمك» (R9) |
| `PHONE_NOT_VERIFIED` | booking quote/start | route to «أكّد رقمك» |
| `PROFILE_ALREADY_COMPLETE` | start (register) | `refreshAccount()` then continue |
| `OTP_SEND_BLOCKED` | start/send | `PvBlocked` |
| `PHONE_NOT_ON_WHATSAPP` | status (`failed` reason) | notice + «تعديل الرقم» + «كلّم الدعم» |
| `APP_ATTESTATION_FAILED` | send | notice «حدّث التطبيق…» |
| `OTP_TEMPORARILY_UNAVAILABLE` | send (global cap) | «الخدمة مشغولة دلوقتي، جرّب بعد شوية» + retry later |
| `OTP_SUPERSEDED` | verify | «استخدم آخر كود وصلك» |
| `OTP_ATTEMPTS_EXCEEDED` | verify | «اطلب كود جديد» |
| existing `RATE_LIMITED`, `OTP_INVALID`, `OTP_EXPIRED`, `PHONE_ALREADY_USED`, `PHONE_COUNTRY_NOT_SUPPORTED`, `TERMS_CHANGED` | — | as today, with WhatsApp wording where relevant |

## 8. Persistence summary

| Data | Where | Cleared |
|---|---|---|
| Supabase session (Google/Apple/email) | secure storage (existing) | sign-out |
| `device_install_id` (iOS) | Keychain | never by the app (survives reinstall by design) |
| Pending phone, draft name, provider name, ID tokens, App Check tokens, codes | memory only | screen/cubit close, sign-out |
| Account status/providers/hasPassword | in `AuthCubit` state from context | sign-out |
