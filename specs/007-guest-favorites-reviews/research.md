# Phase 0 Research: Guest Favorites & Reviews (G5)

All `/speckit-clarify` questions are resolved (see spec `## Clarifications`). No `NEEDS CLARIFICATION`
remains. This file records the design decisions that shape Phase 1, grounded in the as-built code.

## R1 — Where the review-write feature lives

- **Decision**: New feature folder `lib/features/reviews/{data,domain,presentation}`. Reading stays where
  it is (`features/property` + `ListingsRepository.reviews`).
- **Rationale**: Guest Plan §3.3 explicitly lists `features/reviews/` ("write review, my reviews"). The
  write path is a distinct concern (booking-scoped, auth-gated, moderated) from the public reading path;
  splitting keeps `ListingsRepository` read-only and visitor-facing.
- **Alternatives**: Put the write method on `StayRepository` (rejected — stay is check-in/out/cash/claims;
  review is a separate lifecycle) or on `ListingsRepository` (rejected — that layer is the open,
  visitor-readable discovery layer and must not carry an authenticated write).

## R2 — Review status model

- **Decision**: `GuestReview { int rating (1..5); String? comment; ReviewStatus status; DateOnly createdOn }`
  with `ReviewStatus { pending, published, rejected }`. The status maps to the plain-Arabic labels
  «قيد المراجعة» / «منشور» / «غير مقبول». Comment is nullable (optional, clarification 2026-11-25).
- **Rationale**: Mirrors AC-049 and Guest Plan §6.15; matches the reading-side `ApprovedReview` which
  already treats `comment` as nullable. The guest's own review (any status) comes inside
  `guest_get_booking`, so no separate fetch.
- **Alternatives**: A boolean `isApproved` (rejected — loses the three distinct states the booking screen
  must show); a separate `guest_get_my_review` call (rejected — an extra round trip when the data already
  belongs in the booking payload).

## R3 — Eligibility and the «قيّم إقامتك» action (server authority)

- **Decision**: Add a `submit_review` action code and a `BookingActionRegistry.g5()` that extends the g3
  set with it. The booking-details screen shows «قيّم إقامتك» only when `submit_review` is in the
  server's `available_actions`; `booking_action_ui` maps it to `context.push('/bookings/:id/review')`.
- **Rationale**: Constitution II — the app must not decide "checked out", "already reviewed", or "may
  resubmit after rejection". The server already drives every other booking action through
  `available_actions` + `BookingActionRegistry.visible(...)`; reviews follow the same proven path. The
  resubmit-after-rejection clarification is honored for free: the server simply re-lists `submit_review`
  when it decides a rejected review may be redone.
- **Alternatives**: Deriving eligibility from booking status in the client (rejected — violates
  Constitution II and duplicates server rules that can drift).

## R4 — Submit call, idempotency, single-submit

- **Decision**: `ReviewsWriteRepository.submit({bookingId, rating, comment, idempotencyKey})` →
  `guest_submit_review` via the existing `_rpc(fn, params)` + `_guard` pattern in
  `SupabaseStayRepository`. `ReviewCubit` generates one UUIDv4 `idempotency_key` per attempt, reuses it on
  retry, disables «إرسال» on first tap (`submitting` state), and treats double taps as one submit.
- **Rationale**: Matches `guest_cancel_booking` / `guest_respond_damage_claim` which already pass
  `p_idempotency_key`; satisfies the spec's single-submit requirement (FR-014) and the repo's established
  write discipline.
- **Alternatives**: A Node endpoint (rejected — this is a plain RLS-guarded RPC, no external integration,
  like other `guest_*` writes).

## R5 — Review screen UX

- **Decision**: `ReviewScreen` at `/bookings/:id/review`: a `StarRatingInput` (1–5, star token `#FFB300`,
  `Semantics` label per star, 48×48 targets) on the Reviews gradient surface, an **optional** multi-line
  comment field with a provisional ~500-char counter hint (server is authority — FR-016), «إرسال»
  disabled until a star is chosen, a `submitting` progress state, the success message
  «شكرًا! هيظهر تقييمك بعد المراجعة» then pop back to booking details (which now shows «قيد المراجعة»), and
  server errors shown via mapped localized messages.
- **Rationale**: Guest Plan §6.15 + §4.3 (Reviews gradient) + Constitution VI/VIII.
- **Alternatives**: A bottom sheet (rejected — a dedicated route is already reserved and supports the
  review-invite deep link).

## R6 — Error-code mapping

- **Decision**: Map the server error codes to localized messages: check-out not confirmed, already
  reviewed, comment too long/short, and the generic not-available. Reuse the existing unified error shape
  (`code`, `message_key`, `request_id`) and the app's error → `.arb` mapping. No raw server text shown.
- **Rationale**: Constitution VI and Guest Plan §10.3. Exact code strings are fixed in V1–V4
  ([contracts/supabase-reviews.md](contracts/supabase-reviews.md)); the mock returns the same codes.

## R7 — Favorites "unavailable" state (US1 gap)

- **Decision**: `FavoritesCubit.refresh` no longer drops a favorite whose public details 404. It keeps the
  id and renders a placeholder card flagged `available = false`. `FavoritesScreen` shows it dimmed with
  «غير متاحة حاليًا», not navigable to a booking, with a working remove (heart) control. Modeled as a
  per-card `available` flag on the existing favorites card list (minimal state change).
- **Rationale**: Spec FR-006 / AC-6 and Guest Plan §6.14 require the dimmed state; today the item silently
  disappears, which the guest reads as data loss. Keeping the id lets them remove it deliberately.
- **Alternatives**: A second list for unavailable ids (rejected — more state to keep in sync than a flag);
  leaving the drop behavior (rejected — fails the spec).

## R8 — Reviewer name shortening & privacy

- **Decision**: The app never shortens names; it renders `reviewer_short_name` exactly as the server
  returns it (already true for `ApprovedReview`). No reviewer identity/contact is ever requested.
- **Rationale**: Constitution IV; Guest Plan §2.7.2 ("الأسماء الكاملة للمقيّمين" never reach the guest).

## R9 — Mock parity

- **Decision**: Add review fields to the mock `guest_get_booking` (a `submit_review` action on a
  checked-out mock booking, and the `review` object once submitted) and a `MemoryReviewsWriteRepository`
  that enforces one-per-stay and the check-out precondition locally, returning the same codes as V1–V4.
- **Rationale**: Guest Plan §2.6 mock-first; lets US2 be demoed and integration-tested with no backend,
  switching to remote by the existing `BackendMode` flag with no UI change.

## Backend deltas (owned by `onair-backend`, not built here)

Drafted as **V1–V4** in [contracts/supabase-reviews.md](contracts/supabase-reviews.md):

- **V1** `property_reviews` table + RLS: one row per (booking, guest); columns for rating, nullable
  comment, moderation status, created-at; guest reads only their own row, public read is approved-only.
- **V2** `guest_submit_review(p_booking_id, p_rating, p_comment, p_idempotency_key)`: enforces confirmed
  check-out, one review per stay (idempotent), the comment length limit, and returns the stored review
  with `status = pending`.
- **V3** `guest_get_booking`: include `review: {rating, comment, status}` for the guest's own review, and
  list `submit_review` in `available_actions` after a confirmed check-out while submission is allowed
  (including re-allow after a rejection, per the clarification — server's decision).
- **V4** the server-shortened `reviewer_short_name` and the approved-only projection already consumed by
  `guest_list_property_reviews` / the rating summary (confirm present; no app change).
