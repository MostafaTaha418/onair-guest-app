# G0 Validation Record — Quickstart V1–V20

Tracks the validation scenarios from
[quickstart.md](../quickstart.md) against the Guest App Foundation (G0).
Recorded 2026-10-28, after Phases 1–10 (all eight user stories) were implemented on
`feature/001-guest-app-foundation`.

## Status legend

- **PASS (automated)** — proven by the committed unit/widget/golden test suite
  (`flutter test`, 108 tests green on 2026-10-28) and CI.
- **PARTIAL** — the app-side behaviour is proven automatically; the device/real-service
  part of the scenario is not.
- **PENDING** — blocked on the Staging backend, a physical device, or repository settings;
  nothing recorded yet.

## Matrix

| # | Scenario (short) | Automated coverage | Status | Notes |
|---|---|---|---|---|
| V1 | Fresh install → splash → Home, no white flash | `test/app/goldens/splash_and_shell_golden_test.dart`, `test/app/splash/splash_transition_test.dart` | PARTIAL | Cold-start timing (< 2.5 s, Profile mode, mid-range Android) needs the device run in `docs/perf/g0-baseline.md` |
| V2 | Per-tab scroll position preserved | `test/app/shell/app_shell_test.dart` | PASS (automated) | — |
| V3 | Live dark-mode switch | `OnAirTheme.light/dark` wired to `ThemeMode.system`; light/dark goldens | PARTIAL | Device toggle run pending |
| V4 | English device stays Arabic RTL | `test/app/app_locale_test.dart` | PASS (automated) | — |
| V5 | Text scale capped at 1.3×, nothing clipped | Clamp in `app.dart`; goldens at 1.3× | PASS (automated) | — |
| V6 | Phone sign-up → code → profile → verified | `integration_test/phone_sign_in_test.dart` (written) | PENDING | Needs Staging Supabase (Egypt-only SMS hook, fixed-OTP test numbers) |
| V7 | Non-Egyptian number message | `test/features/auth/presentation/login_phone_test.dart` | PASS (automated) | — |
| V8 | Wrong code error, then rate-limit wait | `test/features/auth/presentation/otp_screen_test.dart` | PASS (automated) | Error announced via live region |
| V9 | Registered vs unregistered → identical copy | `test/features/auth/presentation/login_phone_test.dart` | PASS (automated) | Server-side rate limits need the live Staging run |
| V10 | Force-close and reopen stays signed in | `test/core/auth/secure_session_storage_test.dart` | PARTIAL | Secure-storage persistence proven at unit level; force-close/reopen needs a device |
| V11 | Server-ended session → login → same screen | `test/features/account_gate/presentation/session_ended_test.dart` | PARTIAL | Ending a session from the Supabase dashboard needs Staging |
| V12 | Sign-out clears everything | `test/features/account_gate/application/sign_out_service_test.dart`; `integration_test/sign_out_test.dart` (written) | PENDING | Token unregister + storage-empty check on device needs Staging |
| V13 | Email registration + emailed code | `test/features/auth/data/supabase_auth_repository_email_test.dart`, `test/features/auth/presentation/email_flows_test.dart` | PARTIAL | Flow proven against the mocked client; real emailed code needs Staging (Resend hook) |
| V14 | Recovery: forgot → code → new password | `email_flows_test.dart`, `test/features/auth/presentation/email_flows_test.dart` | PARTIAL | Same as V13 |
| V15 | Visitor → members-only → login → lands there | `test/app/router/redirect_test.dart` | PASS (automated) | — |
| V16 | Malformed link → `/not-available` | `test/app/router/link_parser_test.dart` | PARTIAL | Parser proven; `assetlinks.json`/AASA for the real domain pending the link-domain decision (R15) |
| V17 | Staging and Production side by side | Flavors, icons, ids configured (T098–T101) | PENDING | Needs installing both builds on a device |
| V18 | Bad PR blocked by CI | `.github/workflows/ci.yml` + `.gitleaks.toml` (T106–T107) | PENDING | Requires branch protection + repo secrets per `docs/ci.md`; first real PR will confirm |
| V19 | Below-minimum build blocked | `test/core/config/version_gate_test.dart`, `redirect_test.dart`, `test/app/app_foundation_test.dart` | PASS (automated) | Staging config flip (`min_supported_build_android`) to be repeated live |
| V20 | Isolation: A cannot read B | `integration_test/isolation_test.dart` (written) | PENDING | Needs Staging RLS + two test accounts |

## What blocks the PENDING items

1. **Staging Supabase project** per [`contracts/supabase-backend.md`](../../contracts/supabase-backend.md)
   (tables, RLS, RPC, SMS hook, emailed codes, test numbers) — research R22.
2. **Link domain** decision (R15) for verified links (`assetlinks.json` / AASA).
3. **Physical devices** (mid-range Android for V1/V10/V17, plus TalkBack/VoiceOver runs for
   `docs/qa/g0-accessibility.md`).
4. **Repository settings** (branch protection + secrets per [`docs/ci.md`](../../../docs/ci.md))
   for V18 and the `staging-build` distribution.

When each blocker clears, run the scenario per quickstart.md and flip the status with the
date and a one-line result here.
