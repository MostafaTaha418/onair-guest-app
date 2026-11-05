# Research: Guest Stay & Cancellation (G3)

Decisions behind [plan.md](plan.md). Sources: [spec.md](spec.md) and its Clarifications,
`docs/OnAir Guest App Plan.md`, `docs/OnAir Master Plan.md`, `onair-backend`
(`docs/OnAir Backend Master Plan.md` §7–§8 and §12, migrations `20261028183127_stay_lifecycle`,
`20261028183927_remaining_payment`, `20261028184123_refund_workflow`), `contracts/` in this repo,
`DESIGN.md`, and `docs/design_reference/`. The Technical Context had no open
"NEEDS CLARIFICATION"; the items below settle the design choices.

## R1. What the backend already has for G3

- **Decision**: Use the as-built calls as they are, and request the missing ones as deltas
  S1–S8 in [contracts/supabase-stay.md](contracts/supabase-stay.md).
  - **As-built:** `guest_confirm_checkin`, `guest_confirm_checkout`,
    `guest_start_remaining_payment` (called by Node `remaining-payment`), the refunds table and
    workflow, and the `damage_claims`, `replacement_offers`, `property_cash_collectors`, and
    `attachments` tables.
  - **Missing:** cancellation preview and cancel, cash start and confirm, the cash receipt read,
    the claim read and respond, the offer respond, and the G3 fields in `guest_get_booking` and
    `guest_list_bookings`.
- **Rationale**: The backend review (`BACKEND_IMPLEMENTATION_REVIEW_2026-10-28.md`) lists
  cancellation, replacement offers, damage flows, and cash payment as "not implemented". The
  app repo must not hold backend code (AGENTS.md), so the gaps are written as a contract for the
  backend owner, as in G2 (D0–D5).
- **Alternatives considered**:
  - Waiting for the backend before building: rejected, because G2 proved the mock-first approach
    works and the screens do not change when switching.
  - Calling tables directly: rejected, because guest writes go only through functions
    (`20261028181247_revoke_direct_writes`).

## R2. Where the guest's actions are decided

- **Decision**: Booking details renders actions only from `available_actions`. The G2
  `BookingActionRegistry.g2()` becomes `g3()`, with this supported set:
  - `contact_support`, `pay_remaining`, `confirm_cash_payment`, `request_cancellation`;
  - `confirm_checkin`, `confirm_checkout`, `respond_damage_claim`.

  `write_review` stays hidden until G5. One `BookingActionLauncher` maps each code to a route or
  a sheet.
  - The **primary** action is the first code in server order, excluding `request_cancellation`,
    `respond_damage_claim` when disputing, and `contact_support`. It sits in the
    `BottomActionBar` as the filled button.
  - The others are outlined, and cancellation is a destructive text button (FR-032).
- **Rationale**: This keeps Constitution II (no local rules) and gives one place to map
  code → UI. The ordering rule is a pure function and simple to test.
- **Alternatives considered**: A hard-coded priority list in the app was rejected, because it
  would re-implement server rules (Guest Plan §6.8.1).

## R3. Remaining payment: reuse G2, extend the attempt record

- **Decision**: Extend `PaymentAttempt` with `kind` (`initial` | `remaining`) and `paymentId`.
  For `remaining`, `quoteId`, `propertyId`, and `termsHash` are null and `bookingId` is required.
  The flow is:
  1. The Node call `startRemainingPayment(bookingId, idempotency_key)` returns `PaymentSession`.
  2. The same in-app browser and `/payment/return?booking=<id>` handle the return.
  3. The verification screen picks its outcome function by `kind`. For `remaining`, it reads the
     `PaymentLine` with `id == paymentId`:
     - `succeeded` → success;
     - `failed` / `cancelled` / `expired` → failed;
     - anything else → waiting.

     The booking status stays `confirmed` throughout.
  - **Conflict:** a server `CONFLICT` (an open remaining payment already exists) opens
    verification for the payment the server reports in `pending_remaining_payment_id` (S1), and
    never starts a second payment.
- **Rationale**: Payment integrity rules (Constitution III) are already implemented and tested
  once. Copying them would create a second, drifting path. The status-based G2 outcome cannot be
  used here, because the booking stays `confirmed`.
- **Alternatives considered**: A separate `RemainingPaymentAttempt` store was rejected, because
  it adds a second "open attempt on launch" check and a second banner.

## R4. Idempotency for non-payment actions

- **Decision**: Cancel, check-in, check-out, claim answer, offer answer, and cash confirm each
  get a UUID v4 action key, kept in a small `ActionAttemptStore` in secure storage. The store is
  keyed by `<action>:<entityId>`, created on the first tap, reused on retry after a network
  error, and deleted on any server answer (success or business error). The keys are sent as
  `p_idempotency_key` (S3–S7).
- **Rationale**: FR-002 and SC-006 need "exactly once" even when the answer is lost. The server
  functions for check-in and check-out are already naturally idempotent (they set
  `*_guest_at` once). Cancel and claim/offer answers are not, so the contract asks for the key.
- **Alternatives considered**: Relying on button disabling alone was rejected, because it does
  not cover a dropped response followed by a retry.

## R5. Cash confirmation: two entries, one code step

- **Decision**:
  - **Guest-started entry:** the guest enters the collector's phone (Egyptian mobile, validated
    with the G0 phone formatter). The amount is shown read-only from `details.remaining`. The
    app calls `guest_start_cash_confirmation(booking_id, collector_phone, expected_amount_minor,
    idempotency_key)`, which returns `{payment_id, challenge_id, collector_display_name,
    amount_minor, masked_email, code_expires_at}`. The app then calls Node
    `POST /v1/otp/send {challenge_id}`.
  - **Collector-started entry:** `guest_get_booking.pending_cash` (S1) carries the same object.
    The notification `cash.confirmation_requested` opens `/bookings/<id>/cash-confirm`, which
    skips the phone step when `pending_cash` exists.
  - **Code step:** `OnAirOtpField` (G0), a resend button with the existing countdown driven by
    the server's `retry_after_seconds`, an explicit statement checkbox ("I confirm I handed
    {amount} in cash to {name}"), and confirm. The confirm call is
    `guest_confirm_cash_payment(payment_id, challenge_id, code)`, which returns a receipt.
- **Rationale**:
  - The Master Plan signature includes `amount_minor`. With the Clarification (no partial cash),
    it becomes an echo of the server's remaining amount, checked server-side (`CASH_AMOUNT_CHANGED`
    on mismatch, S5). The app never chooses an amount.
  - Masking the email and not copying the code follows Constitution IV.
- **Alternatives considered**: Dropping the amount from the call was rejected, because it would
  diverge from the agreed Backend Master Plan signature. The echo is simpler to agree on.

## R6. Check-in / check-out and the waiting state

- **Decision**: The confirmation bottom sheet (`OnAirConfirmSheet`) offers "Yes, I received it" /
  "Not yet" and "Yes, I left" / "Not yet". After a successful call, the details screen refreshes:
  - **Waiting message:** shown from S1's `acknowledgements` (`guest_checkin_at`,
    `host_checkin_at`, `guest_checkout_at`, `host_checkout_at`, `key_left_safe`) while the status
    has not changed yet.
  - **Owner's step:** the `AcknowledgementTracker` shows the owner's side as "Waiting" or
    "Confirmed {time}".
  - **New status:** it comes from the server (Realtime notification signal → refetch).
  - **Errors:** a `REMAINING_NOT_PAID` error shows the remaining note and the pay action.
  - **Owner can't be reached:** the sheet also offers "I have a problem with the handover",
    which opens support linked to the booking (closes the spec note from clarify).
- **Rationale**: This follows AC-026/027. The as-built `advance_stay` only flips status when both
  timestamps exist. The guest needs to see which side is pending, and that is a server fact.
- **Alternatives considered**: Inferring "waiting" from the action disappearing was rejected,
  because it is ambiguous and offline-fragile.

## R7. Damage claim evidence: private, memory-only

- **Decision**: `guest_get_damage_claim(claim_id)` (S6) returns the claim with `evidence:
  [{attachment_id, kind, width?, height?}]`.
  - **Loading:** the claim Cubit asks Node `GET /v1/files/{id}/url` per thumbnail when it becomes
    visible. It keeps `{url, expires_at}` in memory and refetches when a URL is within 30 s of
    expiry or fails with 403.
  - **No disk:** images render with `Image.network` + `cacheWidth` and a memory-only cache, so
    they never reach the `cached_network_image` disk store.
  - **Viewer:** a full-screen viewer with pinch-zoom and a semantic label per photo.
- **Rationale**: Constitution IV says private attachments use short-lived signed URLs and are
  never cached persistently. The Node route already exists.
- **Alternatives considered**: Returning signed URLs inside the RPC was rejected, because the
  RPC cannot sign storage URLs safely and they would expire in the JSON cache.

## R8. Damage claim answer: written reason only

- **Decision**:
  - The call is `guest_respond_damage_claim(claim_id, decision ∈ {accept, dispute}, note,
    attachment_ids = [], idempotency_key)`.
  - The reason is required for a dispute: trimmed, 10 to 1000 characters, with a counter. The
    limits are provisional and live in one constant.
  - The answer returns `{status, support_case_id?, support_case_number?}`.
  - No attachment UI in G3 (Clarification 2026-11-05). `attachment_ids` is always empty until G4.
  - The claim card in details is shown for every claim (S1 `damage_claims[]` summary).
- **Rationale**: This keeps the agreed signature, so G4 can add attachments without a contract
  change.
- **Alternatives considered**: A free-length reason was rejected, because an unbounded note is
  hard to show on the partner side. 10 characters stops empty "no" disputes without being
  strict.

## R9. Cancellation preview and terms change

- **Decision**:
  - **Preview:** `guest_preview_cancellation(booking_id)` → `{refund_minor,
    non_refundable_minor, reason_code, reason_params, free_cancellation_until?, policy_case ∈
    {free, deposit_lost, no_refund}, preview_token, valid_until}`.
  - **Display:** the screen builds its sentence from `reason_code` + params through `.arb`
    (`cancelReason_free`, `cancelReason_depositLost`, `cancelReason_noRefund`). It does not show
    server text.
  - **Cancel:** `guest_cancel_booking(booking_id, expected_refund_minor, reason, idempotency_key)`.
  - **Terms changed:** on `CANCELLATION_TERMS_CHANGED`, the app calls
    `guest_preview_cancellation` again (the shared `ApiError` carries no `details` payload). The
    screen swaps the new preview in, marks changed rows with the existing "changed" highlight
    from G2's quote diff (`QuoteChange` styling), and requires a new confirm.
  - **Reasons:** a fixed set of `change_of_plans`, `found_other_place`, `travel_problem`,
    `other` (with optional text ≤ 300). They are reporting only.
- **Rationale**: This matches Guest Plan §6.9 and the Backend Master Plan signature. Reusing the
  G2 diff style keeps the "something changed" look consistent.
- **Alternatives considered**: Showing the server's prose reason was rejected, because raw
  server text is forbidden (FR-035) and it is not localizable.

## R10. Replacement offer in details

- **Decision**:
  - **Data:** S1 adds `replacement_offer` (the open one, or the latest answered one) with
    `{id, status, offered_property {id, title, area, cover_image}, check_in, check_out,
    price_difference_minor, expires_at}`.
  - **Wording:** the card words the difference from the sign:
    - positive → "You will pay {amount} more";
    - negative → "{amount} will be refunded to you";
    - zero → "No price difference".

    It uses `Money.abs()` for display only, with no arithmetic.
  - **Answer:** `guest_respond_replacement_offer(offer_id, accept, idempotency_key)`.
  - **Not available:** `OFFER_NOT_AVAILABLE` (expired or withdrawn) shows a message and
    refreshes.
  - **Notification:** `booking.replacement_offered` opens `/bookings/<id>?focus=offer`, which
    scrolls to the card.
- **Rationale**: The offer belongs to the booking (Backend Master Plan §7.5), so a section in
  details avoids a new route.
- **Alternatives considered**: A separate offer screen was rejected, because the guest needs the
  original booking context next to the offer.
- **Open point**: accepting an offer with a positive difference implies a
  `replacement_difference` payment (payments.purpose). The Guest Plan does not define that UI. In
  G3, the app shows the server's next state, and if the server returns a `pay_remaining`-like
  action later, the existing remaining-payment screen handles it. This is recorded for the
  backend owner in S7.

## R11. Notifications and routes for G3

- **Decision**: Update `NotificationRouter` targets as shown below. The full table is in
  [contracts/app-routes.md](contracts/app-routes.md).

  | Notification | Target |
  |---|---|
  | `payment.remaining_due` | `/bookings/<id>/remaining-payment` |
  | `cash.confirmation_requested` | `/bookings/<id>/cash-confirm` |
  | `cash.payment_confirmed` | `/bookings/<id>/receipts/<paymentId>`, falling back to details |
  | `damage.*` (entity `damage_claim`) | `/damage-claims/<claimId>` |
  | `booking.replacement_offered` | details with `focus=offer` |

  `/damage-claims/<claimId>` resolves the booking through `guest_get_damage_claim`, then
  replaces itself with `/bookings/<bookingId>/damage-claim/<claimId>`.

  Each screen re-checks the server and falls back to details when the action is no longer
  allowed.
- **Rationale**: Push payloads carry only `type` + `target_id` (G2 §5). Damage notifications
  target the claim, so a claim-only alias avoids needing the booking ID in the payload.
- **Alternatives considered**: Adding `booking_id` to the push payload was rejected, because it
  would widen the payload contract.

## R12. No new dependencies

- **Decision**: Use no new packages:
  - `OnAirConfirmSheet` / `OnAirConfirmDialog` wrap `showModalBottomSheet` / `showDialog` with
    theme tokens;
  - pinch-zoom uses `InteractiveViewer`;
  - masking uses a small pure function;
  - the resend countdown reuses `core/time/countdown.dart`.
- **Rationale**: Constitution VII requires reviewing each dependency, and none is needed.

## R13. Visual consistency with the current app

- **Decision**: Every new screen follows [contracts/ui-screens.md](contracts/ui-screens.md):
  - the same app bar as `BookingDetailsScreen` (title + mirrored back chevron);
  - 16dp gutter, sections titled with `titleMedium` in `textPrimary`;
  - amounts in `AmountRow`, and messages in `NoticeCard` / `InfoBanner` tones (info, warning,
    success, neutral) as already used in G2;
  - the main action in `BottomActionBar`;
  - dialogs patterned on reference image 15 (title, body, quiet "Cancel" and accent action),
    restyled with tokens and with a destructive variant for cancellation;
  - remaining-payment option cards patterned on image 30 (radio-style surface cards and an amount
    summary card), with Arabic copy and EGP.

  Goldens for each new screen sit beside the G2 details golden, so the reviewer compares them in
  one place.
- **Rationale**: The user asked that G3 look exactly like the current UI. DESIGN.md says to reuse
  components and not create a second vocabulary. Image 23's on-card buttons are intentionally not
  adopted (Clarification).
- **Alternatives considered**: Building new card styles from the screenshots was rejected,
  because it would drift from the shipped G2 look.

## R14. Diagnostics

- **Decision**: Add events `remaining_payment_started|verified|failed`,
  `cash_confirm_started|code_sent|confirmed|refused`, `checkin_confirmed`, `checkout_confirmed`,
  `cancellation_previewed|confirmed|terms_changed`, `claim_answered`, and `offer_answered`. Each
  carries `booking_id`, `payment_id`/`claim_id`/`offer_id`, and `request_id` only, with no
  phones, emails, names, codes, or notes.
- **Rationale**: FR-038 and Constitution IV.

## R15. Offline behaviour

- **Decision**:
  - **Details:** booking details from cache show the new sections read-only, and every action
    button is disabled with the existing offline banner.
  - **Not available offline:** the cancellation preview, cash code step, claim evidence, and
    remaining-payment start show an `ErrorView` variant "Needs a connection" with retry when
    connectivity returns.
  - **Receipts:** cash receipts are part of booking details (`payments[].receipt`, S1), so they
    open offline from cache.
- **Rationale**: Constitution VIII. Receipts are useful offline, and they carry no secret.
