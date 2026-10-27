---

description: "Task list for Guest App Foundation (G0)"
---

# Tasks: Guest App Foundation (G0)

**Input**: Design documents from `specs/001-guest-app-foundation/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. Constitution IX requires them: test-first for Money, Cairo time, error
mapping, router redirect, and the auth state machine; widget tests for every screen state;
goldens in light, dark, RTL, and 1.3× text; Staging E2E for phone sign-in and isolation.

**Organization**: Grouped by user story so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: User story from spec.md (US1–US8)
- Paths are relative to the repository root (single Flutter project, see plan.md)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Replace the counter template with the planned project skeleton and toolchain.

- [X] T001 Update `pubspec.yaml`: set `name: on_air`, description "OnAir Guest App"; add dependencies `flutter_localizations` (sdk), `intl`, `flutter_bloc` (Cubit), `go_router`, `supabase_flutter`, `dio`, `retrofit`, `freezed_annotation`, `json_annotation`, `flutter_secure_storage`, `shared_preferences`, `app_links`, `connectivity_plus`, `package_info_plus`, `firebase_core`, `firebase_messaging`, `smart_auth`, `uuid`, `timezone`; dev dependencies `build_runner`, `bloc_test`, `freezed`, `json_serializable`, `retrofit_generator`, `swagger_parser`, `very_good_analysis`, `mocktail`, `alchemist`, `integration_test` (sdk); remove `cupertino_icons` and Riverpod packages; set `flutter: generate: true`; use latest stable compatible versions and commit `pubspec.lock`
- [X] T002 [P] Replace `analysis_options.yaml` with `include: package:very_good_analysis/analysis_options.yaml`, exclude `**/*.g.dart`, `**/*.freezed.dart`, `lib/core/api/generated/**`, `lib/l10n/generated/**`
- [X] T003 [P] Create `l10n.yaml` with `arb-dir: lib/l10n`, `template-arb-file: app_ar.arb`, `output-localization-file: app_localizations.dart`, `output-dir: lib/l10n/generated`, `nullable-getter: false`
- [X] T004 [P] Add Cairo static TTFs for weights 400, 500, 600, 700, 800 plus `OFL.txt` under `assets/fonts/cairo/` and declare font family `Cairo` with those weights in `pubspec.yaml` (no 200/300/900)
- [X] T005 [P] Create `env/example.json` with keys `FLAVOR`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `NODE_API_BASE_URL`, `LINK_DOMAIN` (placeholder values only) and add `env/*.json` with an exception for `env/example.json` to `.gitignore`
- [X] T006 [P] Create root `contracts/` by copying `specs/001-guest-app-foundation/contracts/node-api.openapi.yaml`, `supabase-backend.md`, `error-codes.md`, `app-routes.md`, and add `contracts/README.md` stating these are drafts for the backend owner
- [X] T007 [P] Create `swagger_parser.yaml` with `schema_path: contracts/node-api.openapi.yaml`, `output_directory: lib/core/api/generated`, freezed models, dio/retrofit client
- [X] T008 Delete template `lib/main.dart` and `test/widget_test.dart`; create empty folder skeleton from plan.md (`lib/app/{router,shell}`, `lib/core/{env,api,network,auth,errors,money,time,logging,connectivity,config,push,platform}`, `lib/design_system/{tokens,typography,theme,components}`, `lib/features/{auth,account_gate,home,search,bookings,favorites,account,app_update}`, `lib/l10n`, `lib/shared`, `test/helpers`, `integration_test`, `tool`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core, design system, router base, and auth domain used by every story.

**⚠️ CRITICAL**: No user story work starts before this phase is done.

### Tests first (write, see them fail, then implement)

- [X] T009 [P] Write `test/core/money/money_test.dart`: `amountMinor` is an int in piasters, currency only `EGP`, value equality, arithmetic only with the same currency (throws otherwise), formatting uses Western digits through the single formatter
- [X] T010 [P] Write `test/core/time/cairo_time_test.dart`: UTC ISO-8601 timestamps display in `Africa/Cairo` regardless of the test's device zone (including a DST date); `DateOnly(year, month, day)` has no time or zone and parses/serializes as `YYYY-MM-DD`
- [X] T011 [P] Write `test/core/errors/error_mapper_test.dart`: every code in `contracts/error-codes.md` maps to its camelCase ARB key; unknown code → `INTERNAL`/`errorUnexpected` with `requestId` kept; no response → `network`/`errorNoConnection`; `details.retry_after_seconds` and `Retry-After` header → `retryAfter`
- [X] T012 [P] Write `bloc_test` cases in `test/features/auth/presentation/auth_cubit_test.dart` covering every transition in data-model.md "AuthState": unknown→signedOut/signedIn, signedOut→codeSent→signedIn, codeSent→rateLimited→codeSent, signedIn(incomplete)→signedIn(complete), signedIn→sessionEnded(returnTo)→signedOut, signedIn→signingOut→signedOut; `resendAt`/`until` only from server values
- [X] T013 [P] Write `test/core/logging/app_logger_test.dart`: redaction masks Egyptian phone numbers, emails, and JWT-like strings; release level drops `debug`/`info`
- [X] T014 [P] Write `test/core/env/env_config_test.dart`: rejects non-HTTPS `NODE_API_BASE_URL` and `SUPABASE_URL`; rejects a `SUPABASE_ANON_KEY` whose JWT payload `role` is `service_role`; requires all keys
- [X] T015 [P] Write `test/core/network/interceptors_test.dart`: every request has `x-request-id` (UUID v4) and `Authorization: Bearer <current token>`; on 401 refresh once and retry once, a second 401 surfaces `UNAUTHENTICATED`; error bodies become `ApiError`

### Core implementation

- [X] T016 [P] Implement `Money` and `MoneyFormatter` in `lib/core/money/money.dart` (passes T009)
- [X] T017 [P] Implement `DateOnly` and `CairoTime` (init `timezone` database, `Africa/Cairo` location) in `lib/core/time/date_only.dart` and `lib/core/time/cairo_time.dart` (passes T010)
- [X] T018 [P] Implement `ErrorCode` enum (all codes in `contracts/node-api.openapi.yaml`), `ApiError {code, messageKey, requestId, retryAfter}`, `AppFailure` (adds `network`, `cancelled`), and `ErrorMapper` (code → ARB key) in `lib/core/errors/` (passes T011)
- [X] T019 [P] Implement `AppLogger` (levels, PII redaction, release = warning/error only) and `CrashReporter` interface with `NoopCrashReporter` in `lib/core/logging/` (passes T013)
- [X] T020 [P] Implement `EnvConfig` from `String.fromEnvironment` keys in `env/example.json`, with HTTPS and anon-key-role checks, in `lib/core/env/env_config.dart` (passes T014)
- [X] T021 Implement `SecureSessionStorage` (Supabase `LocalStorage` on `flutter_secure_storage`, iOS `KeychainAccessibility.first_unlock_this_device`, Android Keystore-backed) in `lib/core/auth/secure_session_storage.dart`
- [X] T022 Implement Dio factory with `AuthInterceptor`, `RequestIdInterceptor`, `RefreshRetryInterceptor`, `ErrorInterceptor` in `lib/core/network/` (passes T015; depends on T018, T020)
- [X] T023 [P] Implement `ConnectivityCubit` (banner only; never used to decide request success) in `lib/core/connectivity/connectivity_cubit.dart`; cancel its connectivity subscription in `close()`
- [X] T024 [P] Implement `AppConfig` model (`minSupportedBuildAndroid`, `minSupportedBuildIos`, `supportPhone`, `currentTermsVersion`) and `AppConfigRepository` selecting only those columns from `app_config`, cached per app session, in `lib/core/config/`
- [X] T025 Implement `lib/bootstrap.dart` (init timezone, logger, `FlutterError.onError` + `PlatformDispatcher.onError` → logger, `Supabase.initialize` with `SecureSessionStorage`, `MultiRepositoryProvider` composition root) and entry points `lib/main_staging.dart`, `lib/main_production.dart` that pass the flavor (depends on T020, T021); root Cubits are wired in T039/T041 when available

### Localization

- [X] T026 Create `lib/l10n/app_ar.arb` (template) and `lib/l10n/app_en.arb` with every ARB key from `contracts/error-codes.md` plus shell, splash, auth, and state-view strings; run `flutter gen-l10n` into `lib/l10n/generated/`

### Design system

- [X] T027 [P] Implement `OnAirColors` `ThemeExtension` with `light` and `dark` constants for every token in `docs/UI_UX_DESIGN_SYSTEM.md` (primary, accent, background, surface, text, borders, buttons, inputs, status incl. chip colors, settings icon tones, gradients), with §4.8 fallbacks: light error text `#C62828`, dark error text `#FFCDD2`, dark muted text `#E0E0E0`, in `lib/design_system/tokens/on_air_colors.dart`
- [X] T028 [P] Implement provisional tokens in `lib/design_system/tokens/dimens.dart`: spacing `4, 8, 12, 16, 20, 24, 32, 40, 48` (screen side margin 16), radius `8` chips / `12` fields+buttons / `16` cards / `24` sheets, min touch target 48
- [X] T029 [P] Implement `TextTheme` from the design file's general scale and `OnAirTextStyles` named styles (`authTitle` 36/800 −0.5 h1.1 and 32 below 360 width, `authDescription`, `input`, `placeholder`, `forgotLink`, `authButton`, `homeWelcome`, `homeUserName`, `sectionTitle`, `seeAll`, `homeSearch`, `navLabel`) on family `Cairo` in `lib/design_system/typography/`
- [X] T030 Implement light/dark `ThemeData` with the ColorScheme mapping in Guest Plan §4.2, extensions registered, and `context.colors` / `context.textStyles` in `lib/design_system/theme/` (depends on T027, T029)
- [X] T031 [P] Implement `OnAirPrimaryButton` (solid `#006399` + auth-gradient variant with 25% primary shadow; `isLoading` shows in-button loader and disables taps; min height 48) in `lib/design_system/components/on_air_primary_button.dart`
- [X] T032 [P] Implement `OnAirTextField` (fill, normal/focus/error/error-focus borders, placeholder colors per design file; error text visible below field and announced with a live-region `Semantics`) in `lib/design_system/components/on_air_text_field.dart`
- [X] T033 [P] Implement `OnAirOtpField` (6 boxes, LTR digits inside RTL, paste distributes digits, `AutofillHints.oneTimeCode`, `onCompleted` callback, never writes to clipboard) in `lib/design_system/components/on_air_otp_field.dart`
- [X] T034 [P] Implement `LoadingView` (content-shaped skeleton), `EmptyView` (icon + sentence + action), `ErrorView` (message + retry + optional reference number), `OfflineBanner` in `lib/design_system/components/state_views.dart`
- [X] T035 [P] Implement `SectionHeader` (title 18/800 + "see all" 14/700) in `lib/design_system/components/section_header.dart`
- [X] T036 Add `test/flutter_test_config.dart` (alchemist CI-mode goldens, Cairo loaded) and golden tests for T031–T035 in light, dark, RTL, and 1.3× text under `test/design_system/goldens/`
- [X] T037 [P] Create `tool/check_hardcoded_styles.sh` that fails on `Color(0x`, `Colors.`, `fontSize:`, or `fontWeight:` in `lib/` outside `lib/design_system/` and generated folders

### App shell base, router base, auth domain

- [X] T038 Create route names/paths in `lib/app/router/routes.dart`, a pure `resolveRedirect(RedirectContext)` in `lib/app/router/redirect.dart` (returns null for now), and a `GoRouter` factory in `lib/app/router/app_router.dart` accepting a `Listenable` refresh source; wire Cubit state changes to it in T041
- [X] T039 Implement `lib/app/app.dart`: `MaterialApp.router`, `locale: Locale('ar')`, `supportedLocales: [ar, en]`, localization delegates, `theme`/`darkTheme`, `ThemeMode.system`, `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)`, root `BlocProvider<ConnectivityCubit>` and `OfflineBanner` overlay via `BlocBuilder<ConnectivityCubit, ConnectivityState>` (depends on T023, T026, T030, T038)
- [X] T040 Implement `GuestAccount` (fields and rules from data-model.md: `fullName` "2–80 chars after trim", phone `^\+201[0125]\d{8}$`, at least one of phone/email, `isComplete = fullName != null && acceptedTermsVersion == currentTermsVersion`), sealed `AuthState`, and `AuthRepository` interface (requestPhoneCode, verifyPhoneCode, signUpEmail, verifyEmailCode, signInEmail, requestRecovery, verifyRecovery, setNewPassword, completeProfile, signOut, authStateChanges) in `lib/features/auth/domain/` (provides domain types for T012)
- [X] T041 Implement `AuthCubit` driving immutable `AuthState` in `lib/features/auth/presentation/auth_cubit.dart`; inject `AuthRepository` through its constructor, cancel subscriptions in `close()`, register it with root `BlocProvider`, connect its stream to the router refresh adapter, and pass T012 (depends on T038, T040)
- [X] T042 [P] Create test helpers `test/helpers/fake_auth_repository.dart`, `test/helpers/fake_app_config_repository.dart`, `test/helpers/pump_app.dart` (`MultiRepositoryProvider`/`BlocProvider` + themes + Arabic locale + RTL)

**Checkpoint**: Foundation ready. User stories can start.

---

## Phase 3: User Story 1 — Open the app and move around as a visitor (P1) 🎯 MVP

**Goal**: Splash → five-tab Arabic RTL shell, light/dark, large text, per-tab state.

**Independent Test**: Open a build with no account; move through all five tabs in light and
dark; layout direction, fonts, colors, and per-tab scroll position are correct (quickstart V1–V5).

### Tests for User Story 1

- [X] T043 [P] [US1] Widget test `test/app/shell/app_shell_test.dart`: five tabs in order Home, Search, My Bookings, Favorites, My Account with Home on the right in RTL; active tab highlighted; each tab keeps its scroll position after switching
- [X] T044 [P] [US1] Widget test `test/app/app_locale_test.dart`: with device locale `en`, the app renders Arabic RTL
- [X] T045 [P] [US1] Golden tests `test/app/goldens/splash_and_shell_golden_test.dart`: splash and shell in light, dark, and 1.3× text, plus a 320-wide screen

### Implementation for User Story 1

- [X] T046 [P] [US1] Implement `OnAirBottomNav` (Surface background, top Nav Border, active item on Badge/Nav Active background, labels 10/700 active and 10/500 inactive, `Semantics` labels, 48×48 targets) in `lib/design_system/components/on_air_bottom_nav.dart`
- [X] T047 [US1] Implement `StatefulShellRoute.indexedStack` shell with five branches in `lib/app/shell/app_shell.dart` and register `/home`, `/search`, `/bookings`, `/favorites`, `/account` in `lib/app/router/routes.dart`
- [X] T048 [P] [US1] Implement splash (Splash gradient `#004B74 → #006399 → #147DBC`, dark `#002D47 → #006399 → #0A3D62`; "OnAir" 48/800 letter spacing 1.2; waits only for session restore) in `lib/app/splash/splash_screen.dart` and route `/splash`
- [X] T049 [P] [US1] Set native launch background to the gradient start color (`#004B74` light, `#002D47` dark) in `android/app/src/main/res/drawable/launch_background.xml`, `android/app/src/main/res/drawable-v21/launch_background.xml`, `android/app/src/main/res/values-night/styles.xml`, and `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- [X] T050 [P] [US1] Implement Home placeholder with Header gradient, welcome text, and a notifications bell (`Semantics` label, no badge yet) in `lib/features/home/presentation/home_placeholder_screen.dart`
- [X] T051 [P] [US1] Implement Search, My Bookings, Favorites, and My Account placeholders using `EmptyView` in `lib/features/{search,bookings,favorites,account}/presentation/*_placeholder_screen.dart`
- [X] T052 [US1] Widget test `test/app/offline_banner_test.dart`: offline shows the banner and disables server actions; back online hides it

**Checkpoint**: US1 works on its own (visitor shell).

---

## Phase 4: User Story 2 — Create an account and sign in with a phone number (P1)

**Goal**: Egyptian phone + SMS code sign-up/sign-in, profile completion with terms.

**Independent Test**: On Staging, sign up with a test number, enter the code, complete name and
terms, sign out, sign in again (quickstart V6–V9).

### Tests for User Story 2

- [X] T053 [P] [US2] Unit test `test/features/auth/domain/egypt_phone_test.dart`: normalizes `01XXXXXXXXX` and `+20…` to E.164; accepts only `^\+201[0125]\d{8}$`; rejects other countries and lengths
- [X] T054 [P] [US2] Unit test `test/features/auth/data/supabase_auth_repository_phone_test.dart` (mocked Supabase auth client): `signInWithOtp(phone, shouldCreateUser: true)`; `verifyOTP(type: sms)`; maps auth errors to `OTP_INVALID`, `OTP_EXPIRED`, `RATE_LIMITED` (with retry seconds), `PHONE_COUNTRY_NOT_SUPPORTED`
- [X] T055 [P] [US2] Widget test `test/features/auth/presentation/login_phone_test.dart`: invalid format keeps send disabled with an Arabic hint; send disables on tap; non-Egyptian number shows `authPhoneCountryNotSupported` and an email sign-up action; success copy identical for new and existing numbers
- [X] T056 [P] [US2] Widget test `test/features/auth/presentation/otp_screen_test.dart`: paste fills six boxes and submits; wrong code shows an announced error under the field; resend countdown uses the server value; rate-limit shows wait time and disables entry; "change number" discards countdown and code
- [X] T057 [P] [US2] Widget test `test/features/auth/presentation/complete_profile_test.dart`: name required "2–80 chars after trim"; terms checkbox required; `TERMS_CHANGED` reloads the current terms version and asks again
- [X] T058 [P] [US2] Unit test cases in `test/app/router/redirect_test.dart`: signed in with incomplete profile → `/auth/complete-profile?from=…`; complete → no redirect

### Implementation for User Story 2

- [X] T059 [P] [US2] Implement `EgyptPhone` value object in `lib/features/auth/domain/egypt_phone.dart` (passes T053)
- [X] T060 [US2] Implement phone methods in `lib/features/auth/data/supabase_auth_repository.dart` (passes T054)
- [X] T061 [US2] Implement `ProfileRepository` (select own `profiles` row columns `full_name`, `accepted_terms_version`, `accepted_terms_at`; call RPC `complete_guest_profile(full_name, terms_version)`) in `lib/features/auth/data/profile_repository.dart`
- [X] T062 [US2] Implement `LoginScreen` with Phone | Email tabs (Email tab shows the phone path only until US4), auth title, gradient button, Terms/Privacy links, register link in `lib/features/auth/presentation/login_screen.dart` (passes T055)
- [X] T063 [US2] Implement `OtpScreen` (channel-driven copy, `OnAirOtpField`, Android SMS User Consent via `smart_auth`, resend countdown from server, rate-limit state) in `lib/features/auth/presentation/otp_screen.dart` (passes T056)
- [X] T064 [P] [US2] Implement secure-screen channel: Dart `lib/core/platform/secure_screen.dart`; Android `FLAG_SECURE` toggle in `android/app/src/main/kotlin/.../MainActivity.kt`; iOS cover view on inactive in `ios/Runner/SceneDelegate.swift`; enable on OTP screens only
- [X] T065 [US2] Implement `RegisterScreen` phone path (phone only, no email/password) in `lib/features/auth/presentation/register_screen.dart`
- [X] T066 [US2] Implement `CompleteProfileScreen` (name + terms checkbox using `AppConfig.currentTermsVersion`) in `lib/features/auth/presentation/complete_profile_screen.dart` (passes T057)
- [X] T067 [US2] Register `/auth/login`, `/auth/register`, `/auth/otp`, `/auth/complete-profile` in `lib/app/router/routes.dart` and add the profile-incomplete rule to `lib/app/router/redirect.dart` (passes T058)
- [X] T068 [US2] Staging E2E `integration_test/phone_sign_in_test.dart`: sign up with a fixed-OTP test number → complete profile → signed in with phone verified → sign out → sign in again

**Checkpoint**: US1 + US2 work independently.

---

## Phase 5: User Story 3 — Keep the account secure and sign out (P1)

**Goal**: Persistent secure session, session-ended handling, full sign-out cleanup, isolation.

**Independent Test**: Sign in, force-close and reopen (still signed in); end the session from
Supabase (session-ended → back to same screen after sign-in); sign out (nothing personal left)
(quickstart V10–V12, V20).

### Tests for User Story 3

- [X] T069 [P] [US3] Unit test `test/core/auth/secure_session_storage_test.dart`: session persisted only through secure storage; nothing written to `shared_preferences`
- [X] T070 [P] [US3] Unit test `test/features/account_gate/application/sign_out_service_test.dart`: order = unregister device token (with bearer) → Supabase sign-out → clear caches → clear preferences except `themeMode` and `localeCode`; unregister failure does not block sign-out. Extend `auth_cubit_test.dart` to verify signedOut emission and personal-data Cubit reset after cleanup
- [X] T071 [P] [US3] Widget test `test/features/account_gate/presentation/session_ended_test.dart`: refresh failure or server-ended session → `errorUnauthenticated` message → login → back to the same route; inactive >30 days (server refuses refresh) behaves the same

### Implementation for User Story 3

- [X] T072 [US3] Generate the Node client with `dart run swagger_parser` into `lib/core/api/generated/` (do not edit by hand)
- [X] T073 [P] [US3] Implement `PushTokenSource` interface with `NoopPushTokenSource` in `lib/core/push/push_token_source.dart`
- [X] T074 [US3] Implement `DeviceRepository` (`registerDeviceToken {token, platform: android|ios, locale: ar|en}`, `unregisterDeviceToken(token)`) on the generated client in `lib/features/account_gate/data/device_repository.dart` (depends on T072)
- [X] T075 [US3] Implement `DeviceRegistrationService` (register after sign-in when a token exists; re-register on token refresh) in `lib/features/account_gate/application/device_registration_service.dart`
- [X] T076 [US3] Implement `SignOutService` in `lib/features/account_gate/application/sign_out_service.dart`; have `AuthCubit.signOut` call it and emit signedOut after cleanup, then reset app-scoped personal-data Cubits through a root listener (passes T070)
- [X] T077 [US3] Implement `SessionListener` mapping Supabase auth events (refresh failure, signed out by server) into `AuthCubit` so it emits `AuthState.sessionEnded(returnTo)` in `lib/features/account_gate/presentation/session_listener.dart` (passes T071)
- [X] T078 [US3] Add a sign-out action (Danger tone) to `lib/features/account/presentation/account_placeholder_screen.dart`
- [X] T079 [US3] Staging E2E `integration_test/sign_out_test.dart`: after sign-out, secure storage has no session keys and the app shows visitor Home
- [X] T080 [US3] Staging E2E `integration_test/isolation_test.dart` per `contracts/supabase-backend.md` §5: A cannot select B's `profiles` row (0 rows), A's `complete_guest_profile` cannot change B, anonymous select returns 0 rows

**Checkpoint**: US1–US3 work; G0 exit criterion (sign up, sign in, sign out on Staging + isolation) is provable.

---

## Phase 6: User Story 4 — Sign up and sign in with email and password (P2)

**Goal**: Email sign-up with emailed 6-digit code, email sign-in, recovery by emailed code.

**Independent Test**: On Staging, register with a test email, enter the emailed code, sign in,
recover the password with the emailed code, sign in with the new password (quickstart V13–V14).

### Tests for User Story 4

- [X] T081 [P] [US4] Unit test `test/features/auth/domain/password_rule_test.dart`: minimum 8 characters with at least one letter and one digit; strength levels weak/medium/strong
- [X] T082 [P] [US4] Unit test `test/features/auth/data/supabase_auth_repository_email_test.dart`: `signUp(email, password, data: {full_name})`; `verifyOTP` with the email confirmation type; `resetPasswordForEmail`; `verifyOTP(type: recovery)`; `updateUser(password)`; wrong credentials → `authInvalidCredentials`; recovery for unknown email → same success as known
- [X] T083 [P] [US4] Widget tests `test/features/auth/presentation/email_flows_test.dart`: email tab sign-in; email register has no phone field; forgot-password shows `authRecoverySent` for any email; new-password enforces the rule; code screen shows "change email" for email channels

### Implementation for User Story 4

- [X] T084 [P] [US4] Implement `PasswordRule` in `lib/features/auth/domain/password_rule.dart` and `PasswordStrengthHint` (12/400, height 1.4) in `lib/features/auth/presentation/widgets/password_strength_hint.dart` (passes T081)
- [X] T085 [US4] Implement email methods in `lib/features/auth/data/supabase_auth_repository.dart` (passes T082)
- [X] T086 [US4] Add the Email tab (email, password, "forgot?" 11/700) to `lib/features/auth/presentation/login_screen.dart`
- [X] T087 [US4] Add the email path (name, email, password, terms; no phone) to `lib/features/auth/presentation/register_screen.dart`
- [X] T088 [US4] Support `emailSignup` and `emailRecovery` channels in `lib/features/auth/presentation/otp_screen.dart`
- [X] T089 [P] [US4] Implement `ForgotPasswordScreen` and `NewPasswordScreen` in `lib/features/auth/presentation/forgot_password_screen.dart` and `new_password_screen.dart`; register `/auth/forgot-password` and `/auth/new-password` in `lib/app/router/routes.dart` (passes T083)
- [X] T090 [US4] Show email verification status ("غير مؤكد" + verify-now → code screen) on `lib/features/account/presentation/account_placeholder_screen.dart`

**Checkpoint**: Both sign-in methods work.

---

## Phase 7: User Story 5 — Visitors return to members-only areas after signing in (P2)

**Goal**: Members-only guard with safe `from` return; verified-link parsing with neutral fallback.

**Independent Test**: As a visitor tap My Bookings → sign in → land on My Bookings; open a
malformed link → `/not-available` (quickstart V15–V16).

### Tests for User Story 5

- [X] T091 [P] [US5] Add cases to `test/app/router/redirect_test.dart`: members-only route without session → `/auth/login?from=<location>`; `from` accepted only when it is a relative registered path (reject `https://…`, `//…`, unknown paths); signed in on `/auth/*` → `from` or `/home`; sign-in cancel returns to origin as visitor
- [X] T092 [P] [US5] Unit test `test/app/router/link_parser_test.dart`: host must equal `EnvConfig.linkDomain`; path IDs must be UUID v4; query parameters never change state; unknown or malformed → `/not-available`; members-only link while signed out → login then link

### Implementation for User Story 5

- [X] T093 [US5] Implement members-only and auth-route rules plus `from` validation in `lib/app/router/redirect.dart` (passes T091)
- [X] T094 [P] [US5] Implement `LinkParser` in `lib/app/router/link_parser.dart` and the `app_links` listener in `lib/app/router/incoming_links.dart` (passes T092)
- [X] T095 [P] [US5] Implement `NotAvailableScreen` (neutral copy, never says whether the item exists) in `lib/features/app_update/presentation/not_available_screen.dart` and route `/not-available`
- [X] T096 [US5] Register later-phase link patterns (`/property/:id`, `/search/results`, `/bookings/:id`, `/bookings/:id/remaining-payment`, `/bookings/:id/damage-claim/:claimId`, `/bookings/:id/review`, `/support/:caseId`, `/payment/return`) resolving to `/not-available` in `lib/app/router/routes.dart`
- [X] T097 [US5] Add a close/cancel action to `lib/features/auth/presentation/login_screen.dart` that returns to the origin as a visitor

**Checkpoint**: Navigation rules complete.

---

## Phase 8: User Story 6 — The team ships separate test and live builds (P2)

**Goal**: Staging and Production flavors with final-pending identifiers, icons, Firebase, verified-link config, release hardening.

**Independent Test**: Install both builds side by side; names/icons differ; Staging account
does not work on Production; build scan finds no secrets (quickstart V17).

### Implementation for User Story 6

- [X] T098 [US6] Android flavors in `android/app/build.gradle.kts`: `namespace = "com.onair.guest"`, `applicationId = "com.onair.guest"`, `staging` with `applicationIdSuffix = ".staging"`, `resValue` app name "OnAir (Staging)" / "OnAir", `manifestPlaceholders["linkDomain"]`; move `MainActivity.kt` to `android/app/src/main/kotlin/com/onair/guest/`; use `@string/app_name` in `android/app/src/main/AndroidManifest.xml` (identifiers provisional, see research R14)
- [X] T099 [US6] Android hardening: R8/minify + `android/app/proguard-rules.pro`, `android:allowBackup="false"`, `android/app/src/main/res/xml/network_security_config.xml` with cleartext disabled, release not debuggable
- [X] T100 [US6] iOS configurations `Debug-staging`, `Release-staging`, `Debug-production`, `Release-production` with `ios/Flutter/staging.xcconfig` and `ios/Flutter/production.xcconfig` (`PRODUCT_BUNDLE_IDENTIFIER` `com.onair.guest.staging` / `com.onair.guest`, display name, `ONAIR_LINK_DOMAIN`) and shared schemes `staging`, `production` in `ios/Runner.xcodeproj/xcshareddata/xcschemes/`; confirm `ios/Runner/Info.plist` has no ATS exceptions
- [X] T101 [P] [US6] Distinct Staging icons in `android/app/src/staging/res/mipmap-*/` and `ios/Runner/Assets.xcassets/AppIcon-Staging.appiconset/`, selected per configuration
- [X] T102 [US6] Verified-link native config: Android intent filter with `android:autoVerify="true"` for `https://${linkDomain}` in `android/app/src/main/AndroidManifest.xml`; iOS `ios/Runner/Runner.entitlements` with `applinks:$(ONAIR_LINK_DOMAIN)`
- [X] T103 [US6] Firebase per flavor with `flutterfire configure`: `lib/core/env/firebase_options_staging.dart`, `lib/core/env/firebase_options_production.dart`, `android/app/src/staging/google-services.json`, `android/app/src/production/google-services.json`, iOS `GoogleService-Info.plist` per configuration
- [X] T104 [US6] Implement `FirebasePushTokenSource` in `lib/core/push/firebase_push_token_source.dart` and select Firebase options + token source by flavor in `lib/bootstrap.dart` (no permission prompt in G0)
- [X] T105 [P] [US6] Create `tool/scan_build_for_secrets.sh` that unpacks an APK/IPA and fails on `service_role`, the base64 fragment of `"role":"service_role"`, and Kashier/Resend/SMS key patterns

**Checkpoint**: Two installable, separated builds.

---

## Phase 9: User Story 7 — Every change passes the same automated quality checks (P3)

**Goal**: PR gate and Staging build on merge.

**Independent Test**: Open a PR with a format error or a `service_role` string → checks fail,
merge blocked; fix → checks pass (quickstart V18).

### Implementation for User Story 7

- [ ] T106 [P] [US7] Create `.gitleaks.toml` extending defaults with rules for Supabase `service_role` JWTs, the literal `service_role`, Kashier keys, Resend keys (`re_…`), and SMS provider keys; allowlist `contracts/` docs that mention the word without a key
- [ ] T107 [US7] Create `.github/workflows/ci.yml` (on pull_request): Flutter 3.44.3, `flutter pub get`, `dart format --set-exit-if-changed .`, `flutter analyze`, `tool/check_hardcoded_styles.sh`, `dart run build_runner build --delete-conflicting-outputs` + `flutter gen-l10n` + `dart run swagger_parser` then `git diff --exit-code`, `flutter test` (unit + widget + goldens), gitleaks
- [ ] T108 [US7] Create `.github/workflows/staging-build.yml` (on push to `main`): write `env/staging.json` from secrets, `flutter build apk --flavor staging -t lib/main_staging.dart --obfuscate --split-debug-info=build/symbols --dart-define-from-file=env/staging.json`, upload symbols artifact, run `tool/scan_build_for_secrets.sh`, distribute with Firebase App Distribution
- [ ] T109 [US7] Document required repository settings (branch protection on `main` requiring `ci.yml`; secrets list) in `docs/ci.md`

**Checkpoint**: Quality gate active.

---

## Phase 10: User Story 8 — Outdated app versions are asked to update (P3)

**Goal**: Blocking update screen driven by server config.

**Independent Test**: Set `min_supported_build_android` above the installed build on Staging
and reopen (quickstart V19).

### Tests for User Story 8

- [ ] T110 [P] [US8] Add cases to `test/app/router/redirect_test.dart`: build below platform minimum → `/update-required` from any route; config fetch failure → no redirect
- [ ] T111 [P] [US8] Widget + golden test `test/features/app_update/update_required_screen_test.dart`: store button present, back navigation blocked, light/dark

### Implementation for User Story 8

- [ ] T112 [US8] Implement `VersionGate` (build number from `package_info_plus` vs `minSupportedBuildAndroid`/`minSupportedBuildIos`; re-check on resume with `AppLifecycleListener`) in `lib/core/config/version_gate.dart`
- [ ] T113 [US8] Implement `UpdateRequiredScreen` (store link per platform, `PopScope(canPop: false)`) in `lib/features/app_update/presentation/update_required_screen.dart` and route `/update-required`
- [ ] T114 [US8] Add the version-gate rule as the first rule in `lib/app/router/redirect.dart` (passes T110)

**Checkpoint**: All eight stories done.

---

## Phase 11: Polish & Cross-Cutting Concerns

- [ ] T115 [P] Accessibility pass: `Semantics` labels on every icon-only control, 48×48 targets, RTL focus order; run phone sign-in with TalkBack and VoiceOver and record results in `docs/qa/g0-accessibility.md` (SC-009)
- [ ] T116 [P] Measure cold start to Home skeleton in Profile mode on a mid-range Android device and per-ABI size (`flutter build apk --split-per-abi --analyze-size`); record in `docs/perf/g0-baseline.md` (SC-002)
- [ ] T117 [P] Update `README.md` with setup, flavors, env files, codegen, and test commands from quickstart.md
- [ ] T118 Run quickstart V1–V20 on Staging and record pass/fail in `specs/001-guest-app-foundation/checklists/validation.md`
- [ ] T119 Tick completed G0 items in `docs/OnAir Guest App Plan.md` §17 and note any open decisions resolved (app IDs, link domain, crash tool)

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)** → **Foundational (Phase 2)** → user stories → **Polish (Phase 11)**.
- Foundational blocks every story.

### User story dependencies

- **US1 (P1)**: after Foundational. No story dependency.
- **US2 (P1)**: after Foundational. Uses the shell from US1 only for navigation after sign-in;
  testable alone with a direct route to `/auth/login`.
- **US3 (P1)**: after US2 (needs a signed-in session to test).
- **US4 (P2)**: after US2 (shares `login_screen.dart`, `register_screen.dart`, `otp_screen.dart`,
  `supabase_auth_repository.dart`).
- **US5 (P2)**: after US1 and US2 (guards protect shell tabs and use the login route).
- **US6 (P2)**: after Foundational; native files only, can run in parallel with US1–US5.
- **US7 (P3)**: after Setup; can start any time, most useful early.
- **US8 (P3)**: after Foundational; touches `redirect.dart`, so sequence its T114 after US5's T093.

### Shared files (no [P] across these)

`lib/app/router/routes.dart`, `lib/app/router/redirect.dart`, `test/app/router/redirect_test.dart`,
`lib/features/auth/presentation/login_screen.dart`, `register_screen.dart`, `otp_screen.dart`,
`lib/features/auth/data/supabase_auth_repository.dart`,
`lib/features/account/presentation/account_placeholder_screen.dart`, `lib/bootstrap.dart`.

### Within each story

Tests first (they must fail), then domain → data → presentation → routes → E2E.

---

## Parallel Examples

### Foundational

```text
T009 money_test · T010 cairo_time_test · T011 error_mapper_test · T012 auth_state_test ·
T013 app_logger_test · T014 env_config_test · T015 interceptors_test
then: T016 Money · T017 CairoTime · T018 errors · T019 logger · T020 EnvConfig ·
T027 OnAirColors · T028 dimens · T029 typography · T031–T035 components
```

### User Story 1

```text
T043 app_shell_test · T044 app_locale_test · T045 shell goldens
then: T046 OnAirBottomNav · T048 splash · T049 native launch · T050 home · T051 placeholders
```

### User Story 2

```text
T053 egypt_phone_test · T054 repo phone test · T055 login test · T056 otp test ·
T057 complete profile test · T058 redirect cases
then: T059 EgyptPhone · T064 secure screen (in parallel with T060–T063)
```

### Across stories

```text
US6 (T098–T105, native) and US7 (T106–T109, CI) can run alongside US1–US5.
```

---

## Implementation Strategy

### MVP first

1. Phase 1 Setup → Phase 2 Foundational.
2. Phase 3 (US1): visitor shell. **Stop and validate** V1–V5.

### G0 exit (Guest Plan §17)

3. US2 + US3: phone sign-up/sign-in/sign-out on Staging + isolation test (V6–V12, V20).
   This meets the G0 exit criterion together with US1's light/dark check.

### Incremental delivery

4. US4 (email) → US5 (guards/links) → US6 (flavors) → US7 (CI) → US8 (version gate) → Polish.
   Recommended: start US7 right after Setup so every later task runs through the gate.

---

## Notes

- Provisional values to confirm before the first store upload: app identifiers (R14), link
  domain (R15), crash tool (R19).
- Backend-dependent tasks (T068, T079, T080, all Staging validation) need the Staging Supabase
  setup in `contracts/supabase-backend.md`; until then use fakes and the Prism mock.
- Commit after each task or logical group; stop at any checkpoint to validate.
