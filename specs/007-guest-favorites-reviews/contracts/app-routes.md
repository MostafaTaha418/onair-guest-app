# Contract — App routes & notification routing (G5)

All routes already exist in `AppRoutes` / `app_router.dart`; G5 only wires one placeholder and relies on
existing notification routing. Account-gated routes keep the sign-in gate + return-to-origin.

## Routes

| Route | Screen | Auth | Change in G5 |
|---|---|---|---|
| `/favorites` | `FavoritesScreen` | required | Render unavailable favorites dimmed «غير متاحة حاليًا» (no routing change). |
| `/property/:id` | property details (rating + reviews section) | no | None (reading already built). |
| `/property/:id/reviews` | `ReviewsScreen` (all approved) | no | None. |
| `/bookings/:id` | booking details | required | Show review status + «قيّم إقامتك» when server lists `submit_review`. |
| `/bookings/:id/review` | **`ReviewScreen`** | required | **Replace `NotAvailableScreen` placeholder** with the real screen (provide `ReviewCubit`); validate `:id` is UUIDv4 → `NotAvailableScreen` if not. |

- `/bookings/:id/review` is already in the account-gated branch and in the `_bookingReview` deep-link
  allow-list in `routes.dart`. The builder provides a `ReviewCubit` (with `ReviewsWriteRepository` and the
  booking id) exactly as `linked-support-case` provides `CaseDetailsCubit`.

## Notification routing (unchanged — verify only)

`notification_router.dart` already maps these to booking details; G5 just makes that screen show what they
point at:

| Notification type | Lands on | Note |
|---|---|---|
| `stay.completed` | `/bookings/:id` | Review invite (Guest Plan §9.3). Booking details offers «قيّم إقامتك» if the server lists the action. |
| `review.approved` | `/bookings/:id` | Status now shows «منشور». |
| `review.rejected` | `/bookings/:id` | Status now shows «غير مقبول» (and «قيّم إقامتك» reappears only if the server re-lists `submit_review`). |

- A non-UUID or unknown entity id falls back to `/bookings` (existing behavior); nothing about a booking
  is revealed on a bad id.

## Navigation from booking details

- `booking_action_ui` maps `BookingActionCode.submitReview` → `context.push('/bookings/:id/review')`.
- On submit success the review screen pops back; booking details reloads via its existing cubit and shows
  «قيد المراجعة».
