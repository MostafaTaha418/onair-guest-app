# CI/CD — Quality Gates and Staging Distribution

This repository has two GitHub Actions workflows (User Story 7 / tasks.md T107–T109):

| Workflow | File | Trigger | Purpose |
|---|---|---|---|
| `ci` | [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) | every pull request | Blocks merges on formatting, analysis, stale generated code, failing tests, or leaked secrets |
| `staging-build` | [`.github/workflows/staging-build.yml`](../.github/workflows/staging-build.yml) | push to `main` (and manual dispatch) | Builds the obfuscated Staging APK and distributes it via Firebase App Distribution |

Both workflows pin **Flutter 3.44.3 (stable)**. The secret-scan job pins **gitleaks 8.30.1** with the repository config [`.gitleaks.toml`](../.gitleaks.toml).

## ci.yml — pull-request gate

Four parallel jobs; every one of them must pass:

| Check name | What it runs |
|---|---|
| `format & analyze` | `flutter pub get`, `dart format --set-exit-if-changed .`, `flutter analyze` (very_good_analysis, zero warnings), `tool/check_hardcoded_styles.sh` (no hard-coded colors/font sizes outside the design system) |
| `generated code up to date` | Re-runs all codegen (`build_runner`, `flutter gen-l10n`, `swagger_parser`) and fails if any tracked file changes — generated code must be committed, never edited by hand (Constitution VII) |
| `unit, widget & golden tests` | `flutter test` (unit + widget + goldens; goldens run in alchemist CI mode, so they are platform-independent) |
| `secret scan (gitleaks)` | gitleaks over the full git history with `.gitleaks.toml` |

## staging-build.yml — merge to main

1. Writes `env/staging.json` from the `STAGING_ENV_JSON` secret (never committed).
2. Builds: `flutter build apk --flavor staging -t lib/main_staging.dart --obfuscate --split-debug-info=build/symbols --dart-define-from-file=env/staging.json`.
3. Uploads `build/symbols` as the `staging-symbols-<sha>` artifact — keep it so obfuscated stack traces can be symbolicated.
4. Scans the built APK with `tool/scan_build_for_secrets.sh` (same pattern set as gitleaks: Supabase `service_role`, Kashier, Resend, SMS provider keys).
5. Distributes the APK with [Firebase App Distribution](https://firebase.google.com/docs/app-distribution) to the Staging testers group.

iOS TestFlight distribution is deferred until the Apple developer account and signing are
ready (research.md R21).

## Required repository settings

### Branch protection on `main`

Settings → Branches → Add branch protection rule for `main`:

- **Require a pull request before merging** — on.
- **Require status checks to pass before merging** — require these checks (they appear
  under the `ci` workflow):
  - `format & analyze`
  - `generated code up to date`
  - `unit, widget & golden tests`
  - `secret scan (gitleaks)`
- **Require branches to be up to date before merging** — on, so a PR is re-tested when
  `main` moves.
- Recommended: **Do not allow bypassing the above settings**, **Do not allow force
  pushes**, **Do not allow deletions**.

### Required action secrets

Settings → Secrets and variables → Actions → Repository secrets:

| Secret | Purpose | How to obtain |
|---|---|---|
| `STAGING_ENV_JSON` | Full contents of `env/staging.json` written verbatim by CI: `FLAVOR`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `NODE_API_BASE_URL`, `LINK_DOMAIN` | Copy from the Staging Supabase project settings and the Node API Staging base URL; the anon key is the **anon** key, never `service_role` (Constitution IV) |
| `FIREBASE_APP_ID_STAGING` | Android app ID of the Staging Firebase project | Firebase console → Project settings → General → Apps → Android (`1:…:android:…`) |
| `FIREBASE_SERVICE_CREDENTIALS` | Service-account key used to upload releases | Google Cloud console → IAM → Service accounts → the App Distribution service account → Keys → JSON; grant it the **Firebase App Distribution Admin** role |
| `FIREBASE_STAGING_TESTERS` | Tester group alias that receives the build | Firebase console → App Distribution → Testers & Groups → create a group and use its alias |

## Local parity

Run the same checks a PR runs:

```sh
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
bash tool/check_hardcoded_styles.sh
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
dart run swagger_parser
git status --porcelain   # must be empty
flutter test
```

## Secret scan policy (.gitleaks.toml)

- Extends the gitleaks defaults with rules for the key classes forbidden by
  Constitution IV: Supabase `service_role` JWTs (base64 payload fragments, plus the
  plaintext word), Kashier keys, Resend keys (`re_…`), and SMS provider keys
  (Twilio / MessageBird / generic).
- Allowlists are narrow and documented in the config: contract and governance docs that
  only *mention* the word `service_role`, the key-checker code and its test, the build
  scanner itself, and FlutterFire public config files (`google-services.json`,
  `GoogleService-Info.plist`, `firebase_options_*.dart`) — Firebase API keys are public
  client configuration restricted per service in the Firebase console.
- **If a scan fails:** treat it as a leak until proven otherwise. Rotate the exposed key
  first (Supabase dashboard → rotate JWT secret / provider dashboard), then remove it
  from the source. Because gitleaks scans full history, a key that was ever committed is
  considered exposed even if a later commit removed it.
- Placeholder and example values (`env/example.json`, docs, test fixtures) are ignored
  by a global allowlist; if a new false positive appears, narrow it with a path or
  pattern allowlist in `.gitleaks.toml` — never disable a rule.

## Notes

- The Staging APK is currently signed with the template's debug key
  (`android/app/build.gradle.kts` release `signingConfig`). Production signing keys will
  live only in CI secrets when the store track is set up (constitution: signed
  production builds are built from CI only).
- `env/staging.json` and `env/production.json` are git-ignored; only `env/example.json`
  is committed.
