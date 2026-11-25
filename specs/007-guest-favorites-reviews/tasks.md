---

description: "Task list for Guest Favorites & Reviews (G5)"
---

# Tasks: Guest Favorites & Reviews (G5)

**Input**: Design documents from `specs/007-guest-favorites-reviews/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. This repo's constitution (VIII) and every prior spec ship `bloc_test`, `alchemist`
goldens and `integration_test`; plan.md specifies them for G5. Write the listed tests to fail first.

**Context**: Favorites (US1) and reviews-reading (US3) already ship; the real new work is writing a
review (US2) plus one favorites gap. Backend objects are **not** built here — they are the V1–V4 deltas
in [contracts/supabase-reviews.md](contracts/supabase-reviews.md), implemented in `onair-backend`
(AGENTS.md). All journeys run on `BackendMode.mock` until V1–V4 ship.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1 / US2 / US3

---

## Phase 1: Setup

- [ ] T001 Create the feature folders `lib/features/reviews/data/`, `lib/features/reviews/domain/`, `lib/features/reviews/presentation/` and `lib/features/reviews/presentation/widgets/`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: shared pieces US2 builds on. US1 and US3 do not depend on these and may proceed in parallel.

- [ ] T002 [P] Add `BookingActionCode.submitReview = BookingActionCode('submit_review')` and a `BookingActionRegistry.g5()` (g3 set ∪ `{'submit_review'}`) in `lib/features/bookings/domain/booking_action.dart`; keep `firstGuestAction`/`needsActionCode` behavior unchanged.
- [ ] T003 [P] Create `GuestReview` + `ReviewStatus { pending, published, rejected }` in `lib/features/reviews/domain/guest_review.dart`: `rating` int 1–5 (required), `comment` String? (**optional/nullable** per clarification), `status`, `createdOn` DateOnly; `fromJson` tolerant of a null `comment`.
- [ ] T004 Add `review: GuestReview?` to `BookingDetails` in `lib/features/bookings/domain/booking_details.dart`, parsed from `guest_get_booking`'s `review` object (null when absent); keep `availableActions` shape unchanged (it may now contain `submit_review`). Update `toJson`/`==`/`hashCode`. (depends on T003)

**Checkpoint**: shared types ready.

---

## Phase 3: User Story 1 — Favorites, incl. unavailable state (Priority: P1)

**Goal**: a signed-in guest saves/removes apartments from anywhere with an optimistic heart; a favorite
whose apartment is no longer published shows dimmed «غير متاحة حاليًا» and is still removable.

**Independent Test**: favorite three apartments from home/search/details; unpublish one (mock) → it shows
dimmed and removes cleanly; toggling fast yields one row.

**Already built**: `FavoritesRepository` (+ memory/supabase), `FavoritesCubit` (optimistic toggle, busy
guard, auth refresh), `toggleFavorite` (sign-in gate), `FavoritesScreen` (loading/empty/error), heart on
`PropertyCard`, `/favorites` route. Only the unavailable-state gap remains.

### Tests for User Story 1

- [ ] T005 [P] [US1] `bloc_test` for `FavoritesCubit`: an unpublished property is **kept** as an unavailable entry (not dropped) on refresh, and `remove` clears it — in `test/features/favorites/favorites_cubit_unavailable_test.dart`.
- [ ] T006 [P] [US1] Golden for `FavoritesScreen` with one unavailable card among live cards (Light/Dark, RTL/LTR, 1.3×, 320/800 dp) in `test/features/favorites/favorites_unavailable_golden_test.dart`.
- [ ] T007 [P] [US1] `integration_test/favorites_unavailable_mock_test.dart`: favorite → unpublish (mock) → dimmed «غير متاحة حاليًا» → remove.

### Implementation for User Story 1

- [ ] T008 [US1] In `lib/features/favorites/presentation/favorites_cubit.dart`, stop dropping a favorite whose `listings.property(id)` fails: keep the id and mark it unavailable (add an `available` flag to the per-card entry / a minimal `unavailableIds` set in `FavoritesState`), preserving order and the existing optimistic `toggle`/`remove`.
- [ ] T009 [US1] In `lib/features/favorites/presentation/favorites_screen.dart`, render unavailable entries as a dimmed card labeled «غير متاحة حاليًا», non-navigable (no `onTap` to details/booking), with a working remove (heart) control; live cards unchanged.
- [ ] T010 [P] [US1] Add the `favoritesUnavailable` string to `lib/l10n/app_ar.arb` («غير متاحة حاليًا») and `lib/l10n/app_en.arb`, then regenerate localizations.

**Checkpoint**: US1 complete and independently testable.

---

## Phase 4: User Story 2 — Write a review after check-out (Priority: P1) 🎯 main increment

**Goal**: a guest with a confirmed check-out rates the stay (1–5 stars + optional comment); the review is
created once, shows «قيد المراجعة», and its status appears in booking details.

**Independent Test**: on a checked-out booking open «قيّم إقامتك» → 4 stars, no comment → success → status
«قيد المراجعة»; double-tap creates one review; a non-checked-out booking never shows the action.

### Tests for User Story 2

- [ ] T011 [P] [US2] `bloc_test` for `ReviewCubit`: «إرسال» disabled until a star is chosen; double-tap = one submit; success → `GuestReview(pending)`; each server error code maps to a failure — in `test/features/reviews/review_cubit_test.dart`.
- [ ] T012 [P] [US2] `bloc_test`/unit: `BookingActionRegistry.g5()` makes `submit_review` visible, and `BookingDetails.fromJson` parses `review` + a `submit_review` action — in `test/features/bookings/booking_review_action_test.dart`.
- [ ] T013 [P] [US2] Goldens for `ReviewScreen` (no-star disabled, stars chosen, submitting, error) and booking-details review states («قيّم إقامتك», «قيد المراجعة», «منشور», «غير مقبول») — Light/Dark, RTL/LTR, 1.3×, 320/800 dp, keyboard open — in `test/features/reviews/review_golden_test.dart`.
- [ ] T014 [P] [US2] `integration_test/review_mock_test.dart`: checked-out booking → review screen → 4 stars no comment → success → «قيد المراجعة» and action gone; second submit rejected `ALREADY_REVIEWED`; non-checked-out stay shows no action and a manual deep link is rejected.

### Implementation for User Story 2

- [ ] T015 [P] [US2] Create `ReviewsWriteRepository` interface in `lib/features/reviews/domain/reviews_write_repository.dart`: `Future<GuestReview> submit({required String bookingId, required int rating, required String? comment, required String idempotencyKey})`.
- [ ] T016 [P] [US2] Implement `MemoryReviewsWriteRepository` in `lib/features/reviews/data/memory_reviews_write_repository.dart`: enforce confirmed check-out and one-per-stay locally, idempotent on the key, return `status = pending`, throw the same `AppFailure` codes as V2 (`CHECKOUT_NOT_CONFIRMED`, `ALREADY_REVIEWED`, `COMMENT_TOO_LONG/SHORT`).
- [ ] T017 [P] [US2] Implement `SupabaseReviewsWriteRepository` in `lib/features/reviews/data/supabase_reviews_write_repository.dart`: call `guest_submit_review` via the shared `_rpc(fn, params)` + `_guard` pattern (as in `SupabaseStayRepository`), passing `p_booking_id`, `p_rating`, `p_comment`, `p_idempotency_key`.
- [ ] T018 [US2] Mock-server parity: make the mock `guest_get_booking` list `submit_review` in `available_actions` for a checked-out booking with no review, and include the `review` object once submitted (keep it in sync with `MemoryReviewsWriteRepository`) in the relevant mock under `lib/features/bookings/`/`lib/features/stay/data/` fixtures.
- [ ] T019 [US2] Register `ReviewsWriteRepository` (memory vs Supabase by `BackendMode`) in `lib/bootstrap.dart`, and provide it at app root in `lib/app/app.dart` (mirroring `FavoritesRepository`).
- [ ] T020 [P] [US2] Create `StarRatingInput` in `lib/features/reviews/presentation/widgets/star_rating_input.dart`: 1–5 interactive stars using the star token (`#FFB300` via `context.colors`), a `Semantics` label per star (e.g. «٣ من ٥»), 48×48 targets, RTL-correct order.
- [ ] T021 [US2] Create `ReviewCubit` in `lib/features/reviews/presentation/review_cubit.dart`: states idle(rating?, comment)/submitting/success(GuestReview)/failure(code); one UUIDv4 idempotency key per attempt reused on retry; `setRating`/`setComment`/`submit` → `ReviewsWriteRepository` (depends on T015, T003).
- [ ] T022 [US2] Create `ReviewScreen` in `lib/features/reviews/presentation/review_screen.dart`: Reviews gradient (§4.3), `StarRatingInput`, optional multiline comment with a provisional ~500-char counter hint, «إرسال» disabled until a star is chosen, submitting progress, success «شكرًا! هيظهر تقييمك بعد المراجعة» then pop, server errors via mapped localized messages (depends on T020, T021).
- [ ] T023 [US2] Wire the route in `lib/app/router/app_router.dart`: replace the `NotAvailableScreen` at `AppRoutes.bookingReviewPattern` with a builder that validates `:id` is UUIDv4 (else `NotAvailableScreen`) and provides `ReviewCubit` with the booking id (mirroring the `linked-support-case` builder).
- [ ] T024 [P] [US2] Map `BookingActionCode.submitReview` → `context.push('/bookings/:id/review')` in `lib/features/bookings/presentation/booking_action_ui.dart`.
- [ ] T025 [US2] In booking details (`lib/features/bookings/presentation/booking_details_screen.dart` + a widget under `lib/features/bookings/presentation/widgets/`), use `BookingActionRegistry.g5()` so «قيّم إقامتك» shows when the server lists `submit_review`, and render a review status line (plain-Arabic «قيد المراجعة»/«منشور»/«غير مقبول», text+icon, never color alone) with the guest's own stars/comment when `booking.review != null`; reload after returning from the review screen.
- [ ] T026 [P] [US2] Add review `.arb` keys to `lib/l10n/app_ar.arb` (screen title, star prompt, optional-comment label/hint, char-count hint, «إرسال», success message, status labels, «قيّم إقامتك», error messages for `CHECKOUT_NOT_CONFIRMED`/`ALREADY_REVIEWED`/`COMMENT_TOO_LONG`/`COMMENT_TOO_SHORT`/not-available) and the English equivalents to `lib/l10n/app_en.arb`; regenerate localizations.
- [ ] T027 [US2] Map the review error `code`s to the new localized messages in the app's error→message mapping (same place other `guest_*` codes are mapped); never show raw server text.

**Checkpoint**: US2 complete and independently testable (mock).

---

## Phase 5: User Story 3 — Read ratings & reviews (Priority: P2) — regression

**Goal**: approved rating + count and the reviews section/full list render correctly for guests and
visitors. **Already built**; this phase only verifies and fills any coverage gap.

**Independent Test**: a property with approved reviews shows the average/count + latest + «عرض الكل»; one
with none shows a neutral empty state; readable while signed out.

- [ ] T028 [P] [US3] Verify/confirm goldens exist for `property_reviews_section` and `ReviewsScreen` covering the approved list, abbreviated names, and the **no-approved-reviews** empty state (no misleading zero score) — add the missing case to `test/features/property/` if absent.
- [ ] T029 [P] [US3] Confirm an `integration_test` opens `/property/:id/reviews` as a visitor (signed out) and paginates; add the visitor case if missing.

**Checkpoint**: US3 verified.

---

## Phase 6: Polish & Cross-Cutting

- [ ] T030 [P] Run `flutter analyze` and `dart format` on all new/changed files; fix issues.
- [ ] T031 [P] Accessibility pass on the review screen and the favorites unavailable card (TalkBack/VoiceOver, focus order in RTL, star/heart semantics, 48×48, 1.3× text).
- [ ] T032 Run `quickstart.md` scenarios A, B and C end-to-end in mock mode and record the result.

---

## Dependencies & Execution Order

- **Setup (T001)** → first.
- **Foundational (T002–T004)**: T002/T003 are independent; T004 depends on T003. Blocks US2 only.
- **US1 (T005–T010)**: depends only on Setup — can run in parallel with US2/US3. Tests (T005–T007) before T008–T009; T010 independent.
- **US2 (T011–T027)**: depends on Foundational. Tests (T011–T014) first. Then T015 → T016/T017 (parallel) → T018/T019; widgets/cubit T020–T022; route+UI T023–T025; l10n/error T026–T027. T019, T023, T025 are sequential where they share files or providers.
- **US3 (T028–T029)**: independent regression; any time after Setup.
- **Polish (T030–T032)**: after the stories you intend to ship.

### Parallel opportunities

- US1 and US2 can be built by different developers in parallel after Setup+Foundational.
- Marked [P] tasks touch different files: e.g. T002/T003, T005/T006/T007, T015/T016/T017, T020 vs T024, and the ar/en `.arb` pairs (note: within one `.arb` file, edits are sequential — T010 and T026 both touch `app_ar.arb`, so order them).

---

## Implementation Strategy

- **MVP = US2** (the genuinely new value): Setup → Foundational → US2 → validate → demo. US1's gap (T005–T010) is small and can ship alongside; US3 is verification only.
- **Incremental**: US2 → US1 gap → US3 verify → Polish. Each story stays independently testable in mock mode; switching to remote needs V1–V4 in `onair-backend` and no UI change.

## Notes

- No backend SQL/migrations in this repo (AGENTS.md) — V1–V4 are implemented in `onair-backend`.
- Commit after each task or logical group. Prevent double-submit everywhere (heart and «إرسال») and
  verify light/dark + RTL + 1.3× per the project rules before accepting any UI task.
