# G2 Quickstart Results (mock mode)

Run of `specs/003-guest-booking-payment/quickstart.md` scenarios 1–25 against the mock
backend, recorded 2026-10-31. Automated = covered by the green test suite
(`flutter test` + `flutter test --tags golden`, 737 tests, see the gates at the bottom).
Device = needs a real device/emulator run and stays open with the Staging work.

| # | Scenario | Result | Evidence |
|---|---|---|---|
| 1 | Verify before booking | Pass (automated) | `test/features/booking/presentation/verify_identity_{cubit,screen}_test.dart` — unverified guest is stopped, wrong/used numbers refused, correct code returns to the date step |
| 2 | Date step rules | Pass (automated) | `dates_screen_test.dart` — past/unavailable days disabled, range rules, guest cap, nights update |
| 3 | Quote refused | Pass (automated) | `booking_flow_cubit_test.dart` — DATES_UNAVAILABLE refreshes availability, GUESTS_EXCEEDED does not |
| 4 | Summary values | Pass (automated) | `summary_screen_test.dart` — every amount equals the fixture quote; remaining + due date only for deposit |
| 5 | Pay and succeed | Pass (automated) | `test/features/journey/booking_journey_test.dart` (step 2) + `payment_return_screen_test.dart`; the push-permission sheet appears once (`push_permission_coordinator_test.dart`) |
| 6 | Return is not confirmation | Pass (automated) | `payment_verification_cubit_test.dart` + `verification_outcome` tests — the outcome comes only from the server, the link never confirms |
| 7 | Failure and retry | Pass (automated) | Journey step 3 («Fail» → «Try again» → same stay) + `payment_attempt_cubit_test.dart` (a new attempt gets a fresh key) |
| 8 | Conflict | Pass (automated) | `payment_return_screen_test.dart` (conflict view) + `refund_display_test.dart` (cancelled tab, refund chip) |
| 9 | Timeout | Pass (automated, shortened backoff) | Journey step 4 («Never answer» → timeout → My Bookings under Current); the real ≈2 min wait needs a device run |
| 10 | Double tap and network retry | Pass (automated) | Double tap: `summary_interruptions_test.dart` + `payment_attempt_cubit_test.dart` (one session per key). Network flip mid-payment stays for the device run (real connectivity) |
| 11 | App killed mid-payment | Pass (automated, simulated restart) | Journey step 5 — the app rebuilds on the same store and the unfinished banner shows on Home; a real process kill needs the device run |
| 12 | Back from page / resume | Partial | `payment_attempt_cubit_test.dart` covers `restore()`; the reopen-page button and the resume routing (`_onResume`) need the device run (real app lifecycle) |
| 13 | Quote expiry | Pass (automated) | `booking_flow_interruptions_test.dart` — refresh 30 s before expiry, changed rows parked until confirmed |
| 14 | Terms changed | Pass (automated) | `booking_flow_interruptions_test.dart` + `summary_interruptions_test.dart` — new terms shown, acceptance required, re-quote |
| 15 | Tampered return link | Pass (automated) | `payment_return_screen_test.dart` — link query parameters other than `booking` are ignored |
| 16 | My Bookings tabs | Pass (automated) | `bookings_{cubit,screen}_test.dart` + `bookings_goldens_test.dart` — tabs/order per data-model §5, `payment_pending` only in the banner, `abandoned` nowhere |
| 17 | Details content | Pass (automated) | `booking_details_{cubit,screen}_test.dart` + goldens — status messages, payments, timeline, instructions only when confirmed |
| 18 | Refund stages | Pass (automated) | `refund_display_test.dart` — stages separate from status, «Refunded» only at `verified` |
| 19 | Offline and instructions | Pass (automated) | US3 cache tests — cached list/details with «Last updated», instructions from secure storage, actions disabled offline |
| 20 | Purge rules | Pass (automated) | `sign_out_service_test.dart` + arrival-instructions purge tests |
| 21 | Foreign booking | Pass (automated, mock) | `booking_details_screen_test.dart` — neutral «Not available» for a foreign id and a non-uuid; the Staging run is `integration_test/booking_isolation_test.dart` (skips until the seed exists) |
| 22 | Push and center | Pass (automated, mock source) | `notifications_{cubit,screen}_test.dart`, `in_app_banner_test.dart`, `notification_router_test.dart`, `unread_count_cubit_test.dart` — banner when open, tap opens the booking, count updates, «Mark all as read»; real FCM needs the device run |
| 23 | Permission declined | Pass (automated) | `push_permission_coordinator_test.dart` — never asked again, the center shows the off notice with settings |
| 24 | Unknown notification type | Pass (automated) | `notification_texts_test.dart` — generic text, tap opens My Bookings |
| 25 | Themes, text size, readers | Pass (goldens) / pending (readers) | Every G2 golden renders Light/Dark × 1.0/1.3 (booking dates, summary plain + re-priced, return in five states, notification center); TalkBack/VoiceOver results are recorded in `docs/qa/g2-accessibility.md` (device runs open) |

## Gates at record time (2026-10-31)

- `dart format --set-exit-if-changed .` — clean
- `flutter analyze` — no issues
- `flutter test` — 737 passed, 0 failed
- `flutter test --tags golden` — 113 passed, 0 failed
- `bash tool/check_hardcoded_styles.sh` — clean

## Still open (device/Staging, same list as the plan §17 note)

- Scenarios 5/9/10/11/12/22 on a real device with the real lifecycle and FCM.
- The Kashier round trip (`booking_payment_staging_test.dart`), the seeded outcomes
  (`booking_outcomes_staging_test.dart`) and the isolation run
  (`booking_isolation_test.dart`) once the contract deltas D0–D4, the Kashier test
  account, and the Staging seed exist.
