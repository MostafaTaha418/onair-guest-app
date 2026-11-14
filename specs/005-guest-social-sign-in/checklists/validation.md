# S005 Validation (T082)

Recorded 2026-11-14, branch `feature/005-guest-social-sign-in` @ the Phase 11 commit.
Automated gates below ran on the host (Windows); the emulator/simulator walks and the mock
integration runs are **pending a device run** — they are listed per scenario with the
automated coverage that stands in for them so far.

## Gates (host)

- `dart format --set-exit-if-changed .` — **pass** (exit 0)
- `flutter analyze` — **pass** (0 issues, very_good_analysis)
- `flutter test` — **pass** (1408 tests, incl. 128 goldens)
- `tool/check_hardcoded_styles.sh` — pass in CI
- Integration in mock mode (`quickstart §3`) — **pending**: the three suites
  (`social_sign_in_mock_test.dart`, `phone_otp_limits_mock_test.dart`,
  `email_register_phone_mock_test.dart`) need a device runner; their journeys are covered on
  the host by the journey/booking/stay suites and the unit tests they exercise.

## Quickstart scenarios (mock mode)

| Scenario | Automated coverage (host) | Device walk |
|---|---|---|
| V1 — Google (new user) → «أكّد رقمك», gated routes | social_sign_in_mock (d) host equivalent: cubit/redirect/router tests; login/confirm goldens | pending |
| V2 — number + code → complete, same spot | phone_verification cubit tests + T056 screen tests + integration (d) pending | pending |
| V3 — wrong code → restart → still phoneless | integration (e) pending; mock_auth_repository_test + restore tests pass | pending |
| V4 — ladder countdowns follow `next_send_at` | mock_otp_server_test (9 waits) + send_window_format_test pass | pending |
| V5 — request before `next_send_at` → RATE_LIMITED | mock_otp_server_test RATE_LIMITED + cubit window-refresh test pending device | pending |
| V6 — 11th request → 7-day block (reinstall/new account/other device) | mock_otp_server_test (3 key scopes, idle/verify resets) + integration (b)(c)(d) pending | pending |
| V7 — attestation failure counts nothing | interceptor test + mock_otp_server_test + integration (e) pending | pending |
| V8 — number not on WhatsApp notice | phone_verification_cubit_code_test (poll) pass | pending |
| V9 — registration without phone → «أكّد رقمك» | email_flows/auth_validation/mock repo tests pass; integration (a) pending | pending |
| V10 — change number from the account | /account/phone route + cubit change tests pass; integration (c) pending | pending |
| V11 — legacy account untouched | mock_auth_repository_test (legacy seed) pass; integration (b) pending | pending |
| V12 — one account: same confirmed email | mock_auth_repository_test (legacyUser same id) pass | pending |
| V13 — Google joins a confirmed-email account | mock_auth_repository_test + integration (f) pending | pending |
| V14 — provider wins over an unconfirmed signup | mock_auth_repository_test (FR-040 takeover) pass | pending |
| V15 — account rows show method/phone/change | account_placeholder_test (4 cases) + goldens pass | pending |
| V16 — sign-out everywhere returns to a visitor | sign_out_test + SignOutService tests pass | pending |
| V17 — booking verify hands the phone to the WhatsApp step | verify_identity cubit/screen tests rewritten pass | pending |

## Staging (T084)

**Blocked until the user confirms backend deltas A1–A9 are deployed and M1–M13 are done** —
not attempted. The checklist row stays empty until then.

## Accessibility (T079)

Code-side fixes landed and pinned by
`test/features/auth/presentation/whatsapp_code_step_semantics_test.dart`: the ticking resend
countdown is excluded from the semantics tree behind one static «ابعت كود جديد» button label,
field errors are live regions (phases 5–6), and the blocked notice announces itself when it
appears. The TalkBack/VoiceOver walkthrough on login / «أكّد رقمك» / the code step / blocked is
**pending a device run** with the emulator walks above.

