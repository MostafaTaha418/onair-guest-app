# Phase 1 Data Model: Guest Favorites & Reviews (G5)

App-side domain only. Database objects live in `onair-backend` (contracts/supabase-reviews.md). Money is
not involved. Dates are date-only; timestamps from the server are UTC ISO-8601.

## New entities (features/reviews/domain)

### GuestReview

The guest's own review for one completed stay, in any moderation state. Read inside `guest_get_booking`;
produced by `guest_submit_review`.

| Field | Type | Notes |
|---|---|---|
| `rating` | int (1–5) | Required; the chosen stars. |
| `comment` | String? | **Optional** (clarification 2026-11-25); may be null/empty. |
| `status` | `ReviewStatus` | `pending` / `published` / `rejected`. |
| `createdOn` | `DateOnly` | When submitted. |

**ReviewStatus → label** (localized from the server status, Constitution VI):

| status | Arabic label |
|---|---|
| `pending` | قيد المراجعة |
| `published` | منشور |
| `rejected` | غير مقبول |

**Validation (client, UX only — server is authority):**
- `rating` must be 1–5; «إرسال» disabled until chosen.
- `comment` optional; a provisional ~500-char max hint only (FR-016). The server enforces the real limit.

### ReviewDraft (transient, in `ReviewCubit`)

| Field | Type | Notes |
|---|---|---|
| `bookingId` | String (UUIDv4) | From the route; validated before use. |
| `rating` | int? | Null until the guest picks stars. |
| `comment` | String | May be empty. |
| `idempotencyKey` | String (UUIDv4) | One per attempt; reused on retry/double tap. |

Not persisted; lives only while the screen is open.

## Repository interface (features/reviews/domain)

```text
abstract interface ReviewsWriteRepository {
  Future<GuestReview> submit({
    required String bookingId,
    required int rating,            // 1..5
    required String? comment,       // null/empty allowed
    required String idempotencyKey, // UUIDv4
  });
}
```

- Memory impl: enforces check-out precondition + one-per-stay locally, returns `status = pending`,
  idempotent on the same key, throws the same `AppFailure` codes as the server.
- Supabase impl: `guest_submit_review` via the shared `_rpc(fn, params)` + `_guard` pattern.

## Changed entities

### BookingDetails (features/bookings/domain) — additive

| New field | Type | Notes |
|---|---|---|
| `review` | `GuestReview?` | Parsed from `guest_get_booking`'s `review` object; null when none exists. |

`availableActions` is unchanged in shape; it may now contain `submit_review`.

### BookingActionCode / BookingActionRegistry (features/bookings/domain)

- Add `BookingActionCode.submitReview = BookingActionCode('submit_review')`.
- Add `BookingActionRegistry.g5()` = g3 set ∪ `{'submit_review'}`. The booking-details screen uses the
  g5 registry so the new action is visible when the server lists it.
- `booking_action_ui` maps `submit_review` → push `/bookings/:id/review`.

### FavoritesState / favorites card (features/favorites/presentation) — additive

- The favorites card list keeps entries whose property is no longer published, flagged `available = false`
  (today those entries are dropped). Minimal addition: an `available` bool alongside the existing card, or
  a parallel `Set<String> unavailableIds`. Remove stays a direct `toggle`/`remove`; navigation is disabled
  for unavailable entries.

## State transitions

**Review (guest-visible):**

```text
(no review) --submit(stars[, comment])--> pending --moderation--> published
                                                   \--moderation--> rejected --(server may re-allow)--> (submit again) --> pending
```

- The app never advances these states; it renders what `guest_get_booking` reports. «قيّم إقامتك» appears
  only while the server lists `submit_review`.

**Favorite (per apartment):**

```text
not-favorite --add--> favorite(available) --property unpublished--> favorite(unavailable, dimmed) --remove--> not-favorite
             <--remove-- (optimistic, reverts on failure)
```

## Localization keys (new, app_ar.arb / app_en.arb)

- Review screen: title, star prompt, comment hint/label (optional), submit, success
  «شكرًا! هيظهر تقييمك بعد المراجعة», char-count hint.
- Review status labels: قيد المراجعة / منشور / غير مقبول; booking-details «قيّم إقامتك».
- Review error messages: check-out not confirmed, already reviewed, comment too long/short, not available.
- Favorites: «غير متاحة حاليًا».
