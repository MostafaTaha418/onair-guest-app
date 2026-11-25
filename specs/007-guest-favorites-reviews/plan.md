# Implementation Plan: Guest Favorites & Reviews (G5)

**Branch**: `feature/007-guest-favorites-reviews` | **Date**: 2026-11-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/007-guest-favorites-reviews/spec.md`

## Summary

Most of G5 already shipped earlier alongside discovery (002) and the property screen: favorites and the
reviews **reading** path are built and wired. This plan closes the two real gaps and keeps everything on
the mock backend until `onair-backend` ships the review write path.

As-built today:

- **Favorites (US1)** — `features/favorites` has the domain repo, a memory and a Supabase repo, a
  `FavoritesCubit` with optimistic toggle, busy-id guarding and auth-driven refresh, `toggleFavorite`
  with the sign-in gate and return-to-origin, and `FavoritesScreen` with loading/empty/error. The heart
  is on every `PropertyCard` (home, search results, favorites) and the `/favorites` route is in the
  account-gated branch of the router with the cubit provided at app root.
- **Reviews reading (US3)** — `ListingsRepository.reviews(...)`, `ApprovedReview` (with a nullable
  comment and a server-shortened reviewer name) and `ReviewsPage`, the property title rating,
  `property_reviews_section`, `ReviewsCubit`/`ReviewsScreen` at `/property/:id/reviews`, and the
  `rating_badge` component. Reading is open to visitors.

Remaining G5 work:

- **US2 — Write a review (new, the bulk of this plan):** a new `features/reviews` feature:
  - a review screen at `/bookings/:id/review` (today a `NotAvailableScreen` placeholder) with a 1–5 star
    input and an **optional** comment (clarification 2026-11-25), «إرسال» disabled until a star is
    chosen, single-submit on double tap, a progress state, the success message
    «شكرًا! هيظهر تقييمك بعد المراجعة», and server-error mapping;
  - a `ReviewsWriteRepository` (memory + Supabase) calling `guest_submit_review` with a UUIDv4
    idempotency key, following the existing `SupabaseStayRepository` RPC pattern;
  - the guest's own review and its moderation status surfaced in **booking details** from
    `guest_get_booking`: a status line in plain Arabic («قيد المراجعة» / «منشور» / «غير مقبول») with the
    submitted stars/comment, and a «قيّم إقامتك» action rendered only when the server lists a
    `submit_review` action (new action code + a `g5()` action registry; the app never decides eligibility
    itself — Constitution II);
  - review-invite and moderation notifications (`stay.completed`, `review.approved`, `review.rejected`)
    already route to booking details via `notification_router`; this plan only makes that screen show the
    status/action they point at.
- **US1 — favorites gap:** a favorited apartment that is no longer published is currently **dropped**
  from the list (`FavoritesCubit.refresh` silently skips a property whose public details 404). The spec
  and Guest Plan §6.14 require it to appear **dimmed with «غير متاحة حاليًا» and still removable**. This
  plan keeps unavailable favorites as placeholder entries and renders a dimmed, non-navigable card with a
  remove control.

**Backend dependency:** the review write path is owned by `onair-backend` (AGENTS.md — no SQL/migrations
here). Needed deltas (drafted as **V1–V4** in
[contracts/supabase-reviews.md](contracts/supabase-reviews.md)): `property_reviews` table + RLS +
moderation status, `guest_submit_review(booking_id, rating, comment, idempotency_key)` enforcing
confirmed check-out and one-review-per-stay, `guest_get_booking` returning the guest's review
(`review: {rating, comment, status}`) and a `submit_review` entry in `available_actions` after a
confirmed check-out while no review exists (and again only if a rejected review may be resubmitted —
server's decision), and the server-shortened reviewer name already used by the reading path. Until V1–V4
ship, every journey runs on `BackendMode.mock`, as in G1–G4.

Details: [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/),
[quickstart.md](quickstart.md).

## Technical Context

**Language/Version**: Dart (SDK constraint `^3.12.2`), Flutter stable. No native code added by this
feature.

**Primary Dependencies**: existing stack only — `flutter_bloc` (Cubit), `go_router` (the reserved
`/bookings/:id/review` route and the account gate), `supabase_flutter` (RPC reads/writes under RLS),
`freezed_annotation`/`json_serializable` (immutable models), `uuid` (idempotency key), `intl` (dates,
rating formatting). No new package is introduced; adding one would need the Constitution VII review and
none is warranted (stars are plain widgets).

**Storage**: nothing personal is persisted. The review draft (stars, comment, idempotency key) lives in
the `ReviewCubit` until the submit resolves. The guest's review status is read fresh from
`guest_get_booking`. Favorites continue to read fresh and cache only the last successful list in memory
(no new persistence).

**Testing**:
- `flutter_test`, `bloc_test`, `mocktail`, `fake_async` (double-tap single-submit).
- Goldens (`alchemist`, matching the repo's existing matrix — Light, Dark, RTL, LTR, 1.3× text, 320 dp
  and 800 dp, keyboard open where there is input):
  - review screen: empty (no stars → «إرسال» disabled), stars chosen, submitting, error;
  - booking details: «قيّم إقامتك» action present, review «قيد المراجعة» / «منشور» / «غير مقبول»;
  - favorites: an unavailable («غير متاحة حاليًا») card among live cards.
- `integration_test` (mock): `review_mock_test.dart` — a checked-out booking → open the review screen →
  4 stars, no comment → success → booking details shows «قيد المراجعة» and the action is gone;
  double-tap «إرسال» creates one review; a stay without a confirmed check-out never shows the action and
  a manual deep link is rejected. `favorites_unavailable_mock_test.dart` — a favorite whose property is
  unpublished shows dimmed and removes cleanly.
- Staging variants once V1–V4 ship.

**Target Platform**: Android 7.0+ (API 24) and iOS 15+ — unchanged; no new permissions, no camera/photo
pickers (reviews are stars + text only).

**Project Type**: Mobile app (single Flutter project at repository root), plus review-path backend deltas
in the separate `onair-backend` repository.

**Performance Goals**: the review screen opens within one frame (static form, no network on open); submit
shows progress immediately and disables the button on first tap; booking details adds the review
status/action with no extra network call (it comes inside the existing `guest_get_booking` payload). 60
fps maintained; the favorites list keeps its existing rendering.

**Constraints**:
- **Constitution II (server authority):** review eligibility (confirmed check-out, one per stay, whether
  a rejected review may be resubmitted), the moderation status, and the comment length limit all come
  from the server. The app renders `available_actions` and the returned status; hiding the «قيّم» button
  is UX only and the server rejects an unauthorized submit (mapped to a localized message).
- **Constitution V/VI:** stars use the design-system star token `#FFB300`, the Reviews gradient is used
  for the review surface, no color/size literals, every string from `.arb`, Arabic RTL + dark verified,
  text scaling clamped, 48×48 touch targets, `Semantics` on the star control, errors announced.
- **Constitution VII:** feature-first; widgets never touch Supabase/Dio — a `ReviewsWriteRepository` is
  the only data path; no pass-through use case; generated clients untouched.
- **Idempotency:** one UUIDv4 key per review attempt, reused across retries/double taps.

**Scale/Scope**: ~1 new feature folder (`features/reviews`), 1 screen replacing a placeholder, 1 cubit,
1 write repository (×2 impls), a star-input widget, a small booking-details addition (status line +
action), and a bounded favorites change for the unavailable state. New `.arb` keys for the review screen,
status labels, and the favorites «غير متاحة حاليًا» label.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Master Plan fidelity & scope | Feature traces to decision 103, AC-048/049, Guest Plan §6.14/§6.15/§17 G5; no invented rules | PASS |
| II. Server is the authority | Review eligibility, status, one-per-stay, resubmit, comment length all server-driven; app renders `available_actions`/status; deep-link IDs are hints only; a rejected submit maps to a message | PASS |
| III. Payment integrity | No payment surface touched | N/A |
| IV. Security & privacy | No secrets; no new PII; reviewer names arrive already shortened; deep-link `:id` validated as UUIDv4 before use; unavailable-favorite reveals nothing beyond that it is not available | PASS |
| V. Design system | Star `#FFB300`, Reviews gradient, no literals, reuse `PropertyCard`/state views/`rating_badge` | PASS |
| VI. Arabic-first, RTL, a11y | All strings from `.arb`, status labels localized from server `code`, star control has `Semantics`, 48×48, 1.3× verified | PASS |
| VII. Layered architecture | `features/reviews/{data,domain,presentation}`; repository-only data access; no pass-through use case | PASS |
| VIII. Complete UX states & performance | Review screen: idle/submitting/success/error + disabled; booking details status states; favorites loading/empty/error/**unavailable** | PASS |
| Mock-first / contract parity | Mock `ReviewsWriteRepository` + mock `guest_get_booking` review fields on the same contract as V1–V4; flag-switch to remote with no UI change | PASS |

No violations. Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/007-guest-favorites-reviews/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── supabase-reviews.md   # V1–V4 deltas (built in onair-backend)
│   ├── app-routes.md         # /bookings/:id/review + notification routing
│   └── ui-screens.md         # review screen + booking-details additions + favorites unavailable
├── checklists/
│   └── requirements.md  # from /speckit-specify (16/16)
└── tasks.md             # /speckit-tasks output (NOT created here)
```

### Source Code (repository root)

```text
lib/
├── app/
│   └── router/
│       ├── app_router.dart          # replace NotAvailableScreen at bookingReviewPattern with the review screen (provide ReviewCubit)
│       └── notification_router.dart  # unchanged (review.* / stay.completed already route to booking details)
├── features/
│   ├── reviews/                      # NEW (Guest Plan §3.3 lists this feature)
│   │   ├── data/
│   │   │   ├── memory_reviews_write_repository.dart
│   │   │   └── supabase_reviews_write_repository.dart
│   │   ├── domain/
│   │   │   ├── guest_review.dart          # rating, comment?, status(pending/published/rejected), createdOn
│   │   │   └── reviews_write_repository.dart
│   │   └── presentation/
│   │       ├── review_cubit.dart
│   │       ├── review_screen.dart
│   │       └── widgets/star_rating_input.dart
│   ├── bookings/
│   │   ├── domain/
│   │   │   ├── booking_action.dart        # add submit_review code + g5() registry
│   │   │   └── booking_details.dart       # add review: GuestReview? parsed from guest_get_booking
│   │   └── presentation/
│   │       ├── booking_action_ui.dart     # map submit_review → push /bookings/:id/review
│   │       └── widgets/                    # review status line + stars/comment block
│   └── favorites/
│       ├── presentation/
│       │   ├── favorites_cubit.dart        # keep unavailable ids as placeholder cards (don't drop)
│       │   └── favorites_screen.dart       # dimmed «غير متاحة حاليًا» card with remove
│       └── (domain/data unchanged)
└── l10n/
    ├── app_ar.arb                          # review screen, status labels, «غير متاحة حاليًا»
    └── app_en.arb
```

**Structure Decision**: Single Flutter project at the repository root (Guest Plan §2.4/§3.3). The new
work is a self-contained `features/reviews` feature plus small, additive edits to `features/bookings`
(action + review status), `features/favorites` (unavailable state), the router (wire the review screen),
and `.arb`. No change to `design_system`/`core` beyond a star-input widget and reused tokens. Review-path
database objects are **not** built here — they are V1–V4 deltas implemented in `onair-backend`.

## Complexity Tracking

> No constitution violations; no entries.
