# Implementation Plan: Guest App Foundation (G0)

**Branch**: `001-guest-app-foundation` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-guest-app-foundation/spec.md`

## Summary

Turn the default Flutter template in this repository into the Guest App's foundation: two
environments (Staging, Production), an in-repo design system built from
`docs/UI_UX_DESIGN_SYSTEM.md`, a core layer (backend clients, secure session, errors, Money,
Cairo-time formatting, logging, env), an Arabic RTL app shell with a five-tab bottom navigation
and auth-aware routing, complete sign-in (phone + SMS code for Egyptian numbers; email + password
with emailed 6-digit codes for verification and recovery), a forced-update gate, and a CI
pipeline that blocks merges on format, analysis, tests, goldens, stale codegen, or leaked
secrets.

The app talks to the backend only: Supabase Auth and RLS-protected reads directly, Node commands
over HTTPS. Backend behaviour the app relies on (Egypt-only SMS, emailed codes, 30-day inactivity
timeout, profile completion, isolation) is written as draft contracts for the backend owner.
Details: [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/),
[quickstart.md](quickstart.md).

## Technical Context

**Language/Version**: Dart 3.12.2, Flutter 3.44.3 (stable). SDK constraint `^3.12.2`.

**Primary Dependencies**: `flutter_bloc` (Cubit state management; `bloc_test` for transition tests),
`go_router` (routing, guards, deep links), `supabase_flutter` (auth, RLS reads), `dio`
(Node commands), `freezed` + `json_serializable` (models), `flutter_secure_storage` (session),
`shared_preferences` (non-sensitive prefs), `flutter_localizations` + `intl` (i18n),
`app_links` (verified links), `connectivity_plus` (offline banner only), `package_info_plus`
(version gate), `firebase_core` + `firebase_messaging` (push token plumbing), `smart_auth`
(Android SMS User Consent), `swagger_parser` (client generation from OpenAPI), `uuid`.
Versions: latest stable at implementation start, locked by `pubspec.lock` (Guest Plan §3.2).

**Storage**: Device secure storage (Keychain `first_unlock_this_device` / Android Keystore) for
the session only; `shared_preferences` for language/appearance/last search. No local database in
G0. Server: Supabase Postgres (owned by the backend repository).

**Testing**: `flutter_test` (unit + widget), `bloc_test` (Cubit transitions), `mocktail` (fakes), `alchemist` (golden tests in
CI mode), `integration_test` (Staging E2E: phone sign-in, isolation). Lints: `very_good_analysis`.

**Target Platform**: Android 7.0+ (API 24) and iOS 15+. Other platform folders stay in the repo
but are not release targets.

**Project Type**: Mobile app (single Flutter project at repository root).

**Performance Goals**: Cold start to Home skeleton < 2.5 s on a mid-range Android device in
Profile mode (SC-002); 60 fps scrolling; Android per-ABI size < ~30 MB.

**Constraints**: Arabic + RTL only at launch; text scale clamped to 1.3; no secrets beyond
public config (Constitution IV); server is the authority for all auth decisions (Constitution
II); offline shows banner + cache, never decides success.

**Scale/Scope**: ~12 screens (splash, 5 tab placeholders, login, register, code entry, complete
profile, forgot password + new password, update required, not available, session ended state),
~15 design-system components, 2 flavors, 1 CI workflow + 1 staging-build workflow.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | How G0 complies | Status |
|---|---|---|
| I. Master Plan fidelity & scope | Auth methods, phone verification, no social login, no government ID, no VIP/offer features follow Master Plan §2.3 (incl. 2026-10-26 decisions). Out-of-scope items untouched. | PASS |
| II. Server is the authority (NON-NEGOTIABLE) | OTP validity, rate limits, countdown durations, Egypt-only rule, session expiry, min version, and profile completeness all come from the server. Deep links never change state; IDs are format-checked then fetched under RLS. | PASS |
| III. Payment integrity (NON-NEGOTIABLE) | No payment in G0. Shared pieces payment needs later (request IDs, disabled-on-tap buttons, verified links) are built here. | PASS (N/A) |
| IV. Security & privacy (NON-NEGOTIABLE) | anon key only; env files git-ignored; secure session storage; full sign-out cleanup; HTTPS only; PII-free logs; uniform auth messages; no OTP clipboard; OTP screens hidden in recents; release obfuscation; gitleaks + build scan in CI; automated isolation test. | PASS |
| V. Design system | `OnAirColors`/`OnAirTextStyles` ThemeExtensions from the design file; Cairo 400–800 bundled; light + dark; provisional spacing/radius in one file; §4.8 contrast fallbacks; lint rule + test that forbids `Color(0x` outside `lib/design_system/`. | PASS |
| VI. Arabic-first, RTL & a11y | Locale fixed to `ar`, `.arb` for ar + en; directional insets only; `withClampedTextScaling(max 1.3)`; Semantics labels; 48×48 targets; goldens at 1.3×. | PASS |
| VII. Layered, feature-first | `features/<f>/{data,domain,presentation}`; widgets never touch Supabase/Dio; core/design_system never import features; Money as int piasters; stay dates date-only; unified error model; generated client not hand-edited. | PASS |
| State management | `flutter_bloc` Cubits own presentation state; repositories enter through constructors; root and route `BlocProvider` scopes control lifetime; `close()` cancels requests and subscriptions. | PASS |
| VIII. UX states & performance | Shared `LoadingView`/`EmptyView`/`ErrorView`/`OfflineBanner`; in-button loaders; version gate; const + lazy lists; cold-start budget measured. | PASS |
| IX. Test discipline | Test-first for Money, error mapping, router guards, auth state machine; widget tests per screen state; goldens light/dark/RTL/1.3×; Staging isolation test; contracts drive the mock. | PASS |
| Repository constraints | Single repo = Guest App; no cross-repo code; backend contracts drafted in `contracts/` for the backend owner. | PASS |

No violations. Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-guest-app-foundation/
├── plan.md              # This file
├── research.md          # Phase 0: decisions + rationale
├── data-model.md        # Phase 1: entities, validation, state machines
├── quickstart.md        # Phase 1: setup + validation scenarios
├── contracts/           # Phase 1: draft backend contracts + app route contract
│   ├── node-api.openapi.yaml
│   ├── supabase-backend.md
│   ├── error-codes.md
│   └── app-routes.md
├── checklists/requirements.md
└── tasks.md             # Phase 2 ($speckit-tasks)
```

### Source Code (repository root)

```text
on_air/
├── lib/
│   ├── main_staging.dart
│   ├── main_production.dart
│   ├── bootstrap.dart                  # env, Firebase, Supabase (secure storage), logger, error zones
│   ├── app/
│   │   ├── app.dart                    # MaterialApp.router, themes, locale ar, text-scale clamp
│   │   ├── router/                     # routes, auth/version guards, `from` return, link parsing
│   │   └── shell/                      # StatefulShellRoute + OnAirBottomNav
│   ├── core/
│   │   ├── env/                        # EnvConfig (dart-define-from-file), firebase_options_*.dart
│   │   ├── api/                        # generated Node client (swagger_parser) — do not edit
│   │   ├── network/                    # Dio factory, auth + request-id + retry interceptors
│   │   ├── auth/                       # SecureSessionStorage (Supabase LocalStorage impl)
│   │   ├── errors/                     # AppFailure, ApiError, code → message-key mapping
│   │   ├── money/                      # Money value object (int piasters + currency)
│   │   ├── time/                       # Cairo-time + date-only formatting
│   │   ├── logging/                    # AppLogger (PII redaction), CrashReporter interface
│   │   ├── connectivity/               # online/offline stream for the banner
│   │   └── config/                     # AppConfig repository (min build, support phone)
│   ├── design_system/
│   │   ├── tokens/                     # OnAirColors (light/dark), spacing, radii, elevation
│   │   ├── typography/                 # TextTheme + OnAirTextStyles (Cairo)
│   │   ├── theme/                      # light/dark ThemeData, context extensions
│   │   └── components/                 # buttons, text field, OTP field, bottom nav,
│   │                                   # section header, state views, offline banner
│   ├── features/
│   │   ├── auth/                       # data/ domain/ presentation/: login, register,
│   │   │                               # code entry, complete profile, forgot/new password
│   │   ├── account_gate/               # session-ended handling, sign-out
│   │   ├── home/ search/ bookings/ favorites/ account/   # G0 placeholders only
│   │   └── app_update/                 # update-required + not-available screens
│   ├── l10n/                           # app_ar.arb, app_en.arb (generated localizations)
│   └── shared/
├── assets/fonts/cairo/                 # Cairo-Regular…ExtraBold (400–800), OFL licence
├── contracts/                          # draft API contracts handed to the backend owner
├── env/                                # staging.json / production.json (git-ignored),
│                                       # example.json (committed, no secrets)
├── test/                               # unit + widget + golden (mirrors lib/)
├── integration_test/                   # Staging E2E: phone sign-in, isolation
├── .github/workflows/                  # ci.yml (PR gate), staging-build.yml (main)
├── android/  ios/                      # flavors, app IDs, link verification, hardening
└── pubspec.yaml
```

**Structure Decision**: Single Flutter project at the repository root (this repo *is* the Guest
App, per the constitution). Design system and core are internal modules under `lib/` that never
import `features/`. Draft backend contracts live at the root `contracts/`; the copies under this
spec's `contracts/` are the reviewed source they are created from.

## Post-Design Constitution Re-check

Re-run after writing research, data model, and contracts:

- **II**: Every auth rule the UI shows (countdown, wait time, attempts, Egypt-only, session end,
  profile completeness) has a server source in [contracts/supabase-backend.md](contracts/supabase-backend.md).
  PASS.
- **IV**: Contracts carry no secrets; the only client config is in `EnvConfig` (public values).
  Isolation is a contract-level requirement with an automated Staging test. PASS.
- **VII**: Node client is generated from [contracts/node-api.openapi.yaml](contracts/node-api.openapi.yaml);
  Supabase access is behind repositories in `features/*/data`. PASS.
- **Open items** (do not block G0 code, tracked in research.md): final app identifiers (R14),
  link domain (R15), crash tool (R19), Staging backend readiness (R22).

## Complexity Tracking

None. No constitution violations to justify.
