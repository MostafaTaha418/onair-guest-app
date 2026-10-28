# Research: Guest Discovery (G1)

Phase 0 output. Each decision records what was chosen, why, and what else was considered.
The Technical Context had no open `NEEDS CLARIFICATION` items; the topics below are the design
choices that needed a decision before Phase 1.

## R1. How discovery data is read

- **Decision**: Every discovery read goes through a Supabase RPC with the `guest_` prefix:
  - `guest_home_feed`
  - `guest_search_properties`
  - `guest_get_property`
  - `guest_get_property_unavailable_dates`
  - `guest_list_property_reviews`
  - `guest_search_locations`
  - `guest_get_reference_data`

  Each is `security definer`, uses a fixed `search_path`, and is granted to `anon` and
  `authenticated`. The app never reads `properties`, `property_versions`, or
  `property_reviews` directly.
- **Rationale**:
  - The shared registry (`docs/shared-backend/REGISTRY.md`) is the naming authority. It marks
    `property_versions` and its media/amenities as **F** for the guest (read only through a
    function). It also requires every public function to start with an app prefix.
    `guest_search_properties` and `guest_get_property` are already planned there.
  - Functions can join the published version, the final price, and the policy summary, and
    leave out owner data, base price, margin, and coordinates. A view cannot easily hide those
    per column for `anon`.
- **Alternatives considered**:
  - The Guest Plan §10.1 conceptual names (`published_properties_view`, `home_feed`, …): the
    registry overrides them. The plan rows stay as concepts.
  - A Node endpoint: no secrets are involved, so it would only add latency. The plan
    reserves Node for sensitive commands.
- **Follow-up**: Five of the seven names are new to the registry
  (`guest_home_feed`, `guest_get_property_unavailable_dates`, `guest_list_property_reviews`,
  `guest_search_locations`, `guest_get_reference_data`). The backend owner adds them through a
  registry PR ([contracts/supabase-discovery.md](contracts/supabase-discovery.md)).

## R2. Full-stay availability

- **Decision**: `guest_search_properties` excludes an apartment when any night in
  `[check_in, check_out)` overlaps one of:
  - an active `booking_date_locks` row (hold or confirmed, `released_at is null`);
  - a `property_blocks` range.

  `guest_get_property_unavailable_dates` returns the same nights for a window, as date-only
  values with no reason. The app does no availability filtering.
- **Rationale**:
  - AC-012 and Guest Plan §6.4.3 say this filter runs on the server.
  - Using the same half-open `daterange` (`[)`) as the registry's exclusion constraint makes
    search and booking agree on what a night is.
- **Alternatives considered**: Client-side filtering after fetch. It is forbidden by the plan,
  and it breaks pagination counts.

## R3. Nights, dates, and calendar selection

- **Decision**:
  - A new `StayRange` value object in `lib/core/time/` holds `checkIn` and `checkOut` as
    `DateOnly`, with `nights = checkOut − checkIn` (at least 1).
  - The past is judged against "today" in `Africa/Cairo` (G0 `CairoTime`).
  - A calendar range is valid when every **night** `checkIn … checkOut−1` is available. So the
    departure day may be a day that is unavailable as a night, which is the next guest's
    arrival day.
  - The device never computes money from `nights`. `nights` is only for the label and for
    validation.
- **Rationale**: Date-only values prevent midnight and time-zone bugs (Guest Plan §10.4).
  Treating a stay as nights matches the server's half-open ranges.
- **Alternatives considered**: `DateTimeRange` from Flutter. It carries time and zone, which
  the constitution forbids for stay dates.

## R4. Pagination and the "Show X results" count

- **Decision**:
  - Keyset pagination with an opaque `next_cursor` string and pages of 20.
  - `guest_search_properties` returns `{items, next_cursor, total_count}`.
  - The filters sheet asks for the count with `p_limit = 0` (count only), debounced at ~400 ms
    while the guest edits, with stale answers dropped.
- **Rationale**:
  - The cursor stays stable while new listings are published (Guest Plan §12.3).
  - One function for list and count keeps the filter rules in one place.
- **Alternatives considered**:
  - Offset pagination: it duplicates or skips rows when data changes.
  - A separate count function: two copies of the filter logic.

## R5. Prices and totals

- **Decision**:
  - Cards and details carry `nightly_price_minor` (final, base + OnAir margin, from the
    server's pricing function) and `currency`.
  - When dates are sent, cards also carry `nights` and `stay_total_minor` from the server.
  - The app wraps every amount in `Money` and formats it with `MoneyFormatter`.
  - Details show no total. The quote is G2.
- **Rationale**: AC-010 and Constitution II. Integer piasters only.
- **Alternatives considered**: Multiplying nightly × nights on the device. It is forbidden,
  and it would drift from the server if rounding or policies change.

## R6. Home cache (stale-while-revalidate)

- **Decision**:
  - `JsonFileCache` writes one versioned JSON document to the app support folder
    (`path_provider`).
  - It holds Home's public sections (areas with counts, suggested, newest) and the reference
    lists.
  - On open, Home shows the cached document at once (SC-004), then calls `guest_home_feed`
    and replaces sections as they arrive.
  - The `upcoming_booking` part is personal, so it is **never written to disk**. It is
    fetched fresh for signed-in guests and dropped on sign-out.
  - Cache schema changes bump the file's `schema` number; a mismatch discards the file.
- **Rationale**:
  - The constitution allows only non-sensitive local storage and requires sign-out to clear
    personal caches. Keeping personal data out of the cache satisfies both.
  - A file avoids loading a large JSON string into preferences on every launch.
- **Alternatives considered**:
  - `shared_preferences` string: works, but the whole preferences store is read at start.
  - A local database: too heavy for one document.
- **Section independence**: `guest_home_feed` returns all sections in one call (Guest Plan
  §6.3 performance note). It reports per-section `error` markers instead of failing the
  whole call, so the app can show a per-section error with retry (FR-004). A section retry
  calls the feed again and replaces only that section.

## R7. Reference lists (locations, amenities, property types, price bounds)

- **Decision**:
  - `guest_get_reference_data` returns amenities, property types (enum keys with Arabic and
    English labels), the nightly price bounds, a slider step, and a `version`.
  - `guest_home_feed` also returns the current `reference_version`. When it differs from the
    cached one, the app refetches the reference data.
  - Locations are **not** downloaded whole. `guest_search_locations(query)` returns matches
    with Arabic-normalised search (أ/إ/آ→ا، ة→ه، ى→ي) and the number of published apartments.
- **Rationale**:
  - FR-008 asks for a long cache refreshed by server version.
  - A location tree can grow large, and Arabic normalisation belongs in one place (the
    server).
- **Alternatives considered**:
  - Reading `locations` directly (the registry allows **R**): no normalisation and no
    published counts.
  - Hard-coded property-type labels: they would drift from the registry list, which is still
    to be confirmed in phase zero.
- **Slider step**: the server provides `price_step_minor`. If it is missing, the app falls
  back to 5,000 piasters (50 EGP). That fallback is a UI choice and can be changed in one
  place.

## R8. Images

- **Decision**:
  - The server returns each photo as a list of variants `{width, url}`, plus an optional
    `blurhash`.
  - `ImageVariants.pick(renderedWidth × devicePixelRatio)` chooses the smallest variant at
    least that wide, or the largest when none is.
  - `OnAirNetworkImage` wraps `cached_network_image`. It sets `memCacheWidth`, shows a Detail
    Card colored placeholder, and has a broken-image fallback.
  - Only the next gallery photo is prefetched.
- **Rationale**:
  - How Cloudflare produces sizes is still open (Guest Plan §12.2). A variant list keeps that
    choice on the server side, while the app still never downloads a 4000 px image for a
    160 px card.
  - The disk cache lets Home and the Hero photo appear offline and on relaunch.
- **Alternatives considered**:
  - The app building Cloudflare resize URLs: it ties the app to an undecided CDN setup.
  - `Image.network` only: memory cache only, so photos would be lost on relaunch.

## R9. Navigation shape

- **Decision**:
  - `/search/results` is a child route of `/search` inside the Search branch, so results stay
    on that tab's stack and keep their scroll position.
  - `/property/:id`, `/property/:id/gallery`, and `/property/:id/reviews` are top-level routes
    pushed over the shell. They are full screen with their own bottom bar. Back returns to
    whichever tab opened them, with its state intact.
  - `SearchCubit` is provided at the Search branch level. A `PropertyCubit` is created per
    details route.
  - The card's photo variant URL travels in `GoRouterState.extra` for the Hero image. If it
    is absent (deep link), the details simply load normally.
- **Rationale**:
  - The route table in Guest Plan §5.3 defines `/property/:id` as top level.
  - Branch scoping satisfies FR-016 without global state.
- **Alternatives considered**: Nesting details under each branch (`/home/property/:id`,
  `/search/property/:id`): duplicate routes, and the link paths stop matching §5.3.

## R10. "Book now", "Contact OnAir", and returning after sign-in

- **Decision** (resume protocol, full detail in [contracts/app-routes.md](contracts/app-routes.md)):
  - **Signed-in guest, "Book now"**: go to
    `/book/:propertyId/dates?checkIn=&checkOut=&guests=&terms=<terms_version>`. This is the G2
    entry; until G2 it is a localized placeholder that shows the carried values.
  - **Visitor, "Book now"**: go to sign-in with
    `from=/property/:id?checkIn=&checkOut=&guests=&resume=book&terms=<shown version>`.
  - **After sign-in or sign-up**:
    1. The details screen loads the apartment again.
    2. It removes `resume` from the location, so Back does not trigger it again.
    3. If the freshly loaded `terms_version` equals `terms`, it continues to the booking
       entry. If not, it stays on the page and shows "The terms were updated, please review
       them" (AC-013 safety).
  - **Cancelling sign-in**: returns to the same `/property/...` location. G0's
    `resolveAuthCancelDestination` already allows it, because the route does not require an
    account.
  - **"Contact OnAir"**: uses the same mechanism with `resume=contact`, to
    `/support/new?property=<id>`. That route needs an account; it is a placeholder until G4.
- **Rationale**:
  - G0's redirect already keeps a validated `from` location with its query.
  - Encoding the choices in the URL keeps them across process death and needs no extra
    state store.
  - Re-checking the terms version prevents a guest from "accepting" terms they never saw.
- **Alternatives considered**:
  - Sending visitors straight to `/book/...`: the guard would bounce them, but cancelling
    would land on Home, which breaks FR-029.
  - Keeping pending actions in memory: lost if the OS kills the app during sign-up.

## R11. New dependencies (Constitution VII review)

| Package | Why | Size/health notes | Decision |
|---|---|---|---|
| `cached_network_image` | Disk image cache, placeholders, `memCacheWidth` | Widely used, maintained. Pulls `flutter_cache_manager` (+ `sqflite`, `path_provider`); adds roughly a few hundred KB per ABI, to be measured | Adopt; measure the APK delta in the size check |
| `share_plus` | Native share sheet on Android/iOS | Flutter Community Plus, maintained, small | Adopt behind a `ShareService` interface |
| `path_provider` | App support folder for the Home cache | Official Flutter package, already transitive | Adopt as a direct dependency |
| `table_calendar` / `syncfusion` calendars | Range calendar | Extra weight; RTL and Arabic styling would fight the design system | **Reject**. Build `RangeCalendar` in the design system (month grid, directional, `intl` month names) |
| `shimmer` | Skeleton animation | Unneeded; one small animated widget does it | **Reject** |

Exact versions are the latest stable at implementation start, locked by `pubspec.lock`.

## R12. Location suggestions and stale responses

- **Decision**:
  - `LocationSuggestCubit` debounces input at ~350 ms (Guest Plan §6.4.4).
  - Each request gets an increasing sequence number, and a response whose number is not the
    latest is dropped. The underlying request is also aborted where the client supports it.
  - Queries of fewer than 2 characters show recent and popular areas from the Home cache
    instead of calling the server.
- **Rationale**: The PostgREST client cannot always cancel an in-flight call. Dropping by
  sequence guarantees an older list never replaces a newer one (spec US1, scenario 1).
- **Alternatives considered**: Bloc events with `restartable()` from `bloc_concurrency`. That
  means a new package and a move away from the Cubit-only convention for one screen.

## R13. Search criteria in links and in the last search

- **Decision**:
  - `SearchCriteria` has one strict codec used for three things: the shared link, the
    `/search/results` location, and the stored last search.
  - Parameters: `loc` (UUID), `in`, `out` (YYYY-MM-DD), `g` (1–50), `pmin`, `pmax`
    (piasters), `bed`, `bath` (0–20), `am` (comma-separated amenity keys), `type` (comma
    keys), `sort` (`price_asc` | `price_desc` | `newest`).
  - Unknown keys are dropped.
  - Invalid values drop only that field.
  - Past or inverted dates drop both dates, and the screen asks for new dates (US5,
    scenario 5).
  - `LinkParser` is extended to keep only these keys for `/search/results`. All other link
    queries are still discarded.
- **Rationale**: One codec means a shared link, Back navigation, and the reopened Search all
  agree. Whitelisting keeps links as navigation hints only (Constitution II).
- **Alternatives considered**: Base64-encoded JSON in one parameter. It is unreadable,
  harder to validate, and harder to debug.

## R14. Sharing and devices without the app

- **Decision**:
  - Share text is the localized apartment name, or "Search on OnAir", plus
    `https://<LINK_DOMAIN>/property/<id>` or `https://<LINK_DOMAIN>/search/results?<codec>`.
  - On devices without the app, the link domain serves a redirect to the store page for
    the device (clarification 2026-10-28).
  - That redirect, `assetlinks.json`, and `apple-app-site-association` are served outside
    this repository. Their requirements are in
    [contracts/verified-links.md](contracts/verified-links.md).
- **Rationale**: This keeps G1 inside the app repository. It also reuses G0's configurable
  `LINK_DOMAIN`, since the domain itself is still open (§19.2).
- **Alternatives considered**: A web preview page. It was declined in clarification.

## R15. Errors and the "not available" screen

- **Decision**:
  - Add `NOT_FOUND`, a shared registry code, to `ErrorMapper`, mapped to the existing
    `propertyNotAvailable` key.
  - `guest_get_property` returns `NOT_FOUND` for unknown, unpublished, paused, archived, or
    rejected apartments alike. The app then shows the G0 `NotAvailableScreen`.
  - Invalid filters or cursors give `VALIDATION_FAILED`. The app resets to the first page and
    shows the generic error with retry.
  - Unknown codes become `INTERNAL`, shown with a reference number (G0 behaviour).
- **Rationale**: One response for "does not exist" and "not public" prevents existence leaks
  (AC-003, Guest Plan §5.3).

## R16. Address, rating, and reviewer names

- **Decision**:
  - `address_text` is returned for published apartments (D-001). It is nullable, and the app
    hides the row when it is null, so the screen still works if the backend has not added it.
  - `rating_avg` (numeric, one decimal) and `review_count` count approved reviews only. When
    `review_count = 0`, `rating_avg` is null and no number is shown.
  - Reviewer names are shortened on the server ("أحمد م."). The app never receives full
    names.
- **Rationale**: Privacy first. The server is the one place that applies the rules.

## R17. Offline behaviour

- **Decision**:
  - G0's `ConnectivityCubit` drives the banner.
  - Home renders the cache.
  - Screens already showing data keep it.
  - Search, load-more, location suggestions, "Book now", and "Contact OnAir" are disabled
    while offline.
  - Opening a new apartment offline shows the offline state with retry.
  - Nothing else is persisted (clarification 2026-10-28).
- **Rationale**: Matches FR-032 and Guest Plan §13 with the smallest storage footprint.

## R18. Mock backend and fixtures

- **Decision**:
  - `MockListingsRepository` implements the same interfaces from JSON fixtures in
    `features/listings/data/fixtures/`. The fixtures include:
    - approved, unapproved, and paused apartments;
    - booked, blocked, and on-hold date ranges;
    - deposit and full-payment policies;
    - apartments with and without reviews and addresses;
    - 120 generic apartments for scroll tests.
  - The mock applies the same availability rule as R2, so widget and journey tests behave
    like Staging.
  - Contract tests parse the fixtures with the same models the Supabase repository uses.
- **Rationale**: Guest Plan §2.6 and §14.3: build screens before the tables exist, and keep
  the mock honest to the contract.
- **Alternatives considered**: A local HTTP mock server. Supabase RPC calls would need a
  PostgREST emulator; the in-process mock is simpler and matches G0's `BACKEND_MODE=mock`.

## R19. Measuring the success criteria

| SC | How it is measured |
|---|---|
| SC-001 | Moderated usability check, timed from launch to details of an available apartment |
| SC-002, SC-003 | `integration_test/discovery_rules_test.dart` against the Staging seed (plus the same cases in the mock) |
| SC-004 | Widget test with a pre-filled cache and no network; manual Profile-mode check on a mid-range Android |
| SC-005 | `results_scroll_perf_test.dart` with `traceAction`; frame build/raster times tracked in CI artifacts |
| SC-006 | Widget test: the details Hero uses the card's cached URL before the larger variant loads |
| SC-007 | Router/redirect unit tests + `discovery_journey_test.dart` |
| SC-008 | Widget test asserting no owner contact fields; review of RPC column lists |
| SC-009 | Goldens (Light, Dark, RTL, 1.3×) + state widget tests per screen |
| SC-010 | Manual TalkBack and VoiceOver pass recorded in `docs/qa/` |
| SC-011 | Usability check script with three comprehension questions |
