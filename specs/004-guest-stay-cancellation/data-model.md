# Data Model: Guest Stay & Cancellation (G3)

Entities the app reads or keeps for G3. Wire names are in
[contracts/supabase-stay.md](contracts/supabase-stay.md). Money is `Money` (int piasters, EGP);
instants are UTC `DateTime` shown in Cairo time; stay dates are `DateOnly`. No field below is
computed by the app.

## 1. BookingDetails — G3 additions (from `guest_get_booking`, S1)

Extends G2 `BookingDetails` (G2 data-model §8). New fields:

| Field | Type | Notes |
|---|---|---|
| `acknowledgements` | `StayAcknowledgements` (§4) | always present; times null until confirmed |
| `pendingCash` | `CashRequest?` (§2) | the collector-started request waiting for the guest's code |
| `pendingRemainingPaymentId` | `String?` | an open `pending`/`verifying` remaining payment |
| `damageClaims` | `List<DamageClaimSummary>` (§7) | every claim on the booking, newest first |
| `replacementOffer` | `ReplacementOffer?` (§8) | open offer, or the latest answered one |
| `payments[].receipt` | `CashReceipt?` (§3) | only on succeeded cash payments |
| `cancellation` | `CancellationInfo?` | `{cancelledAt, byScope ∈ guest/platform, reasonCode}` once cancelled |

**Cache rule:** `toCacheJson()` keeps all of the above except `pendingCash.challengeId`, which is
fetched fresh before the code step.

**Derived for display only (pure functions, server order):**

- `firstGuestAction(availableActions)`: the first code in the G3 registry other than
  `contact_support`. It feeds the "Needs your action" line on cards and the filled primary
  button. `request_cancellation` is never chosen as primary; if it is the only one, the bar
  shows it as a destructive text button.

## 2. CashRequest

| Field | Type | Rule |
|---|---|---|
| `paymentId` | `String` (UUID) | from the server |
| `challengeId` | `String` (UUID) | from the server; never cached, never logged |
| `collectorDisplayName` | `String` | as returned (for example "أحمد م."); no phone shown |
| `amount` | `Money` | = the remaining amount at creation; read-only |
| `maskedEmail` | `String` | server-masked (`m***@gmail.com`); the app never builds it |
| `codeExpiresAt` | `DateTime` | for the "code valid until" hint |
| `resendAvailableAt` | `DateTime?` | from `retry_after_seconds`; drives the resend countdown |
| `origin` | `guest` \| `collector` | which entry created it |

**Phone input (guest-started entry):** the number is normalised with the G0 Egyptian formatter
to E.164. It must be a valid Egyptian mobile (`+201[0125]` + 8 digits). An invalid number shows a
field error and sends nothing.

**State machine (`CashConfirmCubit`):**

`phoneEntry` → `starting` → `codeEntry` ⇄ `resending` → `confirming` → `receipt`. Errors:

| From | Error | Goes to |
|---|---|---|
| `starting` | `COLLECTOR_NOT_AUTHORIZED` | `notAuthorized`, with a support action |
| `starting` | `CASH_NOT_ALLOWED` | `notAllowed` |
| `starting` | `CASH_AMOUNT_CHANGED` | refresh the booking, back to `phoneEntry` with the new amount, or close if remaining = 0 |
| `confirming` | `OTP_INVALID` / `OTP_EXPIRED` | `codeEntry` with an error |
| any | `RATE_LIMITED` | resend disabled until `retry_after` |

## 3. CashReceipt

`{paymentId, amount, collectorDisplayName, confirmedAt, receiptNo}`. It is shown on the receipt
screen right after a confirmation and later from the payments section, including offline from
cache.

## 4. StayAcknowledgements

| Field | Type |
|---|---|
| `guestCheckInAt`, `hostCheckInAt` | `DateTime?` |
| `guestCheckOutAt`, `hostCheckOutAt` | `DateTime?` |
| `keyLeftSafe` | `bool` |

**Display mapping (`AcknowledgementTracker`):**

| Status | Guest step | Owner step | Message |
|---|---|---|---|
| `confirmed`, both null | — | — | no tracker; the status message only |
| `confirmed`, guest set | "You confirmed {time}" | "Waiting for the owner" | "Waiting for the owner to confirm the handover" |
| `confirmed`, host set only | "Waiting for you" | "The owner handed over {time}" | "The owner confirmed the handover. Confirm you received the apartment" |
| `checked_in` | both done | both done | "Have a nice stay" (§7.2) |
| `checked_in`, guest checkout set | "You confirmed leaving {time}" | "Waiting for the owner" (+ "Key left in the agreed place" when `keyLeftSafe`) | "Waiting for the owner to confirm receiving the apartment" |
| `completed` | done | done | "Your stay is complete" |

The status changes only when the server's `status` changes.

## 5. CancellationPreview

| Field | Type | Notes |
|---|---|---|
| `refund` | `Money` | amount that will be returned |
| `nonRefundable` | `Money` | may be zero |
| `policyCase` | `free` \| `depositLost` \| `noRefund` | chooses the `.arb` sentence |
| `freeCancellationUntil` | `DateTime?` | used in the sentence |
| `previewToken` | `String` | opaque; sent back for audit, never shown |
| `validUntil` | `DateTime` | after it the screen re-previews before confirming |

**`PreviewChange`:** compares old vs new preview, field by field (`refund`, `nonRefundable`,
`policyCase`), and marks changed rows. It only highlights and never computes.

**Reason:** `CancellationReason ∈ {changeOfPlans, foundOtherPlace, travelProblem, other}`, plus
an optional note (≤ 300 characters, `other` only).

**State machine (`CancellationCubit`):** `loadingPreview` → `ready(preview, reason)` →
`confirmingDialog` → `submitting` → `done`. Errors and exits:

- `CANCELLATION_TERMS_CHANGED`: the Cubit calls the preview again, then emits
  `ready(newPreview, changes)` with a confirmation required again.
- `INVALID_BOOKING_STATE`: refresh, then back to details with a message.
- "Keep my booking": the screen pops and nothing is sent.

## 6. PaymentAttempt — G3 change (secure storage)

| Field | `initial` (G2) | `remaining` (G3) |
|---|---|---|
| `kind` | `initial` | `remaining` |
| `attemptKey` | UUID v4 | UUID v4 |
| `quoteId`, `propertyId`, `termsHash` | required | null |
| `bookingId` | set after start | required from the start |
| `paymentId` | set after start | set after start |
| `paymentUrl`, `paymentUrlExpiresAt`, `startedAt` | as G2 | as G2 |

- **Old records:** a stored record without `kind` reads as `initial`, which keeps old installs
  compatible.

**Verification outcome by kind:**

| Kind | Read from | Outcome |
|---|---|---|
| `initial` | booking `status` + `payment_state` | unchanged from G2 data-model §6 |
| `remaining` | the payment line with `id == paymentId` | `succeeded` → success; `failed` / `cancelled` / `expired` → failed; else → waiting |
| `remaining` | the line is missing | waiting |

## 7. DamageClaim

**`DamageClaimSummary`** (in booking details): `{id, amount, status, createdAt}`.

**`DamageClaim`** (from `guest_get_damage_claim`, S6):

| Field | Type | Notes |
|---|---|---|
| `id`, `bookingId` | `String` | the booking ID is checked against the route's `:id` |
| `description` | `String` | the owner's text, shown as plain text |
| `amount` | `Money` | the claimed amount |
| `status` | `open` \| `guestAccepted` \| `guestDisputed` \| `inMediation` \| `resolved` \| `withdrawn` \| `unknown` | chip text + icon |
| `evidence` | `List<EvidenceRef>` | `{attachmentId, kind ∈ image}`; URLs are never stored |
| `guestResponse` | `{decision, note, respondedAt}?` | |
| `supportCaseNumber` | `String?` | shown after a dispute |
| `resolution` | `{outcomeCode, amount?, decidedAt}?` | sentence from `.arb` by `outcomeCode` |
| `canRespond` | `bool` | from the server (= `respond_damage_claim` is in the booking's actions) |

**Answer validation:** a dispute reason is trimmed and must be 10 to 1000 characters
(`ClaimLimits`). "I agree" needs no note.

**Status chip mapping:**

| Status | Chip tone |
|---|---|
| `open` | warning |
| `guestAccepted`, `resolved` | completed |
| `guestDisputed`, `inMediation` | pending |
| `withdrawn` | cancelled |

**Evidence URL cache (memory only, `EvidenceUrlCache`):** maps an attachment ID to
`{url, expiresAt}`. An entry is refetched when it is within 30 s of expiry or when a load fails.
The cache is cleared when the screen closes.

## 8. ReplacementOffer

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | |
| `status` | `pending` \| `accepted` \| `declined` \| `expired` \| `withdrawn` | |
| `property` | `{id, title, areaName, coverImage}` | card visuals as G1 `PropertyCard` small variant |
| `stay` | `StayRange` | |
| `priceDifference` | `Money` (signed) | the sign chooses the sentence; the value is shown as `abs` |
| `expiresAt` | `DateTime?` | the card shows "Answer before {time}" |

Answers are shown only when `status == pending`. Accept or decline goes through a dialog and is
sent once (`ActionAttemptStore`).

## 9. ActionAttempt (secure storage)

Key: `action_attempt.<action>.<entityId>`; value: `{key: UUID v4, createdAt}`.

- **Actions:** `cancel`, `claim_answer`, `offer_answer`, `cash_start`. Check-in and check-out
  need no key: the as-built functions record each side once, so a retry is harmless.
- **Lifecycle:** created on the first tap, reused on a network-error retry, and deleted on any
  server response (success or business error) and at sign-out.

## 10. BookingSummary — G3 addition (from `guest_list_bookings`, S2)

Adds `availableActions: List<String>` (same codes as details), so the card can show the
"Needs your action" line. It uses `firstGuestAction` and is labelled with the action's `.arb`
text.

## 11. Local storage summary

| Data | Where | Removed |
|---|---|---|
| Booking details incl. acknowledgements, claim summaries, offer, receipts | JSON file cache (per guest) | sign-out |
| `pendingCash.challengeId` | not stored | — |
| PaymentAttempt (`initial` or `remaining`) | secure storage | final outcome, "Try again", sign-out |
| ActionAttempt keys | secure storage | server answer, sign-out |
| Evidence URLs and images | memory only | screen close |
| Collector phone typed by the guest | memory only (Cubit) | screen close |
