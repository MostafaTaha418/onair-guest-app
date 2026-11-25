# Contract — UI screens & components (G5)

Design system: Constitution V/VI. Colors from `OnAirColors`/`context.colors` (star `#FFB300`, heart
`#E53935`), Reviews gradient (§4.3), no literals, every string from `.arb`, Arabic RTL + dark, text scale
clamped (~1.3), 48×48 targets, `Semantics` on icon-only controls.

## Review screen — `ReviewScreen` (`/bookings/:id/review`) — NEW

| Element | Behavior |
|---|---|
| Surface | Reviews gradient header (§4.3); scrolls with keyboard; back control mirrored in RTL. |
| `StarRatingInput` | 1–5 stars, star token `#FFB300`; tapping sets the rating; each star has a `Semantics` label (e.g. «٣ من ٥»); 48×48 targets. |
| Comment field | **Optional** multi-line input; placeholder makes "optional" clear; provisional ~500-char counter hint only (server is authority). |
| «إرسال» | Disabled until a star is chosen; on tap → `submitting` (spinner, button disabled); single-submit on double tap. |
| Success | Show «شكرًا! هيظهر تقييمك بعد المراجعة», then pop to booking details. |
| Error | Localized message mapped from the server `code` (CHECKOUT_NOT_CONFIRMED / ALREADY_REVIEWED / COMMENT_TOO_* / not-available); nothing shown as submitted. |
| States | idle / submitting / success / error + disabled; verified in both themes and at 1.3×. |

### `ReviewCubit`

- `state`: `idle(rating?, comment)`, `submitting`, `success(GuestReview)`, `failure(code)`.
- Holds one UUIDv4 `idempotencyKey` per attempt (reused on retry/double tap).
- `setRating(int)`, `setComment(String)`, `submit()` → `ReviewsWriteRepository.submit(...)`.

## Booking details additions — `features/bookings/presentation`

| Element | Behavior |
|---|---|
| «قيّم إقامتك» action | Shown only when `submit_review` is in the server `available_actions` (via `BookingActionRegistry.g5()`); pushes `/bookings/:id/review`. |
| Review status line | When `booking.review != null`: a plain-Arabic label «قيد المراجعة» / «منشور» / «غير مقبول» plus the guest's own stars and comment. No «قيّم» button while a review exists, unless the server re-lists the action. |
| Color-independent | Status conveyed by text (and an icon), never color alone (Constitution V). |

## Favorites screen — `FavoritesScreen` (`/favorites`) — CHANGE

| Element | Behavior |
|---|---|
| Live favorite | Unchanged `PropertyCard` (heart filled, optimistic toggle, busy guard, navigates to details). |
| Unavailable favorite | **NEW**: a dimmed card labeled «غير متاحة حاليًا»; not navigable to a booking; the heart still removes it. Backed by the `available = false` flag added to the favorites card list (research R7). |
| States | Unchanged loading / empty / error; add the unavailable card rendering among live cards. |

## Reused components (no change)

- `PropertyCard`, `rating_badge`, `property_reviews_section`, `property_title_section` (rating + count),
  `ReviewsScreen` (`/property/:id/reviews`), `state_views` (Loading/Empty/Error), `AppIcons`.

## New component

- `StarRatingInput` (`features/reviews/presentation/widgets/star_rating_input.dart`) — input stars; the
  read-only `rating_badge` stays for display. Kept in the feature (interactive, review-specific); promote
  to `design_system` later only if another screen needs an input star control.

## Accessibility & localization checklist (per screen)

- All strings from `app_ar.arb` / `app_en.arb`; server errors via mapped keys, never raw text.
- Star control and remove/heart have `Semantics`; focus order logical in RTL.
- Verified: Light/Dark, RTL/LTR, 1.3× text, 320 dp and 800 dp, keyboard open on the review screen.
