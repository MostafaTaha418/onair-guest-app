# Contract: G2 Routes, Payment Return, and Notification Routing

Extends [G1 app-routes](../../002-guest-discovery/contracts/app-routes.md). All IDs from links,
queries, and push payloads are UUID v4–validated before use; a failed check or a refused fetch
shows the neutral "Not available" screen. No route changes state on arrival.

## 1. Routes

| Path | Screen | Account | Linkable | Query (whitelisted) |
|---|---|---|---|---|
| `/book/:propertyId/verify` | Verify email/phone before booking | yes | no | `returnTo` ∈ `dates`, `summary`; carried draft keys |
| `/book/:propertyId/dates` | Date step (replaces G1 placeholder) | yes | no | `checkIn`, `checkOut`, `guests`, `terms` (from G1 "Book now") |
| `/book/:propertyId/summary` | Booking summary | yes | no | none (state lives in `BookingFlowCubit`) |
| `/payment/return` | Verification screen | yes | **yes** (Kashier return) | `booking` (UUID) — navigation hint only |
| `/bookings` | My Bookings | yes | no | `tab` ∈ `current`, `past`, `cancelled` |
| `/bookings/:id` | Booking details | yes | yes (notifications) | none |
| `/notifications` | Notification center | yes | no | none |

- `/book/:propertyId/*` share one `ShellRoute` that provides `BookingFlowCubit`; leaving the
  branch disposes the draft (the payment attempt record is separate and survives).
- Deep-linking into `/book/...` is not allowed (`isLinkablePath` stays false), so a link cannot
  carry terms acceptance.
- `/payment/return` without a valid `booking` uses the stored payment attempt; with neither, it
  redirects to `/bookings`.
- `/bookings/:id/remaining-payment`, `/bookings/:id/damage-claim/:claimId`,
  `/bookings/:id/review` stay registered (G0) and keep showing "Not available" until G3/G5.

## 2. Flow entry and return rules

1. "Book now" (G1) → `/book/:propertyId/dates?checkIn&checkOut&guests&terms`.
2. The dates route checks `common_get_my_context()`; if email or phone is unconfirmed it replaces
   itself with `/book/:propertyId/verify?returnTo=dates` (draft keys kept).
3. Verify success → `returnTo` location with the same draft.
4. "Continue" with a quote → push `/book/:propertyId/summary`.
5. `PHONE_NOT_VERIFIED` / `EMAIL_NOT_VERIFIED` at payment start → push
   `/book/:propertyId/verify?returnTo=summary`; on success pop back to the summary (quote kept,
   re-quoted if expired).
6. Payment session ready → open the in-app browser; on link or resume → `go('/payment/return?booking=<id>')`
   (clears the booking branch from the stack).
7. "View booking" → `/bookings/<id>`; "Find other dates" → `/property/<propertyId>`;
   "Go to My Bookings" → `/bookings?tab=current`; "Try again" → back to the summary with a new
   attempt (re-quote if needed).
8. Session expiry anywhere in the branch uses the G0 return-after-sign-in rule to the same path.

## 3. Payment return link

```
https://<LINK_DOMAIN>/payment/return?booking=<booking_uuid>
```

- Served by the verified-links setup from G1 (`contracts/verified-links.md`); `/payment/return`
  is already listed in the app's linkable paths.
- Any other query key (`status`, `intent`, provider fields) is dropped by the link parser.

## 4. Notification routing table

`NotificationRouter.locationFor(typeKey, entityType, entityId)`; used for push taps and center
taps. Unknown type, wrong entity type, or invalid ID → `/bookings`.

| `type_key` | Location in G2 | Later phase target |
|---|---|---|
| `booking.request_received`, `booking.confirmed`, `booking.rejected`, `booking.expired`, `booking.payment_conflict`, `booking.cancelled_by_guest`, `booking.cancelled_by_platform`, `booking.no_show_recorded`, `booking.reopened`, `booking.replacement_offered` | `/bookings/<id>` | offer section (G3) |
| `payment.failed`, `payment.remaining_paid`, `cash.payment_confirmed` | `/bookings/<id>` | — |
| `payment.remaining_due` | `/bookings/<id>` | `/bookings/<id>/remaining-payment` (G3) |
| `cash.confirmation_requested` | `/bookings/<id>` | `/bookings/<id>/cash-confirm` (G3) |
| `stay.*` | `/bookings/<id>` | — |
| `refund.requested`, `refund.executed`, `refund.verified` | `/bookings/<id>` | — |
| `damage.claim_opened`, `damage.resolved` | `/bookings/<id>` | `/bookings/<id>/damage-claim/<claimId>` (G3) |
| `review.approved`, `review.rejected` | `/bookings/<id>` | — |
| `support.staff_replied`, `support.case_resolved` | `/support/new` placeholder (G1) | `/support/<caseId>` (G4) |
| `account.phone_changed`, `account.password_changed` | `/account` | `/account/security` (G4) |
| anything else | `/bookings` (generic text) | — |

Tapping marks the notification read (`common_mark_notifications_read([id])`) before navigating;
a failed mark-read never blocks navigation.

## 5. Push payload

```json
{ "type": "booking.confirmed", "target_id": "<uuid>" }
```

`target_id` is the `entity_id` of the notification row. No other field is read. Foreground
messages show the in-app banner (text from the same ARB table) and emit a refresh signal; the
banner's tap uses §4.
