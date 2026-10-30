# Implementation Plan: Guest Discovery (G1)

**Branch**: `feature/002-guest-discovery` | **Date**: 2026-10-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-guest-discovery/spec.md`

## Summary

Replace the G0 Home and Search placeholders with the real discovery experience. It covers:

- a cached Home feed (areas, suggested, newest, upcoming booking);
- search with server-side full-stay availability, filters, sort, and cursor pagination;
- full apartment details: gallery, specs, public address (D-001), rules, deposit and
  cancellation policy, a pickable availability calendar, and approved reviews;
- visitor browsing that returns to the same apartment with the same dates and guests after
  sign-in;
- apartment and search sharing through verified links.

The app stays a display-and-request client:

- **Server decides:** availability, approval, final nightly price, stay totals, suggestion
  logic, result counts, and reviewer short names.
- **How the app reads:** all discovery data comes from Supabase RPCs with the `guest_` prefix
  (the shared registry's naming rule), callable by `anon` for visitors. Nothing reads a table
  directly.
- **What the app keeps:** only Home's public sections and the reference lists, as one small
  JSON cache on disk, plus the last search in preferences. Images are requested at the size
  they render from a disk-backed cache.
- **Booking hand-off:** "Book now" carries the shown terms version, dates, and guests to a G2
  entry route. That route is a localized placeholder until G2 ships.

Details: [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/),
[quickstart.md](quickstart.md).

## Technical Context

**Language/Version**: Dart 3.12.2, Flutter 3.44.3 (stable). SDK constraint `^3.12.2`.

**Primary Dependencies**: Existing G0 stack: `flutter_bloc`, `go_router`, `supabase_flutter`,
`dio`, `freezed` + `json_serializable`, `shared_preferences`, `intl`, `app_links`,
`connectivity_plus`. New, each reviewed in research R11:
- `cached_network_image`: disk-backed image cache, so Home photos show offline and on relaunch.
- `share_plus`: the system share sheet.
- `path_provider`: location of the on-disk Home cache file.

**Storage**:
- On-disk JSON file in the app support folder: Home public sections and reference lists, keyed
  by a schema version.
- `shared_preferences`: last search criteria (non-sensitive).
- Image disk cache.
- Nothing personal is persisted. The upcoming-booking card is never cached.
- Server: Supabase Postgres in the shared backend repository.

**Testing**:
- `flutter_test` (unit + widget), `bloc_test` (Cubits), `mocktail`.
- `alchemist` goldens: Light, Dark, RTL, 1.3× text.
- `integration_test`:
  - Staging discovery journey;
  - availability and approval checks against seed data;
  - results scroll performance with `traceAction`.

**Target Platform**: Android 7.0+ (API 24) and iOS 15+.

**Project Type**: Mobile app (single Flutter project at repository root).

**Performance Goals**:
- Cached Home visible within 1 s on relaunch (SC-004).
- Cold start to Home skeleton < 2.5 s (G0 target).
- 60 fps scrolling over 100+ results with no noticeable jank (SC-005).
- Details first photo shown immediately from the card's cached image (SC-006).
- Location suggestions debounced at ~350 ms.

**Constraints**:
- Server is the authority for availability, approval, prices, totals, and counts
  (Constitution II).
- No map and no coordinates; address shown as text only (D-001).
- Arabic RTL only.
- Text scale clamped at 1.3.
- Offline: banner, cached Home, server actions disabled.
- Every new backend name must be added to the shared registry by the backend owner before
  Remote mode depends on it.

**Scale/Scope**:
- **Screens (8):** Home, Search form, Filters sheet, Results, Apartment details, Gallery,
  Reviews list, plus 2 localized placeholders (booking entry, support entry).
- **Design-system components:** ~10 new.
- **Supabase RPCs (7):** `guest_home_feed`, `guest_search_properties`, `guest_get_property`,
  `guest_get_property_unavailable_dates`, `guest_list_property_reviews`,
  `guest_search_locations`, `guest_get_reference_data`.
- **Pilot catalogue:** hundreds of apartments.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | How G1 complies | Status |
|---|---|---|
| I. Master Plan fidelity & scope | Implements decisions 97–99 and Guest Plan §6.3–§6.5 only. No map, no favorites toggle (G5), no owner chat (AC-047), no fees, discounts, or VIP. The public address follows the recorded decision D-001 (§6.5 and §19.8 updated). Open items (suggestion logic §19.3, link domain §19.2, numerals §4.9, Cloudflare variants) stay server-driven or configurable. | PASS |
| II. Server is the authority | Availability filtering, approval, final nightly price, stay total, result count, suggestion order, reviewer short name, and terms version all come from RPCs. The app never filters, prices, or totals. Links and resume parameters are navigation hints; data is re-fetched and the terms version is re-checked before continuing. | PASS |
| III. Payment integrity | No payment in G1. "Book now" only navigates and carries `terms_version`, dates, and guests; it sends no amount. | PASS (N/A) |
| IV. Security & privacy | Only the anon key is used. RPCs are `security definer` with a fixed `search_path` and return only approved published versions. They never return owner contact details, base price, margin, or coordinates. An unknown and an unpublished ID give the same `NOT_FOUND`. Nothing personal is cached. The last search holds no personal data. Link IDs are UUID-validated and query parameters are whitelisted. Nothing is logged except IDs. | PASS |
| V. Design system | New components (property card, area card, range calendar, filter chips, skeletons, rating, price text, expandable text, bottom action bar, network image) live in `lib/design_system/` and take primitives only. Colors and text styles come from tokens; placeholders use Detail Card colors. | PASS |
| VI. Arabic-first, RTL & a11y | All copy is in `.arb`. The calendar uses directional layout and Arabic month names via `intl`. Gallery, share, close, and chip-remove controls have Semantics labels. Targets are 48×48. Goldens run at 1.3×. A TalkBack/VoiceOver pass covers search → details. | PASS |
| VII. Layered, feature-first | `features/listings` (shared models and repositories), `features/home`, `features/search`, `features/property`. Widgets talk to Cubits; Cubits talk to repository interfaces; Supabase and mock implementations are chosen in `bootstrap`. Money is int piasters. Stay dates use `DateOnly` / `StayRange`. New error codes go through `ErrorMapper`. | PASS |
| State management | Cubits per screen. `SearchCubit` is scoped to the Search branch, so results survive tab switches and details round-trips. `close()` cancels debouncers and drops stale responses. | PASS |
| VIII. UX states & performance | Per-section skeletons, empty, error with reference, and offline states. `SliverList` builders, cursor pages of 20, images sized by `width × devicePixelRatio` with `memCacheWidth`, lazy reviews and calendar, `RepaintBoundary` on the gallery, stale-while-revalidate Home. | PASS |
| IX. Test discipline | Test-first for `StayRange` (nights, overlap), `SearchCriteria` link codec and validation, image variant picking, resume protocol, and error mapping. Widget tests cover every screen state. Goldens for new components and screens. Staging tests cover AC-003 (unapproved never appears or opens) and AC-012 (booked, blocked, or held dates excluded). The mock follows the same contracts and fixtures. | PASS |
| Repository constraints | No cross-repo code. New RPC names are drafted in `contracts/` for the backend owner to add to `REGISTRY.md`. The store-fallback redirect is specified for the web/domain owner. | PASS |

No violations. Complexity Tracking is empty.

### Post-design re-check (after Phase 1)

The design artifacts (data model, three contracts, quickstart) keep every row above at PASS.
Points checked specifically:

- **Server authority (II)**: The contracts give the server every decision: availability
  (§2), approval (§0), price and totals (§1–§3), counts (`p_limit = 0`), suggestion order, and
  reviewer short names. `StayRange.nights` is display-only. `PolicySummary` shows the received
  values with fixed copy from Master Plan §7.2 and computes no amounts.
- **AC-013**: The resume protocol re-checks `terms_version` after sign-in and never forwards
  on a mismatch. Shared property links strip all query parameters, so they cannot trigger
  `resume`.
- **Privacy (IV)**: The upcoming-booking card is never written to disk. `address_text` is
  nullable, so the app does not depend on D-001 before the backend owner agrees. Coordinates
  exist nowhere in the model. The isolation and forbidden-field tests are listed in
  `supabase-discovery.md` §10.
- **Request cancellation (VIII)**: Supabase RPC calls are aborted where the client supports
  it. Otherwise, results that arrive after `close()` or after a newer request are dropped by
  sequence number (research R12). This meets the rule's purpose: no screen is updated by a
  stale or orphaned request. It is noted here, not treated as a violation.
- **Backend agreement (Workflow)**: The app depends on 5 new RPC names and the public address
  field only after the backend owner adds them to the registry. Until then, mock mode covers
  development and tests.

## Project Structure

### Documentation (this feature)

```text
specs/002-guest-discovery/
├── plan.md              # This file
├── research.md          # Phase 0: decisions + rationale
├── data-model.md        # Phase 1: entities, validation, state
├── quickstart.md        # Phase 1: setup + validation scenarios
├── contracts/           # Phase 1: draft backend + app contracts
│   ├── supabase-discovery.md   # guest_* RPCs, security, errors, isolation tests
│   ├── app-routes.md           # G1 routes, query params, resume protocol, share links
│   └── verified-links.md       # domain files + store fallback for the link domain owner
├── checklists/requirements.md
└── tasks.md             # Phase 2 ($speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── app/router/
│   ├── routes.dart                 # + /search/results child, /property/:id(/gallery|/reviews),
│   │                               #   /book/:propertyId/dates, /support/new
│   ├── link_parser.dart            # keep whitelisted query params for /search/results
│   └── app_router.dart             # real screens replace NotAvailable for property/search
├── core/
│   ├── time/stay_range.dart        # NEW: check-in/out DateOnly pair, nights, validation
│   ├── images/image_variants.dart  # NEW: pick smallest variant ≥ rendered px
│   ├── cache/json_file_cache.dart  # NEW: versioned JSON file cache (app support dir)
│   ├── share/share_service.dart    # NEW: interface over share_plus
│   └── errors/error_mapper.dart    # + NOT_FOUND → propertyNotAvailable
├── design_system/components/
│   ├── property_card.dart  area_card.dart  on_air_network_image.dart
│   ├── range_calendar.dart  filter_chip_bar.dart  skeletons.dart
│   ├── rating_badge.dart  price_text.dart  expandable_text.dart  bottom_action_bar.dart
│   └── counter_stepper.dart
├── features/
│   ├── listings/                   # shared data layer for home/search/property
│   │   ├── domain/   listing_image, listing_card, location_suggestion, reference_data,
│   │   │             results_page, property_details, approved_review, home_feed,
│   │   │             listings_repository (interface)
│   │   └── data/     supabase_listings_repository.dart, mock_listings_repository.dart,
│   │                 reference_data_cache.dart, fixtures/ (mock seed JSON)
│   ├── home/        data/home_feed_cache.dart
│   │                presentation/home_cubit.dart, home_screen.dart, widgets/
│   ├── search/      domain/search_criteria.dart (+ link codec), last_search_store.dart
│   │                presentation/search_cubit.dart, location_suggest_cubit.dart,
│   │                search_screen.dart, filters_sheet.dart, results_screen.dart
│   ├── property/    domain/policy_text.dart, resume_intent.dart
│   │                presentation/property_cubit.dart, availability_cubit.dart,
│   │                reviews_cubit.dart, property_screen.dart, gallery_screen.dart,
│   │                reviews_screen.dart, widgets/
│   ├── booking/presentation/booking_entry_placeholder_screen.dart   # G2 fills
│   └── support/presentation/support_entry_placeholder_screen.dart   # G4 fills
└── l10n/app_ar.arb, app_en.arb     # + discovery strings

test/                               # mirrors lib/ (unit, widget, goldens)
integration_test/
├── discovery_journey_test.dart     # Staging: search → details → Book now → sign-in → resume
├── discovery_rules_test.dart       # AC-003, AC-012 against Staging seed
└── results_scroll_perf_test.dart   # traceAction over 100+ results (mock)
contracts/                          # root drafts handed to backend (copied from specs/002/contracts)
```

**Structure Decision**: This is a single Flutter project, extended in place, so it keeps G0's
layout. Discovery models and repositories live once in `features/listings`, because Home,
Search, and Property all use the same cards, images, and reference lists; screens stay in their
own feature folders. Design-system components take only primitives, so the design system never
imports feature code (Constitution VII).

## Complexity Tracking

No constitution violations to justify.
