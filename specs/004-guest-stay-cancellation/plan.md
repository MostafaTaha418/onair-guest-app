# Implementation Plan: Guest Stay & Cancellation (G3)

**Branch**: `feature/004-guest-stay-cancellation` | **Date**: 2026-11-05 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/004-guest-stay-cancellation/spec.md`

## Summary

Turn the server's G3 action codes, which G2 receives but hides, into real flows on top of the G2
booking details screen:

- **Pay the remaining amount online** (`pay_remaining`): a remaining-payment screen that reuses
  G2's in-app browser, payment return link, and verification screen. The open-attempt record
  gains a `remaining` kind, so the verification outcome is read from that payment's own status.
- **Confirm a cash payment with an email code** (`confirm_cash_payment`). There are two entries:
  - the guest enters only the collector's phone number, and the amount is the server's
    remaining amount, read-only;
  - the guest opens the collector's pending request from a notification or from details.

  Both entries lead to one code step built on the existing `OnAirOtpField` and resend countdown,
  and end at an in-app receipt that can be reopened from the payments section.
- **"I received the apartment" / "I left the apartment"** (`confirm_checkin` /
  `confirm_checkout`): a confirmation bottom sheet, then waiting messages until the server
  reports the new status. A two-party acknowledgement tracker appears in details.
- **Cancellation with preview** (`request_cancellation`): server preview → optional reason →
  destructive confirm and final dialog → cancel. The request carries the previewed refund amount,
  and `CANCELLATION_TERMS_CHANGED` re-shows the new preview with the changes highlighted. Refund
  stages reuse the G2 `RefundStageTracker`.
- **Damage claim** (`respond_damage_claim`): a claim screen with evidence loaded through
  short-lived private file URLs that are never cached on disk. "I agree" or "I dispute" with a
  required written reason, and no attachments in G3 (Clarification). A claim card stays in
  details for every claim.
- **Replacement offer**: an "Alternative offer from OnAir" card in details with accept / decline
  dialogs.
- **Cards and routing**: My Bookings cards get a "Needs your action" line (no buttons,
  Clarification). The notification routing for G3 types moves from "booking details" to the
  real G3 screens.

**Design rule for this phase:** every new surface is built from the existing app look: the G2
booking details layout, `NoticeCard`, `AmountRow`, `StatusChip`, `RefundStageTracker`,
`BookingTimeline`, `BottomActionBar`, `OnAirOtpField`, state views, and 24dp sheets. Two shared
pieces are added to `lib/design_system/components/`:
- `OnAirConfirmSheet` / `OnAirConfirmDialog`;
- `AcknowledgementTracker`, a two-step variant of the stage tracker.

They are added only where nothing similar exists. Screen-by-screen mapping to components and to
reference screenshots is in [contracts/ui-screens.md](contracts/ui-screens.md).

The app stays a display-and-request client:
- **Server decides:** remaining amount, due date, cash permission, collector authorization,
  refund preview, refund stages, stay status, claim and offer status, allowed actions.
- **App sends:** booking/claim/offer IDs, attempt keys, the collector phone, and amounts only as
  echoes of a value the server just showed (`expected_refund_minor`,
  `expected_amount_minor`). The server rejects a mismatch, so the app never decides an amount.

**Backend dependency:** as-built `onair-backend` has `guest_confirm_checkin`,
`guest_confirm_checkout`, `guest_start_remaining_payment` (behind Node `remaining-payment`), the
refund workflow, and the `damage_claims` / `replacement_offers` / `property_cash_collectors`
tables. It does **not** have:
- cancellation preview or cancel;
- cash start or confirm (the receipt comes back inside booking details);
- damage claim read or respond;
- replacement offer respond;
- the G3 fields in `guest_get_booking`.

These are drafted as deltas S1–S8 in [contracts/supabase-stay.md](contracts/supabase-stay.md)
for the backend owner. The app builds and tests every flow against the mock until they ship.

Details: [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/),
[quickstart.md](quickstart.md).

## Technical Context

**Language/Version**: Dart 3.12.2, Flutter 3.44.3 (stable). SDK constraint `^3.12.2`.

**Primary Dependencies**: Existing G0–G2 stack only:
- `flutter_bloc`, `go_router`, `supabase_flutter` (RPC + the existing notification Realtime
  signal);
- `dio` + `retrofit` (generated Node client: `startRemainingPayment`, `sendOtpCode`,
  `getFileUrl`), `freezed` + `json_serializable`;
- `flutter_secure_storage`, `url_launcher` (in-app browser), `uuid`, `connectivity_plus`,
  `intl`, `timezone`, `cached_network_image` (memory-only for evidence; research R7).

No new package (research R12).

**Storage**:
- Existing per-guest JSON cache: booking details now also carry the acknowledgement fields,
  claim summaries, the open offer, and the pending cash request (no codes, no file URLs).
- Existing secure-storage `PaymentAttempt` record gains `kind` (`initial` | `remaining`) and
  `paymentId`. Quote fields are optional for `remaining`.
- New secure-storage key, per action attempt, for action keys: the idempotency key of an
  in-flight cancel, check-in, check-out, claim answer, or offer answer. It is kept until a final
  answer, so a retry after a dropped connection reuses it (research R4).
- Nothing new in `shared_preferences`. Evidence images and their URLs are memory-only.
- Everything is purged at sign-out through the existing `PersonalDataResetter`.

**Testing**:
- `flutter_test` (unit + widget), `bloc_test`, `mocktail`, `fake_async` (resend countdown,
  waiting states).
- `alchemist` goldens for every new screen and component: Light, Dark, RTL, LTR (English), 1.3×
  text, narrow 320dp and tablet 800dp. They are compared against the G2 details golden for
  visual consistency.
- `integration_test`:
  - `stay_journey_mock_test.dart`: remaining payment → check-in → check-out on the mock;
  - `cash_confirm_mock_test.dart`: both entries, wrong code, and rate limit;
  - `cancellation_mock_test.dart`: three policy cases plus the terms-changed retry;
  - `claim_offer_mock_test.dart`;
  - Staging versions once S1–S8 ship (AC-025 to AC-038, AC-042).

**Target Platform**: Android 7.0+ (API 24) and iOS 15+.

**Project Type**: Mobile app (single Flutter project at repository root).

**Performance Goals**:
- Each G3 screen shows its skeleton within 1 frame of navigation and content ≤ 1 s on a warm
  connection.
- A confirm button shows its in-place loader on the first frame after the tap. A second tap is
  ignored (SC-006).
- After a server change arrives through the existing notification signal, an open details screen
  refreshes ≤ 10 s, like the G2 verification screen.
- Evidence images are decoded at their display size (`cacheWidth` = width × DPR), with no
  full-size decode.

**Constraints**:
- Constitution II/III: no computed amounts. Echoed amounts are checked by the server, and money
  actions use one idempotency key per attempt.
- Private evidence: only short-lived URLs from `GET /v1/files/{id}/url`, never written to the disk
  cache (Constitution IV).
- No code autofill to the clipboard. The email in the code step is masked.
- Arabic RTL first with English LTR; text scale clamped at 1.3; Cairo time; EGP from `Money`.
- One filled primary action per details screen. Cancel and "I dispute" are destructive and never
  filled primary (FR-032).
- Remote mode for G3 depends on backend deltas S1–S8.

**Scale/Scope**:
- **New screens (6):**
  - Remaining payment;
  - Cash confirmation (phone step + code step);
  - Cash receipt;
  - Cancellation (preview + reason);
  - Damage claim;
  - Evidence viewer.

  Also new: two bottom sheets (check-in, check-out), confirmation dialogs, and sections added to
  booking details (acknowledgement tracker, claim cards, offer card, primary-action bar).
- **New design-system components (3):** `OnAirConfirmSheet`, `OnAirConfirmDialog`,
  `AcknowledgementTracker`. Everything else is reused.
- **Backend calls:**
  - RPCs: `guest_get_booking` (+S1), `guest_list_bookings` (+S2),
    `guest_preview_cancellation`, `guest_cancel_booking`, `guest_start_cash_confirmation`,
    `guest_confirm_cash_payment`, `guest_get_damage_claim`,
    `guest_respond_damage_claim`, `guest_respond_replacement_offer`, `guest_confirm_checkin`,
    `guest_confirm_checkout`;
  - Node: `POST /v1/guest/bookings/{id}/remaining-payment`, `POST /v1/otp/send`,
    `GET /v1/files/{id}/url`.
- **Pilot volume:** a booking has at most a few payments, one open offer, and a handful of
  claims.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | How G3 complies | Status |
|---|---|---|
| I. Master Plan fidelity & scope | Implements Guest Plan §6.9–§6.13, §7.3, §17 G3, and Master Plan §5.5, §6.1–§6.4, §7.2–§7.4, §8.3 only. Cash exists only to pay the remaining amount after confirmation, never at request time. No OTP or photos for check-in. No partial cash (Clarification). No owner or collector chat (AC-047). Review screen stays G5 and support/uploads stay G4. | PASS |
| II. Server is the authority | Remaining amount, cash amount, preview amounts, refund stage, stay status, and claim/offer status all come from the server. Echoed amounts (`expected_refund_minor`, `expected_amount_minor`) only confirm what the guest saw; the server rejects a mismatch. Waiting states end only on a server status. The "Needs your action" line is the first server action, not a local rule. | PASS |
| III. Payment integrity | Remaining payment sends only the booking and an attempt key. It reuses G2's in-app browser, return link, and "verifying until the server says" screen, with no "pay again" while verifying. An existing `pending`/`verifying` remaining payment routes to verification instead of a new start (server `CONFLICT`). Cash is paid only with the guest's email code (AC-037). | PASS |
| IV. Security & privacy | IDs from links and push are UUID-checked. Claim and receipt fetches go through `guest_*` functions under ownership checks, and a refusal shows "Not available". Evidence is fetched via `/v1/files/{id}/url`, held in memory only, and never logged. The email is masked in the code step and codes are never copied to the clipboard. Diagnostics carry IDs only. Collector phone numbers are not logged. | PASS |
| V. Design system | New screens use existing tokens and components. The three new shared components live in `lib/design_system/components/` with primitives only. Status uses `StatusChip` with text + icon. The destructive colour comes from the theme `error` role. There are no hex or font-size literals. The screen map to DESIGN.md roles and reference screenshots is in `contracts/ui-screens.md`. | PASS |
| VI. Arabic-first, RTL & a11y | All copy is in `.arb`, in Egyptian Arabic matching G2 tone, plus English. Directional paddings are used. The two-party tracker reads as text ("You confirmed · Waiting for the owner"). Sheets and dialogs trap focus and announce titles. The code field announces errors. Touch targets are ≥ 48dp. Goldens run at 1.3×. | PASS |
| VII. Layered, feature-first | New `features/stay` holds remaining payment, cash, check-in/out, cancellation, claims, and offers, with its own domain, data, and presentation layers. It depends on `features/bookings` domain types and `features/booking` payment-attempt plumbing through their public interfaces only. Supabase/Node and mock repositories are wired in `bootstrap`. Every new error code goes through `ErrorMapper`. | PASS |
| State management | One Cubit per screen. `BookingDetailsCubit` gains `refresh()` hooks for action results. A small `ActionAttemptStore` (secure storage) keeps idempotency keys per in-flight action. `PaymentAttemptCubit` is reused for the remaining payment. `close()` cancels timers. | PASS |
| VIII. UX states & performance | Every screen has a shaped skeleton, error with reference, offline banner with actions disabled, and an in-button loader. The cancellation preview and code step are not available offline, with a clear notice. Lists are unchanged. | PASS |
| IX. Test discipline | Test-first coverage for: the action registry G3 set, first-needs-action selection, remaining-attempt outcome mapping, preview diff on `CANCELLATION_TERMS_CHANGED`, cash form validation and the read-only amount, resend countdown, idempotency key reuse, routing table for G3 types, and evidence-never-on-disk. Widget tests cover every state, and goldens cover every new screen and component. | PASS |
| Repository constraints | No backend files here (AGENTS.md). Required RPCs and fields are drafted in `contracts/supabase-stay.md`, and the Node contract already has the needed routes. | PASS |

No violations. Complexity Tracking is empty.

### Post-design re-check (after Phase 1)

The design artifacts keep every row above at PASS. Points checked specifically:

- **Server authority (II)**: [data-model.md](data-model.md) holds no derived amount. The
  cancellation diff (§5) compares two server previews and only highlights fields. The
  "Needs your action" line (§1) is `firstGuestAction(availableActions)` over the server's own
  order.
- **Echoed amounts (II/III)**: [contracts/supabase-stay.md](contracts/supabase-stay.md) S3 and S5
  define `expected_*_minor` as a must-equal check that returns `CANCELLATION_TERMS_CHANGED` /
  `CASH_AMOUNT_CHANGED`. That keeps the Master Plan signature while making the server the
  source.
- **Payment integrity (III)**: the remaining attempt record (data-model §3) is saved before the
  Node call and cleared only on a final payment status, sign-out, or "Try again". A `CONFLICT`
  answer opens verification for the open payment and never starts a second one.
- **Privacy (IV)**: `DamageClaim.evidence` holds attachment IDs only, and URLs live in the
  evidence Cubit's memory (data-model §7). `toCacheJson` drops `pending_cash.challenge_id`.
- **Design (V)**: [contracts/ui-screens.md](contracts/ui-screens.md) maps each screen section to
  an existing component. Only the three new shared components are added, each with goldens.

## Project Structure

### Documentation (this feature)

```text
specs/004-guest-stay-cancellation/
├── plan.md              # This file
├── research.md          # Phase 0: decisions + rationale
├── data-model.md        # Phase 1: entities, validation, state
├── quickstart.md        # Phase 1: setup + validation scenarios
├── contracts/           # Phase 1
│   ├── supabase-stay.md        # RPCs used, as-built vs required (S1–S8), errors, tests, seed
│   ├── app-routes.md           # G3 routes, entry rules, notification routing changes
│   └── ui-screens.md           # Screen → component/token map + design reference per screen
├── checklists/requirements.md
└── tasks.md             # Phase 2 ($speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── app/router/
│   ├── routes.dart                 # + /bookings/:id/cash-confirm, /bookings/:id/cancel,
│   │                               #   /bookings/:id/receipts/:paymentId, /damage-claims/:claimId;
│   │                               #   remaining-payment + damage-claim become real
│   ├── app_router.dart             # G3 routes under the bookings branch
│   └── notification_router.dart    # G3 targets (contracts/app-routes §3)
├── core/errors/error_mapper.dart   # + G3 codes (contracts/supabase-stay §6)
├── design_system/components/
│   ├── on_air_confirm_sheet.dart       # NEW: 24dp sheet, title, body, primary + quiet action
│   ├── on_air_confirm_dialog.dart      # NEW: dialog styled like image 15, destructive variant
│   └── acknowledgement_tracker.dart    # NEW: two labelled steps (you / owner) with times
├── features/
│   ├── booking/                    # G2 flow — PaymentAttempt gains kind + paymentId,
│   │                               #   verification outcome reads payment status for remaining
│   ├── bookings/
│   │   ├── domain/   booking_details (+ acknowledgements, claims, offer, pendingCash),
│   │   │             booking_action (G3 registry + firstGuestAction)
│   │   ├── data/     fixtures (+ G3 states), mock_booking_server (+ G3 commands)
│   │   └── presentation/ booking_details_screen (+ primary action bar, tracker, claim cards,
│   │                 offer card, remaining note), widgets/booking_card (+ needs-action line)
│   └── stay/                       # NEW feature: everything the guest does on a booking in G3
│       ├── domain/   stay_repository (interface), cancellation_preview, cash_request,
│       │             cash_receipt, damage_claim, replacement_offer, action_result
│       ├── data/     supabase_stay_repository.dart (RPC + Node), mock_stay_repository.dart
│       │             (delegates to MockBookingServer), action_attempt_store.dart
│       └── presentation/
│           ├── remaining_payment/  remaining_payment_cubit, remaining_payment_screen
│           ├── cash/               cash_confirm_cubit, cash_phone_step, cash_code_step,
│           │                       cash_receipt_screen
│           ├── stay_ack/           stay_ack_cubit, checkin_sheet, checkout_sheet
│           ├── cancellation/       cancellation_cubit, cancellation_screen, widgets/
│           ├── claims/             damage_claim_cubit, damage_claim_screen, evidence_viewer
│           └── offer/              replacement_offer_cubit, offer_card
└── l10n/app_ar.arb, app_en.arb     # + G3 copy, status messages, notification texts

test/                               # mirrors lib/ (unit, widget, goldens)
integration_test/
├── stay_journey_mock_test.dart
├── cash_confirm_mock_test.dart
├── cancellation_mock_test.dart
├── claim_offer_mock_test.dart
└── stay_staging_test.dart          # enabled once S1–S8 are on Staging
```

**Structure Decision**: The G3 flows live in a new `features/stay` feature, not inside
`features/bookings`:
- `bookings` stays the long-lived, cached record and its details screen. It gains only display
  sections and a single place that maps an action code to a route or sheet.
- `stay` owns the commands and their short-lived screens, so each command can be tested and
  mocked on its own.
- The G2 payment-attempt and verification plumbing in `features/booking` is reused by extending
  `PaymentAttempt`, not copied.
- Shared visual pieces go to the design system so G4/G5 can reuse the confirm sheet, dialog, and
  tracker.

## Complexity Tracking

No constitution violations to justify.
