# Contract: Supabase Discovery RPCs for G1 (DRAFT)

**Audience**: backend owner (shared `onair-backend`, Guest Plan §2.3 and
`docs/shared-backend/SHARED_BACKEND_PLAN.md`). **Status**: draft for review.

**Sources**:
- Master Plan decisions 97–99, §7.1–§7.2, §13.4, AC-003, AC-010, AC-012, AC-013, AC-047
- Guest Plan §6.3–§6.5, §10.1, §12
- Decision [D-001](../../../docs/decisions/D-001-public-property-address.md)
- spec FR-001–FR-038

**Owner code**: `guest` (registry §5.1). Every function below is a `public` function with the
`guest_` prefix.

## 0. Common rules (all functions)

- **Function settings:** `security definer`, `set search_path = public, pg_temp`,
  `stable`, and `grant execute ... to anon, authenticated`. Visitors call them with the anon
  key.
- **"Published" means all of the following:**
  - `properties.status = 'published'`;
  - `published_version_id` is not null;
  - that version's `status = 'approved'`;
  - the owning workspace's `verification_status = 'approved'` (AC-003).
- **Never returned:**
  - owner or workspace contact data (phone, email, member names);
  - `base_nightly_price_minor`;
  - markup or margin values;
  - `latitude` / `longitude`;
  - internal notes;
  - review moderation data;
  - other guests' booking data.
- **Final nightly price**: `nightly_price_minor` comes from one shared pricing function
  (base + markup per `markup_policies`, property > workspace > platform). The app never
  receives the parts.
- **Money**: integer minor units (`bigint`) plus `currency` (`'EGP'`).
- **Stay dates**: `date` values, half-open `[check_in, check_out)`.
- **Errors**: raised as `raise exception '<CODE>' using errcode = 'P0001'` with codes from §8.
  The app maps them in `ErrorMapper`. A `request_id` is added when the call goes through a
  gateway.
- **Images**: each photo is `{"variants":[{"width":320,"url":"https://…"},…],"blurhash":null}`.
  The backend decides how variants are produced (Cloudflare setup still open, Guest Plan
  §12.2). At least one variant is required; three (≈320/≈720/≈1440 px) are recommended.

## 1. `guest_home_feed(p_locale text default 'ar') returns jsonb`

Returns all Home sections in one call. A failing section is reported, not raised.

```json
{
  "reference_version": "2026-10-28.3",
  "areas":     {"status": "ready", "items": [{"location_id": "uuid", "name": "التجمع الخامس", "listing_count": 42, "image": {"variants": [...]}}]},
  "suggested": {"status": "ready", "items": [ /* ListingCard */ ]},
  "newest":    {"status": "ready", "items": [ /* ListingCard */ ]},
  "upcoming_booking": {"status": "ready", "item": null}
}
```

- **Failed section:** `{"status": "failed", "error_code": "INTERNAL"}`.
- **Suggested:** ordering is decided by the server (Guest Plan §19.3 is still open). Until
  decided: newest published apartments, or a list chosen by the admin.
- **Section sizes:** up to 10 areas, 10 suggested, 10 newest.
- **`upcoming_booking`:**
  - For `auth.uid()` only.
  - `null` for anon callers, and when there is no confirmed booking with `check_in ≥ today`
    (Cairo).
  - Shape: `{"booking_id", "property_title", "check_in", "check_out", "status"}`.
  - May stay `null` until G2 tables exist.

**ListingCard JSON** (shared by the feed and search):

```json
{
  "id": "uuid", "title": "شقة 3 غرف بإطلالة", "property_type": "apartment",
  "area_name": "التجمع الخامس", "city_name": "القاهرة الجديدة",
  "cover": {"variants": [{"width": 320, "url": "https://…"}], "blurhash": null},
  "nightly_price_minor": 150000, "currency": "EGP",
  "rating_avg": 4.6, "review_count": 12,
  "stay": {"nights": 3, "stay_total_minor": 450000}
}
```

- `stay` is present only when the request had dates.
- `rating_avg` is `null` when `review_count = 0`.

## 2. `guest_search_properties(...) returns jsonb`

| Param | Type | Notes |
|---|---|---|
| `p_location_id` | uuid, null | Governorate, city, or area; matches the apartment's location and its ancestors |
| `p_check_in`, `p_check_out` | date, null | Both or neither; `p_check_out > p_check_in`; `p_check_in ≥ today` (Cairo) |
| `p_guests` | int, null | `max_guests ≥ p_guests` |
| `p_price_min_minor`, `p_price_max_minor` | bigint, null | On the **final** nightly price |
| `p_min_bedrooms`, `p_min_bathrooms` | int, null | |
| `p_amenity_keys` | text[], null | Apartment has **all** of them |
| `p_property_types` | text[], null | Apartment type is **any** of them |
| `p_sort` | text, null | `price_asc` \| `price_desc` \| `newest` (default `newest`) |
| `p_cursor` | text, null | Opaque keyset cursor from a previous page |
| `p_limit` | int, default 20 | 0 = count only; maximum 50 |

**Returns**: `{"items": [ListingCard…], "next_cursor": "…" | null, "total_count": 137}`.

**Availability (AC-012, MUST)**: when dates are given, exclude any apartment with **any**
night in `[p_check_in, p_check_out)` overlapping either of:
- an active `booking_date_locks` row (`released_at is null`, hold or confirmed);
- a `property_blocks` range.

Use the same `daterange '[)'` semantics as the exclusion constraint.

**Errors**: `VALIDATION_FAILED` (one date without the other, inverted or past dates, bad
cursor, `p_limit` out of range, guests < 1).

## 3. `guest_get_property(p_property_id uuid, p_locale text default 'ar') returns jsonb`

```json
{
  "id": "uuid", "title": "…", "description": "…", "property_type": "apartment",
  "governorate_name": "القاهرة", "city_name": "القاهرة الجديدة", "area_name": "التجمع الخامس",
  "address_text": "شارع 90، عمارة 12، الدور 4",
  "images": [{"variants": [...], "blurhash": null}],
  "bedrooms": 3, "bathrooms": 2, "max_guests": 6, "area_sqm": 160,
  "amenities": [{"key": "wifi", "label": "واي فاي", "icon": "wifi"}],
  "rules": {"check_in_time": "14:00", "check_out_time": "12:00", "visitors_allowed": true,
            "max_visitors": 2, "house_rules": "…"},
  "policy": {"deposit_type": "percent", "deposit_percent_bp": 2500, "deposit_amount_minor": null,
             "free_cancellation_hours": 72},
  "nightly_price_minor": 150000, "currency": "EGP",
  "rating_avg": 4.6, "review_count": 12,
  "latest_reviews": [ /* up to 3 ApprovedReview */ ],
  "terms_version": "sha256:…"
}
```

- **Address:** `address_text` comes from the approved version (D-001). Coordinates are never
  included.
- **Policy:** comes from `private.resolve_booking_terms(property_id)`.
  - `deposit_percent_bp` is set when the type is `percent`.
  - `deposit_amount_minor` is set when the type is `fixed`.
  - Both are null when the type is `full`.
  - **To confirm:** the unit of `booking_policies.deposit_value` for percent.
- **`terms_version`:** identifies the exact rules + policy text shown. The same value must be
  accepted later by `guest_quote_booking` / `guest_start_booking` (G2). If it differs there,
  they raise `TERMS_CHANGED`.
- **Errors:** `NOT_FOUND` for unknown **and** for not-published IDs, with an identical
  response so existence is not revealed (AC-003).

## 4. `guest_get_property_unavailable_dates(p_property_id uuid, p_from date, p_to date) returns date[]`

- **Returns:** every **night** in `[p_from, p_to)` that is unavailable, for any reason
  (active lock, owner block, or past). No reason and no booking data are returned.
- **Range cap:** the server may cap `p_to − p_from` (suggested ≤ 120 days). Over the cap it
  raises `VALIDATION_FAILED`.
- **Errors:** `NOT_FOUND` as in §3.

## 5. `guest_list_property_reviews(p_property_id uuid, p_cursor text default null, p_limit int default 20) returns jsonb`

**Returns:** `{"items": [ApprovedReview…], "next_cursor": … }`, newest first, with
`status = 'approved'` only.

```json
{"id": "uuid", "rating": 5, "comment": "…", "created_on": "2026-09-14", "reviewer_short_name": "أحمد م."}
```

- **Reviewer short name:** formatted on the server as first name + first letter of the last
  name. Full names are never returned.
- **Errors:** `NOT_FOUND` as in §3.

## 6. `guest_search_locations(p_query text, p_limit int default 10) returns jsonb`

**Returns:**

```json
[{"id": "uuid", "level": "area", "name": "التجمع الخامس", "parent_label": "القاهرة الجديدة", "listing_count": 42}]
```

- **Locations returned:** active ones (`is_active`) only, ranked by name match, then by
  `listing_count`.
- **Arabic normalisation:** the same normalisation is applied to both the query and the names
  (أ/إ/آ→ا، ة→ه، ى→ي, tatweel and diacritics removed).
- **Query length:** must be 2–60 characters. Outside that range the server returns an empty
  array, not an error.

## 7. `guest_get_reference_data(p_locale text default 'ar') returns jsonb`

```json
{
  "version": "2026-10-28.3",
  "amenities": [{"key": "wifi", "label": "واي فاي", "icon": "wifi"}],
  "property_types": [{"key": "apartment", "label": "شقة"}],
  "price_bounds": {"min_minor": 50000, "max_minor": 1500000, "currency": "EGP"},
  "price_step_minor": 5000
}
```

- **Version:** `version` changes whenever any list or the bounds change. `guest_home_feed`
  returns the same value as `reference_version`.
- **Property types:** keys follow `property_versions.property_type` (the list is confirmed in
  phase zero).

## 8. Error codes used by G1

| Code | When | App behaviour |
|---|---|---|
| `NOT_FOUND` | Unknown or unpublished property (§3–§5) | Neutral "not available" screen |
| `VALIDATION_FAILED` | Bad parameters or cursor | Reset to page 1; generic error with retry |
| `RATE_LIMITED` | Optional gateway throttling | Message with remaining time; retry disabled |
| `INTERNAL` | Anything else | Unexpected-error message with reference number |

`NOT_FOUND` is a shared registry code (registry §6) and is new to the app's error contract. It
maps to `propertyNotAvailable`.

## 9. Registry additions requested

| Function | owner | phase | Notes |
|---|---|---|---|
| `guest_search_properties` | guest | P0 | Already planned; signature above |
| `guest_get_property` | guest | P0 | Already planned; includes `address_text` (D-001) |
| `guest_home_feed` | guest | P0 | **New** |
| `guest_get_property_unavailable_dates` | guest | P0 | **New** |
| `guest_list_property_reviews` | guest | P0 | **New**. Reads `property_reviews` (approved) + `profiles.full_name` (shortened) |
| `guest_search_locations` | guest | P0 | **New** |
| `guest_get_reference_data` | guest | P0 | **New**. Reads `amenities`, the property-type list, and the price bounds |

Because they read `core` tables (`properties`, `property_versions`, `booking_date_locks`), the
PR needs the core-review rule from the registry.

## 10. Security tests (MUST, automated on Staging)

Run by `integration_test/discovery_rules_test.dart` against the seed in §11.

1. **Unapproved never appears or opens.** An apartment that is draft, in review, rejected,
   paused, archived, or owned by an unapproved workspace:
   - never appears in `guest_home_feed` or `guest_search_properties`;
   - gives `NOT_FOUND` from `guest_get_property`, identical to a random UUID (AC-003).
2. **Unavailable dates are excluded.** Searching dates that include one booked night, one
   on-hold night, or one blocked night never returns that apartment. Searching the
   neighbouring free range does (AC-012).
3. **No forbidden fields.** No response contains: base price, markup, coordinates, owner
   phone/email/name, full reviewer names, or pending/rejected reviews.
4. **Anon has no direct table access.** `anon` cannot `select` from `properties`,
   `property_versions`, `property_reviews`, `booking_date_locks`, or `property_blocks`.
5. **The calendar reveals nothing else.** `guest_get_property_unavailable_dates` returns dates
   only, and the same dates whether the caller is anon or signed in.

## 11. Staging seed (needed for G1 acceptance)

- At least 3 governorates/cities with areas.
- Apartments:
  - approved;
  - draft;
  - in review;
  - rejected;
  - paused;
  - in an unapproved workspace.
- On one approved apartment, dates that are:
  - booked (confirmed lock);
  - on hold;
  - owner-blocked.
- Policies:
  - one deposit-percent apartment;
  - one fixed-deposit apartment;
  - one full-payment apartment.
- One apartment with ≥ 4 approved reviews plus pending and rejected ones; one with no reviews.
- One apartment without `address_text`.
- Enough approved apartments (≥ 25) to exercise pagination.
