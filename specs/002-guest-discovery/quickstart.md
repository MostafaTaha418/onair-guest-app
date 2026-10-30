# Quickstart: Guest Discovery (G1)

How to run and check G1. Setup is the same as G0
([G0 quickstart](../001-guest-app-foundation/quickstart.md)). Contracts are in
[contracts/](contracts/), and entities and rules are in [data-model.md](data-model.md).

## Prerequisites

- G0 is merged into `develop`. This work is on `feature/002-guest-discovery`.
- `env/staging.json` exists, holding public values only.
- **Mock mode** (`"BACKEND_MODE": "mock"`) works today with the fixtures in
  `lib/features/listings/data/fixtures/`.
- **Remote mode** needs:
  - the 7 `guest_*` RPCs deployed to Staging and added to the registry;
  - the Staging seed ([supabase-discovery.md §11](contracts/supabase-discovery.md)).

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

Run each scenario in mock mode first, then on Staging once the RPCs exist. "Expected" is what
proves the scenario passes.

| # | Scenario | Steps | Expected | Covers |
|---|---|---|---|---|
| 1 | Home loads and caches | Fresh install → open app | Section skeletons, then areas, suggested, and newest. Kill the app, turn on airplane mode, reopen: Home content shows within 1 s with the offline banner | US3, FR-001–FR-005, SC-004 |
| 2 | Section failure is isolated | Mock: make `suggested` fail | Only that section shows an error with "Try again"; the others work | FR-004 |
| 3 | Search without location | Search → set guests only → Search | Results from all areas; nightly price only; hint that dates are needed to book | Clarification 1, FR-009 |
| 4 | Full-stay availability | Search the dates of the fixture apartment that is booked on 1 night, on hold on 1 night, and blocked on 1 night | That apartment never appears. It does appear for the neighbouring free range | AC-012, SC-002 |
| 5 | Unapproved stays hidden | Search and Home with fixtures for draft, paused, rejected, and unapproved-workspace apartments; open their IDs via `/property/<id>` | Never listed. Opening any of them gives the neutral "not available" screen, the same as a random UUID | AC-003, SC-003 |
| 6 | Filters and count | Open the filters sheet, change price, bedrooms, and an amenity | "Show X results" updates after a short pause. Confirm → chips appear above the results; removing a chip refreshes them | FR-011, FR-015 |
| 7 | Pagination and state kept | Scroll results past 40 items → open an apartment → Back → switch tab → return | More items load automatically. Same list, filters, and scroll position, with no new request | FR-015, FR-016 |
| 8 | Details content | Open the deposit-percent fixture apartment | Gallery with indicator and zoom. Specs. Public address text. Rules. Policy sentences (deposit %, free cancellation hours, deposit-only loss after). Final nightly price. No owner contact. "Contact OnAir" only | US2, FR-018–FR-021, FR-024, AC-010, AC-047 |
| 9 | Calendar pick | On details, pick a range crossing an unavailable night, then a valid range | Invalid range rejected with a message. Valid range replaces the search dates in the bottom bar | Clarification 3, FR-022 |
| 10 | Visitor resume | Signed out: search with dates and guests → details → "Book now" → sign in | Back on the same apartment, then forwarded to the booking-entry placeholder showing the same dates, guests, and terms version | US4, FR-029, SC-007 |
| 11 | Terms changed during sign-in | Mock: bump the apartment's `terms_version` while on the sign-in screen, then sign in | Stays on details with the "terms updated" notice; no automatic forward | AC-013, R10 |
| 12 | Cancel sign-in | Signed out: "Book now" → cancel | Same apartment, same dates and guests, still a visitor | FR-029 |
| 13 | Share and open | Share an apartment and a search; open both links on a second device (`adb shell am start -a android.intent.action.VIEW -d "<url>"`) | Correct screens open. A link with past dates opens the search and asks for new dates | US5, FR-030–FR-031 |
| 14 | Bad links | Open `/property/not-a-uuid` and `/property/<random uuid>` links | Neutral "not available" in both cases | FR-031 |
| 15 | Offline details | Airplane mode → open an apartment not yet viewed; separately, go offline while on an open page | New page: offline state with retry. Open page: stays visible; "Book now" disabled | Clarification 5, FR-032 |
| 16 | Themes and text size | Repeat scenarios 1, 7, 8 in Dark mode and at 1.3× text | No clipping or overflow; RTL order correct | FR-035, SC-009 |
| 17 | Screen readers | TalkBack and VoiceOver: search → results → details | Every control announced; record the results in `docs/qa/g1-accessibility.md` | FR-036, SC-010 |

## Automated checks

```bash
flutter test test/core/time test/features/search test/features/property test/app/router
```

```bash
flutter test integration_test/discovery_journey_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

```bash
flutter test integration_test/discovery_rules_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

```bash
flutter drive --driver=test_driver/perf_driver.dart --target=integration_test/results_scroll_perf_test.dart --profile --flavor staging --dart-define-from-file=env/staging.json
```

- **Unit and widget tests:** `StayRange`, `SearchCriteria` codec, `ImageVariants`, the resume
  intent, error mapping, the router, and every screen state.
- **`discovery_rules_test`:** requires remote mode and the Staging seed. It skips with a clear
  message in mock mode.
- **Perf test:** needs a real mid-range Android device. `test_driver/perf_driver.dart` is new
  in G1 (it writes the `traceAction` timeline summary). Record the frame timings in
  `docs/perf/g1-results-scroll.md`.

## Done for G1 when

- Scenarios 1–17 pass on Staging.
- CI is green.
- The backend owner has confirmed the 7 RPCs in the registry and the address field (D-001).
- The link domain owner has confirmed the store fallback ([verified-links.md](contracts/verified-links.md)).
