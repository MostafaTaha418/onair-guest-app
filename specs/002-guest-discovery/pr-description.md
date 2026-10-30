# PR: Guest Discovery (G1) — US1–US5

**Branch:** `feature/002-guest-discovery` → `develop`
**Spec:** [spec.md](spec.md) · **Plan:** [plan.md](plan.md) · **Tasks:** [tasks.md](tasks.md) (T001–T109)

## Summary

Implements the discovery milestone: the Home tab with a cached feed and
independently failing sections, the Search tab (location suggestions, date sheet,
guests, filters sheet with debounced result counts, sort), server-filtered results
with cursor pagination and kept scroll position, the full property details screen
(gallery, specs, description, amenities, address, rules, deposit policy, availability
calendar, reviews), the visitor resume flow (sign-in returns to the same apartment
with the same dates, guests, and shown terms), and sharing of property and search
links through a verified link domain.

Everything is built and green in **mock mode**; remote mode is wired behind the
same `ListingsRepository` interface and waits on the backend dependencies below.

## Definition of Done (Constitution → Development Workflow)

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | Matches the Master Plan with no invented rules | ✅ | Deposit rules follow Master Plan §7.2 (`test/features/property/policy_text_test.dart`); availability filter per AC-012 (`test/features/listings/mock_listings_repository_test.dart` (b), `integration_test/discovery_rules_test.dart`); no client-side totals — the nightly price and stay total come from the server (`test/features/listings/listings_json_test.dart`) |
| 2 | All UX states implemented | ✅ | Per-screen state tables (loading/empty/failed/offline/not-available) covered in `test/features/home/home_screen_test.dart`, `test/features/search/results_screen_test.dart`, `test/features/search/search_screen_test.dart`, `test/features/property/property_screen_test.dart`, `test/features/property/gallery_and_reviews_test.dart` |
| 3 | Light, Dark, RTL, and large text work | ✅ | Goldens run every component/screen in Light/Dark × RTL × 1.0/1.3 (`test/design_system/goldens/discovery_components_golden_test.dart`, `test/features/search/goldens/search_goldens_test.dart`, `test/features/home/goldens/home_goldens_test.dart`, `test/features/property/goldens/property_goldens_test.dart`); text scale clamped at the app root (G0 T039) |
| 4 | No hard-coded colors, font sizes, or UI strings | ✅ | `tool/check_hardcoded_styles.sh` clean (T103, exit 0); every visible string comes from `.arb` (Appendix A keys); new styles added as tokens only (`on_air_text_styles.dart`) |
| 5 | No client-side money/status/permission decisions | ✅ | Money is int-piaster `Money` everywhere; the app never multiplies price × nights — totals arrive from the server (`test/features/listings/listings_json_test.dart`); statuses map through `ErrorMapper` (`test/core/errors/error_mapper_test.dart`, `error_message_test.dart`) |
| 6 | Sensitive actions are idempotent and double-tap safe | ✅ | G1 adds no state-changing network action (discovery is read-only); navigation is push/replace based and the resume intent is consumed once (`test/features/property/property_resume_test.dart`) |
| 7 | No PII in logs or crash reports | ✅ | `AppLogger` carries IDs only; `LinkParser` never logs; the share text contains only the apartment title and the public link (`test/core/share/share_service_test.dart`); search criteria in links hold no personal data (Assumptions) |
| 8 | Required tests pass and linked ACs are tested | ✅ | 455 tests green; AC-003 (`discovery_rules_test.dart`, `mock_listings_repository_test.dart` (a)(c)), AC-010 (`property_screen_test.dart`), AC-012 (same files, (b)/(i) + Staging integration), AC-013 (`property_resume_test.dart`), AC-047 (`property_screen_test.dart`); remote-only AC checks (T061/T079/T095) skip with a printed reason until Staging |
| 9 | Interactive elements have semantics | ✅ | Static a11y pass in [docs/qa/g1-accessibility.md](../../docs/qa/g1-accessibility.md): every icon-only control has tooltip + `Semantics`, touch targets ≥ 48, calendar day semantics, chip-remove labels with the filter name; TalkBack/VoiceOver runs left for the tester (scenario 17) |
| 10 | No noticeable jank in Profile mode | ⏳ | Scroll-perf harness ready: `integration_test/results_scroll_perf_test.dart` + `test_driver/perf_driver.dart` write `build/perf/results_scroll_timeline_summary.json`; numbers pending the device run (`docs/perf/g1-results-scroll.md`) |
| 11 | PR reviewed | ⏳ | Not yet — awaiting reviewer assignment |
| 12 | Plan/decision docs updated when an open point is resolved | ✅ | `docs/OnAir Guest App Plan.md` §17 G1 ticked with a status note (T107); D-001 handled as text-only address, no coordinates (D-001 decision); fixtures/clock decisions recorded in `research.md` items |

## Gates (T108)

| Gate | Result |
|---|---|
| `dart format --set-exit-if-changed .` | ✅ |
| `flutter analyze` | ✅ zero issues |
| `flutter test` | ✅ 455 passed |
| `flutter test --tags golden` | ✅ 53 passed (8 regenerated for the share buttons) |
| `bash tool/check_hardcoded_styles.sh` | ✅ |

Quickstart scenarios 1–16 in mock mode on an Android emulator: pending the manual
device walk (the CI device job covers the automated part; any scenario that cannot
run in mock mode will be noted there).

## Still open (external)

**Backend (`onair-backend` registry)** — Remote mode needs these 7 RPCs deployed and
reviewed per `contracts/supabase-discovery.md`:

1. `guest_home_feed`
2. `guest_search_properties`
3. `guest_get_property`
4. `guest_get_property_unavailable_dates`
5. `guest_list_property_reviews`
6. `guest_search_locations`
7. `guest_get_reference_data`

Plus the Staging seed (Appendix B equivalent) and the D-001 `address_text` field in
the public property payload.

**Link domain (`contracts/verified-links.md`)** — the domain itself, its
`assetlinks.json` / AASA association files, and the store-listing fallback for
devices without the app.

**Device runs** — quickstart 1–16 walk, TalkBack/VoiceOver pass (scenario 17),
scroll-perf numbers, and the cold-start follow-up from `docs/perf/g0-baseline.md`.
