# Research: Guest App Foundation (G0)

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-10-26

Each entry: **Decision**, **Rationale**, **Alternatives considered**. Items marked *Open* do not
block G0 implementation; they have a safe default and a named owner.

---

## Architecture & state

### R1. State management

- **Decision**: Cubit through `flutter_bloc`, with immutable states. Repositories are injected
  through constructors; `BlocProvider` owns route-scoped Cubits and root `BlocProvider`s own session-
  scoped Cubits. `BlocSelector` narrows rebuilds, while `close()` cancels requests and streams.
- **Rationale**: Guest Plan §3.2 now chooses Cubit. `bloc_test` verifies state transitions;
  explicit lifetime and cancellation meet Constitution VIII.
- **Alternatives**: Riverpod with generated providers was the previous plan and is superseded
  for this app; plain Provider does not supply the chosen Cubit state model.
- **Migration**: Phase 1 had dependency configuration only, with no Riverpod classes to rewrite.
  Replace the three Riverpod packages in `pubspec.yaml` and implement future state classes as
  Cubits. No backend contract or business rule changes.

### R2. Routing, guards, and return-to-origin

- **Decision**: `go_router` with `StatefulShellRoute.indexedStack` for the five tabs. One global
  `redirect` evaluates, in order: (1) version gate → `/update-required`; (2) members-only route
  with no session → `/auth/login?from=<encoded original location>`; (3) signed-in but profile
  incomplete → `/auth/complete-profile?from=…`. After sign-in, the router navigates to `from`
  only if it parses as an internal route (no scheme/host) — prevents open-redirects.
- **Rationale**: Meets FR-017/018/021/033 with one testable function; indexedStack keeps per-tab
  state.
- **Alternatives**: auto_route (codegen-heavy, no extra value); per-screen guards (duplicated,
  easy to miss).

### R3. Backend access split

- **Decision**: `supabase_flutter` for Auth and RLS-protected reads (`profiles`, `app_config`).
  `dio` for Node commands (device registration in G0) with interceptors: bearer token from the
  current Supabase session; `x-request-id` (UUID v4) on every request; on 401, refresh once and
  retry once; map error bodies to `ApiError`.
- **Rationale**: Matches Master Plan §13.4 and Guest Plan §10. Request IDs satisfy FR-043.
- **Alternatives**: Everything through Node (adds latency and a backend dependency for simple
  RLS reads); `http` package (no interceptors/cancel tokens).

### R4. Session storage

- **Decision**: Implement Supabase's `LocalStorage` on top of `flutter_secure_storage`
  (iOS accessibility `first_unlock_this_device`; Android Keystore-backed) and pass it through the
  Supabase client's auth options. No session data in `shared_preferences`.
- **Rationale**: FR-032/035, Constitution IV. Default Supabase storage uses shared preferences.
- **Alternatives**: Default storage (not secure); Hive with encryption (extra key management).

## Authentication

### R5. Phone sign-in, Egypt only

- **Decision**: Supabase Auth phone OTP (`signInWithOtp(phone, shouldCreateUser: true)` →
  `verifyOTP(type: sms)`). The backend routes SMS through a **Send SMS hook** to the Node service,
  which rejects any number not starting with `+20` and sends through the Egyptian SMS provider.
  The app also validates the Egyptian mobile format locally (`+20 1[0125]XXXXXXXX`) for fast
  feedback only.
- **Rationale**: FR-022 requires server-side rejection; the hook also lets the backend pick the
  SMS provider still open in the Master Plan (§19) and blocks SMS-pumping.
- **Alternatives**: Built-in Twilio provider with geo-permissions (still needs provider
  decision); client-only check (not security).

### R6. Emailed 6-digit codes for verification and recovery

- **Decision**: Supabase email templates use the OTP token (`{{ .Token }}`), not the
  confirmation URL. Email OTP length set to 6. Flows:
  - Sign-up: `signUp(email, password, data: {full_name})` → code screen → `verifyOTP` with the
    email confirmation type.
  - Recovery: `resetPasswordForEmail(email)` → code screen → `verifyOTP(type: recovery)` →
    `updateUser(password)`.
  - Exact OTP type names are confirmed against the installed `supabase_flutter` version during
    implementation.
  Emails are sent through Resend as Supabase's custom SMTP.
- **Rationale**: Clarification Q1 (Master Plan §2.3). No dependency on the undecided link domain;
  no phishable links.
- **Alternatives**: Magic links (need domain + deep links); custom Node OTP service (duplicates
  Supabase Auth).

### R7. Uniform responses and rate limits

- **Decision**: Always call OTP send with `shouldCreateUser: true` and show the same success copy;
  for email sign-in and recovery show one generic message regardless of the error. Rate limits
  come from Supabase Auth (per-number/email + IP) and the hook; the app reads `retry_after`
  seconds when present (or maps `RATE_LIMITED` with server-provided wait) and disables the
  action with a countdown.
- **Rationale**: FR-028/029; Constitution IV.
- **Alternatives**: Checking "user exists" first (leaks accounts).

### R8. Profile completion and terms acceptance

- **Decision**: A `profiles` row (id = `auth.uid()`) holds `full_name`,
  `accepted_terms_version`, `accepted_terms_at`. After any successful code verification, if the
  profile is missing or incomplete, the router forces `/auth/complete-profile` (name + terms
  checkbox) and calls an RPC `complete_guest_profile(full_name, terms_version)` that writes only
  the caller's row. Phone/email and their verified flags are read from the Supabase auth user.
- **Rationale**: Supabase creates the auth user at verification time, so "account complete"
  means auth user + completed profile (spec Story 2 AC7). The RPC keeps writes server-validated.
- **Alternatives**: Collect name before sending the OTP (lost if the user abandons; leaks intent);
  client-side insert (bypasses validation).

### R9. 30-day inactivity sign-out

- **Decision**: Backend configures Supabase Auth session **inactivity timeout = 30 days** (a
  Supabase paid-plan setting; the backend owner confirms availability). When refresh fails, the
  app ends the session locally, shows "session ended", and returns the guest to the same screen
  after sign-in. No client-side timer decides expiry.
- **Rationale**: Clarification Q3; Constitution II (server enforces).
- **Alternatives**: Client-side "last opened" timer (bypassable, device-clock dependent); short
  refresh-token lifetime (signs out active users too).

### R10. Code entry UX: autofill, paste, recents protection

- **Decision**: 6-box `OnAirOtpField` with paste support; iOS `AutofillHints.oneTimeCode`;
  Android SMS User Consent via `smart_auth` (no SMS read permission). On code screens, Android
  sets `FLAG_SECURE` and iOS shows a cover view when the app goes inactive, via a small method
  channel. Codes are never copied to the clipboard.
- **Rationale**: FR-023/037; SMS User Consent needs no dangerous permission.
- **Alternatives**: SMS Retriever API (needs app-hash in SMS template, harder with a hook);
  third-party screen-protection packages (extra dependency for two lines of native code).

## Presentation

### R11. Design tokens and theming

- **Decision**: `OnAirColors` and `OnAirTextStyles` as `ThemeExtension`s with `light`/`dark`
  constants transcribed from `docs/UI_UX_DESIGN_SYSTEM.md`; `ColorScheme` mapping per Guest Plan
  §4.2; provisional spacing/radius/elevation in `tokens/` per §4.5; `ThemeMode.system` in G0.
  Error text: `#C62828` (light) / `#FFCDD2` (dark); muted text in dark: `#E0E0E0` (§4.8).
  A custom lint check (simple CI grep) fails on `Color(0x` or `fontSize:` outside
  `lib/design_system/`.
- **Rationale**: FR-004–009, SC-004.
- **Alternatives**: Material 3 seed colours (would not match the design file).

### R12. Fonts

- **Decision**: Bundle Cairo static TTFs for weights 400, 500, 600, 700, 800 (SIL OFL licence
  file included) under `assets/fonts/cairo/`.
- **Rationale**: FR-005, no runtime download, smaller than the variable font + 200/300/900.
- **Alternatives**: `google_fonts` runtime fetch (network dependency, layout shift).

### R13. Localization and RTL

- **Decision**: `flutter gen-l10n` with `app_ar.arb` (template) and `app_en.arb`;
  `locale: Locale('ar')` fixed; `supportedLocales: [ar, en]` so English can be enabled by flag
  later. Western digits until the numerals decision (Guest Plan §4.9) — applied in the single
  formatter in `core/time` and `core/money`. Text scale: `MediaQuery.withClampedTextScaling(
  maxScaleFactor: 1.3)` at the app root.
- **Rationale**: FR-010–015.
- **Alternatives**: `easy_localization` (non-standard, runtime loading).

## Environments & build

### R14. Flavors and app identifiers *(identifiers: Open — confirm before first store upload)*

- **Decision**: Android `productFlavors { staging, production }` and iOS build configurations +
  schemes (`Debug/Release-staging`, `Debug/Release-production`), configured by hand (no
  generator dependency). Entry points `main_staging.dart` / `main_production.dart`. Config via
  `--dart-define-from-file=env/<flavor>.json` (git-ignored; `env/example.json` committed with
  placeholder values). **Provisional identifiers**: `com.onair.guest` and
  `com.onair.guest.staging` (display names "OnAir" / "OnAir (Staging)", distinct icons).
- **Rationale**: FR-001–003. App IDs cannot change after the first store upload, so the owner
  confirms them before G6, not before G0 code.
- **Alternatives**: `flutter_flavorizr` (adds a dependency and overwrites native files);
  a single build with runtime switch (risk of mixing environments).

### R15. Verified links *(domain: Open — Guest Plan §19.2)*

- **Decision**: `app_links` for incoming links; Android intent filters with `autoVerify`, iOS
  Associated Domains, both reading the domain from a per-flavor build variable
  (`ONAIR_LINK_DOMAIN`). Router validates paths and UUID formats; unknown → `/not-available`.
  G0 tests use simulated URIs; device-level verification waits for the domain and its
  `assetlinks.json` / `apple-app-site-association` files.
- **Rationale**: FR-020/021; email flows no longer depend on links (R6).
- **Alternatives**: Custom scheme `onair://` (hijackable, rejected by Guest Plan §8.3).

### R16. Firebase

- **Decision**: Separate Firebase projects per flavor; `flutterfire configure` output stored as
  `lib/core/env/firebase_options_staging.dart` / `_production.dart` (public config). G0 wires
  token retrieval and `registerDeviceToken` / `unregisterDeviceToken`; the permission prompt
  itself arrives in G2 (after first payment, Guest Plan §9.1).
- **Rationale**: FR-034 needs unregister-on-sign-out plumbing from day one.
- **Alternatives**: Defer Firebase entirely to G2 (sign-out cleanup would need rework).

### R17. Version gate

- **Decision**: Public `app_config` row (RLS: select for `anon`) with
  `min_supported_build_android`, `min_supported_build_ios`, `support_phone`,
  `current_terms_version` (used by profile completion, R8). Compare against the
  integer build number from `package_info_plus`. Checked at startup and on resume; failure to
  fetch never blocks.
- **Rationale**: FR-041; integer builds avoid semver parsing ambiguity.
- **Alternatives**: Semantic version strings (parsing edge cases); store-API checks (slow, third
  party).

## Quality & operations

### R18. Errors and messages

- **Decision**: `ApiError {code, messageKey, requestId, details}` from Node; Supabase
  `AuthException`s mapped into the same codes. One mapping table → `.arb` keys; unknown codes →
  `INTERNAL` message with the reference number. Full list in
  [contracts/error-codes.md](contracts/error-codes.md). G0 adds three codes to the Guest Plan
  §10.3 list: `PHONE_COUNTRY_NOT_SUPPORTED` (Egypt-only), `PROFILE_INCOMPLETE`, and
  `VALIDATION_FAILED`; the backend owner confirms them.
- **Rationale**: FR-011/042/043.

### R19. Logging and crash reporting *(tool: Open — team decision)*

- **Decision**: `AppLogger` with levels; release keeps `warning`/`error` only; a redaction step
  masks phone numbers, emails, and JWT-like strings. `CrashReporter` interface with a no-op
  implementation in G0; Crashlytics or Sentry plugs in later without screen changes.
- **Rationale**: FR-036; Constitution TODO(CRASH_TOOL) remains with the team.
- **Alternatives**: Pick Sentry now (decision belongs to the team across apps).

### R20. Testing approach

- **Decision**: Test-first for `Money`, Cairo-time formatting, error mapping, the router
  `redirect`, and the auth state machine. Widget tests per screen state with fake repositories
  (`mocktail`). Goldens with `alchemist` in CI mode (platform-agnostic text rendering) for every
  design-system component and foundation screen in light, dark, RTL, and 1.3× text. Staging
  `integration_test`: phone sign-up/sign-in/sign-out with a test number, and the isolation test
  (user A cannot select user B's `profiles` row).
- **Rationale**: Constitution IX; SC-003/006.
- **Alternatives**: `golden_toolkit` (discontinued); goldens on developer machines only (font
  rendering differs between OSes).

### R21. CI/CD

- **Decision**: GitHub Actions (remote is GitHub).
  - `ci.yml` on every PR: `dart format --set-exit-if-changed`, `flutter analyze`
    (`very_good_analysis`, zero warnings), hard-coded style grep (R11),
    `dart run build_runner build --delete-conflicting-outputs` + `git diff --exit-code`,
    `flutter test` (unit + widget + goldens), `gitleaks` with custom rules (Supabase
    `service_role` JWTs, Kashier/Resend/SMS key patterns).
  - `staging-build.yml` on merge to `main`: Android staging build (obfuscated, split debug info
    uploaded as an artifact) to Firebase App Distribution; plus a scan of the built artifact for
    forbidden patterns. iOS TestFlight is added when the Apple developer account and signing
    are ready.
  - Branch protection on `main` requires `ci.yml`.
- **Rationale**: FR-045/046, SC-005/007.
- **Alternatives**: Codemagic (paid, separate config); manual builds (no gate).

### R22. Contracts and mock *(Staging backend readiness: Open)*

- **Decision**: Draft contracts live at root `contracts/` (copied from this spec's
  `contracts/`): OpenAPI 3.1 for Node commands; Markdown for Supabase auth config, tables, RPC,
  and RLS. The Dart Node client is generated with `swagger_parser`. Widget tests use fake
  repositories. Local manual runs against Node endpoints use a Prism mock of the OpenAPI file;
  auth runs against the Staging Supabase project (or the backend owner's local Supabase stack
  until Staging exists).
- **Rationale**: FR-044; keeps the app unblocked while backend ownership (Guest Plan §2.3) is
  open.
- **Alternatives**: Hand-written mock server for Supabase Auth (re-implements GoTrue; fragile).

### R23. Build hardening

- **Decision**: Release builds use `--obfuscate --split-debug-info`; R8 enabled;
  `android:allowBackup="false"`; cleartext disabled via network security config; iOS ATS
  without exceptions; no debug screens in release.
- **Rationale**: Constitution IV, Guest Plan §11.7.
