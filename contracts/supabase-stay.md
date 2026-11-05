# Contract: Stay, Cash, Cancellation, Claims, and Offers (Guest App, G3)

This is a draft for the backend owner.
- **Single source of names:** `docs/OnAir Backend Master Plan.md` (§7.5 offers, §7.6 claims,
  §8.1 payments, §8.3 refunds, §12 functions).
- **As-built facts** come from `onair-backend` migrations:
  - `20261028183127_stay_lifecycle` (check-in and check-out);
  - `20261028183927_remaining_payment`;
  - `20261028184123_refund_workflow`;
  - plus `contracts/node-api.openapi.yaml`.
- **Where changes go:** nothing here is implemented in this repository (AGENTS.md). Changes go
  to `onair-backend` in their own commits.

Rules from the G2 contract §0 still apply:
- `security definer`, `authenticated` only, ownership by `guest_user_id = auth.uid()`;
- `P0001` codes; minor-unit amounts with `currency = 'EGP'`; UTC instants.

## 1. Calls the app makes in G3

| Call | Status | Used for |
|---|---|---|
| `guest_get_booking(p_booking_id)` | exists (G2 D1) — **needs S1** | details sections, remaining outcome |
| `guest_list_bookings(p_tab, p_cursor)` | exists (G2 D2) — **needs S2** | "Needs your action" line |
| Node `POST /v1/guest/bookings/{id}/remaining-payment` `{idempotency_key}` → `PaymentSession` | exists | remaining payment |
| `guest_confirm_checkin(p_booking_id)` → `text` (new status) | exists — **S8 errors** | "I received the apartment" |
| `guest_confirm_checkout(p_booking_id)` → `text` | exists — **S8 errors** | "I left the apartment" |
| `guest_preview_cancellation(p_booking_id)` | **missing — S3** | cancellation preview |
| `guest_cancel_booking(p_booking_id, p_expected_refund_minor, p_reason, p_reason_note, p_idempotency_key)` | **missing — S3** | cancel |
| `guest_start_cash_confirmation(p_booking_id, p_collector_phone, p_expected_amount_minor, p_idempotency_key)` | **missing — S5** | guest-started cash |
| Node `POST /v1/otp/send` `{challenge_id}` | exists | email code for cash |
| `guest_confirm_cash_payment(p_payment_id, p_challenge_id, p_code)` | **missing — S5** | confirm cash, returns receipt |
| `guest_get_damage_claim(p_claim_id)` | **missing — S6** | claim screen |
| `guest_respond_damage_claim(p_claim_id, p_decision, p_note, p_attachment_ids, p_idempotency_key)` | **missing — S6** | agree / dispute |
| Node `GET /v1/files/{attachmentId}/url` | exists | evidence images (memory only) |
| `guest_respond_replacement_offer(p_offer_id, p_accept, p_idempotency_key)` | **missing — S7** | offer answer |

## 2. Requested deltas

### S1 — `guest_get_booking`: G3 sections

Add these to the guest view (all values are server-computed):

```json
{
  "acknowledgements": {
    "guest_checkin_at": null, "host_checkin_at": "2026-11-12T12:05:00Z",
    "guest_checkout_at": null, "host_checkout_at": null, "key_left_safe": false
  },
  "pending_remaining_payment_id": null,
  "pending_cash": {
    "payment_id": "uuid", "challenge_id": "uuid", "collector_display_name": "أحمد م.",
    "amount_minor": 350000, "masked_email": "m***@gmail.com",
    "code_expires_at": "…", "retry_after_seconds": 0, "origin": "collector"
  },
  "payments": [
    { "id": "uuid", "purpose": "remaining", "method": "cash", "status": "succeeded",
      "amount_minor": 350000, "paid_at": "…",
      "receipt": { "receipt_no": "R-2026-000123", "collector_display_name": "أحمد م.",
                   "confirmed_at": "…" } }
  ],
  "damage_claims": [
    { "id": "uuid", "amount_minor": 50000, "status": "open", "created_at": "…" }
  ],
  "replacement_offer": {
    "id": "uuid", "status": "pending",
    "offered_property": { "id": "uuid", "title": "…", "area_name": "…", "cover_image": { } },
    "check_in": "2026-11-20", "check_out": "2026-11-23",
    "price_difference_minor": 50000, "expires_at": "…"
  },
  "cancellation": { "cancelled_at": "…", "by_scope": "guest", "reason_code": "change_of_plans" }
}
```

- `pending_cash`: present only while a cash payment is `pending_guest_confirmation` for this
  guest. It shows the collector's **display name only** (first name + initial), never the phone.
- `receipt`: only on succeeded `cash` payments.
- `available_actions`: must include:
  - `confirm_cash_payment` when cash is allowed for the property **or** `pending_cash` exists;
  - `respond_damage_claim` while any claim is `open`;
  - `confirm_checkin` / `confirm_checkout` exactly when the guest's timestamp is still null and
    the status allows it;
  - `pay_remaining` only when `remaining_minor > 0` and status is `confirmed`.

### S2 — `guest_list_bookings`: actions on cards

Each item adds `available_actions` (same function as details), so the card can show
"Needs your action".

### S3 — Cancellation preview and cancel

`guest_preview_cancellation(p_booking_id uuid)` returns jsonb:

```json
{
  "refund_minor": 360000, "non_refundable_minor": 100000, "currency": "EGP",
  "policy_case": "deposit_lost",
  "free_cancellation_until": "2026-11-09T10:00:00Z",
  "preview_token": "opaque", "valid_until": "2026-11-05T14:10:00Z"
}
```

- The result comes from the booking's **policy snapshot** and `now()`, following Master Plan §7.2.
- `policy_case`:
  - `free`: full refund (AC-030);
  - `deposit_lost`: only the deposit is lost, the rest is refunded (AC-031);
  - `no_refund`: fully paid and now ≥ 24 h after the scheduled check-in (AC-032).

`guest_cancel_booking(p_booking_id uuid, p_expected_refund_minor bigint, p_reason text,
p_reason_note text, p_idempotency_key text)`:
- **Amount check:** recomputes the preview. If `refund_minor ≠ p_expected_refund_minor`, it
  raises `CANCELLATION_TERMS_CHANGED`. The app then calls the preview again; including the new
  preview in `details` is optional.
- **On success:** sets `cancelled`, writes a `booking_events` row (`visibility='all'`), creates
  the refund (`reason='guest_cancellation'`, `status='requested'`) when `refund_minor > 0`, and
  emits `booking.cancelled_by_guest`. It returns `{status, refund: {id, amount_minor, status} |
  null}`.
- **Retry:** the same `p_idempotency_key` returns the same result.
- **Reason values:** `p_reason` ∈ `change_of_plans`, `found_other_place`, `travel_problem`,
  `other`, or null. `p_reason_note` is at most 300 characters.

### S4 — Remaining payment: no change, one clarification

- **Already correct:** the as-built `guest_start_remaining_payment` matches. The amount is
  `total − paid`, and the same key returns the same payment.
- **On `CONFLICT`** (an open remaining payment exists), please put the open payment's ID in
  `details.payment_id`. The app then routes to verification for that payment instead of
  starting a new one. S1's `pending_remaining_payment_id` covers the cold-start case.

### S5 — Cash start and confirm

`guest_start_cash_confirmation(p_booking_id uuid, p_collector_phone text,
p_expected_amount_minor bigint, p_idempotency_key text)`:

- **Checks, in order:**
  1. The booking is the guest's own and its status is `confirmed`.
  2. `properties.cash_collection_allowed`, else `CASH_NOT_ALLOWED`.
  3. The phone resolves to a user in `property_cash_collectors` with `cash.collect` for the
     property, else `COLLECTOR_NOT_AUTHORIZED`. The error does not reveal whether the phone
     exists.
  4. `p_expected_amount_minor = total − paid`, else `CASH_AMOUNT_CHANGED` with
     `details.amount_minor`.
- **Writes:** a `payments` row (`method='cash'`, `purpose='remaining'`,
  `status='pending_guest_confirmation'`, `collector_user_id`) and an OTP challenge whose
  recipient is the guest.
- **Returns:** the `pending_cash` object from S1 (`origin='guest'`).
- **Retry:** the same key returns the same row.
- **Partial cash:** not accepted (Clarification 2026-11-05).

`guest_confirm_cash_payment(p_payment_id uuid, p_challenge_id uuid, p_code text)`:
- Verifies the code inside the function (as `common_verify_otp`): `OTP_INVALID`, `OTP_EXPIRED`,
  `RATE_LIMITED`.
- Then sets `succeeded`, `verified_via='guest_otp'`, and `guest_confirmed_at`, and writes the
  receipt number.
- Emits `cash.payment_confirmed` (entity `payment`) and returns `{receipt}`.

The collector-started path (`partner_record_cash_collection`) creates the same pending row and
emits `cash.confirmation_requested` (entity `booking`).

### S6 — Damage claim read and respond

`guest_get_damage_claim(p_claim_id uuid)` returns jsonb:

```json
{
  "id": "uuid", "booking_id": "uuid", "description": "…", "amount_minor": 50000,
  "status": "open", "created_at": "…",
  "evidence": [ { "attachment_id": "uuid", "kind": "image", "width": 1600, "height": 1200 } ],
  "guest_response": null, "support_case_number": null,
  "resolution": null
}
```

- `evidence`: `attachments` rows with `entity_type='damage_claim'`, IDs only. The app gets
  URLs from Node `/v1/files/{id}/url`, and that route must allow the booking's guest.
- **Not the guest's claim:** returns `NOT_FOUND` (same as missing).
- **Resolution:** `resolution` uses `outcome_code` ∈ `guest_pays`, `partial`, `no_charge`,
  `withdrawn`, plus `amount_minor` if any.

`guest_respond_damage_claim(p_claim_id uuid, p_decision text, p_note text,
p_attachment_ids uuid[], p_idempotency_key text)`:
- `p_decision` ∈ `accept`, `dispute`.
- **Dispute:** requires `p_note` (10 to 1000 characters), sets `guest_disputed`, opens a
  `support_cases` row linked to the booking, and returns `support_case_number`.
- **Already answered:** returns `CLAIM_ALREADY_ANSWERED`.
- **G3 attachments:** in G3 the app always sends an empty `p_attachment_ids`.
- **Effects:** no deduction and no effect on checkout (AC-036).

### S7 — Replacement offer respond

`guest_respond_replacement_offer(p_offer_id uuid, p_accept boolean, p_idempotency_key text)`:
- The offer must be `pending`, not expired, and on the guest's booking, else
  `OFFER_NOT_AVAILABLE`.
- **Accept:** follows Backend Master Plan §7.5 and returns `{status, new_booking_id?}`.
- **Decline:** keeps the refund going.
- **Open point for the backend owner:** what the guest must do when `price_difference_minor > 0`
  (a `replacement_difference` payment). The app shows whatever `available_actions` the server
  returns next.

### S8 — Check-in / check-out errors

The as-built functions raise `INVALID_BOOKING_STATE` and, through `advance_stay`,
`REMAINING_NOT_PAID`. Please:
- raise `REMAINING_NOT_PAID` **before** recording `checkin_guest_at` when `paid < total`, so a
  guest cannot be left half-confirmed;
- emit `stay.checked_in` / `stay.completed` to the guest as already registered.

## 3. Notification rows the app reads in G3

| `type_key` | `entity_type` | `entity_id` |
|---|---|---|
| `payment.remaining_due`, `payment.remaining_paid` | `booking` | booking |
| `cash.confirmation_requested` | `booking` | booking |
| `cash.payment_confirmed` | `payment` | payment; `params.booking_id` is required |
| `stay.host_handover_confirmed`, `stay.checked_in`, `stay.completed`, `stay.checkin_reminder`, `stay.checkout_reminder` | `booking` | booking |
| `booking.cancelled_by_guest`, `booking.cancelled_by_platform`, `booking.no_show_recorded`, `booking.reopened`, `booking.replacement_offered` | `booking` | booking |
| `refund.requested`, `refund.executed`, `refund.verified` | `booking` | booking |
| `damage.claim_opened`, `damage.resolved` | `damage_claim` | claim |

## 4. Error codes used in G3

New rows for `contracts/error-codes.md` (the app's ARB key and proposed Arabic copy):

| Code | ARB key | Arabic (proposed) |
|---|---|---|
| `CANCELLATION_TERMS_CHANGED` | `cancellationTermsChanged` | مبلغ الاسترداد اتغير. راجع التفاصيل الجديدة. *(listed)* |
| `REMAINING_NOT_PAID` | `stayRemainingNotPaid` | *(listed)* |
| `COLLECTOR_NOT_AUTHORIZED` | `stayCollectorNotAuthorized` | الشخص ده مش مفوّض يستلم فلوس للشقة دي. متسلّمش كاش وكلّم OnAir. *(reworded)* |
| `CASH_NOT_ALLOWED` | `stayCashNotAllowed` | *(listed)* |
| `CASH_AMOUNT_CHANGED` *(new)* | `stayCashAmountChanged` | المبلغ المتبقي اتغير. راجع المبلغ الجديد. |
| `CLAIM_ALREADY_ANSWERED` *(new)* | `claimAlreadyAnswered` | المطالبة دي اتردّ عليها قبل كده. |
| `OFFER_NOT_AVAILABLE` *(new)* | `offerNotAvailable` | العرض ده مبقاش متاح. |
| `OTP_INVALID`, `OTP_EXPIRED`, `RATE_LIMITED`, `CONFLICT`, `INVALID_BOOKING_STATE`, `NOT_FOUND`, `VALIDATION_FAILED` | existing | existing |

## 5. Behaviour the app relies on

1. The server never changes a stay status from one acknowledgement alone (AC-026/027).
2. `pay_remaining` disappears and `confirm_checkin` appears only after the remaining amount is
   verified (AC-025).
3. A cash payment becomes `succeeded` only through `guest_confirm_cash_payment` (AC-037).
   Collector handover state never changes the guest's payment (AC-038).
4. A refund shows `verified` only after the final check (AC-042).
5. Free-cancellation, deposit-only loss, and the 24 h no-refund rule come from the booking's
   policy snapshot (AC-030 to AC-032).
6. No automatic no-show for a fully paid late guest (AC-033). Reopening a no-show keeps the
   deposit (AC-034). A platform cancellation of a confirmed booking is an OnAir action (AC-035).
7. A disputed claim never deducts and never blocks checkout (AC-036).

## 6. Tests the backend owner adds (pgTAP / service)

- Preview and cancel for each `policy_case`, with the expected-refund mismatch →
  `CANCELLATION_TERMS_CHANGED`. The same idempotency key gives a single cancellation and a
  single refund.
- Cash:
  - an unauthorized phone, a missing phone, and cash not allowed;
  - an amount mismatch;
  - a wrong code and an expired code;
  - success creates exactly one `succeeded` payment;
  - another guest's payment ID gives `NOT_FOUND`.
- Check-in with `paid < total` → `REMAINING_NOT_PAID` and no `checkin_guest_at` written.
- Claim: another guest's claim gives `NOT_FOUND`; a dispute without a note gives
  `VALIDATION_FAILED`; a second answer gives `CLAIM_ALREADY_ANSWERED`; the files route allows the
  booking's guest only.
- Offer: an expired or withdrawn offer gives `OFFER_NOT_AVAILABLE`.

## 7. Staging seed needed

One test guest with:
1. a confirmed deposit-only booking (cash allowed, one authorized collector);
2. a confirmed fully paid booking on its arrival date;
3. a checked-in booking;
4. three confirmed bookings positioned for `free`, `deposit_lost`, and `no_refund`;
5. a completed booking with one open claim (2 evidence photos) and one resolved claim;
6. a rejected booking with a pending replacement offer (positive difference) and an expired one;
7. a cancelled booking whose refund sits at each stage.
