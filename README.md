# OnAir Guest App

The OnAir **Guest App** (تطبيق المستأجر) — the Flutter mobile app guests use to discover,
book, pay for, and manage short-term apartment stays. Arabic-first, RTL, light and dark.

This repository contains the **Guest App only**; the Owner/Office app and the admin web are
separate projects. The backend (Supabase + Node services) is the only integration point and
its draft contracts live in [`contracts/`](contracts/).

- Master plan: [`docs/OnAir Master Plan.md`](docs/OnAir%20Master%20Plan.md)
- Guest app plan (phases, quality bars): [`docs/OnAir Guest App Plan.md`](docs/OnAir%20Guest%20App%20Plan.md)
- Design system source: [`docs/UI_UX_DESIGN_SYSTEM.md`](docs/UI_UX_DESIGN_SYSTEM.md)
- CI/CD, branch protection, and required secrets: [`docs/ci.md`](docs/ci.md)

## Requirements

- Flutter **3.44.x stable** (Dart 3.12.x), Android Studio / Xcode 16+ for device builds.
- Targets: Android 7.0+ (API 24) and iOS 15+.

## Project layout

```text
lib/
├── app/            # MaterialApp.router, router + guards + link parsing, shell, splash
├── core/           # env, generated API client, network, auth, errors, money, time, logging, config
├── design_system/  # tokens (colors light/dark), Cairo typography, theme, components
├── features/       # feature-first: auth, account_gate, home, search, bookings, favorites, account, app_update
└── l10n/           # app_ar.arb (template) + app_en.arb, generated localizations
```

Layers: widgets never touch Supabase/Dio directly — repositories own data access; core and
the design system never import features. Generated code (`**/*.g.dart`, `**/*.freezed.dart`,
`lib/core/api/generated/`, `lib/l10n/generated/`) must not be edited by hand.

## Setup

1. Create your environment file from the template and fill in the **public** Staging values
   only (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `NODE_API_BASE_URL`, `LINK_DOMAIN`).
   `env/*.json` files are git-ignored and must never contain a `service_role` key or any
   provider secret.

   `BACKEND_MODE` chooses the backend (Guest Plan §2.6): `mock` (the default in
   `env/example.json`) runs on in-memory data with no Supabase, Node, or Firebase connection;
   every code is `123456` and only Egyptian numbers are accepted, like the real contract.
   Set `BACKEND_MODE` to `remote` (or remove it) to use Staging. Production rejects `mock`.

   ```bash
   cp env/example.json env/staging.json
   ```

2. Fetch dependencies and run code generation:

   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   flutter gen-l10n
   dart run swagger_parser        # regenerates lib/core/api/generated from contracts/
   ```

## Flavors & running

Two flavors, each with its own application id, name, icon, and Firebase project. Config is
injected at build time with `--dart-define-from-file`; there is no default flavor.

```bash
# Staging (com.onair.guest.staging, "OnAir (Staging)")
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=env/staging.json

# Production (com.onair.guest, "OnAir")
flutter run --flavor production -t lib/main_production.dart --dart-define-from-file=env/production.json
```

`env/production.json` follows the same shape as `env/staging.json` against the Production
Supabase/Node/Firebase projects.

## Tests

```bash
flutter test                      # unit + widget + golden (alchemist CI mode)
dart format --set-exit-if-changed .
flutter analyze                   # very_good_analysis, zero warnings
bash tool/check_hardcoded_styles.sh   # no hard-coded colors/sizes outside the design system
```

Golden baselines are renderer-specific (Cairo text); CI runs on Windows and the committed
baselines were generated there. Regenerate only on purpose:

```bash
flutter test --update-goldens --tags golden
```

Staging end-to-end (needs the Staging Supabase setup from
[`contracts/supabase-backend.md`](contracts/supabase-backend.md)):

```bash
flutter test integration_test --flavor staging --dart-define-from-file=env/staging.json
```

Until the backend is live, widget tests run against fakes and the Node contract can be
mocked locally: `npx @stoplight/prism-cli mock contracts/node-api.openapi.yaml`.

## CI/CD

Every pull request runs the quality gate (format, analyze, hard-coded-style check,
generated-code freshness, tests, gitleaks secret scan); pushes to `main` build the
obfuscated Staging APK and distribute it through Firebase App Distribution. Branch
protection on `main` and the required action secrets are documented in
[`docs/ci.md`](docs/ci.md).

## Useful background

- Validation scenarios V1–V20 and their status: [`specs/001-guest-app-foundation/checklists/validation.md`](specs/001-guest-app-foundation/checklists/validation.md)
- Performance baseline: [`docs/perf/g0-baseline.md`](docs/perf/g0-baseline.md)
- Accessibility review: [`docs/qa/g0-accessibility.md`](docs/qa/g0-accessibility.md)
