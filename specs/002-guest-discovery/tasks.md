---

description: "Task list for Guest Discovery (G1)"
---

# Tasks: Guest Discovery (G1)

**Input**: Design documents from `specs/002-guest-discovery/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. Constitution IX requires:
- test-first for `StayRange`, `SearchCriteria`, `ImageVariants`, `ResumeIntent`, error mapping,
  and router rules;
- widget tests for every screen state;
- goldens in Light, Dark, RTL, and 1.3× text;
- Staging checks for AC-003 and AC-012.

**Organization**: Grouped by user story (US1–US5 from spec.md), so each story can be built and
checked on its own after Phase 2.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: User story from spec.md (US1–US5)
- Paths are relative to the repository root (single Flutter project)

---

## Implementer Guide (read before any task)

These tasks are written for an implementer who has not seen the design discussion. Follow them
literally. When a task says "copy the pattern of X", open X first and match its style.

**Commands**

- After every task, run:
  1. `dart format .`
  2. `flutter analyze` (must show zero issues)
  3. the tests the task names
- After changing models, `.arb` files, or anything with `part` files, run
  `dart run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n`.
- Tagged golden tests: `flutter test --tags golden`. Regenerate only when the task says the
  picture is expected to change: `flutter test --tags golden --update-goldens`.

**Hard rules (CI rejects violations)**

1. No `Color(0x…)`, `Colors.*`, `fontSize:`, or `fontWeight:` outside `lib/design_system/`
   (`tool/check_hardcoded_styles.sh` enforces this).
   - Colors: `context.colors['tokenName']`, or getters such as `context.colors.primary`
     (see `lib/design_system/tokens/on_air_colors.dart` for token names).
   - Text: `context.textStyles.<name>` or `Theme.of(context).textTheme.<name>`.
   - Spacing and radii: `Dimens.*` (`lib/design_system/tokens/dimens.dart`).
2. Every visible string comes from `AppLocalizations.of(context)`. Never type Arabic or English
   text in a widget.
3. Layout is RTL-safe:
   - use `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`;
   - never `EdgeInsets.only(left:/right:)` or `Alignment.centerLeft`.
4. Money is always `Money` (`lib/core/money/money.dart`, integer piasters), shown with
   `MoneyFormatter().format(money)`.
   - Never use `double` for money.
   - **Never multiply nightly price × nights.** Totals come from the server.
5. Stay dates are always `DateOnly` (`lib/core/time/date_only.dart`). Never `DateTime` for
   arrival/departure.
6. Widgets never call Supabase or repositories directly. Widget → Cubit → `ListingsRepository`.
7. Every icon-only button has a `tooltip` and is wrapped in `Semantics(label: …, button: true)`.
   Touch targets are at least `Dimens.minTouchTarget` (48).
8. Never log names, phones, emails, or tokens. Log IDs only, via `AppLogger`.

**Code style used in this repo (match it)**

- **Models**: hand-written `@immutable final class` with a `const` constructor, a
  `factory X.fromJson(Map<String, dynamic> json)`, and `==`/`hashCode`.
  - Copy `lib/core/config/app_config.dart` and `lib/core/time/date_only.dart`.
  - Do **not** add `freezed` to these models.
- **Cubit states**: a `sealed class` with `final class` subclasses. Copy
  `lib/features/auth/domain/auth_state.dart`.
- **Cubits**: copy `lib/core/connectivity/connectivity_cubit.dart`:
  - check `isClosed` before every `emit`;
  - cancel timers and subscriptions in `close()`.
- **Errors**: repositories throw `AppFailure(ApiError)` (`lib/core/errors/api_error.dart`),
  built with `ErrorMapper.fromCode(code, requestId: …)` or `ErrorMapper.noResponse()`.
- **Widget tests**: wrap the screen like `test/helpers/pump_app.dart` (Arabic locale, RTL,
  `OnAirTheme`).
- **Goldens**: copy `test/design_system/goldens/components_golden_test.dart`. That means
  `alchemist` `goldenTest` with Light/Dark × RTL × 1.0/1.3 scale, tagged `golden`.
- **Repositories** are provided with `RepositoryProvider` in `lib/bootstrap.dart`; Cubits with
  `BlocProvider` close to the screen that owns them.

**Glossary**

| Term | Meaning |
|---|---|
| Night | A date D meaning "sleeping from D to D+1" |
| Stay `[checkIn, checkOut)` | The nights `checkIn … checkOut−1` |
| Visitor | Not signed in |
| Published | Approved and visible; the server decides |
| Mock mode | `BACKEND_MODE=mock`: in-memory repositories, no backend |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependencies, folders, strings, and copied contracts that every later task uses.

- [X] T001 Add the direct dependencies `cached_network_image`, `share_plus`, and `path_provider` (latest stable versions compatible with Flutter 3.44.3 / Dart 3.12.2) to `pubspec.yaml` under `dependencies:`, keeping alphabetical order. Run `flutter pub get` and commit the updated `pubspec.lock`. Done when `flutter pub get` succeeds and `flutter analyze` shows no new issues.
- [X] T002 [P] Copy the drafts for the backend owner. Copy `specs/002-guest-discovery/contracts/supabase-discovery.md` to `contracts/supabase-discovery.md`, `specs/002-guest-discovery/contracts/app-routes.md` to `contracts/app-routes-g1.md`, and `specs/002-guest-discovery/contracts/verified-links.md` to `contracts/verified-links.md`. In the three copies, rewrite relative links so they point at `specs/002-guest-discovery/...` from the `contracts/` folder. Append one line per file to `contracts/README.md` stating it is a G1 draft whose reviewed source is `specs/002-guest-discovery/contracts/`.
- [X] T003 [P] Create the empty folders, each with a `.gitkeep`: `lib/features/listings/domain/`, `lib/features/listings/data/fixtures/`, `lib/features/home/data/`, `lib/features/search/domain/`, `lib/features/property/domain/`, `lib/features/property/presentation/widgets/`, `lib/features/booking/presentation/`, `lib/features/support/presentation/`, `lib/core/images/`, `lib/core/cache/`, `lib/core/share/`, `test/features/listings/`, `test/features/home/`, `test/features/search/`, `test/features/property/`, `test/design_system/components/`.
- [X] T004 Add every key in **Appendix A** to `lib/l10n/app_ar.arb` (Arabic text exactly as listed) and `lib/l10n/app_en.arb` (the English text listed). Add the `@key` metadata blocks for keys with placeholders (types `String` or `int`, as listed) and use ICU `plural` exactly as written. Run `flutter gen-l10n`. Done when `lib/l10n/generated/app_localizations.dart` exposes every key and `flutter analyze` is clean. (Do **not** remove existing keys.)
- [X] T005 [P] Add four styles to `lib/design_system/typography/on_air_text_styles.dart`, next to the existing getters and using the same private `_style(size, weight)` helper: `areaCardTitle` 17/800, `areaBadge` 11/700, `propertyTitle` 15/800, `price` 14/800 (Guest Plan §4.4 table). Add `test/design_system/text_styles_test.dart` asserting each new style's `fontSize` and `fontWeight`.

**Checkpoint**: `flutter pub get`, `flutter gen-l10n`, and `flutter analyze` all pass.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared value objects, all server models, the repository (Supabase + mock),
shared UI components, routes, and wiring. Every user story depends on this phase.

**⚠️ CRITICAL**: No user story work starts before this phase is done.

### Tests first (write them, run them, see them fail, then implement)

- [X] T006 [P] Write `test/core/time/date_only_extras_test.dart` for the new `DateOnly` helpers and the date formatter:
  - **`DateOnly` helpers:**
    - `DateOnly(2026,2,28).addDays(1) == DateOnly(2026,3,1)`;
    - `addDays(-1)` crosses months and years;
    - `a.daysUntil(b)` returns the whole-day difference (negative when b is before a);
    - `isBefore` / `isAfter` / `compareTo`;
    - `DateOnly.fromDateTime(DateTime)` keeps only year/month/day.
  - **`CairoTime.today(now: DateTime.utc(2026,10,27,22,30))`** returns `DateOnly(2026,10,28)` (Cairo is UTC+2/+3). Call `CairoTime.initialize()` in `setUpAll`.
  - **`DateOnlyFormatter.dayMonth(DateOnly(2026,11,20))`** returns a string containing `20` written in **Western digits** and the Arabic month name «نوفمبر». `DateOnlyFormatter.monthYear(DateOnly(2026,11,1))` contains «نوفمبر» and `2026`.
  - **Setup:** in `setUpAll`, call `await initializeDateFormatting('ar')` (from `package:intl/date_symbol_data_local.dart`); without it, `DateFormat` with `'ar'` throws in plain unit tests. Do the same in every other test that formats dates, including T034 and the screen tests.
- [X] T007 [P] Write `test/core/time/stay_range_test.dart` for `StayRange` (data-model "StayRange"):
  - `StayRange.tryCreate(checkIn, checkOut, today)` returns `null` when checkOut ≤ checkIn or checkIn is before `today`.
  - It returns an object when checkIn == today.
  - `nights` equals `checkIn.daysUntil(checkOut)`.
  - `nightsIterable()` yields `checkIn … checkOut−1` (the last night is the day before checkOut).
  - `isSelectable(unavailable)` is `false` if any night is in the set, and `true` when only the **checkOut day** is in the set.
  - Value equality.
- [X] T008 [P] Write `test/core/images/image_variants_test.dart`. `ImageVariants.pick(variants, logicalWidth: 160, devicePixelRatio: 2)` with widths `[320, 720, 1440]`:
  - returns 320 (needs 320);
  - with dpr 3 (needs 480) returns 720;
  - with logicalWidth 1000 and dpr 3 returns 1440 (the widest when none is big enough);
  - an empty list returns `null`;
  - unsorted input still works.
- [X] T009 [P] Write `test/core/cache/json_file_cache_test.dart` for `JsonFileCache`, using a temp directory passed through the constructor (`JsonFileCache(directory: Directory.systemTemp.createTempSync(), fileName: 'x.json', schema: 1)`):
  - `read()` returns `null` when the file is missing;
  - `write(map)` then `read()` returns an equal map;
  - a file written with `schema: 1` read by a cache with `schema: 2` returns `null` and deletes the file;
  - a corrupt file (not JSON) returns `null` without throwing;
  - `clear()` deletes the file.
- [X] T010 [P] Extend `test/core/errors/error_mapper_test.dart`:
  - `ErrorMapper.fromCode('NOT_FOUND')` gives `code == ErrorCode.notFound` and `messageKey == 'propertyNotAvailable'`;
  - an unknown code still maps to `ErrorCode.internal`.
- [X] T011 [P] Write `test/core/errors/error_message_test.dart` for `apiErrorMessage(ApiError, AppLocalizations)`:
  - `network` → `l10n.errorNoConnection`;
  - `notFound` and `propertyNotAvailable` → `l10n.propertyNotAvailable`;
  - `validationFailed` → `l10n.errorValidationFailed`;
  - `internal` → `l10n.errorUnexpectedNoRef` (the reference number is shown separately by `ErrorView`);
  - any other code → `l10n.errorUnexpectedNoRef`.

  Get `AppLocalizations` with `lookupAppLocalizations(const Locale('ar'))`.
- [X] T012 [P] Write `test/features/listings/listings_json_test.dart`. It loads every fixture file from `lib/features/listings/data/fixtures/` (as plain files with `dart:io`) and parses them with the model `fromJson` factories from T018–T024. Assert:
  - `ListingCard.nightlyPrice` is a `Money`;
  - `stay` is `null` when absent;
  - `ratingAvg` is `null` when `review_count` is 0;
  - `PropertyDetails.addressText` may be `null`;
  - `PolicySummary.depositType` parses `percent | fixed | full`;
  - `HomeFeed` parses a failed section `{"status":"failed","error_code":"INTERNAL"}` as `FeedSection.failed`.
- [X] T013 [P] Write `test/features/listings/mock_listings_repository_test.dart` against `MockListingsRepository` (loaded from the fixtures):
  - **(a) Hidden apartments:** a search with no criteria never returns the apartments marked unpublished in Appendix B.
  - **(b) AC-012:** a search for the dates of `prop-busy` that include its booked night, its held night, or its blocked night does not return `prop-busy`; the free range next to them does.
  - **(c) `NOT_FOUND`:** `property('<unpublished id>')` and `property('<random uuid>')` both throw `AppFailure` with `ErrorCode.notFound`.
  - **(d) Pagination:** pages of 20 with `nextCursor`; the last page has `nextCursor == null`; `totalCount` is the same on every page.
  - **(e) Count:** `countProperties(params)` equals `totalCount`.
  - **(f) Filters:** `priceMin`/`priceMax` filter on the **final** nightly price; `amenityKeys` requires all; `propertyTypes` matches any; `guests` uses `maxGuests`.
  - **(g) Sort:** `price_asc` and `price_desc` order correctly; the default is newest first.
  - **(h) Locations:** `searchLocations('التجمع')` and `searchLocations('التجمّع')` return the same area; a 1-character query returns an empty list.
  - **(i) Calendar:** `unavailableNights(prop-busy, from, to)` returns exactly the booked + held + blocked nights inside the window.
  - **(j) Reviews:** `reviews(id)` returns only approved reviews, newest first, with `reviewerShortName` and no full name.
- [X] T014 [P] Write `test/features/listings/supabase_listings_repository_test.dart`. Construct `SupabaseListingsRepository(rpc: fakeRpc)`, where `fakeRpc` is a function that records `(functionName, params)` and returns fixture JSON. Assert:
  - every method calls the exact function name and parameter names from `contracts/supabase-discovery.md` (for example `searchProperties` → `guest_search_properties` with `p_location_id`, `p_check_in` as `YYYY-MM-DD`, `p_limit: 20`);
  - `countProperties` sends `p_limit: 0` and returns `total_count`;
  - a thrown `PostgrestException(message: 'NOT_FOUND')` becomes `AppFailure` with `ErrorCode.notFound`;
  - a `SocketException` or `http.ClientException` becomes `ErrorCode.network`;
  - any other exception becomes `ErrorCode.internal`.
- [X] T015 [P] Write `test/features/listings/reference_data_cache_test.dart` for `ReferenceDataCache` (T027), using a fake repository and a temp-dir `JsonFileCache`:
  - `load()` with an empty cache calls the repository once and saves the result;
  - a second `load()` returns the cached data without calling the repository;
  - `refreshIfVersionChanged('v2')` refetches only when the cached version is not `v2`;
  - a repository failure with an existing cache returns the cache;
  - a repository failure with no cache rethrows.

### Core implementation

- [X] T016 Implement the `DateOnly` helpers and formatting (makes T006 pass):
  - **In `lib/core/time/date_only.dart`:** `DateOnly addDays(int days)` (via `DateTime.utc`), `int daysUntil(DateOnly other)`, `bool isBefore(DateOnly)`, `bool isAfter(DateOnly)`, `implements Comparable<DateOnly>`, and `factory DateOnly.fromDateTime(DateTime)`.
  - **In `lib/core/time/cairo_time.dart`:** `static DateOnly today({DateTime? now})`, which converts `now ?? DateTime.now()` to Cairo with `tz.TZDateTime.from` and keeps year/month/day.
  - **Create `lib/core/time/date_only_formatter.dart`:** `abstract final class DateOnlyFormatter` with `dayMonth(DateOnly)` → `'${d.day} ${monthName}'` and `monthYear(DateOnly)` → `'$monthName ${d.year}'`. Get the month name from `DateFormat.MMMM('ar').format(DateTime.utc(y, m, 1))`. Write the numbers with `toString()` so they are always Western digits (G0 decision).
- [X] T017 Implement `StayRange` (after T016, because it uses `addDays` and `daysUntil`) in `lib/core/time/stay_range.dart` exactly as data-model "StayRange" (makes T007 pass). Rules:
  - `checkOut` must be after `checkIn`; `checkIn` must not be before `today`;
  - `nights` is for display and validation only;
  - the unnamed constructor asserts validity;
  - `static StayRange? tryCreate(DateOnly? checkIn, DateOnly? checkOut, DateOnly today)` never throws;
  - `bool isSelectable(Set<DateOnly> unavailableNights)` checks only the nights, not the checkOut day.
- [X] T018 [P] Implement the image types in two files (makes T008 pass). Core must never import `features/`, so `ImageVariant` lives in core:
  - **`lib/core/images/image_variants.dart`:** `ImageVariant {int width; Uri url}` with `fromJson` (keys `width`, `url`), and `abstract final class ImageVariants` with `static ImageVariant? pick({required List<ImageVariant> variants, required double logicalWidth, required double devicePixelRatio})`.
  - **`lib/features/listings/domain/listing_image.dart`:** `ListingImage {List<ImageVariant> variants; String? blurhash}` with `fromJson` (keys `variants`, `blurhash`), sorting `variants` by width ascending. It imports `ImageVariant` from core.
- [X] T019 [P] Implement `JsonFileCache` in `lib/core/cache/json_file_cache.dart` (makes T009 pass):
  - **Constructor:** `JsonFileCache({required Directory directory, required String fileName, required int schema})`, plus `static Future<JsonFileCache> appSupport({required String fileName, required int schema})`, which uses `getApplicationSupportDirectory()` from `path_provider`.
  - **File format:** `{"schema": <int>, "data": <map>}`.
  - **Methods:** `Future<Map<String, dynamic>?> read()`, `Future<void> write(Map<String, dynamic> data)` (write to `<file>.tmp`, then rename, so a crash never leaves half a file), and `Future<void> clear()`.
  - **Failures:** read and write failures are swallowed and return `null` / do nothing. No PII is ever written by this class's callers.
- [X] T020 Add `notFound` to `enum ErrorCode` in `lib/core/errors/api_error.dart` and the entry `'NOT_FOUND': (ErrorCode.notFound, 'propertyNotAvailable')` to `ErrorMapper._keys` in `lib/core/errors/error_mapper.dart` (makes T010 pass). Then create `lib/core/errors/error_message.dart` with `String apiErrorMessage(ApiError error, AppLocalizations l10n)` as specified in T011 (makes T011 pass). Run the whole test suite, because existing `switch`es over `ErrorCode` may need the new case.

### Listings models (all in `lib/features/listings/domain/`, hand-written, `fromJson` with snake_case keys from `contracts/supabase-discovery.md`)

Start these after T017 (`StayRange`) and T018 (`ImageVariant`, `ListingImage`) are done; then
T021–T024 can run in parallel.

- [X] T021 [P] Create `listing_card.dart`: `CardStay {int nights; Money stayTotal}` and `ListingCard {String id; String title; String propertyType; String areaName; String cityName; ListingImage? cover; Money nightlyPrice; double? ratingAvg; int reviewCount; CardStay? stay}`.
  - **Money:** build it from `nightly_price_minor` and `stay.stay_total_minor` as `Money(int, currency: json['currency'] ?? 'EGP')`.
  - **Rating:** force `ratingAvg` to `null` when `review_count == 0`, even if the JSON has a number.
- [X] T022 [P] Create `location_suggestion.dart` (`LocationLevel` enum `governorate|city|area`; `LocationSuggestion {String id; LocationLevel level; String name; String? parentLabel; int listingCount}`). Create `reference_data.dart`:
  - `Amenity {String key; String label; String? icon}`;
  - `PropertyTypeOption {String key; String label}`;
  - `ReferenceData {String version; List<Amenity> amenities; List<PropertyTypeOption> propertyTypes; Money priceMin; Money priceMax; Money priceStep}`, where `priceStep` defaults to `Money(5000)` when `price_step_minor` is missing (research R7);
  - `toJson()` on `ReferenceData` (needed for the disk cache).
- [X] T023 [P] Create `results_page.dart`:
  - `enum SearchSort { priceAsc('price_asc'), priceDesc('price_desc'), newest('newest') }` with a `wire` string field;
  - `PropertySearchParams {String? locationId; StayRange? stay; int? guests; Money? priceMin; Money? priceMax; int? minBedrooms; int? minBathrooms; Set<String> amenityKeys; Set<String> propertyTypes; SearchSort? sort}`;
  - `ResultsPage {List<ListingCard> items; String? nextCursor; int totalCount}` with `fromJson`.
- [X] T024 [P] Create `property_details.dart`:
  - `StayRules {String checkInTime; String checkOutTime; bool visitorsAllowed; int? maxVisitors; String? houseRules}`;
  - `enum DepositType {percent, fixed, full}`;
  - `PolicySummary {DepositType depositType; int? depositPercentBp; Money? depositAmount; int freeCancellationHours}`;
  - `PropertyDetails` with **every** field in data-model "PropertyDetails".

  Rules: `addressText` is nullable; there are **no** latitude/longitude fields; `latestReviews` holds at most 3 items (take the first 3 if more arrive). Create `approved_review.dart` with `ApprovedReview {String id; int rating; String? comment; DateOnly createdOn; String reviewerShortName}` and `ReviewsPage {List<ApprovedReview> items; String? nextCursor}`. Create `home_feed.dart`:
  - `sealed class FeedSection<T>` with `FeedSectionReady<T>(T value)` and `FeedSectionFailed<T>(String errorCode, String? requestId)`;
  - `AreaTile {String locationId; String name; int listingCount; ListingImage? image}`;
  - `UpcomingBookingCard {String bookingId; String propertyTitle; DateOnly checkIn; DateOnly checkOut; String status}`;
  - `HomeFeed {String referenceVersion; FeedSection<List<AreaTile>> areas; FeedSection<List<ListingCard>> suggested; FeedSection<List<ListingCard>> newest; FeedSection<UpcomingBookingCard?> upcomingBooking; DateTime fetchedAt}`;
  - `Map<String, dynamic> toPublicJson()`, which writes **only** `reference_version`, `areas`, `suggested`, `newest`, and `fetched_at` and **never** `upcoming_booking`;
  - `factory HomeFeed.fromPublicJson(...)`, which sets `upcomingBooking` to `FeedSectionReady(null)`.
- [X] T025 Create the repository interface `lib/features/listings/domain/listings_repository.dart` with exactly these methods, documented with `///` and all throwing `AppFailure` on error:
  - `Future<HomeFeed> homeFeed()`;
  - `Future<ResultsPage> searchProperties(PropertySearchParams params, {String? cursor, int limit = 20})`;
  - `Future<int> countProperties(PropertySearchParams params)`;
  - `Future<List<LocationSuggestion>> searchLocations(String query)`;
  - `Future<ReferenceData> referenceData()`;
  - `Future<PropertyDetails> property(String id)`;
  - `Future<Set<DateOnly>> unavailableNights(String id, DateOnly from, DateOnly to)`;
  - `Future<ReviewsPage> reviews(String id, {String? cursor, int limit = 20})`.

### Repository implementations

- [X] T026 Create the mock fixtures in `lib/features/listings/data/fixtures/` exactly as **Appendix B**, as JSON files whose shapes match the RPC responses in `contracts/supabase-discovery.md`. Use UUID v4 strings for every ID. Keep the readable names (`prop-busy`, …) only as a `"_fixture_name"` field, which the models ignore. Declare `lib/features/listings/data/fixtures/` under `flutter: assets:` in `pubspec.yaml`.
- [X] T027 Implement `MockListingsRepository implements ListingsRepository` in `lib/features/listings/data/mock_listings_repository.dart` (makes T013 pass):
  - **Loading:** fixtures are loaded once through `rootBundle.loadString`. Add a constructor parameter `Future<String> Function(String path)? loader` so tests can read files directly.
  - **Published only:** never return or open apartments whose fixture `"_published"` is `false`.
  - **Availability:** apply the rule in research R2 (exclude an apartment if any night of the stay is in its `booked`, `held`, or `blocked` nights).
  - **Prices:** filter by the final nightly price.
  - **Arabic normalisation:** normalise names and query with `أإآ→ا`, `ة→ه`, `ى→ي`, and remove tatweel `ـ` and diacritics `ً-ْ`.
  - **Cursor:** the item offset as a string.
  - **Latency:** add `Future.delayed(const Duration(milliseconds: 300))` on every call, so loading states are visible in mock mode. Pass `Duration.zero` in tests through a constructor parameter.
  - **Unknown or unpublished ID:** throw `AppFailure(ErrorMapper.fromCode('NOT_FOUND'))`.

  Also add `class ReferenceDataCache` in `lib/features/listings/data/reference_data_cache.dart` with:
  - `ReferenceDataCache(ListingsRepository repo, JsonFileCache cache)`;
  - `Future<ReferenceData> load()`;
  - `Future<void> refreshIfVersionChanged(String version)`;
  - keeping the loaded value in memory too.

  This makes T015 pass. The cache stores `{"reference": referenceData.toJson()}`. Use the same file as Home (`discovery_cache.json`, schema 1) under the key `reference`, and read-modify-write so the `home` key is kept.
- [X] T028 Implement `SupabaseListingsRepository implements ListingsRepository` in `lib/features/listings/data/supabase_listings_repository.dart` (makes T014 pass):
  - **Constructor:** `SupabaseListingsRepository({required Future<dynamic> Function(String fn, Map<String, dynamic> params) rpc})`. In production, `bootstrap` passes `(fn, params) => client.rpc<dynamic>(fn, params: params)`.
  - **Parameters:** map `PropertySearchParams` to the `p_*` parameters in `contracts/supabase-discovery.md` §2. Leave out null values. Send dates with `DateOnly.toString()`, amounts as `amountMinor`, and sets as lists.
  - **Errors:** wrap every call in one private `_guard` that converts:
    - a `PostgrestException` whose `message` or `code` is a known code → `ErrorMapper.fromCode(that code)`;
    - `SocketException`, `TimeoutException`, or `http.ClientException` → `ErrorMapper.noResponse()`;
    - anything else → `ErrorMapper.fromCode('INTERNAL')`.

    Throw the result as `AppFailure`. Never log request parameters.
- [X] T029 Create the test fake `test/helpers/fake_listings_repository.dart`: `FakeListingsRepository implements ListingsRepository`. Each method returns a value set by the test, or throws a set `AppFailure`; for example `searchResponses` is a queue of `FutureOr<ResultsPage>`, and `propertyResponse` is a `Completer` so tests can control timing. It records each call in `List<String> calls` with its arguments.

### Shared design-system components (each with its own widget test; components take primitives only and never import `features/`)

Start these after T016 (`DateOnlyFormatter`) and T018 (`ImageVariant`); then T030–T034 can run
in parallel.

- [X] T030 [P] Create `OnAirNetworkImage` in `lib/design_system/components/on_air_network_image.dart` with its test `test/design_system/components/on_air_network_image_test.dart`:
  - **Parameters:** `required List<ImageVariant> variants`, `BoxFit fit = BoxFit.cover`, `BorderRadius? borderRadius`, `String? heroTag`, `String? semanticLabel`.
  - **Picking:** use `LayoutBuilder` to get the width, then pick the URL with `ImageVariants.pick(..., devicePixelRatio: MediaQuery.devicePixelRatioOf(context))`.
  - **Rendering:** render with `CachedNetworkImage` and `memCacheWidth: (width * dpr).round()`.
  - **Placeholder:** a `ColoredBox(color: context.colors['detailCard'])`.
  - **Error widget:** the same box with `Icons.image_not_supported_outlined` in `textSecondary`.
  - **No variants:** show the placeholder only.
  - **Hero:** wrap in `Hero(tag: heroTag)` when `heroTag` is not null.
  - **Test:** empty variants show the placeholder; the hero tag is applied.
- [X] T031 [P] Create `lib/design_system/components/skeletons.dart` with `SkeletonBox({double? width, required double height, double radius = Dimens.radiusCard})`, which pulses between `detailCard` and `borderDetail` colors over 1.2 s. Wrap it in `RepaintBoundary`. When `MediaQuery.disableAnimationsOf(context)` is true, do not animate. Add `PropertyCardSkeleton`, which matches `PropertyCard`'s size. Test in `test/design_system/components/skeletons_test.dart`: with animations disabled, no ticker is active.
- [X] T032 [P] Create `RatingBadge({required String ratingText, required String semanticsLabel})` in `lib/design_system/components/rating_badge.dart`: an `Icons.star_rounded` star in `context.colors['star']` plus the text, wrapped in `Semantics(label: semanticsLabel, excludeSemantics: true)`. Callers do not build it when there is no rating. Create `PriceText({required String price, String? caption})` in `lib/design_system/components/price_text.dart`: `price` uses `context.textStyles.price`, and the optional `caption` (for example the stay total) is `bodySmall` in `textSecondary`. Test both in `test/design_system/components/rating_price_test.dart`.
- [X] T033 [P] Create `PropertyCard` in `lib/design_system/components/property_card.dart`, with its test `test/design_system/components/property_card_test.dart`:
  - **Parameters:** `required String title`, `required String subtitle` (area • city), `required List<ImageVariant> imageVariants`, `required String priceText`, `String? stayTotalText`, `String? ratingText`, `String? ratingSemantics`, `String? heroTag`, `required VoidCallback onTap`, `double width = double.infinity`.
  - **Layout:**
    - a 16:10 image (`OnAirNetworkImage`, `Dimens.radiusCard` top corners);
    - the title in `propertyTitle`, max 2 lines with ellipsis;
    - the subtitle in `bodySmall` / `textSecondary`;
    - a row with `PriceText` at the start and `RatingBadge` at the end, shown only when `ratingText` is not null.
  - **Container:** surface color, a 1 px `subtleBorder` border, `Dimens.radiusCard`, whole card tappable with `InkWell`. No favorite heart (G5).
  - **Semantics:** one merged label: title, subtitle, price.
  - **Test:** the rating is hidden when `ratingText` is null, and `onTap` fires.
- [X] T034 [P] Create `RangeCalendar` in `lib/design_system/components/range_calendar.dart`, with its test `test/design_system/components/range_calendar_test.dart`:
  - **Parameters:** `required DateOnly today`, `required DateOnly initialMonth`, `DateOnly? selectedCheckIn`, `DateOnly? selectedCheckOut`, `Set<DateOnly> unavailableNights = const {}`, `Set<int> loadingMonthKeys = const {}` (key = `year*12+month`), `required void Function(DateOnly day) onDayTap`, `void Function(DateOnly firstDayOfMonth)? onMonthShown`, `DateOnly? lastSelectableDay`.
  - **Header:** one month at a time with previous/next `IconButton`s that have tooltips (`l10n.calendarPrevMonth` / `calendarNextMonth`), and the title from `DateOnlyFormatter.monthYear`.
  - **Grid:** 7 columns, weeks start on **Saturday** (Egypt), weekday initials from `DateFormat.E('ar')`, built with `Directionality`-aware `GridView.count` (no `left`/`right`).
  - **Day states and colors:**

    | State | Look |
    |---|---|
    | past (before `today`) | disabled, `textSecondary` at 40% via the `placeholder` token |
    | unavailable night | struck through with `TextDecoration.lineThrough`, `textSecondary`; still tappable only as a checkOut day |
    | selected start / end | filled `primary` circle with `onPrimary` text |
    | in range | `badgeNavActive` background |
    | loading month | every day greyed and not tappable |

  - **Day semantics:** e.g. «20 نوفمبر، مش متاح» (`l10n.calendarUnavailableDay(date)`).
  - **Behaviour:** the component **does not decide** selection; it only reports taps through `onDayTap`. Callers decide. It calls `onMonthShown` when a new month is displayed.
  - **Test:** Saturday is the first column; a past day does not call `onDayTap`; changing month calls `onMonthShown`.
- [X] T035 Create `test/design_system/goldens/discovery_components_golden_test.dart` (tag `golden`). It covers:
  - `PropertyCard` (with and without rating, with stay total);
  - `PropertyCardSkeleton`;
  - `RangeCalendar` (a month with 3 unavailable nights and a selected range).

  Run them in Light/Dark × RTL × text scale 1.0/1.3, copying `components_golden_test.dart`. Generate the PNGs with `--update-goldens` and commit them.

### Routes, placeholders, and wiring

- [X] T036 Update `lib/app/router/routes.dart` and its tests in `test/app/router/redirect_test.dart`:
  - **Constants to add:** `propertyGalleryPattern = '/property/:id/gallery'`, `propertyReviewsPattern = '/property/:id/reviews'`, `bookingEntryPattern = '/book/:propertyId/dates'`, `supportNew = '/support/new'`.
  - **Helpers to add:** `static String property(String id) => '/property/$id'` (and the same for gallery, reviews, and bookingEntry).
  - **Regexes to add:** `_propertyGallery`, `_propertyReviews`, `_bookingEntry`. Add them to `_validDynamicPath`, and add `supportNew` to the static paths in `isRegisteredLocation`.
  - **`requiresAccount`:** must return `true` for `_bookingEntry` and `supportNew`, and stay `false` for `/property/...` and `/search/results`.
  - **`isLinkablePath`:** do **not** add the new routes.
  - **Tests:** non-UUID IDs are rejected; `/book/<uuid>/dates` requires an account; `/property/<uuid>/gallery` does not.
- [X] T037 Create two localized placeholder screens:
  - **`BookingEntryPlaceholderScreen({required String propertyId, required Map<String, String> query})`** in `lib/features/booking/presentation/booking_entry_placeholder_screen.dart`. It shows `l10n.bookingEntryTitle` in the `AppBar` and `l10n.bookingEntryComingSoon`. When present in `query`, it also shows `checkIn`/`checkOut` (formatted with `DateOnlyFormatter.dayMonth`) and `guests`. It never shows the raw `terms` value; it only shows `l10n.bookingEntryTermsCarried` when `terms` exists. It has a back button.
  - **`SupportEntryPlaceholderScreen({String? propertyId})`** in `lib/features/support/presentation/support_entry_placeholder_screen.dart`, showing `l10n.supportEntryTitle` and `l10n.supportEntryComingSoon`.

  Register both as top-level `GoRoute`s in `lib/app/router/app_router.dart`, building them from `state.pathParameters` and `state.uri.queryParameters`. Add a widget test for each in `test/features/booking/booking_entry_placeholder_test.dart` and `test/features/support/support_entry_placeholder_test.dart`.
- [X] T038 Wire the repositories in `lib/bootstrap.dart`:
  - **`_Backend` record:** add `ListingsRepository listings`.
  - **`_remoteBackend`:** `SupabaseListingsRepository(rpc: (fn, params) => client.rpc<dynamic>(fn, params: params))`.
  - **`_mockBackend`:** `MockListingsRepository()`.
  - **After choosing the backend:** create `final discoveryCache = await JsonFileCache.appSupport(fileName: 'discovery_cache.json', schema: 1);` and `final referenceData = ReferenceDataCache(backend.listings, discoveryCache);`.
  - **Providers:** add `RepositoryProvider<ListingsRepository>`, `RepositoryProvider<JsonFileCache>`, and `RepositoryProvider<ReferenceDataCache>` to the `MultiRepositoryProvider`. Also provide the `ConnectivityCubit` if it is not already provided at the root; check `lib/app/app.dart` first and reuse the existing instance.
  - **Test helpers:** update `test/helpers/pump_app.dart` and `test/app/test_app_harness.dart` to provide a `FakeListingsRepository`, a temp-dir `JsonFileCache`, and a `ReferenceDataCache` by default.
  - **Done when:** all existing G0 tests still pass.

**Checkpoint**: `flutter test` is green; the mock repository passes T013; the app runs in mock mode
with unchanged G0 screens.

---

## Phase 3: User Story 1 — Find an apartment that is free for the whole stay (Priority: P1) 🎯 MVP

**Goal**: The Search tab lets a guest set location (optional), dates (optional), guests,
filters, and sort, and shows server-filtered results with pagination. State is kept across tab
switches and details round-trips.

**Independent Test**: In mock mode, run quickstart scenarios 3, 4, 6, and 7. Only approved
apartments free for every night appear; filters, chips, sort, and pagination work; Back from
an apartment keeps the list and scroll position.

### Tests for User Story 1 (write first, must fail)

- [X] T039 [P] [US1] Write `test/features/search/search_criteria_test.dart` for `SearchCriteria` (data-model "SearchCriteria"; quote the rules exactly). It covers:
  - **Key mapping:** `loc` UUID v4 only; `in`/`out` as `YYYY-MM-DD`; `g` 1–50; `pmin`/`pmax` ≥ 0 piasters, swapped when min > max; `bed`/`bath` 0–20; `am` and `type` as comma lists of `[a-z0-9_]{1,40}`, at most 30 items; `sort` one of `price_asc|price_desc|newest`.
  - **Bad values:** an invalid value drops only its own field.
  - **Bad dates:** past or inverted dates drop **both** dates and set `datesDropped = true`.
  - **Unknown keys:** ignored.
  - **Canonical output:** `toQuery()` returns keys sorted with empty fields left out, so `fromQuery(toQuery(x)) == x`.
  - **Labels:** `locationLabel` is never written to the query.
  - **Empty criteria:** `SearchCriteria.empty` has no fields and is valid.
  - **Chips:** `activeFilterChips` lists price, bedrooms, bathrooms, each amenity, and each type (not location, dates, or guests); `withoutChip(chip)` removes exactly one.
  - **Params:** `toParams()` returns the matching `PropertySearchParams`.
- [X] T040 [P] [US1] Write `test/features/search/last_search_store_test.dart`, using `SharedPreferences.setMockInitialValues({})`:
  - `save(criteria)` writes key `last_search_v1` as the canonical query plus the label (stored as JSON `{"q": "...", "label": "..."}`);
  - `load()` returns equal criteria and label;
  - corrupt stored data returns `null`.

  Also extend the existing sign-out test file `test/features/account_gate/sign_out_service_test.dart` to assert that `last_search_v1` is **kept** after sign-out.
- [X] T041 [P] [US1] Write `test/features/search/location_suggest_cubit_test.dart` with `bloc_test` and fake async (`fakeAsync` or `clock`):
  - typing "ال" then "التج" within 350 ms makes only **one** repository call, with "التج";
  - an older response arriving after a newer one is ignored (control order with the `Completer`s in `FakeListingsRepository`);
  - fewer than 2 characters gives `LocationSuggestIdle` without calling the repository;
  - a failure gives `LocationSuggestFailed`;
  - `close()` cancels the pending debounce.
- [X] T042 [P] [US1] Write `test/features/search/filters_count_cubit_test.dart`:
  - a change triggers `countProperties` after 400 ms;
  - quick consecutive changes give one call;
  - a stale count is ignored;
  - the states are `FiltersCounting` → `FiltersCount(n)` or `FiltersCountFailed`.
- [X] T043 [P] [US1] Write `test/features/search/search_cubit_test.dart` covering:
  - **`search(criteria)`:** emits `loading` then `ready` with the first page (or `empty` when `totalCount == 0`), and saves the criteria with `LastSearchStore`;
  - **`loadMore()`:** appends the next page; it is ignored while already loading, when `nextCursor == null`, or while offline;
  - **Bad cursor:** a `validationFailed` error during `loadMore` resets to page 1;
  - **`removeChip(chip)`:** searches again without that chip;
  - **`openFromQuery(Map<String,String>)`:** parses with `SearchCriteria.fromQuery`; when `datesDropped` is true, the state flag `datesDropped` is set;
  - **Offline:** while `ConnectivityCubit` is offline, `search` emits `offline` without calling the repository;
  - **Scroll offset:** `scrollOffset` is stored with `rememberScroll(double)` and kept in state.

### Implementation for User Story 1

- [X] T044 [US1] Implement `SearchCriteria` in `lib/features/search/domain/search_criteria.dart` to make T039 pass:
  - **Fields:** as data-model "SearchCriteria", plus `bool datesDropped`.
  - **Methods:** `static SearchCriteria fromQuery(Map<String, String> query, {required DateOnly today})`, `Map<String, String> toQuery()`, `PropertySearchParams toParams()`, `List<FilterChipData> get activeFilterChips`, `SearchCriteria withoutChip(FilterChipData chip)`, and `copyWith(...)`.
  - **`FilterChipData`:** `{FilterChipKind kind; String? key}`, where `kind` is `price|bedrooms|bathrooms|amenity|type`.
  - **No UI text:** keep all text out of this class.
- [X] T045 [US1] Implement `LastSearchStore` in `lib/features/search/domain/last_search_store.dart` (makes T040 pass):
  - **Methods:** `Future<void> save(SearchCriteria c, String? label)` and `Future<({SearchCriteria criteria, String? label})?> load({required DateOnly today})`.
  - **Storage:** use `SharedPreferences.getInstance()` with the key `last_search_v1`.
  - **Keep at sign-out:** add `'last_search_v1'` to `SignOutService.preservedPreferenceKeys` in `lib/features/account_gate/application/sign_out_service.dart`. It holds no personal data; see the spec Assumptions.
  - **Provide it:** with `RepositoryProvider<LastSearchStore>` in `lib/bootstrap.dart` and in the test helpers.
- [X] T046 [US1] Implement `LocationSuggestCubit` and its sealed states in `lib/features/search/presentation/location_suggest_cubit.dart` (makes T041 pass). States: `LocationSuggestIdle`, `LocationSuggestLoading(String query)`, `LocationSuggestReady(String query, List<LocationSuggestion> items)`, `LocationSuggestFailed(String query)`.
  - **`onQueryChanged(String text)`:**
    1. Trim the text.
    2. Restart a 350 ms `Timer`.
    3. When it fires, increment `_sequence`, call `repo.searchLocations`, and emit the result only if its sequence number is still the latest and the Cubit is not closed.
  - **`close()`:** cancel the timer.
- [X] T047 [US1] Implement `FiltersCountCubit` in `lib/features/search/presentation/filters_count_cubit.dart` (makes T042 pass). It has the same debounce-and-sequence pattern as T046, with 400 ms and `repo.countProperties(criteria.toParams())`.
- [X] T048 [US1] Implement `SearchCubit` in `lib/features/search/presentation/search_cubit.dart` (makes T043 pass):
  - **Constructor dependencies:** `ListingsRepository`, `LastSearchStore`, `ConnectivityCubit`, and `DateOnly Function() today` (default `CairoTime.today`).
  - **State:** one immutable `SearchState` with `criteria`, `String? locationLabel`, `ResultsStatus status` (`idle|loading|ready|empty|failed|offline`), `List<ListingCard> items`, `String? nextCursor`, `int totalCount`, `bool loadingMore`, `ApiError? error`, `bool datesDropped`, `double scrollOffset`, and `copyWith`.
  - **Lifetime:** the Cubit lives as long as the Search tab branch (T057), so results survive tab switches.
  - **Initial state:** on creation, load the last search with `LastSearchStore.load` into `criteria` and `locationLabel`, without searching automatically.
- [X] T049 [P] [US1] Create `CounterStepper({required int value, required int min, required int max, required ValueChanged<int> onChanged, required String label, required String decrementTooltip, required String incrementTooltip})` in `lib/design_system/components/counter_stepper.dart`:
  - minus/plus `IconButton`s (48×48) with tooltips, disabled at the limits;
  - the value in `titleMedium`;
  - `Semantics(value: '$value', label: label)`.

  Test in `test/design_system/components/counter_stepper_test.dart`.
- [X] T050 [P] [US1] Create `FilterChipBar({required List<({String label, String removeTooltip, VoidCallback onRemove})> chips})` in `lib/design_system/components/filter_chip_bar.dart`:
  - a horizontal `ListView` with `Dimens.space8` gaps and directional padding;
  - each chip is an `InputChip` with a delete icon; `deleteButtonTooltipMessage` = `removeTooltip`;
  - it renders nothing when `chips` is empty.

  Test in `test/design_system/components/filter_chip_bar_test.dart`.
- [X] T051 [US1] Create the location field in `lib/features/search/presentation/widgets/location_field.dart`:
  - **Field:** an `OnAirTextField` (existing component) with hint `l10n.searchLocationHint`.
  - **Suggestions:** listed below the field from `LocationSuggestCubit`. Each row shows `name`, `parentLabel`, and `l10n.areaListingCount(listingCount)`.
  - **Short query:** with fewer than 2 characters, show the guest's last-search location (if any) and «كل الأماكن» (`l10n.searchAnyLocation`), which clears the location.
  - **Selecting:** a row calls back `(String? id, String? label)`.
  - **Offline:** suggestions are disabled and the field shows `l10n.offline` as helper text.
- [X] T052 [US1] Create the date sheet `lib/features/search/presentation/widgets/date_range_sheet.dart`:
  - **What it is:** a modal bottom sheet (`Dimens.radiusSheet` top corners) holding the `RangeCalendar` from T034, with `today = CairoTime.today()` and no unavailable nights.
  - **Selection logic (in this widget's `State`):**
    - the first tap sets checkIn;
    - a second tap after checkIn sets checkOut;
    - a tap on or before checkIn restarts with that day as checkIn.
  - **Buttons:** «مسح» (`calendarClear`) clears; «تمام» (`calendarConfirm`) is enabled only when `StayRange.tryCreate` succeeds and pops with the `StayRange`.
  - **Nights label:** show `l10n.calendarNightsSelected(nights)`.
- [X] T053 [US1] Replace the Search tab with `SearchScreen` in `lib/features/search/presentation/search_screen.dart`:
  - **Fields, top to bottom:** `LocationField` (T051); a dates row that opens `DateRangeSheet` and shows `DateOnlyFormatter.dayMonth(checkIn) – dayMonth(checkOut)` or `l10n.searchDatesHint`; guests with `CounterStepper` (min 1, max 50, empty by default, shown as `l10n.searchGuestsAny` until changed); a «الفلاتر» button showing the number of active chips.
  - **Search button:** «ابحث» uses `OnAirPrimaryButton`. It is always enabled, because every field is optional (Clarification 1), and disabled while offline. On tap it calls `searchCubit.search(...)` and `context.go(Uri(path: AppRoutes.searchResults, queryParameters: criteria.toQuery()).toString())`.
  - **Old placeholder:** delete `lib/features/search/presentation/search_placeholder_screen.dart` and update any G0 test that referenced it.
- [X] T054 [US1] Create `FiltersSheet` in `lib/features/search/presentation/filters_sheet.dart`. It is a draggable modal bottom sheet that edits a local copy of `SearchCriteria`:
  - **Price:** a `RangeSlider` between `ReferenceData.priceMin` and `priceMax`, with `divisions = ((max-min)/step).round()` and labels from `MoneyFormatter`.
  - **Bedrooms and bathrooms:** `CounterStepper`s, 0–20, where 0 means «أي عدد».
  - **Amenities:** `FilterChip`s from `ReferenceData.amenities`, multi-select.
  - **Property types:** `FilterChip`s from `ReferenceData.propertyTypes`.
  - **Sort:** `ChoiceChip`s for `sortPriceAsc|sortPriceDesc|sortNewest`.
  - **Bottom bar:** «مسح الكل» resets the local copy. The primary button shows `l10n.searchShowResults(count)` from `FiltersCountCubit` (a small spinner while counting, `l10n.searchShowResultsUnknown` on failure). It pops with the edited criteria.
  - **Reference data:** load it with `context.read<ReferenceDataCache>().load()`. If that fails, show `ErrorView` with retry inside the sheet; the rest of Search keeps working.
- [X] T055 [US1] Create `ResultsScreen` in `lib/features/search/presentation/results_screen.dart`:
  - **Scroll view:** a `CustomScrollView` holding:
    - a summary bar (location label or «كل الأماكن», dates, guests) that taps back to `/search`;
    - a `SliverToBoxAdapter` with `FilterChipBar` from `activeFilterChips`, using labels such as `l10n.bedroomsAtLeast(n)` and `l10n.filterChipRemove(label)`;
    - a dates-needed hint banner (`l10n.searchDatesNeededHint`) when `criteria.stay == null`;
    - a `datesDropped` banner (`l10n.searchDatesDropped`) with an action that opens `DateRangeSheet`;
    - a `SliverList.builder` of `PropertyCard`s.
  - **Card content:**
    - `priceText = l10n.nightlyPrice(MoneyFormatter().format(card.nightlyPrice))`;
    - `stayTotalText = card.stay == null ? null : l10n.stayTotal(card.stay!.nights, MoneyFormatter().format(card.stay!.stayTotal))`;
    - `ratingText = card.ratingAvg?.toStringAsFixed(1)`;
    - `heroTag = 'listing-${card.id}'`.
  - **Pagination:** call `loadMore()` when the guest is within 600 px of the end (`ScrollNotification`); show a `PropertyCardSkeleton` row while `loadingMore`.
  - **States:**

    | State | What shows |
    |---|---|
    | loading | 4 `PropertyCardSkeleton` |
    | empty | `EmptyView(icon: Icons.search_off, message: l10n.searchNoResults)` with `l10n.searchNoResultsHint` and an action to open filters |
    | failed | `ErrorView` with `apiErrorMessage` and `referenceNumber: error.requestId` |
    | offline | `OfflineBanner` at the top; loaded items stay visible |

  - **Scroll position:** save it with `rememberScroll` on `dispose`, and restore it with a `ScrollController(initialScrollOffset: state.scrollOffset)`.
  - **Card tap:** for now, `context.push(AppRoutes.property(card.id))`. US2 (T072) adds the dates, guests, and hero image.
- [X] T056 [US1] Wire the routes in `lib/app/router/app_router.dart`:
  - **Search branch:** wrap the branch's `/search` route in a `ShellRoute`, or provide `SearchCubit` above the `StatefulShellBranch` navigator, so **one** `SearchCubit` instance serves both `/search` and `/search/results`. Create it with `BlocProvider(create: (ctx) => SearchCubit(...), lazy: false)` at the branch level, so switching tabs keeps it.
  - **Results route:** add `GoRoute(path: 'results', ...)` as a child of `/search`, with the builder calling `context.read<SearchCubit>().openFromQuery(state.uri.queryParameters)` once per new query. Use a stateful wrapper widget that compares the previous query and opens again only when it changed.
  - **Old route:** delete the old top-level `linked-search-results` route that pointed at `NotAvailableScreen`.
  - **Done when:** `test/app/router/redirect_test.dart` and `test/app/shell/*` still pass.
- [X] T057 [US1] Write `test/features/search/search_screen_test.dart`:
  - with no input, «ابحث» is enabled and navigates to `/search/results` with an empty query;
  - typing shows suggestions from the fake repository, and tapping one fills the field;
  - the date sheet does not allow a past day, and «تمام» is disabled until a valid range is picked;
  - offline disables «ابحث».
- [X] T058 [US1] Write `test/features/search/results_screen_test.dart`:
  - loading shows skeletons;
  - ready shows cards with the price, and the stay total only when dates are set;
  - empty shows the empty message;
  - an error shows the message and the reference number;
  - offline keeps the items and shows the banner;
  - removing a chip searches again;
  - scrolling near the end calls `loadMore` once;
  - `datesDropped` shows the banner.
- [X] T059 [US1] Write `test/features/search/filters_sheet_test.dart`:
  - the count label updates after the debounce;
  - «مسح الكل» resets every filter;
  - confirming returns the edited criteria;
  - a reference-data failure shows retry inside the sheet.
- [X] T060 [US1] Add `test/features/search/goldens/search_goldens_test.dart` (tag `golden`) covering `SearchScreen` (empty form), `ResultsScreen` (ready with chips + dates hint), and `FiltersSheet`, in Light/Dark × RTL × 1.0/1.3. Generate and commit the PNGs.
- [X] T061 [US1] Create `integration_test/discovery_rules_test.dart`:
  - **Mode:** skip all tests with a printed reason when `EnvConfig.fromEnvironment().backendMode == BackendMode.mock`.
  - **Remote mode:** use `SupabaseListingsRepository` against Staging and the seed in `contracts/supabase-discovery.md` §11. Seed IDs are read from a git-ignored `env/staging_seed.json`; document its keys at the top of the test.
  - **AC-012:** a search over dates including the booked, held, or blocked night of the busy apartment never returns it; the free range does.
  - **AC-003:** no unpublished seed ID appears in a search with no criteria (page through all results).

**Checkpoint**: US1 is complete in mock mode (quickstart scenarios 3, 4, 6, 7).

---

## Phase 4: User Story 2 — Understand an apartment fully before deciding to book (Priority: P1)

**Goal**: The apartment details screen shows every required section from the server, with a
pickable availability calendar. "Book now" carries the shown terms version, dates, and guests to
the booking entry.

**Independent Test**: In mock mode, run quickstart scenarios 8, 9, and 14. Open the
deposit-percent apartment from a direct route `/property/<id>`, check every section, pick dates
on the calendar, and confirm "Book now" (signed in) opens the booking placeholder with the same
values.

### Tests for User Story 2 (write first, must fail)

- [X] T062 [P] [US2] Write `test/features/property/policy_text_test.dart` for `policyLines(PolicySummary p)`, which returns an ordered `List<PolicyLine>` where `PolicyLine` is a sealed type:
  - `percent` with `depositPercentBp: 2500` → first `DepositPercentLine(percentText: '25')` (bp/100; show one decimal only if not whole, e.g. 1250 → '12.5');
  - `fixed` → `DepositFixedLine(Money)`;
  - `full` → `DepositFullLine()`;
  - then always `FreeCancellationLine(hours: p.freeCancellationHours)`, `AfterDeadlineLine()`, and `FullyPaidLateLine()` (Master Plan §7.2).

  The function computes **no** money.
- [X] T063 [P] [US2] Write `test/features/property/property_cubit_test.dart`:
  - `load(id)` → `PropertyLoading` → `PropertyReady(details)`;
  - `NOT_FOUND` → `PropertyNotAvailable`;
  - a network error while offline → `PropertyOffline`;
  - other errors → `PropertyFailed(error)`;
  - `setStay(StayRange)` updates `stay` in the ready state;
  - an initial stay and guests passed to the constructor are kept;
  - retry calls the repository again.
- [X] T064 [P] [US2] Write `test/features/property/availability_cubit_test.dart`:
  - `showMonth(firstDay)` loads a 3-month window `[firstDay, firstDay+3 months)` once (no repeat calls for already-loaded months) and marks those month keys as loading while it runs;
  - day taps follow the rules in data-model "Availability";
  - a range crossing an unavailable night emits `rangeRejected: true` and restarts with the tapped day as checkIn;
  - a valid range emits `range(StayRange)`;
  - a failed window keeps the months greyed and exposes `retryMonth`.
- [X] T065 [P] [US2] Write `test/features/property/reviews_cubit_test.dart`:
  - first page → ready, or empty when there are no items;
  - `loadMore` appends and stops when `nextCursor == null`;
  - errors → failed with retry.

### Implementation for User Story 2

- [X] T066 [US2] Implement `policyLines` and the `PolicyLine` types in `lib/features/property/domain/policy_text.dart` (makes T062 pass). Then add `String policyLineText(PolicyLine line, AppLocalizations l10n)` in `lib/features/property/presentation/widgets/policy_line_text.dart`, mapping each line to `policyDepositPercent`, `policyDepositFixed`, `policyDepositFull`, `policyFreeCancellation`, `policyAfterDeadline`, or `policyFullyPaidLate` (Appendix A).
- [X] T067 [US2] Implement `PropertyCubit` and its states in `lib/features/property/presentation/property_cubit.dart` (makes T063 pass):
  - **Constructor:** `PropertyCubit({required ListingsRepository repo, required ConnectivityCubit connectivity, required String propertyId, StayRange? initialStay, int? initialGuests})`.
  - **States:** `PropertyLoading`, `PropertyReady {PropertyDetails details; StayRange? stay; int? guests; bool termsUpdatedNotice}`, `PropertyNotAvailable`, `PropertyFailed(ApiError)`, `PropertyOffline`.
  - **`termsUpdatedNotice`:** defaults to `false`; US4 uses it.
- [X] T068 [US2] Implement `AvailabilityCubit` in `lib/features/property/presentation/availability_cubit.dart` (makes T064 pass), using `StayRange.isSelectable`, `CairoTime.today`, and `repo.unavailableNights`. Expose `onStayConfirmed`, a callback passed from the screen that calls `PropertyCubit.setStay`.
- [X] T069 [US2] Implement `ReviewsCubit` in `lib/features/property/presentation/reviews_cubit.dart` (makes T065 pass).
- [X] T070 [P] [US2] Create two components:
  - **`ExpandableText({required String text, required String moreLabel, required String lessLabel, int collapsedLines = 4})`** in `lib/design_system/components/expandable_text.dart`. It shows the toggle only when the text overflows; measure with `TextPainter` in a `LayoutBuilder`.
  - **`BottomActionBar({required Widget leading, required Widget action})`** in `lib/design_system/components/bottom_action_bar.dart`. It has a surface color, a top border in `navBorder`, and `SafeArea(top: false)`, with `leading` expanded at the start and `action` at the end.

  Tests in `test/design_system/components/expandable_text_test.dart` and `bottom_action_bar_test.dart`.
- [X] T071 [US2] Create the details section widgets in `lib/features/property/presentation/widgets/`, each a small `StatelessWidget` class (not a `_buildX()` method):
  - **`property_gallery_header.dart`:**
    - a `PageView` of `OnAirNetworkImage`s at 4:3, with a position indicator «1 / 8» (`l10n.galleryPhotoPosition(current, total)`);
    - the first image uses `heroTag` (`'listing-$id'`) and the `heroVariants` passed from the card when available;
    - tapping opens `/property/:id/gallery?index=n`;
    - a back `IconButton` and an empty `actions` slot (US5 adds Share there);
    - wrapped in `RepaintBoundary`.
  - **`property_title_section.dart`:** the title in `propertyTitle`, the type label from reference data (fall back to the raw key if the reference data is missing), `area • city`, and a `RatingBadge` with `l10n.reviewsCount(count)` only when `reviewCount > 0`.
  - **`property_specs_row.dart`:** bedrooms, bathrooms, max guests, and `areaSqm` (only if not null), each with an icon and its `l10n` plural label.
  - **`property_address_section.dart`:** the section title `l10n.propertyLocation`, `governorate، city، area`, and `addressText` below it. The address line is hidden when null. Text only; **no map, no coordinates** (D-001).
  - **`property_amenities_section.dart`:** a grid of the first 6 amenities (icon + label) and «عرض كل المرافق», which opens a bottom sheet listing all of them. Map amenity `icon` names to `Icons.*` with a small `const` map; unknown names → `Icons.check_circle_outline`.
  - **`property_rules_section.dart`:** check-in and check-out times (`rulesCheckIn(time)`, `rulesCheckOut(time)`), visitors (`rulesVisitorsAllowed(n)`, `rulesVisitorsAllowedNoLimit`, or `rulesVisitorsNotAllowed`), and `houseRules` as plain `Text` inside `ExpandableText` (never rendered as links or HTML).
  - **`property_policy_section.dart`:** a bullet list from `policyLines` + `policyLineText`.
  - **`property_availability_section.dart`:** creates its own `AvailabilityCubit` in `initState`, so it loads only when built. Because it sits inside a lazily built `SliverList`, that happens only when the guest scrolls near it (FR-026). It shows the `RangeCalendar`, the `rangeRejected` message `l10n.calendarRangeInvalid`, and a «تمام» button that confirms the selection into `PropertyCubit.setStay`.
  - **`property_reviews_section.dart`:** uses the `reviews` gradient background (`context.colors.gradient('reviews')`) and shows the latest 3 `ApprovedReview`s (stars, comment, `reviewerShortName`, date via `DateOnlyFormatter.dayMonth`) and «عرض كل التقييمات», which pushes `/property/:id/reviews`. With no reviews: `l10n.reviewsNone`.
- [X] T072 [US2] Create `PropertyScreen` in `lib/features/property/presentation/property_screen.dart`:
  - **Body:** a `CustomScrollView` with the header, then a `SliverList` with a `SliverChildBuilderDelegate` in this order: title, specs, description (`ExpandableText`), amenities, address, rules, policy, availability, reviews, and a «عندك سؤال؟ تواصل مع OnAir» `TextButton` (`l10n.propertyContactOnAir`).
  - **Bottom bar:** `BottomActionBar`:
    - **leading:** `PriceText(price: l10n.nightlyPrice(formatted))`, with the selected dates `dayMonth – dayMonth` as the caption when `stay != null`;
    - **action:** `OnAirPrimaryButton(label: l10n.bookNow)`, disabled while offline.
  - **"Book now", signed in** (`AuthCubit.state is SignedIn`): `context.push(Uri(path: AppRoutes.bookingEntry(id), queryParameters: {if (stay != null) 'checkIn': ..., 'checkOut': ..., if (guests != null) 'guests': '$guests', 'terms': details.termsVersion}).toString())`.
  - **"Book now", visitor (temporary until US4):** push `/auth/login?from=<current location>&cancelTo=<current location>`.
  - **"Contact OnAir":** signed in → push `/support/new?property=<id>`; visitor → the same login push.
  - **States:**

    | State | What shows |
    |---|---|
    | loading | the header with the hero image (from `GoRouterState.extra`, if any) plus `SkeletonBox`es |
    | `PropertyNotAvailable` | the existing `NotAvailableScreen` content |
    | failed | `ErrorView` |
    | offline | `OfflineBanner` with retry |

  - **No owner contact:** there must be no owner phone, email, or chat anywhere.
  - **Results card tap:** update the tap in `lib/features/search/presentation/results_screen.dart` to push `AppRoutes.property(id)` with query `checkIn`, `checkOut` (from `criteria.stay`) and `guests`, and `extra: card.cover?.variants`.
- [X] T073 [US2] Create `GalleryScreen` in `lib/features/property/presentation/gallery_screen.dart`:
  - a full-screen black-free background using `context.colors['background']` in light and `surface` in dark;
  - a `PageView` starting at `?index=`, each page an `InteractiveViewer(minScale: 1, maxScale: 4)` around `OnAirNetworkImage(fit: BoxFit.contain)`;
  - a close `IconButton` with tooltip `l10n.galleryClose`, and a position label with semantics;
  - after each page change, precache **only the next** image with `precacheImage(CachedNetworkImageProvider(url), context)`;
  - images from the cached `PropertyCubit` state when available, otherwise load the details again.
- [X] T074 [US2] Create `ReviewsScreen` in `lib/features/property/presentation/reviews_screen.dart`: a list driven by `ReviewsCubit`, with pagination at 600 px from the end, all states (loading skeletons, empty `reviewsNone`, error, offline), and each review as in T071.
- [X] T075 [US2] Wire the routes in `lib/app/router/app_router.dart`:
  - **Replace `linked-property`** (which pointed at `NotAvailableScreen`) with `GoRoute(path: AppRoutes.propertyPattern)`, building `BlocProvider(create: (_) => PropertyCubit(..., propertyId: id, initialStay: StayRange.tryCreate(DateOnly.tryParse(q['checkIn']), DateOnly.tryParse(q['checkOut']), CairoTime.today()), initialGuests: int.tryParse(q['guests'] ?? ''))..load(), child: PropertyScreen(heroVariants: state.extra as List<ImageVariant>?))`.
  - **`DateOnly.tryParse`:** add it to `date_only.dart` as a `static DateOnly? tryParse(String?)` that returns null on bad input.
  - **Child routes:** add `gallery` and `reviews` as child routes of the property route.
  - **IDs:** every ID is already validated by `routes.dart`; invalid IDs never reach the builder.
- [X] T076 [US2] Write `test/features/property/property_screen_test.dart`:
  - the ready state shows every section title;
  - the price is a single amount and no other money row exists (AC-010);
  - the address row is hidden when `addressText` is null;
  - no text matches «المالك» or a phone pattern (AC-047);
  - "Book now" while signed in pushes the booking entry with `terms`, `checkIn`, `checkOut`, and `guests`;
  - "Book now" is disabled offline;
  - `NOT_FOUND` shows the not-available content;
  - picking a valid range on the calendar updates the bottom-bar caption;
  - an invalid range shows `calendarRangeInvalid`.
- [X] T077 [US2] Write `test/features/property/gallery_and_reviews_test.dart`:
  - the gallery opens at the given index;
  - the close button has a tooltip;
  - reviews paginate;
  - the empty reviews state works.
- [X] T078 [US2] Add `test/features/property/goldens/property_goldens_test.dart` (tag `golden`) for `PropertyScreen` (ready, deposit-percent fixture, with reviews) and the loading state, in Light/Dark × RTL × 1.0/1.3. Generate and commit.
- [X] T079 [US2] Extend `integration_test/discovery_rules_test.dart` (remote only):
  - `guest_get_property` for each unpublished seed ID and for a random UUID throws `AppFailure` with `ErrorCode.notFound` in all cases (AC-003);
  - the raw JSON from `guest_get_property` for a published apartment has none of the keys `base_nightly_price_minor`, `markup`, `latitude`, `longitude`, `owner`, `phone`, `email`. Call the RPC directly through `Supabase.instance.client.rpc` for this check.

**Checkpoint**: US1 and US2 work together in mock mode: search → details → calendar → "Book
now" (signed in) → booking placeholder.

---

## Phase 5: User Story 3 — Get ideas from the Home tab (Priority: P2)

**Goal**: Home shows the greeting, search box, areas, suggested, newest, and (when signed in)
the upcoming booking. Content is cached for instant display and sections fail independently.

**Independent Test**: In mock mode, run quickstart scenarios 1 and 2: per-section skeletons,
area → results, card → details, relaunch in airplane mode shows cached content within 1 s.

### Tests for User Story 3 (write first, must fail)

- [X] T080 [P] [US3] Write `test/features/home/home_feed_cache_test.dart` (temp-dir `JsonFileCache`):
  - `save(feed)` then `load()` returns the public sections;
  - the file content (read as raw JSON) **does not contain** `upcoming_booking` or the booking ID, even when the saved feed had an upcoming booking;
  - the existing `reference` key in the same file is kept after `save`.
- [X] T081 [P] [US3] Write `test/features/home/home_cubit_test.dart`:
  - with a cached feed, the first state is `HomeState(feed: cached, refreshing: true)`, then fresh data replaces it;
  - without a cache, every section starts as loading;
  - a `FeedSectionFailed` section shows only that section as failed;
  - `retrySection(HomeSectionId.suggested)` calls `homeFeed()` again and replaces only that section;
  - `refresh()` reloads everything;
  - when `AuthCubit` emits `SignedOut`, `upcomingBooking` becomes `null` immediately;
  - when `feed.referenceVersion` differs, `ReferenceDataCache.refreshIfVersionChanged` is called;
  - offline with a cache keeps the cache and sets `offline: true`.

### Implementation for User Story 3

- [X] T082 [US3] Implement `HomeFeedCache` in `lib/features/home/data/home_feed_cache.dart`, which makes T080 pass:
  - **Constructor:** `HomeFeedCache(JsonFileCache)`.
  - **`save(HomeFeed)`:** reads the file, sets the key `home` to `feed.toPublicJson()`, keeps `reference`, and writes it back.
  - **`load()`:** returns `HomeFeed.fromPublicJson` or `null`.

  Provide it in `lib/bootstrap.dart` and the test helpers.
- [X] T083 [US3] Implement `HomeCubit` in `lib/features/home/presentation/home_cubit.dart`, which makes T081 pass:
  - **Dependencies:** `ListingsRepository`, `HomeFeedCache`, `ReferenceDataCache`, `ConnectivityCubit`, `AuthCubit`.
  - **State:** `HomeState {HomeFeed? feed; Map<HomeSectionId, bool> sectionLoading; bool refreshing; bool offline; ApiError? fatalError}`, where `enum HomeSectionId {areas, suggested, newest, upcoming}`.
  - **On start:**
    1. Show the cache.
    2. Fetch fresh data.
    3. Save the fresh public sections.
  - **Subscriptions:** subscribe to `AuthCubit.stream` and refetch on `SignedIn`. On `SignedOut`, clear `upcoming`.
  - **`close()`:** cancel the subscriptions.
- [X] T084 [P] [US3] Create `AreaCard({required String title, required String countLabel, required List<ImageVariant> imageVariants, required VoidCallback onTap})` in `lib/design_system/components/area_card.dart`:
  - a 140×170 card with the image filling it;
  - a bottom-to-top scrim: a `LinearGradient` from `context.colors['primaryDark'].withValues(alpha: 0.7)` at the bottom to `context.colors['primaryDark'].withValues(alpha: 0)` at the top. Do not use the VIP tokens; VIP is out of scope;
  - `title` in `areaCardTitle` / `onPrimary`;
  - a badge pill in `badgeNavActive` showing `countLabel` in `areaBadge`.

  Test in `test/design_system/components/area_card_test.dart`, and add it to the discovery golden file from T035.
- [X] T085 [US3] Create the Home widgets in `lib/features/home/presentation/widgets/`:
  - **`home_header.dart`:**
    - the `header` gradient;
    - «أهلًا» (`l10n.homeHello`, `homeWelcome` style) plus the guest's `fullName` in `homeUserName` when `AuthCubit.state is SignedIn` and the name is not null;
    - the notifications bell, keeping the exact G0 behaviour and key `notifications-button` from `home_placeholder_screen.dart`, with no count.
  - **`home_search_box.dart`:** a tappable container styled like a search field, with hint `l10n.homeSearchHint` in `homeSearch` and a search icon. It calls back `onTap`.
  - **`home_section.dart`:**
    - `SectionHeader` plus a child;
    - shows `SkeletonBox`es while loading;
    - shows a compact inline `ErrorView` with retry when failed.
  - **`upcoming_booking_card.dart`:** the title, `dayMonth – dayMonth`, and a text chip «حجز مؤكد» (`l10n.homeUpcomingConfirmed`) using the `successContainer` / `onSuccessContainer` tokens with a check icon (never color alone). Tapping pushes `/bookings/<bookingId>`, which stays a G2 route.
- [X] T086 [US3] Create `HomeScreen` in `lib/features/home/presentation/home_screen.dart`:
  - **Scroll view:** a `RefreshIndicator(onRefresh: cubit.refresh)` around a `CustomScrollView(key: const ValueKey('home-scroll'))`. **Keep this key**, because G0 shell tests use it to check that scroll position is kept.
  - **Sections, in order:** header; search box; upcoming card (only when not null); areas (horizontal `ListView.builder` of `AreaCard`s, label `l10n.areaListingCount`); suggested (horizontal list of `PropertyCard`s, width 260); newest (vertical `SliverList` of `PropertyCard`s).
  - **Taps:**
    - search box → `StatefulNavigationShell.of(context).goBranch(1)`;
    - area → `context.go(Uri(path: AppRoutes.searchResults, queryParameters: {'loc': id}).toString())`;
    - card → `context.push(AppRoutes.property(id), extra: card.cover?.variants)`.
  - **Empty:** when all three public sections are empty lists, show `EmptyView(message: l10n.homeEmpty)` with a button `l10n.homeEmptyAction` that goes to Search.
  - **Offline:** `OfflineBanner` on top when `state.offline`.
- [X] T087 [US3] Wire Home in `lib/app/router/app_router.dart`:
  - replace `HomePlaceholderScreen` with `BlocProvider(create: ... HomeCubit(...)..start(), child: const HomeScreen())` in branch 0;
  - delete `lib/features/home/presentation/home_placeholder_screen.dart`;
  - update the G0 tests that referenced it (search `test/` for `HomePlaceholderScreen` and `home-scroll`), so they still pass with the fake repository.
- [X] T088 [US3] Write `test/features/home/home_screen_test.dart`:
  - each section shows a skeleton while loading;
  - a failed section shows retry, and the others render;
  - the area tap navigates to `/search/results?loc=<id>`;
  - the card tap pushes `/property/<id>`;
  - the signed-in greeting shows the name, and the visitor greeting does not;
  - the upcoming card shows only for a signed-in guest with data;
  - a pre-filled cache plus an offline fake renders content and the offline banner within one frame after `pump()` (SC-004 check);
  - the empty state shows when all sections are empty.
- [X] T089 [US3] Add `test/features/home/goldens/home_goldens_test.dart` (tag `golden`) covering Home ready (visitor), Home ready (signed in with upcoming card), and Home loading, in Light/Dark × RTL × 1.0/1.3. Generate and commit.

**Checkpoint**: US1–US3 work in mock mode; Home is the real entry point.

---

## Phase 6: User Story 4 — Browse as a visitor and continue after signing in (Priority: P2)

**Goal**: A visitor who taps "Book now" or "Contact OnAir" signs in and returns to the same
apartment with the same dates and guests, then the action continues. If the terms changed, the
app shows them again instead of continuing.

**Independent Test**: Quickstart scenarios 10, 11, and 12 in mock mode.

### Tests for User Story 4 (write first, must fail)

- [X] T090 [P] [US4] Write `test/features/property/resume_intent_test.dart` for `ResumeIntent.fromQuery(Map<String,String> q, {required DateOnly today})` (data-model "Navigation intent"; quote the rules):
  - `resume` must be `book` or `contact`, otherwise the result is `null`;
  - `book` requires `terms` (1–128 characters), otherwise `null`;
  - `checkIn`/`checkOut` parse through `StayRange.tryCreate`;
  - `guests` is 1–50;
  - `ResumeIntent.stripFrom(Uri location)` returns the same URI without `resume` and `terms`, keeping `checkIn`, `checkOut`, and `guests`.
- [X] T091 [P] [US4] Write `test/app/router/discovery_resume_test.dart`, using `resolveRedirect` and `resolveAuthCancelDestination` from `lib/app/router/redirect.dart`:
  - `from=/property/<uuid>?checkIn=…&resume=book&terms=t1` is accepted as a safe return location;
  - a signed-out cancel to `/property/<uuid>?…` returns that location (not `/home`);
  - `from=/book/<uuid>/dates` while signed out redirects to login.

  These should pass with G0's code. If any fails, fix `redirect.dart` minimally and explain why in a code comment.

### Implementation for User Story 4

- [X] T092 [US4] Implement `ResumeIntent` and `enum ResumeAction {book, contact}` in `lib/features/property/domain/resume_intent.dart` (makes T090 pass).
- [X] T093 [US4] Update `PropertyScreen` (`lib/features/property/presentation/property_screen.dart`) and `PropertyCubit` for the visitor flow:
  - **(1) Visitor taps "Book now":** build `from = Uri(path: AppRoutes.property(id), queryParameters: {...currentDatesAndGuests, 'resume': 'book', 'terms': details.termsVersion})` and `context.push(Uri(path: AppRoutes.login, queryParameters: {'from': from.toString(), 'cancelTo': <same URI without resume and terms>}).toString())`.
  - **(2) Visitor taps "Contact OnAir":** the same, with `resume=contact` and no `terms`.
  - **(3) Arriving with a resume:** when the screen is built with a `ResumeIntent` (parse it in the route builder from T075 and pass it to `PropertyCubit` as `pendingResume`), then after `load()` succeeds:
    1. call `GoRouter.of(context).replace(ResumeIntent.stripFrom(currentUri).toString())` so Back never re-triggers it;
    2. for `book`, if `details.termsVersion == intent.termsVersion`, push the booking entry exactly as in T072, otherwise emit `termsUpdatedNotice: true`;
    3. for `contact`, push `/support/new?property=<id>`.
  - **(4) Notice:** when `termsUpdatedNotice` is true, show a `MaterialBanner` with `l10n.propertyTermsUpdated` above the content, and scroll to the rules section. The guest must tap "Book now" again.
  - **(5) Not available:** if the load gives `PropertyNotAvailable`, ignore the intent.
  - **Implementation note:** run the navigation in a `BlocListener` (never inside `build`).
- [X] T094 [US4] Write `test/features/property/property_resume_test.dart`:
  - a visitor "Book now" pushes login with the correct `from` and `cancelTo`;
  - a screen opened with `resume=book&terms=t1` and details `termsVersion == 't1'` pushes the booking entry, and the location no longer contains `resume`;
  - with `termsVersion == 't2'`, it does not navigate and shows `propertyTermsUpdated`;
  - `resume=contact` pushes `/support/new?property=<id>`;
  - `NOT_FOUND` ignores the intent.
- [X] T095 [US4] Create `integration_test/discovery_journey_test.dart`. It runs in **mock** mode by default and also in remote mode when `env/staging.json` sets `BACKEND_MODE=remote` and test credentials exist in the git-ignored `env/staging_seed.json`. The journey:
  1. Start as a visitor.
  2. Open Search, pick guests 2, choose dates, and search.
  3. Open the first result.
  4. Tap "Book now", and sign in with the mock phone flow (code `123456`, from `MockBackend.verificationCode`).
  5. Expect the booking placeholder with the same dates and guests.
  6. Go back, then tap "Book now" again and cancel sign-in (repeat as a visitor): expect the same apartment.

**Checkpoint**: Visitor resume works end to end in mock mode (SC-007).

---

## Phase 7: User Story 5 — Share an apartment or a search (Priority: P3)

**Goal**: Guests share apartment and search links; opening them lands on the right screen.

**Independent Test**: Quickstart scenarios 13 and 14 (adb links on Android, or the widget tests
below in CI).

### Tests for User Story 5 (write first, must fail)

- [X] T096 [P] [US5] Extend `test/app/router/link_parser_test.dart`:
  - `https://<domain>/search/results?g=2&in=2026-11-20&out=2026-11-23&evil=1` → `/search/results?g=2&in=2026-11-20&out=2026-11-23` (only the whitelisted keys `loc,in,out,g,pmin,pmax,bed,bath,am,type,sort` are kept; the order follows canonical sorting);
  - `https://<domain>/property/<uuid>?resume=book&terms=x` → `/property/<uuid>` (**all** query parameters removed);
  - other linkable paths still drop every query parameter;
  - a wrong host, `http`, or user-info → `/not-available`.
- [X] T097 [P] [US5] Write `test/core/share/share_service_test.dart`:
  - `ShareLinks(linkDomain: 'onair.test').property('<uuid>')` == `https://onair.test/property/<uuid>`;
  - `ShareLinks.search(criteria)` == `https://onair.test/search/results?<criteria.toQuery() encoded>` and never contains the location label;
  - a `FakeShareService` records the text passed to `share`.

### Implementation for User Story 5

- [X] T098 [US5] Update `LinkParser.parse` in `lib/app/router/link_parser.dart` (makes T096 pass): when `link.path == AppRoutes.searchResults`, keep only the whitelisted query keys, sorted alphabetically; every other path keeps `Uri(path: link.path)` as today. Do not import `features/` into `lib/app/router/link_parser.dart`: define the whitelist as a `const Set<String>` in that file, with a comment pointing to `SearchCriteria`.
- [X] T099 [US5] Create `lib/core/share/share_service.dart`:
  - `abstract interface class ShareService { Future<void> share(String text); }`;
  - `final class SharePlusShareService implements ShareService` using `share_plus` (`SharePlus.instance.share(ShareParams(text: text))`, or the API of the installed version);
  - `final class ShareLinks { const ShareLinks({required String linkDomain}); String property(String id); String search(Map<String,String> query); }`.

  Provide `ShareService` and `ShareLinks(linkDomain: environment.linkDomain)` in `lib/bootstrap.dart`, and fakes in the test helpers (`test/helpers/fake_share_service.dart`). This makes T097 pass.
- [X] T100 [US5] Add a Share `IconButton` (`Icons.share_outlined`, tooltip `l10n.propertyShare`) to the `actions` slot of `property_gallery_header.dart`. On tap: `shareService.share('${details.title}\n${shareLinks.property(details.id)}')`. Disable it while offline.
- [X] T101 [US5] Add a share action to the `ResultsScreen` app bar in `lib/features/search/presentation/results_screen.dart` (tooltip `l10n.searchShare`). On tap: `shareService.share('${l10n.shareSearchText}\n${shareLinks.search(state.criteria.toQuery())}')`.
- [X] T102 [US5] Write `test/app/router/discovery_links_test.dart` using `IncomingLinks` with a fake `UriLinkSource` and the test harness:
  - a property link opens `PropertyScreen` for that ID as a visitor;
  - a search link opens `ResultsScreen` with matching criteria;
  - a search link with past dates shows the `searchDatesDropped` banner;
  - a property link with a non-UUID ID, and one with a random UUID (`NOT_FOUND` from the fake), both show the not-available content;
  - a property link carrying `resume=book` does **not** navigate to the booking entry.

**Checkpoint**: All five stories work in mock mode.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T103 Run `bash tool/check_hardcoded_styles.sh` and fix every hit in G1 files, by moving values into `lib/design_system/` tokens and components.
- [ ] T104 [P] Accessibility pass. With the Flutter semantics debugger (`showSemanticsDebugger: true` in a temporary local run), check Home, Search, Results, Details, Gallery, and Reviews:
  - every icon button has a label;
  - focus order runs right to left;
  - field errors are announced.

  Fix any issues. Create `docs/qa/g1-accessibility.md` with a table (screen, TalkBack result, VoiceOver result, notes) for the manual pass in quickstart scenario 17, leaving the result cells for the tester.
- [ ] T105 [P] Create `test_driver/perf_driver.dart`, which uses `integrationDriver` with `responseDataCallback` and writes the `traceAction` timeline summary to `build/perf/`. Create `integration_test/results_scroll_perf_test.dart`:
  - mock mode with 120 fixture apartments;
  - open results with no criteria;
  - `binding.traceAction` around flinging the list down 10 times, with `reportKey: 'results_scroll'`.

  Document the run command in `docs/perf/g1-results-scroll.md` with empty result fields for the device run.
- [ ] T106 [P] Measure the app size: build `flutter build apk --flavor production -t lib/main_production.dart --split-per-abi --release --dart-define-from-file=env/example.json` (or the CI equivalent) before and after G1. Record the per-ABI sizes and the delta from `cached_network_image` / `share_plus` in `docs/perf/g1-size.md`.
- [ ] T107 Update `docs/OnAir Guest App Plan.md` §17 G1: tick each implemented item, and add a short status note under G1 in the same style as the G0 note. Say that Remote mode waits for the 7 `guest_*` RPCs in the registry, the D-001 address field, and the link-domain store fallback.
- [ ] T108 Run the full gates and fix any failure:
  1. `dart format --set-exit-if-changed .`
  2. `flutter analyze`
  3. `flutter test`
  4. `flutter test --tags golden`
  5. `bash tool/check_hardcoded_styles.sh`

  Then walk through quickstart scenarios 1–16 in mock mode on an Android emulator. Note any scenario that cannot run in mock mode.
- [ ] T109 Write the PR description in `specs/002-guest-discovery/pr-description.md`, with the Definition of Done checklist from the constitution (Development Workflow → Definition of Done) ticked item by item with evidence (test file names), plus the list of backend and link-domain dependencies still open.

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)** → **Foundational (Phase 2)** → user stories (Phases 3–7) → **Polish (Phase 8)**.
- Foundational blocks every story. Inside Phase 2, the "Tests first" tasks (T006–T015) come
  before their implementations (T016–T029).

### User story dependencies

- **US1 (P1)**: after Foundational. No story dependency.
- **US2 (P1)**: after Foundational. Testable alone through a direct `/property/<id>` route.
  T072 also edits `results_screen.dart` (the card tap), so run it after T055 if US1 is in
  progress.
- **US3 (P2)**: after Foundational. Taps navigate to US1/US2 routes; those still open the G0
  not-available screen if US1/US2 are not done, which is acceptable for testing US3 alone.
- **US4 (P2)**: after US2 (it changes `property_screen.dart` and `property_cubit.dart`).
- **US5 (P3)**: after US1 (search link) and US2 (property share button).

### Shared files (never mark tasks on these as parallel with each other)

`lib/app/router/app_router.dart` (T037, T056, T075, T087), `lib/app/router/routes.dart`
(T036), `lib/bootstrap.dart` (T038, T045, T082, T099), `test/helpers/pump_app.dart` and
`test/app/test_app_harness.dart` (T038, T045, T082, T099),
`lib/features/search/presentation/results_screen.dart` (T055, T072, T101),
`lib/features/property/presentation/property_screen.dart` (T072, T093),
`lib/features/property/presentation/widgets/property_gallery_header.dart` (T071, T100),
`lib/l10n/app_ar.arb` / `app_en.arb` (T004 only; if a later task needs a new key, add it in
that task and run `flutter gen-l10n`),
`test/design_system/goldens/discovery_components_golden_test.dart` (T035, T084).

### Within each story

Tests first (they must fail) → domain → Cubits → widgets → screen → routes → widget tests →
goldens → integration.

---

## Parallel Examples

### Phase 2

```text
Tests (all parallel): T006 · T007 · T008 · T009 · T010 · T011 · T012 · T013 · T014 · T015
Step 1 (parallel):    T016 DateOnly helpers · T018 image types · T019 JsonFileCache · T020 errors
Step 2:               T017 StayRange (needs T016)
Step 3 (parallel):    T021 · T022 · T023 · T024 (models) · T030 · T031 · T032 · T033 · T034 (components)
Step 4 (in order):    T025 → T026 → T027 → T028 → T029 → T035 → T036 → T037 → T038
```

### User Story 1

```text
T039 · T040 · T041 · T042 · T043 (tests)   then   T049 CounterStepper · T050 FilterChipBar
```

### User Story 2

```text
T062 · T063 · T064 · T065 (tests)   then   T070 ExpandableText/BottomActionBar
```

### Across stories (after Phase 2, with separate implementers)

```text
Implementer A: US1 (T039–T061)
Implementer B: US2 (T062–T071, then T072 after T055) → US4
Implementer C: US3 (T080–T089)
US5 after US1 + US2.
```

---

## Implementation Strategy

### MVP first (US1 + US2)

1. Phase 1 + Phase 2.
2. US1 (search) → validate scenarios 3, 4, 6, 7.
3. US2 (details) → validate scenarios 8, 9, 14.
4. **Stop and demo**: search → details → "Book now" (signed in) in mock mode.

### Incremental delivery

5. US3 Home → scenarios 1–2.
6. US4 visitor resume → scenarios 10–12.
7. US5 sharing → scenarios 13–14.
8. Polish → full gates, accessibility, perf, size, plan update.

### Remote mode

Remote mode needs the backend owner to deploy the 7 RPCs (`contracts/supabase-discovery.md`)
and the Staging seed. Until then everything is built and tested in mock mode. Run T061, T079, and
T095 (remote) when Staging is ready.

---

## Appendix A: ARB keys for T004

Add each key to `app_ar.arb` (Arabic) and `app_en.arb` (English). Placeholders: `{name}` type
`String` unless marked `int`. Keep the ICU plural forms exactly.

| Key | Arabic (app_ar.arb) | English (app_en.arb) | Placeholders |
|---|---|---|---|
| `homeHello` | أهلًا | Hello | — |
| `homeSearchHint` | دوّر على شقة: المكان، التاريخ، الضيوف | Find a place: where, when, who | — |
| `homeAreasTitle` | مناطق ووجهات | Areas and destinations | — |
| `homeSuggestedTitle` | شقق مقترحة | Suggested apartments | — |
| `homeNewestTitle` | أحدث الشقق | Newest apartments | — |
| `homeUpcomingTitle` | حجزك الجاي | Your next booking | — |
| `homeUpcomingConfirmed` | حجز مؤكد | Confirmed | — |
| `homeEmpty` | مفيش شقق متاحة دلوقتي. | No apartments are available right now. | — |
| `homeEmptyAction` | ابحث عن شقة | Search for an apartment | — |
| `areaListingCount` | `{count, plural, =0{مفيش شقق} =1{شقة واحدة} =2{شقتين} few{{count} شقق} many{{count} شقة} other{{count} شقة}}` | `{count, plural, =0{No apartments} =1{1 apartment} other{{count} apartments}}` | `count` int |
| `searchTitle` | البحث | Search | — |
| `searchLocationLabel` | المكان | Location | — |
| `searchLocationHint` | محافظة، مدينة أو منطقة | Governorate, city, or area | — |
| `searchAnyLocation` | كل الأماكن | All locations | — |
| `searchNoLocationMatches` | مفيش أماكن بالاسم ده. | No places match that name. | — |
| `searchDatesLabel` | التواريخ | Dates | — |
| `searchDatesHint` | الوصول والمغادرة | Arrival and departure | — |
| `searchGuestsLabel` | عدد الضيوف | Guests | — |
| `searchGuestsAny` | أي عدد | Any | — |
| `searchAction` | ابحث | Search | — |
| `searchFilters` | الفلاتر | Filters | — |
| `searchClearAll` | مسح الكل | Clear all | — |
| `searchShowResults` | `{count, plural, =0{مفيش نتايج} =1{عرض نتيجة واحدة} =2{عرض نتيجتين} other{عرض {count} نتيجة}}` | `{count, plural, =0{No results} =1{Show 1 result} other{Show {count} results}}` | `count` int |
| `searchShowResultsUnknown` | عرض النتايج | Show results | — |
| `searchPriceRange` | سعر الليلة | Nightly price | — |
| `searchMinBedrooms` | أقل عدد غرف | Minimum bedrooms | — |
| `searchMinBathrooms` | أقل عدد حمامات | Minimum bathrooms | — |
| `searchAnyCount` | أي عدد | Any | — |
| `searchAmenities` | المرافق والمميزات | Amenities | — |
| `searchPropertyType` | نوع العقار | Property type | — |
| `searchSort` | الترتيب | Sort | — |
| `sortPriceAsc` | السعر: من الأقل | Price: low to high | — |
| `sortPriceDesc` | السعر: من الأعلى | Price: high to low | — |
| `sortNewest` | الأحدث | Newest | — |
| `searchNoResults` | مفيش شقق متاحة بالمعايير دي. | No apartments are available for these criteria. | — |
| `searchNoResultsHint` | جرّب تغيّر التواريخ أو الفلاتر. | Try changing the dates or filters. | — |
| `searchDatesNeededHint` | اختار التواريخ عشان تقدر تحجز. | Choose dates to be able to book. | — |
| `searchDatesDropped` | التواريخ اللي في الرابط فاتت. اختار تواريخ جديدة. | The dates in the link have passed. Choose new dates. | — |
| `searchChooseDates` | اختار التواريخ | Choose dates | — |
| `searchShare` | مشاركة البحث | Share search | — |
| `shareSearchText` | بحث على OnAir | Search on OnAir | — |
| `nightlyPrice` | {price} / الليلة | {price} / night | `price` |
| `stayTotal` | `{nights, plural, =1{إجمالي ليلة واحدة: {total}} =2{إجمالي ليلتين: {total}} few{إجمالي {nights} ليالي: {total}} other{إجمالي {nights} ليلة: {total}}}` | `{nights, plural, =1{Total for 1 night: {total}} other{Total for {nights} nights: {total}}}` | `nights` int, `total` |
| `filterChipRemove` | شيل فلتر {label} | Remove filter {label} | `label` |
| `bedroomsAtLeast` | {count}+ غرف | {count}+ bedrooms | `count` int |
| `bathroomsAtLeast` | {count}+ حمامات | {count}+ bathrooms | `count` int |
| `priceRangeChip` | {min} – {max} | {min} – {max} | `min`, `max` |
| `guestsDecrease` | قلّل عدد الضيوف | Fewer guests | — |
| `guestsIncrease` | زوّد عدد الضيوف | More guests | — |
| `countDecrease` | قلّل | Decrease | — |
| `countIncrease` | زوّد | Increase | — |
| `calendarConfirm` | تمام | Done | — |
| `calendarClear` | مسح | Clear | — |
| `calendarPrevMonth` | الشهر اللي فات | Previous month | — |
| `calendarNextMonth` | الشهر الجاي | Next month | — |
| `calendarRangeInvalid` | الفترة دي فيها ليالي مش متاحة. | This range includes unavailable nights. | — |
| `calendarNightsSelected` | `{count, plural, =1{ليلة واحدة} =2{ليلتين} few{{count} ليالي} other{{count} ليلة}}` | `{count, plural, =1{1 night} other{{count} nights}}` | `count` int |
| `calendarUnavailableDay` | {date}، مش متاح | {date}, unavailable | `date` |
| `propertyBedrooms` | `{count, plural, =1{غرفة واحدة} =2{غرفتين} few{{count} غرف} other{{count} غرفة}}` | `{count, plural, =1{1 bedroom} other{{count} bedrooms}}` | `count` int |
| `propertyBathrooms` | `{count, plural, =1{حمام واحد} =2{حمامين} few{{count} حمامات} other{{count} حمام}}` | `{count, plural, =1{1 bathroom} other{{count} bathrooms}}` | `count` int |
| `propertyMaxGuests` | لحد {count} ضيوف | Up to {count} guests | `count` int |
| `propertyArea` | {sqm} م² | {sqm} m² | `sqm` int |
| `propertyDescription` | الوصف | Description | — |
| `showMore` | عرض المزيد | Show more | — |
| `showLess` | عرض أقل | Show less | — |
| `propertyAmenities` | المرافق | Amenities | — |
| `propertySeeAllAmenities` | عرض كل المرافق | See all amenities | — |
| `propertyLocation` | الموقع | Location | — |
| `propertyRules` | قواعد الإقامة | Stay rules | — |
| `rulesCheckIn` | الاستلام من {time} | Check-in from {time} | `time` |
| `rulesCheckOut` | المغادرة لحد {time} | Check-out by {time} | `time` |
| `rulesVisitorsAllowed` | الزوار مسموحين (لحد {count}) | Visitors allowed (up to {count}) | `count` int |
| `rulesVisitorsAllowedNoLimit` | الزوار مسموحين | Visitors allowed | — |
| `rulesVisitorsNotAllowed` | الزوار مش مسموحين | Visitors not allowed | — |
| `propertyPolicy` | العربون والإلغاء | Deposit and cancellation | — |
| `policyDepositPercent` | العربون {percent}% من إجمالي الحجز. | The deposit is {percent}% of the booking total. | `percent` |
| `policyDepositFixed` | العربون {amount}. | The deposit is {amount}. | `amount` |
| `policyDepositFull` | الحجز ده بيتدفع بالكامل مقدمًا. | This booking is paid in full upfront. | — |
| `policyFreeCancellation` | الإلغاء مجاني لحد {hours} ساعة قبل ميعاد الاستلام، وبيرجعلك المبلغ كامل. | Free cancellation up to {hours} hours before check-in, with a full refund. | `hours` int |
| `policyAfterDeadline` | لو لغيت بعد الميعاد ده وقبل الإقامة، بتخسر العربون بس ويرجعلك الباقي. | If you cancel after that and before the stay, you lose only the deposit and get the rest back. | — |
| `policyFullyPaidLate` | لو الحجز مدفوع بالكامل وألغيته بعد 24 ساعة من ميعاد الاستلام، المبلغ مش بيرجع. | If the booking is fully paid and you cancel more than 24 hours after check-in time, it is not refundable. | — |
| `propertyAvailability` | التوافر | Availability | — |
| `propertyReviews` | التقييمات | Reviews | — |
| `reviewsCount` | `{count, plural, =1{تقييم واحد} =2{تقييمين} few{{count} تقييمات} other{{count} تقييم}}` | `{count, plural, =1{1 review} other{{count} reviews}}` | `count` int |
| `reviewsNone` | لسه مفيش تقييمات. | No reviews yet. | — |
| `reviewsSeeAll` | عرض كل التقييمات | See all reviews | — |
| `ratingSemantics` | التقييم {rating} من 5، {count} تقييم | Rated {rating} out of 5, {count} reviews | `rating`, `count` int |
| `propertyContactOnAir` | عندك سؤال؟ تواصل مع OnAir | Have a question? Contact OnAir | — |
| `bookNow` | احجز الآن | Book now | — |
| `propertyTermsUpdated` | الشروط اتحدّثت. راجعها قبل ما تحجز. | The terms were updated. Review them before booking. | — |
| `propertyShare` | مشاركة | Share | — |
| `galleryOpen` | افتح الصور | Open photos | — |
| `galleryClose` | إغلاق | Close | — |
| `galleryPhotoPosition` | صورة {current} من {total} | Photo {current} of {total} | `current` int, `total` int |
| `bookingEntryTitle` | الحجز | Booking | — |
| `bookingEntryComingSoon` | الحجز من التطبيق هيتفتح قريب. | Booking in the app opens soon. | — |
| `bookingEntryTermsCarried` | الشروط اللي شفتها اتسجّلت مع الطلب. | The terms you saw are attached to this request. | — |
| `supportEntryTitle` | تواصل مع OnAir | Contact OnAir | — |
| `supportEntryComingSoon` | خدمة الدعم من التطبيق هتتفتح قريب. | Support in the app opens soon. | — |

---

## Appendix B: Mock fixture dataset for T026

Create these files in `lib/features/listings/data/fixtures/`. Every apartment uses a real
UUID v4 `id`, plus a readable `_fixture_name` and a `_published` flag. These are mock-only
fields; the models ignore them.

**`locations.json`** — array of `LocationSuggestion` JSON plus `parent_id`:
- 3 governorates: «القاهرة», «الجيزة», «الإسكندرية».
- 4 cities: «القاهرة الجديدة», «مدينة نصر», «الشيخ زايد», «العجمي».
- 6 areas: «التجمع الخامس», «الرحاب», «الحي العاشر», «بيفرلي هيلز», «البيطاش», «الهانوفيل».
- `listing_count` must equal the number of published apartments under each location.

**`reference.json`** — `guest_get_reference_data` shape:
- `version: "mock-ref-1"`;
- 10 amenities: `wifi`, `ac`, `kitchen`, `washer`, `parking`, `pool`, `elevator`, `tv`, `balcony`, `sea_view`;
- property types `apartment`, `studio`, `villa`, `chalet`, `room` with Arabic labels;
- `price_bounds` computed from the published apartments;
- `price_step_minor: 5000`.

**`properties.json`** — array of full `guest_get_property` objects, each with extra mock fields:
- `_fixture_name`;
- `_published` (bool);
- `_location_ids` (the area plus its city and governorate);
- `_created_at` (ISO date, for "newest");
- `_booked`, `_held`, `_blocked` (arrays of `YYYY-MM-DD` nights);
- `_amenity_keys`.

Required apartments:

| `_fixture_name` | `_published` | Notes |
|---|---|---|
| `prop-deposit-percent` | true | `deposit_type: percent`, `deposit_percent_bp: 2500`, `free_cancellation_hours: 72`; 6 images; 5 approved reviews (latest 3 embedded); address set |
| `prop-deposit-fixed` | true | `deposit_type: fixed`, `deposit_amount_minor: 100000`; 1 image; no reviews (`rating_avg: null`, `review_count: 0`) |
| `prop-full-payment` | true | `deposit_type: full`; `address_text: null` |
| `prop-busy` | true | Booked night = today+10, held night = today+12, blocked night = today+14. Store them as `_busy_offsets` (see "Fixture clock" below), not as fixed dates |
| `prop-draft` | false | Must never appear |
| `prop-paused` | false | Must never appear |
| `prop-rejected` | false | Must never appear |
| `prop-unapproved-workspace` | false | Must never appear |
| `prop-generic-001` … `prop-generic-120` | true | Generated variety: prices 50,000–1,500,000 piasters; bedrooms 1–5; spread over the 6 areas; mixed amenities and types; for scroll and pagination tests (you may generate them with a small Dart script under `tool/` and commit the output) |

**`reviews.json`** — map of property ID → array of reviews, each with `status` (`approved`,
`pending`, or `rejected`; the mock returns only `approved`) and `reviewer_short_name`. Include
≥ 25 approved reviews for `prop-deposit-percent` (to test pagination) plus 2 pending and 1
rejected.

**`home_feed.json`** — `guest_home_feed` shape:
- `reference_version: "mock-ref-1"`;
- 6 areas;
- 10 suggested (published only);
- 10 newest (published, by `_created_at`);
- `upcoming_booking`: `{"status":"ready","item":null}`. The mock returns a sample upcoming booking only when the mock auth user is signed in.

**Fixture clock**: the mock treats "today" as the real `CairoTime.today()`. Store the busy-night
dates as **offsets** in a `_busy_offsets` field (`{"booked":[10],"held":[12],"blocked":[14]}`),
and let `MockListingsRepository` convert them to real dates at load time, so the tests never
expire.
