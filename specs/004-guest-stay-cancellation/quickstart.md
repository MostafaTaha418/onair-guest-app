# Quickstart: Guest Stay & Cancellation (G3)

How to run and check G3.
- **Setup:** the same as G2 ([G2 quickstart](../003-guest-booking-payment/quickstart.md)).
- **Reference docs:** contracts are in [contracts/](contracts/), entities and rules are in
  [data-model.md](data-model.md), and the visual map is in
  [contracts/ui-screens.md](contracts/ui-screens.md).

## Prerequisites

- G2 and the UI refresh are merged into `develop`. This work is on
  `feature/004-guest-stay-cancellation`.
- `env/staging.json` exists, holding public values only (as in G2).
- **Mock mode** (`"BACKEND_MODE": "mock"`) covers every G3 flow:
  - fixtures in `lib/features/bookings/data/fixtures/` gain one booking per seed row in
    [supabase-stay.md §7](contracts/supabase-stay.md);
  - the mock server implements S3–S7 (preview, cancel, cash start/confirm, claim, offer) with
    the same JSON shapes;
  - the mock code is always `123456`, and any other code gives `OTP_INVALID`;
  - the collector phone `+201000000001` is authorized, and any other number gives
    `COLLECTOR_NOT_AUTHORIZED`;
  - the debug menu has buttons for owner-side events: "Owner confirms handover", "Owner confirms
    checkout", "Collector records cash", "Open claim", "Advance refund stage", and "Change
    cancellation terms" (forces `CANCELLATION_TERMS_CHANGED` once).
- **Remote mode** needs:
  - S1–S8 deployed to Staging;
  - the Staging seed;
  - the Kashier test account (G2).

  Check-in, check-out, and remaining payment already exist on Staging. The other flows need
  S1, S3, and S5–S7.

## Build and run

```bash
flutter pub get
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

```bash
flutter gen-l10n
```

```bash
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=env/staging.json
```

## Quality gates (same as CI)

```bash
dart format --set-exit-if-changed .
```

```bash
flutter analyze
```

```bash
flutter test
```

```bash
flutter test --tags golden
```

## Validation scenarios

Run each one in mock mode first, then on Staging when the deltas are live.

| # | Scenario | Expected |
|---|---|---|
| 1 | Deposit-only confirmed booking → details | Remaining note, "Pay {amount}" as the only filled action, card shows "مطلوب منك: سداد المتبقي" (US1, FR-003a) |
| 2 | Pay remaining online → mock page Succeed → return | Verification screen, then remaining line "paid"; "Pay" gone; "استلمت الشقة" appears only after the server says so (AC-025) |
| 3 | Same, with the mock page Fail; then tap "Pay" twice fast | "Try again" with a new key; exactly one new payment (SC-006) |
| 4 | Cash, guest-started: wrong phone format → unauthorized phone → `+201000000001` | Field error → warning banner + support → code step with masked email; amount is read-only |
| 5 | Code `000000`, then resend, then `123456` with the statement checked | Error under the field; resend disabled with countdown; receipt; payments line opens the same receipt offline (US2) |
| 6 | Debug "Collector records cash" → tap the notification | Opens the code step directly with the server amount and name |
| 7 | Fully paid booking on arrival day → "استلمت الشقة" → "أيوه" | Waiting message + tracker "You confirmed · Waiting for the owner"; debug "Owner confirms handover" → "Stay in progress" (AC-026) |
| 8 | In stay → "غادرت الشقة" → owner confirms with key left safe | Waiting with "Key left in the agreed place", then "Your stay is complete" (AC-027) |
| 9 | Cancel in each case: free / deposit_lost / no_refund | Amounts and sentence match the fixture; destructive dialog repeats the refund (AC-030 to AC-032) |
| 10 | Debug "Change cancellation terms", then confirm | New preview with changed rows highlighted; must confirm again |
| 11 | After cancelling, advance the refund stages | Requested → In progress → Received only at the last stage (AC-042) |
| 12 | Open claim from the notification; check evidence; dispute with 5 characters, then 20 | Protection notice first; counter error; case number shown; claim card stays in details (US5, AC-036) |
| 13 | Rejected booking with offer: accept one, decline the other; expired offer | Dialogs repeat the difference; `OFFER_NOT_AVAILABLE` message and refresh (US6) |
| 14 | Airplane mode on details with all sections | Cached sections visible, all actions disabled, cancel/code/evidence show "Needs a connection" |
| 15 | Open `/bookings/<other guest>/cancel` and `/damage-claims/<other guest's claim>` | "Not available" without hints (FR-029) |
| 16 | Visual pass of every G3 screen | Matches [ui-screens.md](contracts/ui-screens.md) in light/dark, AR/EN, 1.3×, 320dp and tablet; no new colours/fonts/radii |

## Automated checks

- **Unit:**
  - `BookingActionRegistry.g3` and `firstGuestAction`;
  - `PaymentAttempt` JSON incl. legacy records without `kind`;
  - the remaining verification outcome;
  - `PreviewChange`;
  - the cash phone validator;
  - `ActionAttemptStore` key reuse;
  - `NotificationRouter` G3 rows;
  - `EvidenceUrlCache` expiry;
  - `toCacheJson` dropping `challenge_id`.
- **Bloc:** `RemainingPaymentCubit`, `CashConfirmCubit` (every transition in data-model §2),
  `StayAckCubit`, `CancellationCubit`, `DamageClaimCubit`, `ReplacementOfferCubit`.
- **Widget:**
  - every screen in loading, error, offline, and success states;
  - double-tap on each confirm sends one call;
  - semantics labels on icon buttons, the read-only amount, and the evidence thumbnails.
- **Goldens:** the list in [ui-screens.md §10](contracts/ui-screens.md).
- **Integration (mock):** `stay_journey_mock_test`, `cash_confirm_mock_test`,
  `cancellation_mock_test`, `claim_offer_mock_test`.
- **Integration (Staging, after S1–S8):** `stay_staging_test` covering AC-025 to AC-038 and
  AC-042 (guest side), plus isolation.

## Done for G3 when

- All quality gates are green, and all G3 goldens are reviewed against the G2 details golden.
- Scenarios 1–16 pass on mock, and scenarios 2, 5, 7–9, 11, and 12 pass on Staging (Guest Plan
  §17 G3 exit criterion).
- `docs/OnAir Guest App Plan.md` §17 G3 is ticked, with a status note like G1/G2.
- S1–S8 are agreed with, or shipped by, the backend owner. Any change is reflected back into
  [supabase-stay.md](contracts/supabase-stay.md).
