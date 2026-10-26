# Quickstart & Validation: Guest App Foundation (G0)

How to run the foundation and prove each user story works. Details live in
[data-model.md](data-model.md) and [contracts/](contracts/); this file is a run/validation guide.

## Prerequisites

- Flutter 3.44.x stable (Dart 3.12.x); Android Studio / Xcode 16+ for device builds.
- A Staging Supabase project configured per [supabase-backend.md](contracts/supabase-backend.md)
  (Egypt-only SMS hook, emailed 6-digit codes, 30-day inactivity, `profiles`, `app_config`,
  `complete_guest_profile`), plus Staging test phone numbers with fixed OTPs.
- Staging Firebase project; `flutterfire` CLI.
- Optional, for Node endpoints before the backend is live:
  `npx @stoplight/prism-cli mock contracts/node-api.openapi.yaml`.

## Setup

```bash
cp env/example.json env/staging.json
```

Fill `env/staging.json` with the **public** Staging values only: `SUPABASE_URL`,
`SUPABASE_ANON_KEY`, `NODE_API_BASE_URL`, `LINK_DOMAIN`. Never put a `service_role` key or any
provider secret in it.

```bash
flutter pub get
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

```bash
flutter gen-l10n
```

## Run

```bash
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=env/staging.json
```

## Automated checks (same as CI)

```bash
dart format --set-exit-if-changed .
```

```bash
flutter analyze
```

```bash
flutter test
```

Goldens are compared in CI mode; regenerate only on purpose:

```bash
flutter test --update-goldens --tags golden
```

Staging E2E (phone sign-in + isolation):

```bash
flutter test integration_test --flavor staging --dart-define-from-file=env/staging.json
```

## Validation scenarios

| # | Story | Steps | Expected |
|---|---|---|---|
| V1 | US1 | Fresh install, open app, no account | Splash with no white flash → Home skeleton < 2.5 s (Profile mode, mid-range Android); Arabic RTL; Home first tab on the right |
| V2 | US1 | Scroll a tab, switch tabs, return | Same scroll position |
| V3 | US1 | Toggle device dark mode with app open | App switches palette live |
| V4 | US1 | Device language English | App stays Arabic RTL |
| V5 | US1 | Device text size max | Text capped at 1.3×, nothing clipped |
| V6 | US2 | Sign up with a Staging test number, enter code, complete name + terms | Signed in; phone shown verified |
| V7 | US2 | Enter a non-Egyptian number | Arabic message: Egyptian numbers only; offer email |
| V8 | US2 | Wrong code; then exceed attempts | Clear error under field (announced by screen reader); then wait time with disabled button |
| V9 | US2 | Request code for registered vs unregistered number | Identical message |
| V10 | US3 | Force-close and reopen | Still signed in |
| V11 | US3 | End the session from Supabase dashboard; tap a members-only tab | "Session ended" → sign-in → back to the same tab |
| V12 | US3 | Sign out | Home as visitor; secure storage empty; device token removed (check Node logs / Prism) |
| V13 | US4 | Register with email; enter emailed code | Email verified; no link in the email |
| V14 | US4 | Forgot password → emailed code → new password | Sign in with new password works; same message for unknown email |
| V15 | US5 | As visitor tap My Bookings → sign in | Lands on My Bookings |
| V16 | US5 | Open a simulated link `https://<LINK_DOMAIN>/bookings/not-a-uuid` | `/not-available`, nothing else changes |
| V17 | US6 | Install staging and production builds side by side | Different names/icons; Staging account fails on Production |
| V18 | US7 | Open a PR with a format error or `service_role` string | CI fails, merge blocked |
| V19 | US8 | Set `min_supported_build_android` above installed build; reopen | Blocking update screen |
| V20 | FR-038 | Run `integration_test/isolation_test.dart` | A cannot read B's profile (0 rows) |
