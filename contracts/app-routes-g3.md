# Contract: G3 Routes, Entry Rules, and Notification Routing

Extends [G2 app-routes](app-routes-g2.md). These G2
rules still apply:
- every ID from a route, query, or push payload is UUID v4–validated;
- a failed check or a refused fetch shows the neutral "Not available" screen;
- no route changes state on arrival.

## 1. Routes

| Path | Screen | Account | Linkable | Query (whitelisted) |
|---|---|---|---|---|
| `/bookings/:id` | Booking details (G2) + G3 sections | yes | yes | `focus` ∈ `offer`, `claims`, `payments` |
| `/bookings/:id/remaining-payment` | Remaining payment (replaces G0 placeholder) | yes | yes (notification) | none |
| `/bookings/:id/cash-confirm` | Cash confirmation (phone step or code step) | yes | yes (notification) | none |
| `/bookings/:id/receipts/:paymentId` | Cash receipt | yes | yes (notification) | none |
| `/bookings/:id/cancel` | Cancellation preview + reason | yes | **no** | none |
| `/bookings/:id/damage-claim/:claimId` | Damage claim (replaces G0 placeholder) | yes | yes | none |
| `/damage-claims/:claimId` | Resolver: fetches the claim, then `replace`s with the full path | yes | yes (notification) | none |
| `/payment/return` | Verification (G2) — now also for remaining payments | yes | yes | `booking` (UUID) |

- The evidence viewer is a full-screen page pushed with `Navigator.push` from the claim screen,
  not a router path.
- Check-in and check-out are **bottom sheets** over `/bookings/:id`, not routes. A sheet cannot
  be opened by a link.
- `/bookings/:id/cancel` is not linkable. A cancellation always starts from the details screen
  the guest is looking at.
- `/bookings/:id/review` stays a G0 placeholder ("Not available") until G5.

## 2. Entry rules

1. Every G3 screen loads the booking (or claim) first:
   - if the needed action is no longer in `available_actions`, it replaces itself with
     `/bookings/:id` and shows a short "This step isn't available now" banner;
   - claim screens are always readable, and only the answer buttons need
     `respond_damage_claim`.
2. `/bookings/:id/remaining-payment`:
   - if a remaining `PaymentAttempt` is open, or the booking has `pending_remaining_payment_id`,
     it goes to `/payment/return?booking=<id>` instead of offering a new payment.
3. `/bookings/:id/cash-confirm`:
   - with `pending_cash` it opens the code step;
   - otherwise, with `confirm_cash_payment` allowed, it opens the phone step;
   - otherwise it falls back to details.
4. `/bookings/:id/receipts/:paymentId`:
   - it reads the receipt from the booking's `payments` (cache allowed);
   - if there is no receipt for that payment, it falls back to details.
5. `/damage-claims/:claimId`:
   - it calls `guest_get_damage_claim`;
   - on success it replaces itself with `/bookings/<bookingId>/damage-claim/<claimId>`;
   - on `NOT_FOUND` it shows "Not available".
6. `/bookings/:id/damage-claim/:claimId` checks that `claim.booking_id == :id`, else it shows
   "Not available".
7. Back from any G3 screen returns to `/bookings/:id`. After a successful action, the screen pops
   with a result, and details refreshes and shows a success `NoticeCard` for 1 cycle.

## 3. Notification routing table (G3 changes)

Only the rows that change from G2 §4 are listed. Unknown types, a wrong entity type, or an
invalid ID → `/bookings`.

| `type_key` | Entity | G3 location |
|---|---|---|
| `payment.remaining_due` | booking | `/bookings/<id>/remaining-payment` |
| `cash.confirmation_requested` | booking | `/bookings/<id>/cash-confirm` |
| `cash.payment_confirmed` | payment (+`params.booking_id`) | `/bookings/<booking_id>/receipts/<id>`; without `booking_id` → `/bookings` |
| `damage.claim_opened`, `damage.resolved` | damage_claim | `/damage-claims/<id>` |
| `booking.replacement_offered` | booking | `/bookings/<id>?focus=offer` |
| `refund.requested`, `refund.executed`, `refund.verified` | booking | `/bookings/<id>?focus=payments` |
| all other `booking.*`, `stay.*`, `payment.remaining_paid` | booking | `/bookings/<id>` (unchanged) |

**Push taps:** a push tap carries only `type` + `target_id`. For `cash.payment_confirmed`, the
push tap goes to `/bookings` unless the center row (with `params`) is available. This is an
accepted limitation that keeps the payload minimal.

## 4. Action code → UI (BookingActionLauncher)

| Code | Opens |
|---|---|
| `pay_remaining` | `/bookings/:id/remaining-payment` |
| `confirm_cash_payment` | `/bookings/:id/cash-confirm` |
| `request_cancellation` | `/bookings/:id/cancel` |
| `confirm_checkin` | check-in sheet |
| `confirm_checkout` | check-out sheet |
| `respond_damage_claim` | `/bookings/:id/damage-claim/<first open claim>` |
| `contact_support` | `/support/new?booking=:id` (G2) |
| `write_review`, unknown | not shown |
