# Data Model: Guest Discovery (G1)

App-side entities. JSON field names follow the RPC contracts in
[contracts/supabase-discovery.md](contracts/supabase-discovery.md) (snake_case on the wire,
camelCase in Dart). All models are immutable, hand-written `final class`es with a `fromJson`
factory and value equality, the same style as G0's `lib/core/config/app_config.dart`. Money is
always `Money` (int piasters + `EGP`). Stay dates are always `DateOnly`.

**Where models live**: every server-backed model below (listings, home feed, property details,
reviews, results) is in `lib/features/listings/domain/`. Home, Search, and Property import
them from there and never from each other. Only `SearchCriteria` / `LastSearch`
(`features/search/domain/`), the policy text builder, and `ResumeIntent`
(`features/property/domain/`) live in their own feature.

## Shared value objects (`lib/core/`)

### StayRange (`core/time/stay_range.dart`) — test-first

| Field | Type | Rule |
|---|---|---|
| `checkIn` | `DateOnly` | Not before today in `Africa/Cairo` |
| `checkOut` | `DateOnly` | After `checkIn` |
| `nights` | `int` (derived) | `checkOut − checkIn` in days; ≥ 1. **For display and validation only, never for money.** |

Helpers:
- `nightsIterable()` yields each night `checkIn … checkOut−1`.
- `isSelectable(Set<DateOnly> unavailableNights)` is true when no night is in the set. The
  departure day itself may be in the set.
- `tryCreate(in, out, today)` returns `null` instead of throwing, for link and query parsing.

### ImageVariants (`core/images/image_variants.dart`) — test-first

`pick(List<ImageVariant> variants, double logicalWidth, double devicePixelRatio)` returns the
smallest variant with `width ≥ logicalWidth × dpr`, or the widest if none qualifies. An empty
list returns `null`, and the caller shows the placeholder.

## Listings (`features/listings/domain/`)

### ListingImage

| Field | Type | Notes |
|---|---|---|
| `variants` | `List<ImageVariant>` | `ImageVariant { int width; Uri url }`, sorted by width; at least one |
| `blurhash` | `String?` | Optional placeholder from the server |

### ListingCard

The short form used by Home and Results.

| Field | Type | Notes |
|---|---|---|
| `id` | `String` (UUID v4) | Property ID |
| `title` | `String` | From the approved version |
| `propertyType` | `String` | Enum key; label from reference data |
| `areaName` | `String` | Area name, as returned |
| `cityName` | `String` | City name, as returned |
| `cover` | `ListingImage?` | Cover photo, or the first by order |
| `nightlyPrice` | `Money` | Final price (base + margin, from the server) |
| `ratingAvg` | `double?` | Null when `reviewCount == 0` |
| `reviewCount` | `int` | Approved reviews only |
| `stay` | `CardStay?` | Present only when the request had dates |

`CardStay { int nights; Money stayTotal; }` holds the server values, shown as "total for X
nights".

### LocationSuggestion

| Field | Type | Notes |
|---|---|---|
| `id` | `String` (UUID) | `locations.id` |
| `level` | `governorate` \| `city` \| `area` | |
| `name` | `String` | Localized name (Arabic now) |
| `parentLabel` | `String?` | For example "القاهرة" under an area |
| `listingCount` | `int` | Published apartments inside it |

### ReferenceData (cached; refreshed when `version` changes)

| Field | Type | Notes |
|---|---|---|
| `version` | `String` | Compared with `HomeFeed.referenceVersion` |
| `amenities` | `List<Amenity>` | `Amenity { String key; String label; String? icon }`. `icon` is a Material Symbols name; unknown names fall back to a generic icon |
| `propertyTypes` | `List<PropertyTypeOption>` | `{ String key; String label }` |
| `priceBounds` | `(Money min, Money max)` | Final nightly prices over published apartments |
| `priceStep` | `Money` | Fallback 5,000 piasters when absent (research R7) |

## Home (`features/home/domain/`)

### HomeFeed

| Field | Type | Cached on disk? |
|---|---|---|
| `referenceVersion` | `String` | yes |
| `areas` | `Section<List<AreaTile>>` | yes |
| `suggested` | `Section<List<ListingCard>>` | yes |
| `newest` | `Section<List<ListingCard>>` | yes |
| `upcomingBooking` | `Section<UpcomingBookingCard?>` | **no**, personal; signed-in only |
| `fetchedAt` | `DateTime` (UTC) | yes |

- `Section<T>` is either `ready(T)` or `failed(errorCode, requestId)`. The server marks a
  failed section instead of failing the whole feed.
- `AreaTile { String locationId; String name; int listingCount; ListingImage? image }`.
- `UpcomingBookingCard { String bookingId; String propertyTitle; DateOnly checkIn;
  DateOnly checkOut; String status }`. `status` is a server status key, shown with G0's
  status-chip mapping when it exists. It is `null` until G2 data exists.

**Disk cache document** (`JsonFileCache`, file `discovery_cache.json`):
`{ "schema": 1, "home": {...public sections...}, "reference": {...ReferenceData...} }`.
- A `schema` mismatch discards the file.
- Write failures are logged (no PII) and ignored.
- The file is not removed at sign-out, because it holds only public data.

## Search (`features/search/domain/`)

### SearchCriteria — test-first (one codec for link, route, and last search)

| Field | Type | Query key | Validation (invalid → field dropped) |
|---|---|---|---|
| `locationId` | `String?` | `loc` | UUID v4 |
| `locationLabel` | `String?` | — | Display only; never in links (re-resolved from the server when needed) |
| `stay` | `StayRange?` | `in`, `out` | `YYYY-MM-DD`; past or inverted drops **both** and sets `datesDropped = true` |
| `guests` | `int?` | `g` | 1–50 |
| `priceMin` / `priceMax` | `Money?` | `pmin`, `pmax` | ≥ 0; when min > max, they are swapped |
| `minBedrooms` / `minBathrooms` | `int?` | `bed`, `bath` | 0–20 |
| `amenityKeys` | `Set<String>` | `am` (comma) | `[a-z0-9_]{1,40}`, at most 30 |
| `propertyTypes` | `Set<String>` | `type` (comma) | Same as amenity keys |
| `sort` | `SearchSort?` | `sort` | `price_asc` \| `price_desc` \| `newest`; `null` means the server default |

Rules:
- Every field is optional (Clarification 1). An empty criteria object means "all published
  apartments".
- Unknown query keys are ignored. Encoding is canonical: keys are sorted and empty fields are
  left out, so equal criteria give equal URLs.
- `activeFilterChips` lists the removable chips: price, bedrooms, bathrooms, each amenity, and
  each type. Location, dates, and guests are shown in the search summary bar, not as chips.

### ResultsPage

`{ List<ListingCard> items; String? nextCursor; int totalCount; }`. A null `nextCursor` means
the end of the list.

### LastSearch

`SearchCriteria` stored as its query string under the `shared_preferences` key
`last_search_v1`, together with `locationLabel`. Only search fields are stored, never personal
data.

## Property (`features/property/domain/`)

### PropertyDetails

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | |
| `title`, `description` | `String` | Description is expandable |
| `propertyType` | `String` | |
| `areaName`, `cityName`, `governorateName` | `String` | |
| `addressText` | `String?` | Public (D-001). The row is hidden when null. No coordinates exist in the model |
| `images` | `List<ListingImage>` | Ordered, cover first |
| `bedrooms`, `bathrooms`, `maxGuests` | `int` | |
| `areaSqm` | `int?` | |
| `amenities` | `List<Amenity>` | |
| `rules` | `StayRules` | |
| `policy` | `PolicySummary` | |
| `nightlyPrice` | `Money` | Final price only |
| `ratingAvg` / `reviewCount` | `double?` / `int` | Approved only |
| `latestReviews` | `List<ApprovedReview>` | Up to 3 |
| `termsVersion` | `String` | Opaque. Carried by "Book now" (AC-013) |

### StayRules

`{ String checkInTime; String checkOutTime; bool visitorsAllowed; int? maxVisitors;
String? houseRules; }`.
- Times are `HH:mm` local time at the apartment, shown as Cairo time.
- `houseRules` is owner text from the approved version, shown as plain text and never as HTML
  or links.

### PolicySummary

From `private.resolve_booking_terms`, shape per registry `booking_policies`.

| Field | Type | Notes |
|---|---|---|
| `depositType` | `percent` \| `fixed` \| `full` | |
| `depositPercentBp` | `int?` | When `percent`, in basis points (2500 = 25%). Unit to be confirmed by the backend owner |
| `depositAmount` | `Money?` | When `fixed` |
| `freeCancellationHours` | `int` | Hours before scheduled check-in |

Display: fixed localized sentences built from these fields and the approved rules in Master
Plan §7.2.
- **Before the deadline**: full refund under the saved policy.
- **After the deadline, before the stay**: only the deposit is lost.
- **Fully paid, more than 24 h after scheduled check-in**: non-refundable.

No amounts are computed, since no dates or quote exist yet; percentages and fixed amounts are
shown as received.

### Availability (calendar)

| Field | Type | Notes |
|---|---|---|
| `windows` | `Map<YearMonth, Set<DateOnly>>` | Unavailable **nights** per loaded month |
| `loading` | `Set<YearMonth>` | Months being fetched; shown greyed |
| `selection` | `CalendarSelection` | `none` → `arrivalPicked(DateOnly)` → `range(StayRange)` |

- Months are fetched in windows of 3 (`guest_get_property_unavailable_dates(id, from, to)`).
  The server may cap the range; days it reports as unavailable stay unavailable.
- Picking a range runs `StayRange.isSelectable`. A range crossing an unavailable night is
  rejected with a short inline message, and the selection resets to the tapped day as the new
  arrival.
- A confirmed `range` replaces the search dates in the property screen state and in the bottom
  bar (FR-022).

### ApprovedReview / ReviewsPage

- `ApprovedReview { String id; int rating (1–5); String? comment; DateOnly createdOn;
  String reviewerShortName; }`. The short name is formatted on the server.
- `ReviewsPage { List<ApprovedReview> items; String? nextCursor; }`.

## Navigation intent (`features/property/domain/resume_intent.dart`) — test-first

| Field | Query key | Rule |
|---|---|---|
| `action` | `resume` | `book` \| `contact`; anything else is ignored |
| `stay` | `checkIn`, `checkOut` | Parsed with `StayRange.tryCreate` |
| `guests` | `guests` | 1–50 |
| `termsVersion` | `terms` | Opaque string, at most 128 characters; required for `book` |

Consumed once: the screen replaces its location without `resume` before acting. For `book`, it
continues only if the freshly loaded `termsVersion` equals the carried one; otherwise it shows
the "terms updated" notice (research R10).

## Presentation state (Cubits)

| Cubit | Scope | States |
|---|---|---|
| `HomeCubit` | Home branch | `cached(feed) \| loading(feed?)`. Each section `loading \| ready \| failed`; refresh and retry per section |
| `SearchCubit` | Search branch (survives tab switches and details round-trips) | `criteria`, `results: idle \| loading \| ready(pages, scrollKey) \| empty \| failed(error)`, `loadingMore`, `offline` |
| `LocationSuggestCubit` | Search form | `idle \| loading(query) \| ready(query, items) \| failed`, with stale responses dropped by sequence |
| `FiltersCountCubit` | Filters sheet | `counting \| count(int) \| failed`, debounced ~400 ms |
| `PropertyCubit` | `/property/:id` route | `loading(heroImage?) \| ready(details, stayOverride?, guests?) \| notAvailable \| failed(error) \| offline` |
| `AvailabilityCubit` | Calendar section (lazy) | see Availability above |
| `ReviewsCubit` | `/property/:id/reviews` | `loading \| ready(pages) \| empty \| failed`, plus `loadingMore` |

`close()` on every Cubit cancels debouncers and timers and drops in-flight results.
