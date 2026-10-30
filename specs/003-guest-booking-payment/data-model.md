# Data Model: Guest Booking & Payment (G2)

App-side entities, validation, and state. Wire shapes and backend deltas are in
[contracts/supabase-booking.md](contracts/supabase-booking.md). All amounts are `Money`
(int piasters, `EGP`); stay dates are `DateOnly` / `StayRange` (G1); instants are UTC from the
server and shown in `Africa/Cairo` (`CairoTime`). No entity holds a value the app computed from
other amounts.

## 1. BookingDraft (flow state, in memory)

Lives in `BookingFlowCubit`, scoped to the `/book/:propertyId` route branch.

| Field | Type | Source / rule |
|---|---|---|
| `propertyId` | UUID | route; UUID v4 validated |
| `property` | `PropertyDetails` (G1) | fetched; supplies max guests, photo, title, area |
| `acceptedTermsHash` | String (1–128) | `terms` query from "Book now" (= G1 `termsVersion`, AC-013) |
| `stay` | `StayRange?` | from query or picked; arrival ≥ today (Cairo), departure > arrival, ≤ 90 nights |
| `guests` | int | 1 … `property.maxGuests` |
| `unavailableDays` | `Set<DateOnly>` | `guest_get_property_unavailable_dates`; picker disables them |
| `quote` | `BookingQuote?` | last server quote |
| `pendingChange` | `QuoteChange?` | set after a re-quote that differs; blocks payment until confirmed |

**Validation (local, UX only, FR-004)**: invalid ranges disable "Continue"; the nights label
uses `StayRange.nights` for display. The server re-checks everything at quote time.

**Transitions**: `editing` → (`Continue`) `quoting` → `quoted` | `quoteRejected(code)`;
`quoted` → (`expiry` or `QUOTE_EXPIRED`) `requoting` → `quoted` (+ `pendingChange` if different);
`TERMS_CHANGED` → `termsChanged(newTermsHash)` → guest re-accepts → `editing`.

## 2. BookingQuote (from `guest_quote_booking`)

| Field | Type | Notes |
|---|---|---|
| `quoteId` | UUID | sent to payment start |
| `propertyId` | UUID | |
| `stay` | `StayRange` | `check_in`, `check_out` |
| `nights` | int | server value; shown as-is |
| `guests` | int | `guests_count` |
| `nightly` | Money | `nightly_minor` (final price incl. margin; margin never visible) |
| `total` | Money | `total_minor` |
| `payNow` | Money | `pay_now_minor` (deposit or full) |
| `remaining` | Money | `remaining_minor`; zero ⇒ fully paid now |
| `remainingDueAt` | DateTime? | requested in contract D0 (§4); hidden when null |
| `termsHash` | String | must equal `acceptedTermsHash` |
| `policySummary` | `PolicySummary` (G1) | requested in D0; G1 fallback text from the property |
| `expiresAt` | DateTime (UTC) | re-quote at `expiresAt − 30 s` |

## 3. QuoteChange

Field-by-field comparison of two quotes: `nightly`, `total`, `payNow`, `remaining`,
`remainingDueAt`, `termsHash`. `hasChanges` ⇒ the summary highlights the changed rows (old value
struck through, new value shown) and requires "Confirm new amounts" before payment. Pure
comparison; produces no new amount.

## 4. PaymentAttempt (secure storage, one at a time)

| Field | Type | Rule |
|---|---|---|
| `attemptKey` | UUID v4 | created on first "Go to payment"; reused for every retry (AC-023) |
| `quoteId` | UUID | |
| `propertyId` | UUID | |
| `termsHash` | String | |
| `bookingId` | UUID? | set from `PaymentSession.booking_id` |
| `paymentUrlExpiresAt` | DateTime? | after this, reopening the page needs a retry with the same key |
| `startedAt` | DateTime | |

**Lifecycle**: `created` (saved before the request) → `sessionReady` (booking ID + URL saved,
browser opened) → `returned` (link or resume) → deleted on final outcome
(`success`, `conflict`), on `failed` + "Try again" (a new attempt replaces it), on sign-out, or
when reconciliation (research R5) shows the server no longer has it pending.

Key: `payment_attempt.current`. Never logged except the first 8 characters of the key.

## 5. BookingStatus and tabs

Server values (as-built check constraint): `payment_pending`, `payment_verifying`,
`awaiting_owner`, `payment_conflict`, `confirmed`, `checked_in`, `completed`, `rejected`,
`expired`, `cancelled`, `no_show`, `abandoned`. Unknown values map to `unknown` (generic message,
no actions).

| Tab (server `p_tab`, delta D2) | Statuses | Order |
|---|---|---|
| `current` | payment_verifying, awaiting_owner, confirmed, checked_in | nearest check-in first |
| `past` | completed | newest first |
| `cancelled` | rejected, expired, cancelled, no_show, payment_conflict | newest first |
| `pending` (banner only) | payment_pending | newest first |
| — | abandoned | never shown |

Each status has one message key (`bookingStatusMessage<Status>`, Guest Plan §7.2) and one chip
style (Guest Plan §4.6). The app shows the server's status; it never moves a booking between
statuses.

## 6. VerificationOutcome (payment return screen)

Computed only from server fields of `guest_get_booking` (`status`, `payment_state`, delta D1).
Link parameters are ignored for the outcome (FR-016).

| Server state | Outcome | UI |
|---|---|---|
| `awaiting_owner` (or any later status) | `success` | ✓ paid + sent to owner, countdown to `ownerResponseDeadline`, "View booking"; ask push permission once |
| `payment_conflict` | `conflict` | full refund message + "Find other dates" |
| `payment_pending` + `payment_state = failed` | `failed` | "not completed, nothing charged" + "Try again" (new attempt) |
| `payment_pending` + `payment_state = pending`, or `payment_verifying` | `waiting` | "Verifying…" (keep listening/polling) |
| still `waiting` after ≈ 120 s | `timeout` | "not confirmed yet, don't pay again" + "Go to My Bookings" |
| fetch refused (`NOT_FOUND`) | `notAvailable` | neutral screen |

No outcome shows any "Pay again" control while `waiting` (FR-014).

## 7. BookingSummary (list card, from `guest_list_bookings`)

`id`, `code`, `propertyId`, `title`, `coverImage` (`ListingImage`, G1), `stay`, `status`,
`refundStatus?`, `ownerResponseDeadline?`, `createdAt` (cursor). Cached per tab (first page).

## 8. BookingDetails (from `guest_get_booking`)

| Group | Fields |
|---|---|
| Header | `id`, `code` (copyable), `status`, `refund?.stage` |
| Property | `propertyId`, `title`, `coverImage`, `areaName`, `cityName`, `addressText?` (D-001) |
| Stay | `stay`, `nights`, `guests`, `checkInTime?`, `checkOutTime?` |
| Money | `total`, `paid`, `remaining`, `remainingDueAt?`, `payments: List<PaymentLine>` |
| Refund | `refund: RefundInfo?` |
| Terms | `termsSnapshot: PolicySummary` (saved at booking, not current) |
| Owner | `ownerResponseDeadline?` |
| Arrival | `accessInstructions?` — never cached in the file; see §11 |
| Timeline | `events: List<BookingEvent>` |
| Actions | `availableActions: List<BookingAction>` |
| Payment | `paymentState` (`pending` / `failed` / `succeeded`) for §6 |
| Meta | `fetchedAt` (local, for "Last updated") |

## 9. PaymentLine, RefundInfo, BookingEvent, BookingAction

- **PaymentLine**: `amount` Money, `status` (`pending`, `verifying`, `succeeded`, `failed`,
  `cancelled`, `expired`, `pending_guest_confirmation`), `method` (`kashier`, `cash`),
  `paidAt?`, `purpose` (`initial`, `remaining`). Labels avoid accounting terms.
- **RefundInfo**: `amount` Money, `stage` — server `requested` → «طُلب», `approved` → «اعتُمد»,
  `executed` → «قيد التنفيذ», `verified` → «تم التحقق من وصوله»; `failed` / `cancelled` → shown
  with a support hint. "Refunded" copy only for `verified` (AC-042).
- **BookingEvent**: `eventType`, `toStatus?`, `createdAt`, `note?` (only `visibility = all`).
  Timeline text from `bookingEvent<Type>` keys; unknown types show the status label.
- **BookingAction**: code string. G2 registry: `contact_support`. All other codes
  (`pay_remaining`, `confirm_cash_payment`, `request_cancellation`, `confirm_checkin`,
  `confirm_checkout`, `respond_damage_claim`, `write_review`, unknown) are dropped (FR-023).

## 10. AppNotification (from `common_list_notifications`)

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `typeKey` | String | e.g. `booking.confirmed`; drives text and route |
| `category`, `priority` | String | display grouping only |
| `entityType`, `entityId` | String, UUID | target |
| `params` | Map | ARB placeholders; minor-unit amounts formatted by `Money` |
| `readAt` | DateTime? | unread when null |
| `createdAt` | DateTime | cursor (page size 30) |

**NotificationSignal** (Realtime): `id`, `typeKey`, `entityType`, `entityId`. **Unread count**:
`common_unread_count()`; incremented on a signal, refetched on resume and after mark-read.
**Permission state**: `notDetermined`, `granted`, `denied`; `askedOnce` flag in preferences.

## 11. Local storage summary

| Store | Holds | Cleared |
|---|---|---|
| `BookingsCache` (JSON file per guest) | first page per tab, viewed details **without** `accessInstructions`, `fetchedAt` | sign-out |
| `ArrivalInstructionsStore` (secure, `arrival.<bookingId>`) | instructions of `confirmed` / `checked_in` bookings | sign-out; on refresh with `completed`, `cancelled`, `rejected`, `expired`, `no_show` |
| `PaymentAttemptStore` (secure, `payment_attempt.current`) | §4 | §4 lifecycle; sign-out |
| Preferences | `push_permission_asked` (bool) | never (not personal) |

Nothing here is used to decide a status, amount, or permission.
