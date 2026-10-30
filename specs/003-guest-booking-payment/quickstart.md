# Quickstart: Guest Booking & Payment (G2)

How to run and check G2. Setup is the same as G0 and G1
([G1 quickstart](../002-guest-discovery/quickstart.md)). Contracts are in
[contracts/](contracts/), and entities and rules are in [data-model.md](data-model.md).

## Prerequisites

- G1 is merged into `develop`. This work is on `feature/003-guest-booking-payment`.
- `env/staging.json` exists, holding public values only (Supabase URL + anon key, Node base URL,
  `LINK_DOMAIN`, Firebase options).
- **Mock mode** (`"BACKEND_MODE": "mock"`) covers the whole flow with fixtures in
  `lib/features/bookings/data/fixtures/`. The mock "payment page" is a local screen with
  Succeed / Fail / Cancel / Close buttons, and the mock server emits the matching notification
  signal after a configurable delay (including "never", for the timeout case).
- **Remote mode** needs:
  - deltas D0–D4 deployed to Staging ([supabase-booking.md §4](contracts/supabase-booking.md));
  - the Staging seed ([supabase-booking.md §9](contracts/supabase-booking.md));
  - the Kashier test account and the return link configured (Guest Plan §19.1, §19.2);
  - a Firebase Staging project with the guest app registered (G0).

  Quote and payment start already work on Staging without D0–D4; My Bookings and the
  verification outcomes need D1–D4.

## Build and run

```bash
flutter pub get
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

```bash
flutter gen-l10n
```

```bash
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=env/staging.json
```

## Quality gates (same as CI)

```bash
dart format --set-exit-if-changed .
```

```bash
flutter analyze
```

```bash
flutter test
```

```bash
flutter test --tags golden
```

## Validation scenarios

Run each scenario in mock mode first, then on Staging once the deltas and seed exist.

| # | Scenario | Steps | Expected | Covers |
|---|---|---|---|---|
| 1 | Verify before booking | Guest with unconfirmed phone → apartment → "Book now" | Verify step opens; non-Egyptian number and a used number are refused with clear messages; "has WhatsApp" hides the second number; correct code returns to the date step with the same dates and guests | US2, FR-001–FR-003, AC-001 |
| 2 | Date step rules | Verified guest → "Book now" | Unavailable and past days disabled; departure must follow arrival; guests capped at the maximum; nights update | FR-004 |
| 3 | Quote refused | Mock: make the quote return `DATES_UNAVAILABLE`, then `GUESTS_EXCEEDED` | Message on the date step; unavailable days refresh | US1 sc. 4, FR-005 |
| 4 | Summary values | Quote the deposit fixture and the full-payment fixture | Every amount equals the fixture's quote; remaining + due date only for deposit; 24 h refund notice shown | FR-007, FR-008, AC-014 |
| 5 | Pay and succeed | Summary → "Go to payment" → Succeed | Button disables at once; page opens in the in-app browser; return shows "Verifying…", then success with the owner deadline; push permission asked once | US1 sc. 5–7, FR-010–FR-013, FR-030 |
| 6 | Return is not confirmation | Mock: Succeed on the page but delay the server signal 60 s | "Verifying…" for 60 s; never "paid" before the signal; no "Pay again" anywhere | AC-015, FR-014, SC-002 |
| 7 | Failure and retry | Pay → Fail | "Not completed, nothing charged" + "Try again"; retry uses a new attempt key (check the debug log prefix) | US1 sc. 8, FR-015 |
| 8 | Conflict | Mock: Succeed with conflict outcome | Full-refund message + "Find other dates"; booking listed under Cancelled with a refund chip | US1 sc. 9, AC-018 |
| 9 | Timeout | Mock: server never answers | After ≈ 2 min the not-confirmed message and "Go to My Bookings"; booking shows "Verifying payment" in Current | US1 sc. 10, US6 sc. 6 |
| 10 | Double tap and network retry | Double-tap "Go to payment"; separately, drop network after tap and retry | One session per attempt (mock counts sessions per key = 1) | AC-023, SC-003 |
| 11 | App killed mid-payment | Open the page → kill the app → reopen | Unfinished-payment banner on Home and My Bookings opens the attempt's status | US6 sc. 3, FR-017, Clarification 2 |
| 12 | Back from page / resume | Open the page → press Back / close the tab | App goes to the verification screen automatically | US6 sc. 2, R4 |
| 13 | Quote expiry | Fixture with 1-minute TTL → wait on the summary | Re-quote; changed rows highlighted; "Confirm new amounts" required | US6 sc. 4, FR-009 |
| 14 | Terms changed | Mock: change the terms hash before payment start | New terms shown; acceptance required again | US6 sc. 5, FR-018, AC-013 |
| 15 | Tampered return link | Open `…/payment/return?booking=<id>&status=success` while the server says failed | Failed outcome; link status ignored | FR-016 |
| 16 | My Bookings tabs | Guest seeded in every status | Tabs and order per data-model §5; `payment_pending` only in the banner; `abandoned` nowhere; countdown for awaiting owner | US3, FR-019, FR-020 |
| 17 | Details content | Open confirmed, awaiting, rejected, expired bookings | Status message per §7.2, payments, saved terms, timeline; instructions only when confirmed; only "contact support" as action | US3, US4, FR-021–FR-023, FR-027 |
| 18 | Refund stages | Conflict bookings at each refund stage | Stages shown separately from status; "Refunded" only at `verified` | FR-028, AC-042 |
| 19 | Offline and instructions | View a confirmed booking → airplane mode → reopen | Cached list and details with "Last updated"; instructions shown from secure storage; actions disabled | FR-024, FR-024a, SC-008 |
| 20 | Purge rules | Sign out; separately, cancel a confirmed booking on the server and refresh | Sign-out removes cache, attempt, and instructions; refresh removes that booking's instructions | FR-024a, R13 |
| 21 | Foreign booking | Open `/bookings/<other guest's id>` and `/bookings/not-a-uuid` | Neutral "Not available" in both | FR-025, SC-007 |
| 22 | Push and center | Grant permission → confirm the booking on the server with the app open, in background, and killed | Banner when open; tap opens the booking in the other cases (sign-in first if signed out); center lists it; bell count updates; "Mark all as read" clears it | US5, FR-031–FR-034, AC-024, SC-006 |
| 23 | Permission declined | Decline the permission prompt | Never asked again; center shows "Notifications are off" with a settings button | Clarification 5, FR-030 |
| 24 | Unknown notification type | Mock: insert a notification with an unknown type | Generic text; tap opens My Bookings | FR-033 |
| 25 | Themes, text size, readers | Repeat 4, 5, 16, 17 in Dark mode, at 1.3×, and with TalkBack / VoiceOver | No clipping; RTL order correct; controls announced; record in `docs/qa/g2-accessibility.md` | FR-038 |

## Automated checks

```bash
flutter test test/features/booking test/features/bookings test/features/notifications test/core test/app/router
```

```bash
flutter test integration_test/booking_journey_mock_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

```bash
flutter test integration_test/booking_payment_staging_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

```bash
flutter test integration_test/booking_outcomes_staging_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

```bash
flutter test integration_test/booking_isolation_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

- **Unit tests first:** attempt-key lifecycle, verification outcome table, polling backoff
  (`fake_async`), `QuoteChange`, action registry filtering, notification routing table,
  storage purge rules, error mapping for the new codes.
- **Staging tests** skip with a clear message in mock mode or when the deltas are missing.
- The Kashier steps in `booking_payment_staging_test` may need a tester to complete the test
  card page by hand until Kashier test automation is confirmed (Guest Plan §19.1).

## Done for G2 when

- Scenarios 1–25 pass on Staging.
- AC-014 to AC-024 (guest side) pass end to end on Staging (Guest Plan §17 G2).
- CI is green.
- The backend owner has deployed and confirmed D0–D4, and the Kashier return link is set.
