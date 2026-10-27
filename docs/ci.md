# CI/CD — Quality Gates and Staging Distribution

This repository has two GitHub Actions workflows (User Story 7 / tasks.md T107–T109):

| Workflow | File | Trigger | Purpose |
|---|---|---|---|
| `ci` | [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) | every pull request | Blocks merges on formatting, analysis, stale generated code, failing tests, or leaked secrets |
| `staging-build` | [`.github/workflows/staging-build.yml`](../.github/workflows/staging-build.yml) | push to `main` (and manual dispatch) | Builds the obfuscated Staging APK and distributes it via Firebase App Distribution |

Both workflows pin **Flutter 3.44.3 (stable)**. The secret-scan job pins **gitleaks 8.30.1** with the repository config [`.gitleaks.toml`](../.gitleaks.toml).

Actions are pinned to full commit SHAs, the gitleaks archive is checked against its
pinned SHA256 before execution, and both workflows explicitly use `contents: read`.
Checkout credentials are not persisted. Re-verify upstream references and checksums
when updating these pins; do not replace them with mutable tags.

## ci.yml — pull-request gate

Four parallel jobs; every one of them must pass:

| Check name | What it runs |
|---|---|
| `format & analyze` | `flutter pub get`, `dart format --set-exit-if-changed .`, `flutter analyze` (very_good_analysis, zero warnings), `tool/check_hardcoded_styles.sh` (no hard-coded colors/font sizes outside the design system) |
| `generated code up to date` | Re-runs all codegen (`build_runner`, `flutter gen-l10n`, `swagger_parser`) and fails if any tracked file changes — generated code must be committed, never edited by hand (Constitution VII) |
| `unit, widget & golden tests` | `flutter test` (unit + widget + goldens) and Python CI security-helper tests. Uses `windows-2025`, matching the existing reference images, which preserve real Cairo text (`obscureText: false`). The Alchemist `ci` folder name does not make these text-rendering baselines cross-platform. Failed image comparisons are uploaded as artifacts. |
| `secret scan (gitleaks)` | gitleaks over the full git history with `.gitleaks.toml` |

## staging-build.yml — merge to main

1. Writes `env/staging.json` from the `STAGING_ENV_JSON` secret (never committed), then validates all five keys before building. `FLAVOR` must be `staging`, endpoints must use HTTPS, `LINK_DOMAIN` must be a bare hostname, and the client key must be publishable (or a legacy `anon` JWT). Backend credentials and extra keys are rejected. Firebase secrets must also be present, with the exact Staging Android App ID.
2. Builds: `flutter build apk --flavor staging -t lib/main_staging.dart --obfuscate --split-debug-info=build/symbols --dart-define-from-file=env/staging.json`.
3. Uploads `build/symbols` as the `staging-symbols-<sha>` artifact — keep it so obfuscated stack traces can be symbolicated.
4. Scans the built APK with `tool/scan_build_for_secrets.sh`, which calls the Python standard-library scanner. It reads ZIP entries without extracting paths, decodes JWT claims regardless of Base64 alignment/JSON spacing, checks ASCII/UTF-16 strings and chunk boundaries, and rejects backend Supabase keys, Kashier, Resend, and SMS credentials. No matched credential values are logged.
5. Distributes the APK with [Firebase App Distribution](https://firebase.google.com/docs/app-distribution) to the Staging testers group.

iOS TestFlight distribution is deferred until the Apple developer account and signing are
ready (research.md R21).

## Required repository settings

### Branch protection on `main`

Private repositories require a GitHub plan that supports branch protection. On
2026-10-27 this repository returned `403: Upgrade to GitHub Pro or make this repository
public to enable this feature.` CI can still run, but it cannot enforce blocked merges
until the account plan supports protection. Keep the repository private; upgrading
the plan is an owner/billing decision. Do not treat the existence of workflow files
or completed T106–T109 implementation tasks as proof that merge protection is active.

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
| `STAGING_ENV_JSON` | Full contents of `env/staging.json`: `FLAVOR`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `NODE_API_BASE_URL`, `LINK_DOMAIN` | Use the new Staging Supabase URL and **publishable** key (legacy `anon` is accepted), and the deployed Edge Function command API URL. Never use `service_role` or `sb_secret_` (Constitution IV). Existing variable names remain for compatibility. |
| `FIREBASE_APP_ID_STAGING` | Android app ID of the Staging Firebase project | Firebase console → Project settings → General → Apps → Android (`1:…:android:…`) |
| `FIREBASE_SERVICE_CREDENTIALS` | Service-account key used to upload releases | Google Cloud console → IAM → Service accounts → the App Distribution service account → Keys → JSON; grant it the **Firebase App Distribution Admin** role |
| `FIREBASE_STAGING_TESTERS` | Tester group alias that receives the build | Firebase console → App Distribution → Testers & Groups → create a group and use its alias |

### Verified setup status (2026-10-27)

- GitHub Actions is enabled. Default workflow token permissions were set to read;
  workflows cannot approve pull-request reviews.
- `FIREBASE_APP_ID_STAGING` is configured for
  `1:1093743526436:android:cbd768d954e65acc784eb1` in `onair-guest-staging`.
- `FIREBASE_STAGING_TESTERS` is configured as `onair-staging`; the group
  **OnAir Staging** was created successfully. A human must choose/add tester emails.
- `FIREBASE_SERVICE_CREDENTIALS` is configured using the dedicated account
  `github-staging-distribution@onair-guest-staging.iam.gserviceaccount.com`, with
  `roles/firebaseappdistro.admin`. Its private key was transferred directly to
  GitHub's encrypted secret without writing it to disk or printing it.
- `STAGING_ENV_JSON` is still pending: the owner will replace the old Supabase
  project and supply the new public configuration. Do not keep using the old
  project's values or substitute `https://api.on-air.website` as an API endpoint.
  The deployment will use Supabase Auth, Database, and Edge Functions, without a
  separate Node host. `NODE_API_BASE_URL` is the current legacy config name for
  the command API and can point to the deployed Edge Function base URL, such as
  `https://<new-ref>.supabase.co/functions/v1/guest-api`. That function must be
  implemented/deployed before the URL is usable.
- Branch protection is blocked by the current GitHub plan, not by admin permissions.
- End-to-end CI distribution is pending the real Staging environment. Successful
  source checks alone do not prove that the backend or delivery works.
- Read-only diagnostics with the supplied publishable key reached Supabase Auth
  (`/auth/v1/settings`: HTTP 200). The Data API returned `PGRST205` for both
  `public.profiles` and `public.app_config` using `limit=0`; these required tables
  are not currently available to the client through the API. No user rows were read.
  Also, `api.on-air.website` did not resolve in DNS. Backend readiness must be fixed
  before validating live sign-in/profile completion/device registration.

### Owner steps for pending setup

1. Open GitHub account **Settings → Billing and licensing** (or **Billing & plans**)
   and select a plan supporting protected private repositories. Review the price
   and confirm payment yourself. Then open this repository's **Settings → Branches**
   and configure `main` with the four required checks listed above, requiring a PR,
   an up-to-date branch, and no force pushes/deletions. The check names appear after
   the first PR run. Until then, merge only after manually confirming all checks.
2. Create the replacement Staging Supabase project, retain its database password
   securely, and obtain **Project URL**, **Project Ref**, and the **Publishable key**
   from **Connect** / **Settings → API Keys**. Share only those public values with
   the app developer. Deploy the command API as a Supabase Edge Function from the
   shared Backend repository. Its URL must implement the contract in
   `contracts/node-api.openapi.yaml`; changing only a DNS record does not deploy an API.
   Apply schema changes through the team's migration/PR process, not this Guest repo.
3. Open **Repository Settings → Secrets and variables → Actions → New repository
   secret**, name it `STAGING_ENV_JSON`, and enter exactly:

   ```json
   {
     "FLAVOR": "staging",
     "SUPABASE_URL": "https://YOUR_STAGING_REF.supabase.co",
     "SUPABASE_ANON_KEY": "YOUR_STAGING_PUBLISHABLE_KEY",
     "NODE_API_BASE_URL": "https://YOUR_STAGING_REF.supabase.co/functions/v1/guest-api",
     "LINK_DOMAIN": "on-air.website"
   }
   ```

   Replace all placeholders with real values. Keep server/provider keys out of this
   JSON. Optionally validate the same local file using
   `python3 tool/validate_staging_env.py env/staging.json` (`python` on Windows).
4. Open Firebase project **onair-guest-staging → App Distribution → Testers & Groups**.
   Open group **OnAir Staging** (`onair-staging`), add the intended tester emails, and
   save. Check the selected Google account: the project was created using
   `elhawysasa697@gmail.com`; another account may show “project does not exist”.
   Testers must accept the email invitation to access distributed builds.
5. Open a PR and wait for all four `ci` checks. After review and merge to `main`,
   `staging-build` runs automatically. Alternatively, after the workflow exists on
   `main`, use **Actions → staging-build → Run workflow**, selecting the intended ref.
   Verify `staging-symbols-<sha>`, the release under Firebase App Distribution, and
   installation by a tester. Retain symbols for each distributed build.

Official references: [GitHub protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches),
[Firebase service-account authentication](https://firebase.google.com/docs/app-distribution/authenticate-service-account?platform=android),
[Firebase CLI distribution](https://firebase.google.com/docs/app-distribution/android/distribute-cli),
and [Supabase API keys](https://supabase.com/docs/guides/getting-started/api-keys).

### Golden-image baseline environment

Generate and review baseline changes on Windows using the pinned Flutter version:
`flutter test --update-goldens --tags golden`, then run `flutter test` without the
update flag. Commit reviewed PNG changes with the UI change. Keep `obscureText: false`
to retain readable Arabic/Cairo typography checks; do not hide text or add pixel
tolerances just to make a cross-platform renderer pass. Other quality jobs still run
on Ubuntu. The workflow never updates baselines automatically.

## Local parity

Run the same checks a PR runs:

```sh
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
bash tool/check_hardcoded_styles.sh
dart run swagger_parser
dart format lib/core/api/generated
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
dart format lib/core/api/generated lib/l10n/generated
git status --porcelain   # must be empty
flutter test
python3 -m unittest discover -s tool/tests -v
```

## Secret scan policy (.gitleaks.toml)

- Extends the gitleaks defaults with rules for the key classes forbidden by
  Constitution IV: Supabase `service_role` JWTs (all three Base64 alignments, plus the
  plaintext word), Kashier keys, Resend keys (`re_…`), and SMS provider keys
  (Twilio / MessageBird / generic), and backend-only `sb_secret_` keys. The artifact
  scanner also decodes JWT claims directly, including JSON escape sequences.
- Allowlists are narrow and documented in the config: contract and governance docs that
  only *mention* the word `service_role`, the key-checker code and its test, the build
  shared checker itself (literal-word rule only), and FlutterFire public config files (`google-services.json`,
  `GoogleService-Info.plist`, `firebase_options_*.dart`) — Firebase API keys are public
  client configuration restricted per service in the Firebase console.
- Two exact historical commits of the former Bash scanner are allowed only for its
  encoded search-pattern text. Current files and future commits remain scanned.
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
