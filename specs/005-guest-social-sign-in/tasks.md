---

description: "Task list for S005 — Google / Apple sign-in + mandatory phone confirmed on WhatsApp"
---

# Tasks: Guest Sign-in with Google / Apple + Mandatory Phone Confirmed on WhatsApp (S005)

**Input**: `specs/005-guest-social-sign-in/` — [spec.md](spec.md), [plan.md](plan.md),
[research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/),
[quickstart.md](quickstart.md)

**Tests**: REQUIRED. Constitution IX makes tests mandatory: test-first for router guards and
domain logic, widget tests for every state, goldens for new screens, and security tests. FR-047
also requires full mock coverage. Write each test task **before** its implementation task and
check that it fails first.

**Organization**: Phases follow the spec's user stories (US1–US8) in priority order. Phase 2 is
blocking.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1…US8 from spec.md

---

## 0. Rules for the implementer (read before ANY task)

These rules exist because each task must be done exactly as written. When in doubt, **stop and
ask**. Do not guess.

1. **Read before you write.** Before a task, open every file it names and the closest existing
   file of the same kind. Copy the existing patterns:
   - `lib/features/stay/` for a full feature;
   - `lib/features/auth/presentation/otp_screen.dart` for code entry;
   - `test/features/auth/goldens/login_golden_test.dart` for goldens.
2. **Never edit** `lib/core/api/generated/**` by hand. To change the Node client:
   1. edit `contracts/node-api.openapi.yaml`;
   2. run `dart run swagger_parser`;
   3. run `dart run build_runner build --delete-conflicting-outputs`.
3. **Never write backend code in this repo** (no SQL, no migrations, no Worker code; AGENTS.md).
   Backend work is in `specs/005-guest-social-sign-in/contracts/supabase-auth.md` and
   `contracts/node-otp.md`, and is done in `D:\flutter\onair-backend` separately.
4. **UI rules:**
   - Every user-visible string goes in **both** `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`,
     then run `flutter gen-l10n`.
   - No `Color(0x…)`, no hex, no raw font sizes. Use `context.colors`, theme text styles, and the
     `Dimens.*` spacing.
   - Use `EdgeInsetsDirectional` / `AlignmentDirectional` / `start` / `end`, never `left` /
     `right`.
   - Every tappable icon-only control gets a `Semantics(label: …)` and a touch target ≥ 48dp.
   - Every async button: disable on the first tap, show the loader inside the button, and use
     `RapidSubmitGuard` like `login_screen.dart`.
5. **Mock mode is the default for development.** `MockBackend.verificationCode` (`'123456'`) is
   the only valid code in mock mode, for email and WhatsApp alike.
6. **After every phase** run, in this order, and fix everything before moving on:
   ```bash
   dart format .
   flutter analyze
   flutter test
   ```
   Golden files: only regenerate the goldens that the task says changed:
   ```bash
   flutter test --update-goldens <that golden test file>
   ```
   Then look at the PNG diff before accepting it.
7. **Never** log, print or send to crash reports:
   - phone numbers;
   - the device id;
   - ID tokens;
   - App Check tokens;
   - codes.

   Use `AppLogger` with IDs only.
8. Commit after each phase with a conventional message, for example `feat(auth): …` or
   `test(auth): …`.

### Reference values (use exactly these)

| Name | Value |
|---|---|
| Error codes added | `PROFILE_ALREADY_COMPLETE`, `OTP_SEND_BLOCKED`, `PHONE_NOT_ON_WHATSAPP`, `APP_ATTESTATION_FAILED`, `OTP_TEMPORARILY_UNAVAILABLE`, `OTP_SUPERSEDED`, `OTP_ATTEMPTS_EXCEEDED` (`PROFILE_INCOMPLETE`, `PHONE_NOT_VERIFIED`, `PHONE_ALREADY_USED`, `RATE_LIMITED`, `OTP_INVALID`, `OTP_EXPIRED`, `TERMS_CHANGED` already exist) |
| Ladder (server data, mock only) | waits after send 1…9: `30s, 5m, 1h, 24h, 1h, 24h, 1h, 24h, 1h`; the 11th request → block `7 days`; idle reset `7 days` |
| Code | 6 digits; valid 10 min; 5 wrong attempts |
| Delivery polling | every 5 s, max 60 s, stop on `delivered`/`read`/`failed` |
| New route | `AppRoutes.accountPhone = '/account/phone'` |
| Secure-storage key | `device_install_id` (iOS only) |
| MethodChannel | `on_air/device_identity`, method `androidId` → `String` |
| Headers on `/v1/otp/send` only | `X-Device-Id`, `X-Firebase-AppCheck` |
| Env keys (public, optional) | `GOOGLE_SERVER_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` |

### Localization keys (add to both ARB files exactly)

| Key | Arabic (`app_ar.arb`) | English (`app_en.arb`) |
|---|---|---|
| `authOr` | أو | or |
| `authContinueWithGoogle` | المتابعة بـ Google | Continue with Google |
| `authContinueWithApple` | المتابعة بـ Apple | Continue with Apple |
| `authSocialFailed` | تعذر تسجيل الدخول، حاول مرة أخرى | Couldn't sign you in. Please try again. |
| `confirmPhoneTitle` | أكّد رقمك | Confirm your number |
| `confirmPhoneNewTitle` | تغيير رقم الهاتف | Change phone number |
| `confirmPhoneSubtitle` | هنبعتلك كود على واتساب الرقم ده عشان نتأكد إنه بتاعك | We'll send a code to this number on WhatsApp to make sure it's yours. |
| `confirmPhoneEmailLabel` | حسابك | Your account |
| `confirmPhoneContinue` | متابعة | Continue |
| `confirmPhoneCancel` | إلغاء | Cancel |
| `confirmPhoneLeaveTitle` | تخرج من التسجيل؟ | Leave registration? |
| `confirmPhoneLeaveBody` | لو خرجت، التسجيل مش هيكمل | If you leave, your registration won't be completed. |
| `confirmPhoneLeaveConfirm` | خروج | Leave |
| `confirmPhoneLeaveStay` | كمّل | Stay |
| `whatsappCodeTitle` | اكتب الكود | Enter the code |
| `whatsappCodeSentTo` | بعتنا كود على واتساب {phone} | We sent a code to {phone} on WhatsApp |
| `whatsappOpen` | افتح واتساب | Open WhatsApp |
| `whatsappConfirm` | تأكيد | Confirm |
| `whatsappResend` | ابعت كود جديد | Send a new code |
| `whatsappResendIn` | تقدر تطلب كود جديد بعد {time} | You can request a new code in {time} |
| `durationHoursMinutes` | {hours} ساعة و{minutes} دقيقة | {hours} h {minutes} min |
| `whatsappEditNumber` | تعديل الرقم | Change number |
| `whatsappNotOnWhatsApp` | الرقم ده مش عليه واتساب. استخدم رقم عليه واتساب | This number isn't on WhatsApp. Use a number that has WhatsApp. |
| `whatsappContactSupport` | كلّم الدعم | Contact support |
| `whatsappUseLatestCode` | استخدم آخر كود وصلك | Use the latest code you received. |
| `otpBlockedUntil` | اتوقف إرسال الأكواد مؤقتًا لحد {date}. لو محتاج مساعدة كلّم الدعم | Code sending is paused until {date}. Contact support if you need help. |
| `otpAttestationFailed` | مش قادرين نتأكد إن التطبيق أصلي. حدّث التطبيق من المتجر وجرّب تاني | We couldn't verify this app. Update it from the store and try again. |
| `otpTemporarilyUnavailable` | الخدمة مشغولة دلوقتي، جرّب بعد شوية | The service is busy right now. Try again shortly. |
| `otpAttemptsExceeded` | جربت كتير، اطلب كود جديد | Too many attempts. Request a new code. |
| `confirmPhoneWelcome` | أهلًا بيك في OnAir | Welcome to OnAir |
| `phoneChanged` | رقمك اتغيّر | Your number was changed |
| `accountSignInMethod` | طريقة الدخول | Sign-in method |
| `accountMethodGoogle` | Google | Google |
| `accountMethodApple` | Apple | Apple |
| `accountMethodEmail` | البريد | Email |
| `accountPhone` | رقم الهاتف | Phone number |
| `accountPhoneConfirmed` | متأكد | Confirmed |
| `accountChangePhone` | تغيير | Change |
| `verifyPhoneOnWhatsApp` | أكّد رقمك على واتساب | Confirm your number on WhatsApp |

Placeholders (`{phone}`, `{time}`, `{date}`, `{hours}`, `{minutes}`) need `@key` metadata with
`"placeholders"` in `app_en.arb`, like the existing `authRateLimited`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: packages, env, assets and native config. No behaviour change yet.

- [X] T001 Add packages by running `flutter pub add google_sign_in sign_in_with_apple crypto firebase_app_check` at the repo root. Then run `flutter pub get` and confirm `pubspec.yaml` lists the four. If `firebase_app_check` cannot resolve with `firebase_core: ^5.1.0`, pick the newest `firebase_app_check` version compatible with that `firebase_core` major (do not change `firebase_core`). Do **not** remove `smart_auth` yet (T019 does).
- [X] T002 [P] In `lib/core/env/env_config.dart`, add two optional public fields:
  - `final String? googleServerClientId;` read from `'GOOGLE_SERVER_CLIENT_ID'`;
  - `final String? googleIosClientId;` read from `'GOOGLE_IOS_CLIENT_ID'`.

  Rules:
  - An empty or missing value becomes `null` (not an error).
  - Throw `ArgumentError.value('[redacted]', key, 'Secret forbidden')` if a value contains the
    word `secret` (case-insensitive).

  Add the two keys with empty strings to `env/example.json`. Add tests to the existing env test
  file (find it with `grep -rl EnvConfig test/`): missing → null, empty → null, value kept,
  `secret` rejected.
- [X] T003 **MANUAL — ask the user** to provide the official provider marks unmodified as PNG at 1x/2x/3x:
  - `assets/images/social/google_g.png` (+ `2.0x/`, `3.0x/`, 24×24 logical px), from
    https://developers.google.com/identity/branding-guidelines;
  - `assets/images/social/apple_logo_black.png` and `apple_logo_white.png` (same sizes), from
    Apple Design Resources → Sign in with Apple.

  Do not draw or download them yourself. Continue with the other tasks; T029 needs them.
- [X] T004 [P] In `pubspec.yaml` under `flutter: assets:`, add `- assets/images/social/` (keep the existing entries).
- [X] T005 [P] iOS config:
  1. In `ios/Runner/Runner.entitlements` add:
     - `<key>com.apple.developer.applesignin</key><array><string>Default</string></array>`;
     - `<key>com.apple.developer.devicecheck.appattest-environment</key><string>production</string>`.
  2. In `ios/Flutter/staging.xcconfig` and `ios/Flutter/production.xcconfig` add the lines
     `GOOGLE_IOS_CLIENT_ID = REPLACE_ME` and `GOOGLE_REVERSED_CLIENT_ID = REPLACE_ME`, with a
     comment that the values come from Google Cloud (quickstart M11).
  3. In `ios/Runner/Info.plist` add `GIDClientID` = `$(GOOGLE_IOS_CLIENT_ID)` and a
     `CFBundleURLTypes` entry whose `CFBundleURLSchemes` array contains
     `$(GOOGLE_REVERSED_CLIENT_ID)`. Keep any existing `CFBundleURLTypes` entries.
- [X] T006 [P] Android MethodChannel in `android/app/src/main/kotlin/com/onair/guest/MainActivity.kt`. Inside `configureFlutterEngine`, after the existing `on_air/secure_screen` channel, add a second `MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "on_air/device_identity")`:
  - method `"androidId"` returns `Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)`
    (import `android.provider.Settings`);
  - any other method → `result.notImplemented()`.

**Checkpoint**: the app builds with `flutter build apk --flavor staging -t lib/main_staging.dart --dart-define-from-file=env/staging.json --debug`, and behaviour is unchanged.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**:
- account completeness becomes a server state;
- the dead SMS path is removed;
- new error codes are added;
- device identity, App Check and the OTP interceptor are added;
- the gate signal is added.

**⚠️ No user-story task may start before this phase passes `flutter analyze` and `flutter test`.**

### Tests first (Phase 2)

- [X] T007 [P] Write `test/features/auth/domain/guest_account_test.dart`:
  - `isComplete` is true only when `status == AccountStatus.active`;
  - an `incomplete` account may have `phone == null`;
  - an `active` account with `phone == null` triggers an assertion in debug (`expect(() => …,
    throwsAssertionError)`);
  - `fullName` outside 2–80 throws `ArgumentError`;
  - `AccountStatus.fromJson('something_new')` returns `AccountStatus.unknown`;
  - `AuthProvider.fromJson` maps `'email'|'google'|'apple'` and ignores unknown values.
- [X] T008 [P] Extend `test/core/errors/error_mapper_test.dart` (create it if missing):
  - each new code maps to its `ErrorCode` and message key (table in T013);
  - `details` is kept on `ApiError.details`;
  - `fromCode('PROFILE_INCOMPLETE')` and `fromCode('PHONE_NOT_VERIFIED')` each emit exactly one
    event on `ProfileGate.events`;
  - other codes emit nothing.
- [X] T009 [P] Write `test/core/device/device_identity_test.dart`:
  - **iOS**: `KeychainDeviceIdentity` with a fake secure store returns a v4 UUID, stores it under
    `device_install_id`, and returns the **same** value on a second instance using the same
    store (simulated reinstall).
  - **Android**: `AndroidDeviceIdentity` uses a mocked `MethodChannel('on_air/device_identity')`
    (`TestDefaultBinaryMessengerBinding`) returning `'abc123'` → `'abc123'`. A
    `MissingPluginException` or an empty string → `DeviceIdentityUnavailable` is thrown.
- [X] T010 [P] Write `test/core/network/otp_send_interceptor_test.dart` with a fake `DeviceIdentity` (`'dev-1'`) and a fake `AppAttestation` (`'att-1'` or `null`):
  - `POST /v1/otp/send` gets `X-Device-Id: dev-1` and `X-Firebase-AppCheck: att-1`;
  - `POST /v1/guest/bookings/start-payment` gets **neither** header;
  - when attestation returns `null`, `X-Firebase-AppCheck` is omitted and the request still goes
    out.
- [X] T011 [P] Update `test/app/router/redirect_test.dart` (find the existing redirect tests with `grep -rl resolveRedirect test/`) and add cases:
  - `SignedIn(account(status: incomplete), isComplete: false)` on `/favorites`, `/bookings`,
    `/account`, `/account/phone`, `/notifications`, `/bookings/<uuid>` and
    `/book/<uuid>/dates?…` → `/auth/complete-profile?from=<that location>`;
  - the same state on `/home`, `/search`, `/property/<uuid>` → `/auth/complete-profile?from=…`
    (this matches the existing rule: an incomplete signed-in user is always sent there; keep that
    behaviour and assert it);
  - an `active` account on `/auth/complete-profile?from=/favorites` → `/favorites`.
- [X] T012 [P] Update `test/features/auth/presentation/auth_cubit_test.dart`:
  - delete every SMS test (`requestPhoneCode`, `verifyPhoneCode`) and `completeProfile` /
    `updateTermsVersion` tests;
  - add: `restore()` with an incomplete account emits `SignedIn(isComplete: false)`;
  - add: `refreshAccount()` re-reads the repository and emits the new completeness;
  - add: a `ProfileGate.notify()` while signed in triggers exactly one `refreshAccount()`, even if
    notified twice within 1 s.

### Implementation (Phase 2)

- [X] T013 Errors:
  1. In `lib/core/errors/api_error.dart`:
     - add the enum values `profileAlreadyComplete`, `otpSendBlocked`, `phoneNotOnWhatsApp`,
       `appAttestationFailed`, `otpTemporarilyUnavailable`, `otpSuperseded`,
       `otpAttemptsExceeded`;
     - add `final Map<String, dynamic>? details;` to `ApiError` (constructor param, default
       `null`).
  2. In `lib/core/errors/error_mapper.dart`:
     - add the map entries: `PROFILE_ALREADY_COMPLETE→authProfileIncomplete`,
       `OTP_SEND_BLOCKED→otpBlockedUntil`, `PHONE_NOT_ON_WHATSAPP→whatsappNotOnWhatsApp`,
       `APP_ATTESTATION_FAILED→otpAttestationFailed`,
       `OTP_TEMPORARILY_UNAVAILABLE→otpTemporarilyUnavailable`,
       `OTP_SUPERSEDED→whatsappUseLatestCode`, `OTP_ATTEMPTS_EXCEEDED→otpAttemptsExceeded`;
     - pass `details` into the returned `ApiError`;
     - at the end of `fromCode`, if the mapped code is `ErrorCode.profileIncomplete` or
       `ErrorCode.phoneNotVerified`, call `ProfileGate.notify()`.
- [X] T014 Create `lib/core/auth/profile_gate.dart`:
  - `abstract final class ProfileGate`;
  - a private `static final _controller = StreamController<void>.broadcast();`;
  - `static Stream<void> get events => _controller.stream;`;
  - `static void notify() => _controller.add(null);`;
  - a doc comment: "Server said the account is incomplete or the phone is unverified; AuthCubit
    refreshes the account so the router can redirect (research R9)."
- [X] T015 Add all **Localization keys** from section 0 to `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb` (with placeholder metadata), then run `flutter gen-l10n`. Do not remove any key yet (T020 does).
- [X] T016 [P] Create `lib/features/auth/domain/account_enums.dart`:
  - `enum AccountStatus { incomplete, active, suspended, deleted, unknown; static AccountStatus
    fromJson(String? v) => …unknown fallback }`;
  - `enum AuthProvider { email, google, apple; static AuthProvider? fromJson(String v) }`.
- [X] T017 Update `lib/features/auth/domain/guest_account.dart` per data-model §1:
  - add `required this.status`, `this.authProviders = const {}`, `this.hasPassword = true`;
  - keep `email` nullable for now (legacy tests) but document "always set for real accounts";
  - replace the constructor check `phone == null && email == null` with
    `assert(status == AccountStatus.incomplete || phone != null, 'active account without phone')`
    (debug only);
  - keep the phone regex and name length checks;
  - replace `bool isComplete(String currentTermsVersion)` with
    `bool get isComplete => status == AccountStatus.active;`.

  Fix every compile error this causes (`grep -rn "isComplete(" lib test`).
- [X] T018 Profile source:
  1. In `lib/features/auth/data/profile_repository.dart`:
     - make `loadOwnProfile` call `_client.rpc<dynamic>('common_get_my_context')` instead of
       selecting `profiles`;
     - parse `profile_status`, `auth_providers` (list of strings), `has_password`, `full_name`,
       `phone_e164`, `phone_verified`, `accepted_terms_version`, `accepted_terms_at`, `email`,
       `email_verified` into `ProfileRecord` (add the new fields);
     - delete `completeProfile` (the `complete_guest_profile` RPC no longer exists).
  2. In `lib/features/auth/data/supabase_auth_repository.dart` `_accountFor`, build `GuestAccount`
     from the record, including `status`, `authProviders` and `hasPassword`.
  3. Add `test/features/auth/data/profile_record_test.dart` covering `ProfileRecord.fromJson` with
     a full payload (data-model §1) and with missing optional fields.
- [X] T019 Remove the SMS path (research R10). Delete:
  - `requestPhoneCode`, `verifyPhoneCode`, `completeProfile` from `AuthRepository`
    (`lib/features/auth/domain/auth_repository.dart`), `SupabaseAuthRepository`,
    `MockAuthRepository` and `test/helpers/fake_auth_repository.dart`;
  - `requestOtp` / `verifySmsOtp` from `PhoneAuthClient` / `SupabasePhoneAuthClient`;
  - `VerificationChannel.sms` from `auth_state.dart`;
  - `requestPhoneCode` / `verifyPhoneCode` / `completeProfile` / `updateTermsVersion` from
    `AuthCubit`, and the `updateTermsVersion` call in `lib/app/app.dart` (around line 310; keep
    the rest of that config listener);
  - `SmsCodeReader` / `AndroidSmsCodeReader` and every SMS branch in
    `lib/features/auth/presentation/otp_screen.dart`.

  Then run `flutter pub remove smart_auth`. Add `Future<GuestAccount?> refreshAccount();` to
  `AuthRepository` and implement it: Supabase → `_accountFor(_auth.currentUser)`; mock/fake →
  return the current account.
- [X] T020 Login/Register cleanup:
  - in `lib/features/auth/presentation/login_screen.dart` remove the `phoneAuthEnabled` and
    `initialPhone` parameters, the segmented phone/email control, `_submitPhone`,
    `_signInPhoneFields`, and every phone field **in sign-in mode**;
  - leave the registration phone field for now (US6 removes it);
  - remove `phoneAuthEnabled` from `register_screen.dart` and from both routes in
    `lib/app/router/app_router.dart`;
  - delete `test/features/auth/presentation/login_phone_test.dart` and
    `integration_test/phone_sign_in_test.dart`;
  - remove the ARB keys that are no longer referenced (`authPhoneTab`, `authEmailTab`, and
    SMS-only strings: check each with `grep -rn <key> lib`);
  - run `flutter gen-l10n`;
  - update `test/features/auth/goldens/login_golden_test.dart` to `const LoginScreen()` and
    regenerate only that golden.
- [X] T021 `AuthCubit` (`lib/features/auth/presentation/auth_cubit.dart`):
  - remove the `currentTermsVersion` dependency from completeness: `_emitAccount` emits
    `SignedIn(account, isComplete: account.isComplete)`, and `restore()` no longer waits for the
    terms version (keep the parameter accepted but unused only if removing it breaks `app.dart`;
    prefer removing it and fixing the caller);
  - add `Future<void> refreshAccount()`: if a refresh is in flight, return the same future; else
    call `_repository.refreshAccount()` and `_emitAccount` (or emit `SessionEnded(null)` if
    `null`);
  - in the constructor subscribe to `ProfileGate.events` and call `refreshAccount()` when the
    state is `SignedIn`, ignoring events within 1 s of the last refresh;
  - cancel the subscription in `close()`.
- [X] T022 [P] Create `lib/core/device/device_identity.dart` (research R4):
  - `abstract interface class DeviceIdentity { Future<String> id(); }`;
  - `final class DeviceIdentityUnavailable implements Exception {}`;
  - `final class KeychainDeviceIdentity implements DeviceIdentity`, which takes the existing
    secure store abstraction used by `PaymentAttemptStore` (check `backend.secureStore`'s type in
    `lib/bootstrap.dart` and use the same interface). It reads `device_install_id`; if it is
    missing, it writes `const Uuid().v4()` first. iOS options must be
    `IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device, synchronizable:
    false)`. If the existing store wrapper cannot pass options, construct a dedicated
    `FlutterSecureStorage(iOptions: …)` inside this class;
  - `final class AndroidDeviceIdentity implements DeviceIdentity`, which calls
    `MethodChannel('on_air/device_identity').invokeMethod<String>('androidId')`. A null or empty
    result or a `MissingPluginException` throws `DeviceIdentityUnavailable`;
  - `DeviceIdentity platformDeviceIdentity(...)`: returns the Keychain identity on iOS and the
    Android one otherwise, using `defaultTargetPlatform`.
- [X] T023 [P] Create `lib/core/device/app_attestation.dart`:
  - `abstract interface class AppAttestation { Future<String?> limitedUseToken(); }`;
  - `final class FirebaseAppAttestation implements AppAttestation`: `limitedUseToken()` returns
    `FirebaseAppCheck.instance.getLimitedUseToken()` and returns `null` on any exception (never
    log the token);
  - `final class NoAttestation implements AppAttestation` returns `null` (mock mode and tests).
- [X] T024 Create `lib/core/network/otp_send_interceptor.dart`:
  - `final class OtpSendInterceptor extends Interceptor`, constructed with `DeviceIdentity` and
    `AppAttestation`;
  - in `onRequest`, only when `options.method == 'POST' && options.path.endsWith('/v1/otp/send')`:
    set `X-Device-Id` (on `DeviceIdentityUnavailable`, skip the header) and set
    `X-Firebase-AppCheck` when the token is non-null;
  - always call `handler.next(options)`.

  In `lib/core/network/dio_factory.dart` add optional named params `DeviceIdentity? deviceIdentity,
  AppAttestation? attestation` to `createNodeDio`. When both are non-null, insert
  `OtpSendInterceptor` right after `AuthInterceptor`.
- [X] T025 Bootstrap wiring in `lib/bootstrap.dart`:
  - in `_remoteBackend`, after `await Firebase.initializeApp();`, call
    `await FirebaseAppCheck.instance.activate(...)` with `AndroidProvider.playIntegrity` and
    `AppleProvider.appAttestWithDeviceCheckFallback` in release builds, and the debug providers
    when `kDebugMode`;
  - create `platformDeviceIdentity(...)` and `FirebaseAppAttestation()`, and pass both to
    `createNodeDio`;
  - in `_mockBackend` use a `KeychainDeviceIdentity`-like in-memory fake (`MemoryDeviceIdentity`
    returning `'mock-device'`, put it next to `MockBackend` in
    `lib/core/config/mock_backend.dart`) and `NoAttestation()`.

  Expose `DeviceIdentity` via `RepositoryProvider` (it is needed by the mock OTP server in US5).
- [X] T026 Update `test/helpers/fake_auth_repository.dart` and `lib/features/auth/data/mock_auth_repository.dart`:
  - every created `GuestAccount` gets a `status`;
  - existing complete mock users are `AccountStatus.active` with a phone;
  - newly signed-up email users are `AccountStatus.incomplete` with `phone: null` after email
    verification.

  Run the whole suite and fix the remaining failures caused by the `isComplete` change (do not
  change test intent; update the account fixtures).

**Checkpoint**:
- `flutter analyze` is clean and `flutter test` passes;
- the app runs in mock mode;
- an incomplete mock account is redirected to the **old** complete-profile screen (it is replaced
  in US3);
- no SMS code remains (`grep -rni "sms" lib` shows only comments about "no SMS").

---

## Phase 3: User Story 1 — Sign in or register with Google (Priority: P1) 🎯 MVP

**Goal**: one-tap Google sign-in from login and registration; complete accounts return to `from`,
and new accounts go to «أكّد رقمك».

**Independent Test**: mock mode → open an apartment → «احجز الآن» → login → Google
(scenario "complete user") → back on the same apartment, signed in (quickstart V1/V16).

### Tests for US1

- [ ] T027 [P] [US1] Write `test/design_system/components/social_sign_in_button_test.dart`:
  - renders the asset for each provider;
  - has `Semantics` label `authContinueWithGoogle` / `authContinueWithApple`;
  - is ≥ 48×48;
  - `busy: true` shows a `CircularProgressIndicator` and ignores taps;
  - `enabled: false` ignores taps.
- [ ] T028 [P] [US1] Add to `test/features/auth/presentation/auth_cubit_test.dart`:
  - `signInWithGoogle()` success with an active account → `SignedIn(isComplete: true)`;
  - success with an incomplete account → `SignedIn(isComplete: false)` and `providerFullName`
    set;
  - `SocialSignInCancelled` → state unchanged, `socialBusy` back to null, no error;
  - a generic failure → `socialError` set to `authSocialFailed`;
  - a second call while busy is ignored (the repository is called once).

### Implementation for US1

- [ ] T029 [P] [US1] Create `lib/design_system/components/social_sign_in_button.dart` (contracts/ui-screens.md §1):
  - `final class SocialSignInButton extends StatelessWidget` with `required SocialProvider
    provider`, `required VoidCallback? onPressed`, `bool busy = false`;
  - a 56×56 circle, surface from the Social Fill token in `context.colors` (find the token
    names in `lib/design_system/` with `grep -rn -i social lib/design_system`), border
    `borderSubtle`, 24dp logo `Image.asset`;
  - Apple uses `apple_logo_black.png` in light and `apple_logo_white.png` in dark;
  - busy → 24dp `CircularProgressIndicator(strokeWidth: 2)`;
  - wrap in `Semantics(button: true, label: …)`.

  Put `enum SocialProvider { google, apple }` in `lib/features/auth/domain/social_identity.dart`
  (T030) and import it. If the design system must not import features, move the enum to
  `lib/design_system/components/social_sign_in_button.dart` and re-export it from
  `social_identity.dart`; the design system must not import `features/`.
- [ ] T030 [P] [US1] Create `lib/features/auth/domain/social_identity.dart` with these classes (data-model §2):
  - `SocialSignInCancelled implements Exception`;
  - `SocialSignInUnavailable implements Exception`;
  - `SocialSignInResult { final GuestAccount account; final String? providerFullName; }`;
  - `SocialCredential { provider, idToken, accessToken?, rawNonce?, givenName?, familyName? }`,
    with a doc comment saying it is memory only and must never be logged.
- [ ] T031 [US1] Create `lib/features/auth/data/social_credential_source.dart`:
  - `abstract interface class SocialCredentialSource { Future<SocialCredential> google();
    Future<SocialCredential> apple(); }`;
  - `GoogleAppleCredentialSource` implements it with `google_sign_in`:
    - initialize once with `serverClientId: env.googleServerClientId` and `clientId:
      env.googleIosClientId` on iOS;
    - `authenticate()`;
    - read `idToken`;
    - map the package's cancel exception to `SocialSignInCancelled`;
    - a null `idToken` → throw `StateError`.

  `apple()` is filled in by US2 (throw `SocialSignInUnavailable` for now). Read the installed
  `google_sign_in` version's README in `~/.pub-cache` (or the pub.dev page for that exact
  version) for the exact API names before writing code.
- [ ] T032 [US1] In `lib/features/auth/domain/auth_repository.dart` add `Future<SocialSignInResult> signInWithGoogle();` and `Future<SocialSignInResult> signInWithApple();`. Implement them:
  - **Supabase** (`supabase_auth_repository.dart`): get the credential from
    `SocialCredentialSource`, call
    `_client.signInWithIdToken(provider: OAuthProvider.google, idToken: c.idToken, accessToken:
    c.accessToken)`, then `_accountFor(response.user)`. Return `SocialSignInResult(account,
    providerFullName: <Google display name or null>)`. Map `AuthException` with a network cause
    to `AuthNetworkFailure`; map others to `AuthRequestRejected('SOCIAL_FAILED')`.
  - **Mock** (`mock_auth_repository.dart`): add `MockSocialScenario { newUser, incompleteUser,
    completeUser, legacyUser, unconfirmedEmailCollision, cancel, failure }` with a settable
    `scenario` field (default `newUser`). Return the matching account: `newUser` → `incomplete`,
    `providerFullName: 'Mona Adel'`; `cancel` → throw `SocialSignInCancelled`; `failure` → throw
    `AuthRequestRejected('SOCIAL_FAILED')`.
  - **Fake** (`test/helpers/fake_auth_repository.dart`): settable `socialResult` and
    `socialError`, plus a counter.
- [ ] T033 [US1] In `AuthCubit` add:
  - `SocialProvider? socialBusy` and `String? socialError` (message key). Expose them through a
    small `ValueNotifier<SocialSignInUiState>` named `social` (fields `busy`, `errorKey`) so the
    login screen can listen without changing `AuthState`;
  - `Future<void> signInWithGoogle()`: return early if `social.value.busy != null`; set busy; call
    the repository; on success store `providerFullName` in a private field (getter
    `providerFullName`) and `_emitAccount`; on `SocialSignInCancelled` clear busy only; on another
    error set `errorKey = 'authSocialFailed'`; always clear busy in `finally`;
  - clear `providerFullName` in `signOut()`.
- [ ] T034 [US1] Update `lib/features/auth/presentation/login_screen.dart` (sign-in and registration modes), per contracts/ui-screens.md §2–§3:
  - under the primary button add a row: `Expanded(Divider)` · `Text(l10n.authOr)` ·
    `Expanded(Divider)`;
  - then a centred `Wrap(spacing: Dimens.space16)` of `SocialSignInButton`s. On iOS
    (`defaultTargetPlatform == TargetPlatform.iOS`) show Apple then Google; on Android show
    Google only;
  - hide the Google button if `EnvConfig.googleServerClientId == null` **and** the backend mode is
    remote (mock mode always shows it);
  - listen to `AuthCubit.social`: pass `busy` to the matching button, and disable **all** buttons
    and the email submit while `busy != null`;
  - show `errorKey` in the existing inline error style above the row;
  - in mock mode only (`BackendMode.mock`) and `kDebugMode`, a long-press on the Google button
    opens a simple `SimpleDialog` to pick the `MockSocialScenario` (this lets testers reach every
    scenario).
- [ ] T035 [US1] `SignOutService` (`lib/features/account_gate/application/sign_out_service.dart`): add an optional `Future<void> Function()? socialSignOut` constructor param, called inside the existing try/catch flow (errors ignored). In `bootstrap.dart` pass `() => GoogleSignIn.instance.signOut()` in remote mode. Do **not** delete `device_install_id` (research R13). Add a unit test in the existing sign-out test file: `socialSignOut` is called once and its failure does not stop sign-out.
- [ ] T036 [US1] Goldens: in `test/features/auth/goldens/login_golden_test.dart` add the variants `ios` (Apple + Google) and `android` (Google only) by overriding `debugDefaultTargetPlatformOverride` inside each golden (reset it after), in light/dark × 1.0/1.3. Add `test/design_system/goldens/social_sign_in_button_golden_test.dart`: each provider × {enabled, busy, disabled} × {light, dark}. Generate them and check the PNGs.
- [ ] T037 [US1] Integration test `integration_test/social_sign_in_mock_test.dart` (use the helpers in `integration_test/helpers` and `test/helpers/mock_journey.dart` as patterns):
  - (a) scenario `completeUser`: open the first apartment → «احجز الآن» → Google → back on the
    same apartment and signed in;
  - (b) scenario `cancel`: still on login, with no error text;
  - (c) double-tap Google → the mock repository's call counter is 1.

**Checkpoint**: US1 works in mock mode (a complete Google user signs in and returns). A new Google
user lands on the old completion screen until US3.

---

## Phase 4: User Story 2 — Sign in or register with Apple on iOS (Priority: P1)

**Goal**: Apple sign-in on iOS with a nonce, the first-time name, and relay email support.

**Independent Test**: iOS simulator, mock mode, scenario `newUser` via Apple → «أكّد رقمك» shows
the relay email and an empty required name (quickstart V8/V9).

- [ ] T038 [P] [US2] Write `test/features/auth/data/apple_nonce_test.dart`:
  - `generateRawNonce()` returns 32 bytes as a 64-char URL-safe string, and two calls differ;
  - `sha256Hex(raw)` equals the known SHA-256 of a fixed input (compute the expected value with
    `crypto` in the test).
- [ ] T039 [US2] In `lib/features/auth/data/social_credential_source.dart`:
  - add the top-level functions `String generateRawNonce()` (`Random.secure()`, 32 bytes,
    base64Url without padding) and `String sha256Hex(String input)`;
  - implement `apple()` with `SignInWithApple.getAppleIDCredential(scopes:
    [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName], nonce:
    sha256Hex(raw))`;
  - return `SocialCredential(provider: apple, idToken: credential.identityToken!, rawNonce: raw,
    givenName: credential.givenName, familyName: credential.familyName)`;
  - map `SignInWithAppleAuthorizationException` with code `canceled` to `SocialSignInCancelled`;
  - on non-iOS throw `SocialSignInUnavailable`.
- [ ] T040 [US2] Implement `signInWithApple()`:
  - **Supabase**: `signInWithIdToken(provider: OAuthProvider.apple, idToken: c.idToken, nonce:
    c.rawNonce)`. `providerFullName` = `'${givenName ?? ''} ${familyName ?? ''}'.trim()`, or
    `null` if empty.
  - **Mock**: the same scenarios as Google, plus `newUser` returns email
    `'x7k2@privaterelay.appleid.com'` and `providerFullName: null`.
  - **AuthCubit**: `signInWithApple()` mirrors `signInWithGoogle()` (share one private helper).
  - Wire the Apple button `onPressed` in `login_screen.dart`.
- [ ] T041 [US2] Add to `test/features/auth/presentation/login_screen_social_test.dart` (new):
  - Apple is visible only when `debugDefaultTargetPlatformOverride = TargetPlatform.iOS`;
  - Google is visible on both;
  - while Apple is busy, Google is disabled.

**Checkpoint**: Apple works on iOS in mock mode, and Android shows Google only.

---

## Phase 5: User Story 3 — Mandatory «أكّد رقمك» step (Priority: P1)

**Goal**: the new `ConfirmPhoneScreen` form step replaces `CompleteProfileScreen`. It cannot be
skipped, leaving it signs the guest out, and it shows name/terms only when missing.

**Independent Test**: a mock Google new user is redirected to «أكّد رقمك» from favorites, My
Bookings, the account, «احجز الآن» and a booking deep link. Back → dialog → visitor again
(quickstart V1, V3).

### Tests for US3

- [ ] T042 [P] [US3] Write `test/features/auth/phone_verification/phone_verification_cubit_form_test.dart` (bloc_test, with a fake `PhoneVerificationRepository`):
  - initial `PvForm`;
  - submit with an invalid phone → field error `authPhoneInvalid` and no repository call;
  - name required only when `needsName == true`, and it must be 2–80 chars;
  - terms required only when `needsTerms == true`;
  - `start` throws `AppFailure(phoneAlreadyUsed)` → `PvForm` with the phone field error
    `authPhoneAlreadyUsed`;
  - `PHONE_COUNTRY_NOT_SUPPORTED` → phone field error `authPhoneCountryNotSupported`;
  - `TERMS_CHANGED` → `termsAccepted` is reset to false and `termsChanged: true`;
  - `PROFILE_ALREADY_COMPLETE` → calls `onAlreadyComplete` (the screen refreshes the account).
- [ ] T043 [P] [US3] Write `test/features/auth/phone_verification/confirm_phone_screen_form_test.dart` (widget):
  - register purpose + `needsName` → the name, phone and terms fields are visible;
  - legacy-like email account (`needsName == false`, `needsTerms == false`) → only phone;
  - «متابعة» is disabled until valid;
  - the back button opens the dialog with `confirmPhoneLeaveTitle`; «كمّل» keeps the entries;
    «خروج» calls `AuthCubit.signOut()`;
  - the phone field text is not stored anywhere after `dispose()` (assert the fake repository and
    a fake secure store saw no phone).

### Implementation for US3

- [ ] T044 [P] [US3] Create `lib/features/auth/phone_verification/domain/phone_verification_repository.dart` with these models (data-model §3):
  - `enum PhoneVerificationPurpose { register, change }`;
  - `PhoneVerificationDraft { EgyptPhone phone; String? fullName; String? acceptedTermsVersion;
    String locale; }` — no `toJson`; the doc says memory only;
  - `SendWindow { DateTime serverTime; DateTime? nextSendAt; DateTime? blockedUntil; }` with
    `Duration clockOffset(DateTime deviceNow) => serverTime.difference(deviceNow)` and
    `Duration remainingUntilSend(DateTime deviceNow)`, which returns `Duration.zero` when
    `nextSendAt` is null or in the past, using `deviceNow + offset`;
  - `enum DeliveryStatus { pending, sent, delivered, read, failed, unknown }` and
    `enum DeliveryFailure { notOnWhatsApp, other }`;
  - `WhatsAppChallenge { String challengeId; String maskedPhone; DateTime expiresAt; SendWindow
    window; }`.

  The interface (all failures throw `AppFailure` with `ApiError.details` filled):
  - `Future<String> start(PhoneVerificationDraft draft, PhoneVerificationPurpose purpose);`
  - `Future<WhatsAppChallenge> send(String challengeId);`
  - `Future<(DeliveryStatus, DeliveryFailure?, SendWindow)> status(String challengeId);`
  - `Future<GuestAccount> verify(String challengeId, String code);`
- [ ] T045 [US3] Create `lib/features/auth/phone_verification/presentation/phone_verification_cubit.dart`. Implement **only the form part** now (states `PvForm`, `PvDone` as data-model §4):
  - constructor `(PhoneVerificationRepository repo, {required PhoneVerificationPurpose purpose,
    required bool needsName, required bool needsTerms, String? prefilledName, required String
    locale, required String? currentTermsVersion, DateTime Function()? clock})`;
  - `PvForm` fields: `phoneText`, `nameText`, `termsAccepted`, `termsChanged`, `submitting`,
    `phoneErrorKey`, `nameErrorKey`, `generalErrorKey`;
  - `submit()` validates with `EgyptPhone.tryParse` and the name length rule, then calls
    `repo.start(...)` (the code step continues in US4 with `send`);
  - map errors exactly as in T042;
  - the cubit keeps no static state and writes nothing to storage.
- [ ] T046 [US3] Create `lib/features/auth/phone_verification/presentation/confirm_phone_screen.dart` and `widgets/phone_form_step.dart` per contracts/ui-screens.md §4.1:
  - use `AuthFlowScaffold` + `AuthBrandHeader` for `register`, and a normal `Scaffold` + `AppBar`
    titled `confirmPhoneNewTitle` for `change`;
  - read `AuthCubit` state for `needsName` (`account.fullName == null`) and `needsTerms`
    (`account.acceptedTermsVersion == null`);
  - read `prefilledName` from `AuthCubit.providerFullName`;
  - read the current terms version from `AppConfigSource.load()`, as the old
    `complete_profile_screen.dart` did;
  - the email row is read-only with the mail icon (register only);
  - the phone field uses the existing pill `OnAirTextField` with `keyboardType:
    TextInputType.phone`, `autofillHints: [AutofillHints.telephoneNumber]`, and helper text
    `confirmPhoneSubtitle` as the screen subtitle;
  - the primary button uses the existing gradient auth button with `confirmPhoneContinue`;
  - `PopScope(canPop: false)` with `onPopInvokedWithResult` that shows the leave dialog (register
    only): `confirmPhoneLeaveTitle`, `confirmPhoneLeaveBody`, actions `confirmPhoneLeaveStay`
    and destructive `confirmPhoneLeaveConfirm`. Confirm → `context.read<AuthCubit>().signOut()`,
    then `context.go(resolveAuthCancelDestination(from))`.
- [ ] T047 [US3] Routing:
  - in `lib/app/router/app_router.dart`, change the `AppRoutes.completeProfile` builder to
    `ConfirmPhoneScreen(purpose: PhoneVerificationPurpose.register, from:
    state.uri.queryParameters['from'])` and provide the cubit with `BlocProvider` there;
  - delete `lib/features/auth/presentation/complete_profile_screen.dart` and
    `test/features/auth/presentation/complete_profile_test.dart`;
  - leave `redirect.dart` logic as is (rule 7 already sends incomplete accounts here). Confirm
    with T011.
- [ ] T048 [US3] Provide a `PhoneVerificationRepository` in `lib/bootstrap.dart`: `SupabasePhoneVerificationRepository` in remote mode (created in US4) and `MockPhoneVerificationRepository` in mock mode (created in US5). Until then, register a temporary `MockPhoneVerificationRepository` stub in `lib/features/auth/phone_verification/data/mock_phone_verification_repository.dart` where `start` returns `'mock-challenge'`.
- [ ] T049 [US3] Goldens `test/features/auth/goldens/confirm_phone_form_golden_test.dart`, following `login_golden_test.dart`:
  - full form (Apple, no name) and number-only form;
  - each in light/dark × RTL/LTR × 1.0/1.3, at widths 320 and 800;
  - plus one with the keyboard open: set `MediaQuery.viewInsets.bottom = 300`.

**Checkpoint**: a new Google user cannot reach any account screen without «أكّد رقمك», and leaving
signs them out.

---

## Phase 6: User Story 4 — Confirm the number with a WhatsApp code (Priority: P1)

**Goal**: the code step with send, delivery status, verify and success, against the real contracts
(remote) and the mock.

**Independent Test**: mock, number `01012345678`, code `123456` → account active → back to the
apartment. A wrong code then app restart → still incomplete with no phone (quickstart V2, V3, V7).

### Tests for US4

- [ ] T050 [P] [US4] Write `test/features/auth/phone_verification/phone_verification_cubit_code_test.dart` (bloc_test + `fake_async`):
  - after `start`, the cubit calls `send` → `PvCode(challenge)`;
  - polling calls `status` every 5 s and stops after 60 s, or at the first `delivered` / `read` /
    `failed`;
  - `failed + notOnWhatsApp` → `notice: PvNotice.notOnWhatsApp` and polling stops;
  - `verify` with `OTP_INVALID` → `errorKey authOtpInvalid`;
  - `OTP_EXPIRED` → `authOtpExpired`;
  - `OTP_SUPERSEDED` → `whatsappUseLatestCode`;
  - `OTP_ATTEMPTS_EXCEEDED` → `otpAttemptsExceeded` and `codeFieldEnabled == false`;
  - `PHONE_ALREADY_USED` at verify → back to `PvForm` with the phone error;
  - success → `PvDone(account, purpose)`;
  - «تعديل الرقم» → `PvForm` with the previous draft values;
  - `close()` cancels the timers (no pending timers in `fake_async`).
- [ ] T051 [P] [US4] Write `test/features/auth/phone_verification/supabase_phone_verification_repository_test.dart` with mocked RPC and Node clients:
  - `start(register)` calls RPC `common_start_phone_verification` with `p_phone`, `p_full_name`,
    `p_accepted_terms_version`, `p_locale`, exactly as contracts/supabase-auth.md A5;
  - `start(change)` calls `common_request_phone_change` with `p_new_phone` only;
  - `send` calls the generated `sendOtpCode` and maps `next_send_at`, `blocked_until`,
    `server_time`, `masked_target` and `expires_at`;
  - `status` calls `common_get_otp_status`;
  - `verify` calls `common_verify_otp` and maps the returned profile to `GuestAccount`;
  - a Node 429 with `OTP_SEND_BLOCKED` becomes `AppFailure` whose `details['blocked_until']` is
    set.

### Implementation for US4

- [ ] T052 [US4] Update `contracts/node-api.openapi.yaml` `/v1/otp/send` to match `specs/005-guest-social-sign-in/contracts/node-otp.md` A8:
  - document the two request headers as optional parameters (`X-Device-Id`,
    `X-Firebase-AppCheck`);
  - change the `OtpSent` schema to `channel` (enum `email|whatsapp`), `masked_target` (string),
    `expires_at`, `next_send_at` (nullable), `blocked_until` (nullable), `server_time`, and keep
    `sent_to_masked` / `retry_after_seconds` as **optional** for email back-compat;
  - add the new error codes to the error code enum in that file.

  Then run `dart run swagger_parser` and `dart run build_runner build
  --delete-conflicting-outputs`. Fix the existing callers of `OtpSent` (`grep -rn OtpSent lib`)
  to use the optional fields safely.
- [ ] T053 [US4] Create `lib/features/auth/phone_verification/data/supabase_phone_verification_repository.dart` implementing T044's interface:
  - it is constructed with the same RPC helper type used by `SupabaseStayRepository` (check
    `bootstrap.dart`) and `FallbackClient`;
  - map RPC errors with `ErrorMapper.fromCode` exactly like `lib/features/stay/data/` does;
  - Node errors already arrive as `AppFailure` from `ErrorInterceptor`. Make sure the interceptor
    passes `details` (update `ErrorInterceptor` in `dio_factory.dart` to read
    `error.details` from the body into `ErrorMapper.fromCode(details: …)` if it does not
    already).
- [ ] T054 [US4] Extend `PhoneVerificationCubit` with the code part:
  - after `start` succeeds, call `send` → `PvCode`;
  - start a `Timer.periodic(5s)` for `status`, max 12 ticks;
  - `onCodeChanged`, `verify()` (6 digits only), `resend()` (US5 completes the window logic),
    `editNumber()`;
  - `PvNotice { notOnWhatsApp, attestationFailed, temporarilyUnavailable }`: map
    `APP_ATTESTATION_FAILED` and `OTP_TEMPORARILY_UNAVAILABLE` from `send` to these;
  - on success with `register`, call the `onRegistered` callback (the screen calls
    `AuthCubit.refreshAccount()`); with `change`, call `onChanged`;
  - every async action ignores re-entry while one is in flight.
- [ ] T055 [US4] Create `lib/features/auth/phone_verification/presentation/widgets/whatsapp_code_step.dart` per contracts/ui-screens.md §4.2:
  - title `whatsappCodeTitle` and body `whatsappCodeSentTo(phone: challenge.maskedPhone)`;
  - `OnAirOtpField` with `AutofillHints.oneTimeCode` (copy its use from `otp_screen.dart`);
  - gradient primary `whatsappConfirm`, enabled at 6 digits;
  - outlined `whatsappOpen`, which calls `launchUrl(Uri.parse('whatsapp://'))` inside try/catch
    and silently does nothing on failure;
  - text buttons `whatsappResend` (wired in US5) and `whatsappEditNumber`;
  - `NoticeCard` for each `PvNotice` (find `NoticeCard` with `grep -rn "class NoticeCard" lib`),
    with `whatsappContactSupport` opening `tel:` + `AppConfig.supportPhone` (support screens are
    G4);
  - code errors shown under the field in the error style.

  Show this widget from `ConfirmPhoneScreen` when the state is `PvCode`.
- [ ] T056 [US4] Success handling in `ConfirmPhoneScreen`:
  - `register` → `await context.read<AuthCubit>().refreshAccount()`, then show a `SnackBar` with
    `confirmPhoneWelcome`. The router redirect (rule 8) moves the guest to `from`; do **not**
    navigate manually unless still on the screen after refresh. In that case,
    `context.go(resolveAuthReturnDestination(from))`.
  - `change` → `context.pop(true)` and a `SnackBar` with `phoneChanged`.
- [ ] T057 [US4] Replace the stub with a real `MockPhoneVerificationRepository` that delegates to `MockOtpServer` (T061, US5). For now implement **without limits**:
  - `start` validates like the server (Egyptian, not `01111111111` which is "already used");
  - `send` returns `maskedPhone` like `+20 10•• ••• 678`, `expiresAt = now + 10 min`, and
    `nextSendAt = now + 30 s`;
  - `status` returns `delivered` after 2 s, except numbers ending `0000` → `failed` +
    `notOnWhatsApp`;
  - `verify` accepts only `MockBackend.verificationCode`. On success, set the mock account's
    `phone`, `phoneVerified: true` and `status: active` (call into `MockAuthRepository`).
- [ ] T058 [US4] Goldens `test/features/auth/goldens/whatsapp_code_step_golden_test.dart`: states counting (seconds), ready, code error, not-on-WhatsApp notice, attestation notice, each light/dark × RTL/LTR × 1.0/1.3 at 320 and 800.
- [ ] T059 [US4] Integration test `integration_test/social_sign_in_mock_test.dart`, add case (d): scenario `newUser` → «أكّد رقمك» → phone `01012345678` → code `123456` → lands on the apartment, and `MockAuthRepository` shows the account `active`. Add case (e): a wrong code `000000`, then restart the app widget (pump a new `MockApp` with the same mock backend instance) → «أكّد رقمك» opens with an **empty** phone field and the account has `phone == null`.

**Checkpoint**: the MVP is complete. A new Google user finishes registration with a WhatsApp code
in mock mode.

---

## Phase 7: User Story 5 — Resend ladder and anti-spam block (Priority: P1)

**Goal**: render the server's `next_send_at` / `blocked_until` correctly. The mock server
implements the ladder and the 7-day block across account, phone and device keys.

**Independent Test**: mock → request codes until blocked; countdowns follow the ladder; the 11th
request shows the block; the block survives a simulated reinstall and an account switch
(quickstart V4–V6).

### Tests for US5

- [ ] T060 [P] [US5] Write `test/features/auth/phone_verification/mock_otp_server_test.dart` (`fake_async`, injectable clock):
  - waits after sends 1–9 are exactly `30s, 5m, 1h, 24h, 1h, 24h, 1h, 24h, 1h`;
  - a request before `nextSendAt` → `RATE_LIMITED` with `next_send_at`;
  - the 11th request → `OTP_SEND_BLOCKED` with `blocked_until = now + 7 days`, set on account,
    phone **and** device keys;
  - a new account on the same device is blocked;
  - the same phone from another device and account is blocked;
  - after 7 days the block ends and counters reset;
  - 7 idle days without a block → counters reset;
  - success via `verify` resets the three keys;
  - `attestationFails = true` → `APP_ATTESTATION_FAILED` and nothing counted;
  - a "not on WhatsApp" send still counts.
- [ ] T061 [P] [US5] Write `test/features/auth/phone_verification/send_window_format_test.dart`:
  - `formatSendWait(Duration)` returns `mm:ss` under 1 h (`00:30`, `04:59`);
  - for ≥ 1 h it returns `durationHoursMinutes` with hours and minutes (`1h 0m`, `23h 10m`);
  - `remainingUntilSend` uses the server offset: device clock 10 min behind → the remaining time
    still equals the server difference.

### Implementation for US5

- [ ] T062 [US5] Create `lib/features/auth/phone_verification/data/mock_otp_server.dart` exactly per contracts/node-otp.md A8 "Processing order" and "Ladder":
  - keys are plain strings `acct:<id>`, `phone:<e164>`, `dev:<deviceId>` (no hashing in the
    mock);
  - each key record holds `sendCount`, `lastSendAt`, `nextSendAt` and `blockedUntil`;
  - the constructor takes `DateTime Function() clock`;
  - `bool attestationFails` (default false) and a `List<String> callLog` (method names) for tests;
  - `MockPhoneVerificationRepository.send` calls `MockOtpServer.send(accountId, phone,
    deviceId)`, with the device id from the injected `DeviceIdentity` (T025's
    `MemoryDeviceIdentity`).
- [ ] T063 [US5] In `PhoneVerificationCubit` and `WhatsAppCodeStep`:
  - keep the latest `SendWindow`, and feed a `Stream<Duration>` ticking every second to
    `CountdownText` (only the text rebuilds);
  - `whatsappResend` is disabled while the remaining time is > 0 and shows
    `whatsappResendIn(time: formatSendWait(remaining))`;
  - `resend()` calls `send(challengeId)`. `RATE_LIMITED` updates the window from
    `details.next_send_at`. `OTP_SEND_BLOCKED` → state `PvBlocked(blockedUntil, serverTime)`.
  - Put `formatSendWait` in `widgets/send_window_notice.dart`.
- [ ] T064 [US5] Create `lib/features/auth/phone_verification/presentation/widgets/send_window_notice.dart` with `BlockedNotice` (contracts/ui-screens.md §4.3):
  - warning-tone `NoticeCard` with `otpBlockedUntil(date: …)`;
  - format the date in Cairo time with the existing date formatter in `lib/core/time/` (find it
    with `grep -rn Cairo lib/core/time`);
  - buttons `whatsappContactSupport` and, for `register`, the existing sign-out text.

  Disable every send and confirm control while blocked. `PvBlocked` can also be reached from
  `start`/`send` on the form step: show the same notice there.
- [ ] T065 [US5] Goldens: add the states `counting (hours)` and `blocked` to `whatsapp_code_step_golden_test.dart` (same matrix).
- [ ] T066 [US5] Integration test `integration_test/phone_otp_limits_mock_test.dart`, driving the mock clock through a debug-only `MockClock` exposed by `MockBackend` (add `static DateTime Function() clock = DateTime.now;` and use it in `MockOtpServer`; tests replace it):
  - (a) the countdown text matches each ladder step;
  - (b) the 11th request shows the block date;
  - (c) recreate the app with the same mock backend (same `MemoryDeviceIdentity`) → still
    blocked;
  - (d) sign out, use scenario `newUser` with a different account id → still blocked (device
    key);
  - (e) `attestationFails = true` → attestation notice and `callLog` shows no counted send.

**Checkpoint**: all P1 stories are done. Run quickstart V1–V9 and V15–V17 in mock mode.

---

## Phase 8: User Story 6 — Email registration and phone change use the same step (Priority: P2)

**Goal**: email signup without phone; after the email code → «أكّد رقمك» (number only); change
number from the account via WhatsApp; legacy accounts untouched.

**Independent Test**: register by email in mock → email code `123456` → «أكّد رقمك» with only the
phone field → WhatsApp code → active. Then the account → «تغيير» → new number → code → snackbar
(quickstart V10–V12).

- [ ] T067 [P] [US6] Update `test/features/auth/presentation/email_flows_test.dart` and `auth_validation_test.dart`:
  - registration has no phone field;
  - `signUpEmail` is called with `(name, email, password, termsVersion)`;
  - after `verifyEmailCode` the account is `incomplete` and the router target is
    `/auth/complete-profile`.
- [ ] T068 [US6] Remove the phone from email registration:
  - `AuthRepository.signUpEmail(String name, String email, String password, String
    termsVersion)` (drop `phone`) in the interface and the Supabase, mock and fake repositories,
    plus `AuthCubit.requestEmailSignup`;
  - in `SupabasePhoneAuthClient.signUpWithEmail` send `data: {'full_name': name,
    'accepted_terms_version': termsVersion, 'locale': <current locale code>}` (no phone keys);
  - in `login_screen.dart` registration mode remove the phone field (`email-phone-field`), its
    validation and `_validPhone` use;
  - remove the now-unused ARB keys (`grep` each) and regenerate l10n;
  - update the registration golden.
- [ ] T069 [US6] Mock: `MockAuthRepository.verifyEmailCode` returns an account with `status: incomplete, phone: null`. Add a seeded **legacy** mock user (`legacy@onair.test`, active, phone `+201012340000`, `phoneVerified: true`) used by the `legacyUser` social scenario and by email sign-in.
- [ ] T070 [US6] Change number:
  - add `AppRoutes.accountPhone = '/account/phone'` in `lib/app/router/routes.dart`, add it to
    `requiresAccount` and the registered locations (copy how `AppRoutes.account` is listed);
  - add the `GoRoute` in `app_router.dart` building `ConfirmPhoneScreen(purpose:
    PhoneVerificationPurpose.change)` (needsName/needsTerms are false for change);
  - `MockPhoneVerificationRepository.start(change)` requires an `active` account and keeps the
    old phone until `verify` succeeds.
- [ ] T071 [US6] Booking verify step (`lib/features/booking/presentation/verify_identity_screen.dart` and `verify_identity_cubit.dart`):
  - replace the `_PhoneStep` UI and the `submitPhone` / `resendCode` / `_CodeStep` phone logic
    with one card: text `bookingPhoneNotVerified` (existing key) and a primary button
    `verifyPhoneOnWhatsApp`;
  - the button does `final ok = await context.push<bool>(AppRoutes.accountPhone)`; if `ok ==
    true`, call `cubit.start()` again to re-check;
  - keep the email step unchanged;
  - delete the booking-flow phone methods only if nothing else uses them (`grep -rn
    requestPhoneChange lib`);
  - update or delete the matching tests under `test/features/booking/`.
- [ ] T072 [US6] Integration test `integration_test/email_register_phone_mock_test.dart`:
  - (a) register by email → email code → «أكّد رقمك» with only the phone field → WhatsApp code
    → home;
  - (b) the legacy user signs in → no «أكّد رقمك»;
  - (c) the account → change number → new number → code → snackbar, and the account shows the
    new masked phone.

**Checkpoint**: every account path uses the WhatsApp step, and legacy users are unaffected.

---

## Phase 9: User Story 7 — One personal account across sign-in methods (Priority: P2)

**Goal**: same confirmed email → same account; unconfirmed email signup → the provider wins;
password recovery works for accounts without a password. (The server does the linking; the app
must just behave correctly.)

**Independent Test**: mock scenarios `legacyUser` and `unconfirmedEmailCollision` (quickstart
V13, V14).

- [ ] T073 [P] [US7] Mock behaviour in `MockAuthRepository`:
  - `legacyUser` (Google with `legacy@onair.test`) returns the **same** account object (same id,
    phone, bookings) as email sign-in;
  - `unconfirmedEmailCollision`: first create an unconfirmed email signup for `collide@onair.test`
    with password `Passw0rd!`, then Google with that email returns a new `incomplete` account
    with the **same id**, and from then on `signInEmail('collide@onair.test', 'Passw0rd!')`
    throws the existing invalid-credentials error;
  - `requestRecovery` for a Google-only mock account behaves exactly like any email (same neutral
    result and code `123456`), and `setNewPassword` sets `hasPassword = true`.
- [ ] T074 [US7] Tests in `test/features/auth/data/mock_auth_repository_test.dart` (create it) for the three behaviours above, plus an integration case (f) in `integration_test/social_sign_in_mock_test.dart`: `legacyUser` → no «أكّد رقمك», and My Bookings shows the legacy bookings.

**Checkpoint**: one-account rules hold in mock mode. Staging verification is in Phase 11.

---

## Phase 10: User Story 8 — Account screen for Google / Apple users (Priority: P3)

**Goal**: show the sign-in method, the confirmed phone and the change entry on the current account
placeholder.

**Independent Test**: a complete mock Google account → the account tab shows «طريقة الدخول:
Google», the masked phone with «متأكد», and «تغيير» opens `/account/phone` (quickstart V12).

- [ ] T075 [P] [US8] Widget test `test/features/account/account_placeholder_test.dart` (create or extend):
  - Google account → the `accountMethodGoogle` text is shown;
  - email + google → both, joined with «، »;
  - the phone is shown masked (`+20 10•• ••• 678` style) with the `accountPhoneConfirmed` chip;
  - tapping `accountChangePhone` pushes `/account/phone`.
- [ ] T076 [US8] In `lib/features/account/presentation/account_placeholder_screen.dart`, for a `SignedIn` state:
  - add a row `accountSignInMethod` with the provider names;
  - add a row `accountPhone` with the masked phone. Write `maskPhone(String e164)` in
    `lib/features/auth/domain/egypt_phone.dart`: it keeps the first 4 digits after `+20` and the
    last 3, and puts `•` in the rest. Add a unit test for it in the existing `egypt_phone` test.
  - add a status chip using the existing `StatusChip` (success tone) with
    `accountPhoneConfirmed`;
  - add a text button `accountChangePhone` → `context.push(AppRoutes.accountPhone)`.

  There is no password UI now. Add a `// G4: hide «تغيير كلمة المرور» when !account.hasPassword
  (FR-043)` comment where G4 will add security settings.
- [ ] T077 [US8] Golden `test/features/account/goldens/account_rows_golden_test.dart`: light/dark × RTL/LTR × 1.0/1.3.

**Checkpoint**: all stories are done.

---

## Phase 11: Polish & Cross-Cutting Concerns

- [ ] T078 [P] Privacy/logging audit:
  - `grep -rn "print(\|debugPrint(\|logger\." lib/features/auth lib/core/device lib/core/network`;
  - confirm no phone, device id, idToken, App Check token or code is logged;
  - add a unit test asserting that `OtpSendInterceptor` never writes headers to `AppLogger` (fake
    logger records nothing containing `dev-1` / `att-1`).
- [ ] T079 [P] Accessibility pass:
  - run the app with TalkBack (Android) or VoiceOver (iOS simulator) on login, «أكّد رقمك», the
    code step and blocked;
  - check that every control is announced with its label, that countdown changes are not
    announced every second (wrap `CountdownText` in `ExcludeSemantics` and give the button a
    static label), and that field errors are announced.

  Fix any issue found.
- [ ] T080 [P] Update `contracts/error-codes.md` and `contracts/supabase-backend.md` in the repo root `contracts/` folder:
  - add the S005 codes;
  - add a short "S005 deltas" section linking to `specs/005-guest-social-sign-in/contracts/`;
  - change the statement "There is no SMS. Every code goes to the account's email" in
    `contracts/node-api.openapi.yaml` description to: "phone codes go on WhatsApp; other codes
    by email".
- [ ] T081 Update `README.md`: the env keys `GOOGLE_SERVER_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID`, the Social mock scenario picker (long-press Google in debug mock), and a pointer to `specs/005-guest-social-sign-in/quickstart.md` §1 for the manual Meta/Firebase/Google/Apple setup.
- [ ] T082 Full validation:
  - `dart format --set-exit-if-changed .`;
  - `flutter analyze`;
  - `flutter test`;
  - the three new integration tests in mock mode (commands in quickstart §3);
  - then walk quickstart V1–V17 manually in mock mode on one Android emulator and one iOS
    simulator.

  Record results in `specs/005-guest-social-sign-in/checklists/validation.md` (create it): one
  line per scenario with pass/fail and notes.
- [ ] T083 Update `docs/OnAir Guest App Plan.md` §17 S005: tick the delivered user stories and add a "حالة S005 (date)" paragraph like G3's, listing what is mock-only and that remote mode waits for backend deltas A1–A9 and manual steps M1–M14.
- [ ] T084 **Staging (only after the user confirms A1–A9 are deployed and M1–M13 are done)**:
  - set `BACKEND_MODE` to `remote` in `env/staging.json`;
  - run quickstart Staging checks: a real Google/Apple sign-in, a real WhatsApp code in Arabic
    with «نسخ الكود», a crafted RPC from an incomplete account → `PROFILE_INCOMPLETE`, and `/v1/otp/send` without
    App Check → `APP_ATTESTATION_FAILED`;
  - check the Google nonce and the unconfirmed-email behaviour (research R1/R15);
  - append the results to `checklists/validation.md`.

---

## Dependencies & Execution Order

### Phase dependencies

- **Phase 1 (Setup)**: no dependencies. T003 is manual (the user provides the assets) and blocks
  only T029/T036.
- **Phase 2 (Foundational)**: depends on Phase 1. **Blocks every story.** Internal order:
  1. T007–T012 (tests, parallel);
  2. T013 → T014 → T015;
  3. T016 → T017 → T018 → T019 → T020 → T021;
  4. T022, T023 (parallel) → T024 → T025;
  5. T026 last.
- **US1 (Phase 3)**: after Phase 2.
- **US2 (Phase 4)**: after US1 (it reuses the social button, cubit helper and login row).
- **US3 (Phase 5)**: after Phase 2. It can run in parallel with US1/US2 (different files), except
  T047 touches `app_router.dart`, which US1 does not touch.
- **US4 (Phase 6)**: after US3.
- **US5 (Phase 7)**: after US4.
- **US6 (Phase 8)**: after US5 (it reuses the full confirm flow). T068 touches `login_screen.dart`,
  so do it after US1/US2.
- **US7 (Phase 9)**: after US1 and US6 (mock accounts).
- **US8 (Phase 10)**: after US6 (needs `/account/phone`).
- **Polish (Phase 11)**: after all desired stories. T084 also waits for the backend and the manual
  setup.

### Story dependency graph

```text
Setup → Foundational ─┬─> US1 ─> US2 ─────────────┐
                      └─> US3 ─> US4 ─> US5 ─> US6 ┼─> US7
                                              └────┴─> US8 ─> Polish
```

### Within each story

Tests first (they must fail) → domain/models → data → cubit → UI → goldens → integration.

---

## Parallel Examples

```text
# Phase 2 tests together:
T007 guest_account_test.dart · T008 error_mapper_test.dart · T009 device_identity_test.dart
T010 otp_send_interceptor_test.dart · T011 redirect_test.dart · T012 auth_cubit_test.dart

# Phase 2 core pieces together (after T021):
T022 lib/core/device/device_identity.dart · T023 lib/core/device/app_attestation.dart

# US1 vs US3 in parallel (two developers):
Dev A: T027–T037 (social button, cubit, login row)
Dev B: T042–T049 (confirm-phone form step)

# US5 tests together:
T060 mock_otp_server_test.dart · T061 send_window_format_test.dart
```

---

## Implementation Strategy

### MVP (P1 stories, in order)

1. Phase 1 + Phase 2 → foundation (completeness from the server; no SMS).
2. US1 (Google) → validate V1/V16.
3. US3 + US4 (confirm the phone on WhatsApp) → validate V2/V3/V7. **This is the minimum
   shippable slice**: a new Google user can register with a confirmed phone.
4. US5 (ladder + block) → validate V4–V6. Required before any remote/Staging use (protects the
   WhatsApp budget).
5. US2 (Apple) → required before an iOS release.

### Then

6. US6 (email registration + change number) → V10–V12.
7. US7 (one account) → V13/V14.
8. US8 (account rows) → V12.
9. Polish → T082 full validation; T084 once the backend and the manual setup are ready.

---

## Notes

- `[P]` = different files and no unfinished dependency.
- Remote mode cannot be validated until backend deltas A1–A9
  ([contracts/supabase-auth.md](contracts/supabase-auth.md),
  [contracts/node-otp.md](contracts/node-otp.md)) ship in `onair-backend`, and the manual steps
  M1–M14 ([quickstart.md](quickstart.md) §1) are done. Mock mode covers every story meanwhile.
- If any instruction here conflicts with the current code (a file moved, an API differs in the
  installed package version), **stop and report** the conflict instead of improvising.
