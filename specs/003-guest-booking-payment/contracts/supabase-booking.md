# Contract: Booking, Payment, and Notifications (Guest App, G2)

Draft for the backend owner. The single source of names is `docs/OnAir Backend Master Plan.md`
(§6 bookings, §9 notifications, §11 errors, §12 functions). As-built facts below come from
`onair-backend` `contracts/rpc.md` (generated catalog), `contracts/node-api.openapi.yaml`, and
migration `20261028182013_guest_booking_core.sql`. Nothing here is implemented in this
repository (AGENTS.md); changes go to `onair-backend` in their own commits.

## 0. Rules

- All functions are `security definer`, `set search_path = public, private, pg_temp`, granted to
  `authenticated` only, and filter by `guest_user_id = auth.uid()`.
- The guest never receives: base price, margin, markup mode, owner or staff contact, other
  guests' data, coordinates, internal events (`visibility <> 'all'`).
- Errors: `raise exception '<CODE>' using errcode = 'P0001'`; Node returns `ErrorResponse`.
- Amounts are `bigint` minor units + `currency = 'EGP'`; dates are `date`; instants are
  `timestamptz` (ISO-8601 UTC).

## 1. Calls the app makes

| Call | Status | Used for |
|---|---|---|
| `guest_quote_booking(p_property_id, p_check_in, p_check_out, p_guests, p_terms_hash)` | exists (+D0) | quote |
| Node `POST /v1/guest/bookings/start-payment` `{quote_id, terms_hash, idempotency_key}` → `PaymentSession` | exists | payment start (calls `guest_start_booking`) |
| `guest_get_booking(p_booking_id)` | exists (needs D1) | details, verification outcome |
| `guest_list_bookings(p_tab, p_cursor)` | exists (needs D2) | My Bookings, unfinished-payment banner |
| `guest_get_property_unavailable_dates(...)` | exists (G1) | date step |
| `common_get_my_context()` | exists | email/phone confirmed flags |
| `common_request_phone_change(p_new_phone, p_has_whatsapp, p_whatsapp_e164)` → Node `POST /v1/otp/send` → `common_verify_otp(p_challenge_id, p_code)` | exists | verify-before-booking (phone) |
| `common_list_notifications(p_category, p_unread_only, p_workspace_id, p_cursor, p_limit)` | exists | notification center |
| `common_unread_count()` · `common_mark_notifications_read(p_ids)` | exist | bell, mark read (`null` = all) |
| `common_register_device(p_token, 'guest', p_platform, p_locale)` | exists (G0) | push |
| Realtime `postgres_changes` INSERT on `public.notifications` (RLS: own rows) | exists (publication added in `20261028182417`) | live signals |

`guest_start_booking` is **not** called by the app directly (the Node route owns the Kashier
session).

## 2. `guest_quote_booking` — as-built response

```json
{
  "quote_id": "uuid", "property_id": "uuid",
  "check_in": "2026-11-12", "check_out": "2026-11-15", "nights": 3, "guests_count": 2,
  "nightly_minor": 150000, "total_minor": 450000,
  "pay_now_minor": 100000, "remaining_minor": 350000,
  "currency": "EGP", "terms_hash": "sha256:…", "expires_at": "2026-10-30T15:20:00Z"
}
```

Errors: `ACCOUNT_SUSPENDED`, `PROPERTY_NOT_AVAILABLE`, `VALIDATION_FAILED` (past arrival,
departure ≤ arrival, > 90 nights), `GUESTS_EXCEEDED`, `DATES_UNAVAILABLE`,
`POLICY_OUT_OF_BOUNDS`, `TERMS_CHANGED`.

## 3. Node `start-payment` — as-built

Request `{quote_id, terms_hash, idempotency_key (uuid)}`; response `PaymentSession`
`{booking_id, payment_id, payment_url, payment_url_expires_at, amount_minor, currency}`. The
same `idempotency_key` returns the same booking and session. Errors (via `guest_start_booking`):
`ACCOUNT_SUSPENDED`, `PHONE_NOT_VERIFIED`, `EMAIL_NOT_VERIFIED`, `VALIDATION_FAILED`,
`QUOTE_EXPIRED`, `TERMS_CHANGED`, `PROPERTY_NOT_AVAILABLE`, `DATES_UNAVAILABLE`, plus
`RATE_LIMITED` (429) from the service.

**Requested confirmation**: the Kashier `return_url` is
`https://<LINK_DOMAIN>/payment/return?booking=<booking_id>` (no status in the URL is trusted by
the app; it only navigates).

## 4. Requested deltas

### D0 — quote: due date and policy summary

Add to the quote response:
- `remaining_due_at` (timestamptz or null) — when the remaining amount must be paid (before
  check-in, per policy);
- `policy_summary` — the same shape `guest_get_property` returns for the deposit and
  cancellation policy (G1 `PolicySummary`), taken from the resolved terms.

### D1 — `guest_get_booking` full guest view

Keep the as-built fields and add:

```json
{
  "id": "uuid", "code": "OA-1A2B3C4", "status": "awaiting_owner",
  "property": {
    "id": "uuid", "title": "…", "cover_image": { "variants": {…}, "blurhash": "…" },
    "area_name": "…", "city_name": "…", "address_text": "…",
    "check_in_time": "14:00", "check_out_time": "12:00"
  },
  "check_in": "2026-11-12", "check_out": "2026-11-15", "nights": 3, "guests_count": 2,
  "nightly_minor": 150000, "total_minor": 450000, "pay_now_minor": 100000,
  "paid_minor": 100000, "remaining_minor": 350000, "remaining_due_at": "…", "currency": "EGP",
  "owner_response_deadline": "2026-10-31T15:00:00Z",
  "payment_state": "succeeded",
  "payments": [
    { "id": "uuid", "purpose": "initial", "method": "kashier", "status": "succeeded",
      "amount_minor": 100000, "paid_at": "…" }
  ],
  "refund": { "id": "uuid", "amount_minor": 100000, "status": "approved", "updated_at": "…" },
  "terms_snapshot": { "policy_summary": { … }, "rules_text": "…" },
  "access_instructions": null,
  "available_actions": ["contact_support"],
  "events": [ { "event_type": "booking.started", "to_status": "payment_pending",
                "created_at": "…", "note": null } ]
}
```

- `payment_state` (guest-safe) is derived from the latest `initial` payment: `pending` (pending /
  verifying), `failed` (failed / cancelled / expired), `succeeded`.
- `refund`: the latest refund row of the booking, or `null`; `status` as in the `refunds` check
  constraint.
- `access_instructions` only for `confirmed`, `checked_in`, `completed` (as-built rule kept).
- `available_actions` from D3.
- `NOT_FOUND` for any booking the caller does not own (same error as non-existent).

### D2 — `guest_list_bookings` tabs and card fields

- Accept `p_tab` ∈ `current`, `past`, `cancelled`, `pending` (keep `upcoming` as an alias of
  `current` minus `payment_verifying` only if another app uses it; the guest app stops using it):

  | `p_tab` | Statuses | Order |
  |---|---|---|
  | `current` | payment_verifying, awaiting_owner, confirmed, checked_in | `check_in` asc |
  | `past` | completed | `check_out` desc |
  | `cancelled` | rejected, expired, cancelled, no_show, payment_conflict | `updated_at` desc |
  | `pending` | payment_pending | `created_at` desc |

  `abandoned` is returned by no tab.
- Each item adds `title`, `cover_image`, `refund_status` (latest refund or null), and
  `owner_response_deadline`.
- Response `{ "items": [...], "next_cursor": "opaque or null" }` with page size 20, so ordering
  other than `created_at` can page safely (the as-built `timestamptz` cursor only fits
  `created_at desc`).

### D3 — `private.booking_available_actions(p_booking_id, p_actor)`

Named in Backend Master Plan §6; no migration defines it yet. For the guest it returns the codes
in Guest Plan §6.8.1 (`pay_remaining`, `confirm_cash_payment`, `request_cancellation`,
`confirm_checkin`, `confirm_checkout`, `respond_damage_claim`, `write_review`,
`contact_support`). `contact_support` is present for every status except `abandoned`. The G2 app
acts only on `contact_support`; other codes are accepted and ignored until G3/G5.

### D4 — notifications for the verification screen

Confirm a guest-audience row in `notifications` (`entity_type = 'booking'`, `entity_id =
booking_id`) is inserted for `booking.request_received`, `booking.payment_conflict`, and
`payment.failed` at the same transaction as the status change, so Realtime delivers it.

### D5 — documentation

Add the page size and cursor rules for `guest_list_bookings` and `common_list_notifications`
(as-built default 30, cursor `created_at`) to `contracts/rpc.md`.

## 5. Notification rows the app reads

`common_list_notifications` returns `notifications` rows: `id`, `type_key`, `category`,
`priority`, `entity_type`, `entity_id`, `title_key`, `body_key`, `params`, `read_at`,
`created_at`. The app translates by `type_key` (research R11) and ignores `title_key` /
`body_key` text. Push payload carries only `type` and `target_id` (Constitution IV).

## 6. Error codes used in G2

From the root [`contracts/error-codes.md`](../../../contracts/error-codes.md) (rows marked G2):
`PHONE_NOT_VERIFIED`, `EMAIL_NOT_VERIFIED`, `DATES_UNAVAILABLE`, `GUESTS_EXCEEDED`,
`QUOTE_EXPIRED`, `TERMS_CHANGED`, `PROPERTY_NOT_AVAILABLE`, `PAYMENT_AMOUNT_MISMATCH`,
`DUPLICATE_OPERATION`, `CONFLICT`, `INVALID_BOOKING_STATE`, `ACTION_NOT_ALLOWED`,
`RATE_LIMITED`, `OTP_INVALID`, `OTP_EXPIRED`, `PHONE_COUNTRY_NOT_SUPPORTED`,
`PHONE_ALREADY_USED`, `NOT_FOUND`, `VALIDATION_FAILED`, `ACCOUNT_SUSPENDED`, `INTERNAL`.

New for G2, to add to that table:

| Code | ARB key | Proposed Arabic copy | Reference? |
|---|---|---|---|
| `POLICY_OUT_OF_BOUNDS` | `bookingPolicyOutOfBounds` | السعر مش ثابت على التواريخ دي. جرّب تواريخ تانية أو تواصل مع الدعم. | yes |

## 7. Behaviour the app relies on

1. Return from Kashier never changes status; only the webhook path does (AC-015).
2. The amount charged is `pay_now_minor` of the quote snapshot (AC-016).
3. The same `idempotency_key` → the same booking and session; a used quote with a new key →
   `QUOTE_EXPIRED` (AC-023).
4. Two paid attempts for the same nights → one `awaiting_owner`, one `payment_conflict` + full
   refund (AC-017/018).
5. Owner accept / reject / 24 h timeout write the status, the refund, and the guest
   notification together (AC-019 to AC-021, AC-024).
6. `refunds.status = 'verified'` only after the final check (AC-042).

## 8. Tests the backend owner adds (pgTAP / service)

- Guest A calling `guest_get_booking` on guest B's booking → `NOT_FOUND`; listing never returns
  B's rows.
- No response of D1/D2 contains `base_nightly_minor`, `markup_nightly_minor`, `markup_mode`,
  owner phone/email, or coordinates.
- `access_instructions` is null for every status before `confirmed`.
- Tab membership matches §4 D2 for each status, and `abandoned` appears in no tab.
- `available_actions` for a `payment_verifying` booking contains no payment action.

## 9. Staging seed needed

- Guests: one fully verified, one with unconfirmed phone, one with unconfirmed email.
- Apartments: deposit policy, full-payment policy, one with a short quote TTL (for expiry).
- Bookings for the verified guest in every status of §4 D2, including a `payment_conflict` with
  a refund at each stage (`requested`, `approved`, `executed`, `verified`).
- Kashier test account and cards for success, failure, and user cancellation (Guest Plan §19.1).
