# Quickstart — Validate Guest Favorites & Reviews (G5)

A run/validation guide. Implementation detail lives in the code and `tasks.md`; contracts and the data
model are referenced, not duplicated.

## Prerequisites

- Flutter stable, repo deps installed (`flutter pub get`).
- Mock mode (`BackendMode.mock`, Guest Plan §2.6) — the whole feature runs with no backend.
- A signed-in mock guest. Mock fixtures include a booking with a **confirmed check-out** (so the server
  lists `submit_review`) and a favorited property that becomes **unpublished**.

## Run

```powershell
flutter run --flavor staging -t lib/main_staging.dart --dart-define=BACKEND_MODE=mock
```

## Scenario A — Write a review (US2)

1. Open a completed booking (confirmed check-out) from «حجوزاتي» → details show **«قيّم إقامتك»**.
   - Expected: a booking without a confirmed check-out shows **no** such action.
2. Tap it → `/bookings/:id/review` opens on the Reviews gradient; «إرسال» is **disabled**.
3. Pick 4 stars (leave the comment empty) → «إرسال» enables.
4. Tap «إرسال» **twice fast**.
   - Expected: exactly one review is created; the button shows progress; success
     «شكرًا! هيظهر تقييمك بعد المراجعة»; back on booking details the status reads **«قيد المراجعة»** and the
     «قيّم إقامتك» action is gone.
5. Reopen the review route manually for the same booking.
   - Expected: the server (mock) rejects a second submission (`ALREADY_REVIEWED`) with a localized message.
6. (Mock) flip the review to `published` / `rejected`.
   - Expected: booking details show **«منشور»** / **«غير مقبول»**; after a rejection «قيّم إقامتك»
     reappears only if the server re-lists `submit_review`.
7. Open a `review.approved` / `review.rejected` / `stay.completed` notification.
   - Expected: it opens the matching booking details with the right status/action.

## Scenario B — Favorites, including unavailable (US1)

1. Favorite three apartments from home, search results, and details.
   - Expected: the heart fills immediately (optimistic) and is consistent across surfaces; «المفضلة» lists
     all three.
2. Toggle the heart fast / repeatedly on one.
   - Expected: final state matches the last tap; never more than one favorite row.
3. Make one favorited property unpublished (mock).
   - Expected: in «المفضلة» it now appears **dimmed with «غير متاحة حاليًا»**, is not navigable to a
     booking, and the heart still removes it. (Before G5 it silently disappeared.)
4. Open «المفضلة» with nothing saved → empty state; force a load failure → retryable error view.

## Scenario C — Read reviews (US3, regression)

1. Open an apartment with approved reviews → average rating + count near the title, latest approved
   reviews in the Reviews section, «عرض الكل» → full list paginates; names abbreviated; no personal data.
2. Open an apartment with no approved reviews → neutral empty state, no misleading zero score.
3. As a visitor (signed out) the rating and reviews are still readable.

## Automated checks

```powershell
flutter analyze
flutter test
flutter test integration_test/review_mock_test.dart
flutter test integration_test/favorites_unavailable_mock_test.dart
```

- Unit/bloc: `ReviewCubit` (disabled-until-star, single-submit, success, each error code),
  `FavoritesCubit` (unavailable flag kept, remove works), `BookingActionRegistry.g5()` includes
  `submit_review`, `BookingDetails` parses `review`.
- Goldens: review screen (empty/stars/submitting/error), booking-details statuses, favorites unavailable
  card — each across Light/Dark, RTL/LTR, 1.3×, 320/800 dp.

## Definition of done (maps to Success Criteria)

- SC-004/005: review submittable in < 1 min, one per stay, action only after confirmed check-out.
- SC-006: details show correct approved average/count, abbreviated names, no reviewer identity.
- SC-001/002/003: favorites add/remove in one tap, consistent across surfaces, single row under fast taps,
  reachable from «المفضلة»; unavailable favorites shown dimmed and removable.
- SC-007: all new screens pass Arabic RTL + dark + 1.3× with full UX states and no hard-coded text.
- SC-008: fully usable in mock mode; remote switch (V1–V4) needs no UI change.

## Staging (after V1–V4 ship in `onair-backend`)

- Switch to remote (`BACKEND_MODE=remote`), seed a checked-out booking, submit a review, moderate it in
  Admin web, and confirm the guest sees «قيد المراجعة» → «منشور»/«غير مقبول» and the approved review
  appears in that property's public list with the shortened name.
