# Contract Deltas V1–V4 — Reviews write path (built in `onair-backend`)

> **Ownership:** per AGENTS.md this guest-app repo contains **no** SQL or migrations. The objects below
> are implemented in `D:\flutter\onair-backend` (`supabase/migrations/`, RLS, functions). This file is the
> guest app's expected contract so the mock and the remote client match. Names defer to
> `OnAir Backend Master Plan.md`; if any differ there, the Backend plan wins (Guest Plan §2.3).

The reading path (`guest_list_property_reviews`, the rating summary on feed/details) is already consumed
by the app and is assumed present; V4 only confirms it.

## V1 — `property_reviews` table + RLS

- One row per `(booking_id, guest_user_id)`; a stay has at most one review.
- Columns (app-relevant): `id`, `booking_id`, `property_id`, `guest_user_id`, `rating` (smallint 1–5),
  `comment` (text, nullable), `status` (`pending` | `published` | `rejected`), `created_at` (timestamptz).
- RLS: the guest may `select` only their own row; public/anon read is **approved-only** and exposes only
  the approved projection (stars, comment, server-shortened reviewer name, date) — never `guest_user_id`,
  full name, or contact. No direct `insert`/`update`/`delete` by the guest; writes go through V2.
- Moderation (`pending → published`/`rejected`) is an Admin action (Admin web), out of this app's scope.

## V2 — `guest_submit_review`

```text
guest_submit_review(
  p_booking_id       uuid,
  p_rating           smallint,   -- 1..5
  p_comment          text,       -- nullable / empty allowed
  p_idempotency_key  uuid
) returns { rating, comment, status, created_on }
```

- Rejects unless the booking belongs to the caller and has a **confirmed check-out** → error code
  `CHECKOUT_NOT_CONFIRMED` (or the Backend plan's canonical code).
- One review per stay; a second attempt with a new key → `ALREADY_REVIEWED`. The same `p_idempotency_key`
  returns the same stored review (idempotent) without creating a duplicate.
- Enforces the server-owned comment length limit → `COMMENT_TOO_LONG` / `COMMENT_TOO_SHORT` as applicable.
  The limit value is server/config (Guest Plan §19 open item); the app only hints (~500).
- `p_rating` outside 1–5 → validation error.
- On success returns the stored review with `status = pending`.
- If the server allows resubmission of a **rejected** review, this function accepts it (and V3 re-lists the
  action); otherwise it returns `ALREADY_REVIEWED`. This is the server's decision (clarification).

## V3 — `guest_get_booking` additions

- Include the caller's own review when one exists:
  `review: { rating: int, comment: string|null, status: "pending"|"published"|"rejected" }` (absent/null
  when none).
- Add `"submit_review"` to `available_actions` when the booking has a confirmed check-out and a review may
  be submitted (no review yet, or a rejected one the server permits to redo). Omit it otherwise. This is
  the only signal the app uses to show «قيّم إقامتك» (Constitution II).

## V4 — Approved projection & reviewer name (confirm; no app change)

- `guest_list_property_reviews(p_property_id, p_cursor, p_limit)` returns approved-only items with
  `reviewer_short_name` already shortened server-side (e.g. «أحمد م.»), `rating`, nullable `comment`,
  `created_on`, keyset `next_cursor` — already matching `ReviewsPage`/`ApprovedReview`.
- The apartment rating summary (`rating_avg`, `review_count`) on feed/details reflects approved reviews
  only.

## Error codes (app maps each to a localized message)

| Code | Shown to guest (meaning) |
|---|---|
| `CHECKOUT_NOT_CONFIRMED` | Review not available until the stay's check-out is confirmed. |
| `ALREADY_REVIEWED` | A review already exists for this stay. |
| `COMMENT_TOO_LONG` / `COMMENT_TOO_SHORT` | Comment outside the allowed length. |
| `NOT_FOUND` / not-available | Booking not available (also for a bad deep-link id). |

> Exact code spellings follow the Backend Master Plan; the mock returns the same spellings so the UI
> mapping is identical in mock and remote.
