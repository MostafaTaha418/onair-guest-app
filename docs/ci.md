# CI: Pull Request Checks

Workflow: [`.github/workflows/pr-checks.yml`](../.github/workflows/pr-checks.yml).
Runs on every pull request into `develop` or `main`, and manually from the Actions tab.

## Branch flow

`feature/NNN-name` (one per part) → PR into `develop` → release PR into `main`.
Nothing is pushed directly to `develop` or `main`.

## Jobs

| Job (check name) | Runner | What it proves |
|---|---|---|
| `Quality (format, analyze, tests)` | Ubuntu | Generated code + `pubspec.lock` committed; formatting; `flutter analyze` clean; no hard-coded colors/font sizes (once `tool/check_hardcoded_styles.sh` exists); unit, widget, and golden tests pass |
| `Secrets scan` | Ubuntu | gitleaks finds no keys in the PR's commits (uses `.gitleaks.toml` once added) |
| `Android (API 24)` | Ubuntu + emulator | Debug APK builds, installs, launches, and is still running after 20 s without a crash on the **minimum** supported Android |
| `Android (API 34)` | Ubuntu + emulator | Same on a recent Android |
| `iOS (build + simulator)` | macOS 15 | Unsigned release build for devices compiles; simulator build installs, launches, and keeps running on the newest available iPhone simulator |

Android and iOS jobs start only after `Quality` passes. When `integration_test/*_test.dart`
exists and the `STAGING_ENV_JSON` secret is set, both device jobs also run the integration
tests on the emulator/simulator.

Before G0 adds flavors, the jobs build the template app. Once `lib/main_staging.dart` exists
they build the **Staging** flavor automatically (`tool/ci/build_args.sh`). For that,
`env/example.json` must contain syntactically valid placeholder values (HTTPS URLs) so the app
can start without real Staging config.

## Repository settings (done once by a repo admin)

1. **Branch protection** for `develop` and `main` (Settings → Branches → Add rule):
   - Require a pull request before merging.
   - Require status checks to pass: `Quality (format, analyze, tests)`, `Secrets scan`,
     `Android (API 24)`, `Android (API 34)`, `iOS (build + simulator)`.
   - Require branches to be up to date before merging.
2. **Secrets** (Settings → Secrets and variables → Actions):
   - `STAGING_ENV_JSON` (optional until Staging exists): full content of `env/staging.json`
     with **public** Staging values only. Never a `service_role` key or provider secret.

## Notes

- macOS runner minutes cost about 10× Linux minutes on private repositories. The iOS job runs
  once per PR update; cancelled runs (new pushes) stop early via `concurrency`.
- Hosted macOS runners ship recent iOS runtimes only, so the simulator check runs on the newest
  iOS, not the minimum supported version. Test the minimum on a real device before release.
- Flutter version is pinned in `.github/actions/setup-flutter/action.yml`; keep it in sync with
  `specs/*/plan.md`.

## Run the same checks locally

```bash
dart format --output=none --set-exit-if-changed lib test
```

```bash
flutter analyze
```

```bash
flutter test
```
