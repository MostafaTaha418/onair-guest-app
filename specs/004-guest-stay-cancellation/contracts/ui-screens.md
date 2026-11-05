# Contract: G3 Screens — Visual Consistency Map

The user asked that G3 look exactly like the current app UI. This file fixes, for each G3
surface:
- which existing component or token renders each part;
- which reference screenshot gives the visual direction;
- what differs on purpose.

Sources: `DESIGN.md`, `docs/design_reference/README.md` (image numbers below), and the shipped
G2 screens (`BookingDetailsScreen`, `SummaryScreen`, `PaymentReturnScreen`) and their goldens.

**Global rules (every G3 surface):**

- **App bar:** same as `BookingDetailsScreen` — title in `titleLarge`, mirrored back chevron, no
  extra actions.
- **Page:** `background` canvas, `EdgeInsetsDirectional.all(Dimens.screenSide)`, sections
  separated by `Dimens.space16`, and section titles in `titleMedium` + `textPrimary`, exactly as
  details does today.
- **Amounts:** `AmountRow` (label start, value end) through `MoneyFormatter`. A total is bold as
  in the G2 summary. No new money style.
- **Messages:** `NoticeCard` (icon + one sentence) for status explanations, and `InfoBanner`
  tones for important notes:
  - `info`: e.g. "Must be paid before you receive the apartment";
  - `warning`: e.g. "Don't hand over cash";
  - `success`: e.g. "Payment received";
  - neutral grey (`StatusTone.cancelled`, as the G2 refund-issue banner): e.g. "No amount
    will be deducted…".
- **Main action:** `BottomActionBar` with one filled `OnAirPrimaryButton` (48dp, 12dp radius).
  Secondary actions are `OutlinedButton`. Destructive actions (cancel, dispute) use the theme
  `error` colour as text/outlined, never filled primary.
- **Status:** `StatusChip` (text + icon) for booking, refund, claim, and offer status. Refund
  progress uses `RefundStageTracker`.
- **States:**
  - loading uses skeletons shaped like the final layout, from `skeletons.dart`;
  - errors use `ErrorView` with retry and a reference;
  - offline uses `OfflineBanner` with all actions disabled;
  - "needs connection" uses `ErrorView` with the `errorNoConnection` text.
- **Sheets and dialogs:** new shared `OnAirConfirmSheet` and `OnAirConfirmDialog`:
  - sheet: 24dp top radius, drag handle, title in `titleMedium`, one body sentence, a filled
    primary and a quiet text button, safe-area and keyboard aware;
  - dialog: patterned on **image 15** (title, short body, two text actions at the end), restyled
    with `surface`, 16dp radius, and Cairo, with a `destructive` flag that colours the confirm
    action with `error`.
- **Copy:** Egyptian Arabic, as in G2 (e.g. "هيتبعت طلبك للمالك بعد الدفع"), with English in
  `app_en.arb`. No accounting words. EGP via `MoneyFormatter`.
- **Checks:** every surface is verified in light/dark, AR-RTL/EN-LTR, 1.3× text, 320dp and
  tablet widths, with the keyboard open where there is a field, and with double-tap on every
  confirm.

## 1. Booking details — G3 sections (existing screen)

Order follows the current screen. New parts are marked **+**.

| # | Section | Component | Notes |
|---|---|---|---|
| 1 | Header (photo, title, code, chips) | existing `_Header` | unchanged |
| 2 | Status message | `NoticeCard` | **+** texts for waiting-handover, waiting-checkout, stay in progress, completed, cancelled by you/OnAir, no-show, reopened |
| 3 | **+** Stay tracker | `AcknowledgementTracker` (new) | only when an acknowledgement exists (data-model §4) |
| 4 | **+** Replacement offer card | surface card (16dp) with a small property row (G1 `PropertyCard` compact visuals), `AmountRow` for dates/difference, two buttons | anchor for `focus=offer` |
| 5 | Stay dates | existing `AmountRow`s | unchanged |
| 6 | Payments | existing rows | **+** remaining note `InfoBanner(StatusTone.info)` when `remaining > 0`; **+** cash lines tappable → receipt (chevron, semantics "Show receipt") |
| 7 | Refund | existing `RefundSection` | unchanged (stages + chip) |
| 8 | **+** Damage claims | one compact card per claim: amount, `StatusChip`, chevron | tap → claim screen |
| 9 | Address, terms, timeline | existing | unchanged |
| 10 | Actions | **+** `BottomActionBar` with the primary action; other actions as outlined buttons above "Contact support"; "Cancel booking" as an `error`-coloured text button last | replaces the G2 list of outlined buttons |

## 2. My Bookings card (existing `BookingCard`)

- **+** One line under the dates: an icon (`AppIcons.infoOutline`) and the label
  "مطلوب منك: {action}" in `labelLarge`, coloured `warning` text on no background.
- No buttons. The tap target is unchanged (Clarification).
- **Image 23** is a reference for chip placement only. Its on-card buttons are not adopted.

## 3. Remaining payment — `/bookings/:id/remaining-payment`

Reference: **images 30, 2, 20** (option cards + amount summary card), adapted.

| Part | Component |
|---|---|
| Property row | same compact row as the G2 summary header (photo 64dp, title, area) |
| Amount summary card | surface card: `AmountRow` total · paid · **remaining (bold, primary)** · due date |
| Note | `InfoBanner(StatusTone.info)`: «لازم تسدد المتبقي قبل ما تستلم الشقة» |
| Options (only if cash allowed) | two selectable surface cards (16dp, `selected` tone when chosen, radio icon at end): «ادفع أونلاين» / «دفعت أو هدفع كاش» — image 30 style |
| Action | `BottomActionBar`: «ادفع {amount}» (online) or «كمّل تأكيد الكاش» (cash) |

- Without cash, there are no option cards, only the online button.
- Deliberate difference from image 30: no deposit/full choice (the server already decided), no
  dollar amounts, and no "Checkout Now" wording.

## 4. Cash confirmation — `/bookings/:id/cash-confirm`

**Phone step:**

| Part | Component |
|---|---|
| Amount (read-only) | `AmountRow` «المبلغ» + value, inside a surface card with a lock icon and semantics "Amount, not editable" |
| Collector phone | `OnAirTextField` with phone keyboard, Egyptian prefix hint, error text under the field |
| Warning | `InfoBanner(StatusTone.warning)`: «متسلّمش فلوس غير لشخص مفوّض من OnAir» |
| Action | `BottomActionBar` «ابعت الكود على بريدي» |

**Code step:**

| Part | Component |
|---|---|
| Summary | `NoticeCard`: «بعتنا كود على {maskedEmail}» |
| Amount + collector | `AmountRow` ×2 |
| Code | `OnAirOtpField` (G0) + resend text button with `CountdownText` |
| Statement | checkbox row (48dp target): «أؤكد إني سلّمت {amount} كاش لـ {name}» |
| Action | `BottomActionBar` «أكّد الدفع» (disabled until 6 digits + checkbox) |

- **Not authorized:** `InfoBanner(StatusTone.warning)` with the reworded `COLLECTOR_NOT_AUTHORIZED` text and
  a «كلّم الدعم» outlined button.

## 5. Cash receipt — `/bookings/:id/receipts/:paymentId`

- A success header: a `success` tone icon in a circle and the title «تم تأكيد الدفع الكاش».
- A surface card with `AmountRow`s: amount, collector, date and time (Cairo), receipt number
  (selectable, copy icon with semantics).
- `BottomActionBar` «رجوع للحجز».

## 6. Check-in / check-out sheets

`OnAirConfirmSheet`:

| Sheet | Title | Body | Actions |
|---|---|---|---|
| Check-in | «استلمت الشقة فعلًا؟» | «أكّد بس لو استلمت الشقة والمفاتيح.» | «أيوه، استلمتها» / «لسه» + tertiary link «عندي مشكلة في الاستلام» → support |
| Check-out | «غادرت الشقة؟» | «أكّد بعد ما تسيب الشقة وتسلّم المفاتيح.» | «أيوه، غادرت» / «لسه» |

- No code field and no photo picker.

## 7. Cancellation — `/bookings/:id/cancel`

| Part | Component |
|---|---|
| Result card | surface card: `AmountRow` «هيترجعلك» (bold, `success` text) and «مش هيترجع» (when > 0); a changed row gets the G2 quote-change highlight |
| Reason sentence | `NoticeCard` with the `.arb` sentence for `policy_case` |
| Reason (optional) | four `ChoiceChip`s using `FilterChipBar` styling, plus «سبب تاني» with an `OnAirTextField` (≤ 300) |
| Actions | `BottomActionBar`: «إلغاء الحجز» as an outlined button with `error` colour, plus a quiet «خليني محتفظ بالحجز» |
| Final dialog | `OnAirConfirmDialog(destructive: true)`: «متأكد إنك عايز تلغي؟ هيترجعلك {amount}.» |

- Deliberate: the destructive button is never filled. It is the bar's only strong action, so it
  stays clear without inviting accidental taps.

## 8. Damage claim — `/bookings/:id/damage-claim/:claimId`

| Part | Component |
|---|---|
| Protection notice | `InfoBanner(StatusTone.cancelled)` (neutral grey): «مفيش أي مبلغ هيتخصم من غير موافقتك أو قرار من OnAir» — always first |
| Claim card | surface card: `StatusChip`, description (`bodyMedium`), `AmountRow` «المبلغ المطلوب» |
| Evidence | horizontal row of 96dp rounded (12dp) thumbnails, themed placeholder plus retry on failure; tap → viewer |
| Answer (open only) | `BottomActionBar`: «موافق» (filled) + «معترض» (`error` outlined) |
| Dispute form | expands in place: `OnAirTextField` multiline (10–1000, counter) + «ابعت الاعتراض» |
| After answer | `NoticeCard` with the answer; for a dispute, «رقم الحالة: {n}» selectable |

**Evidence viewer:** a black scrim, `InteractiveViewer`, a page counter «2 من 3», and a close
button (48dp, semantics).

## 9. Replacement offer card (inside details)

- Title «عرض بديل من OnAir» in `titleMedium`.
- A compact property row, dates as `AmountRow`.
- Difference sentence: `InfoBanner(StatusTone.info)` for a refund, `warning` for paying more, neutral grey
  (`StatusTone.cancelled`) for none. Expiry «رد قبل {time}».
- Buttons «موافق» (filled) / «لا، عايز استرداد فلوسي» (outlined), each followed by a
  `OnAirConfirmDialog`.

## 10. Goldens to add

| Golden | Variants |
|---|---|
| `booking_details_g3_{deposit, waiting_handover, in_stay, claim_offer}` | light/dark × AR/EN × 1.0/1.3 |
| `remaining_payment`, `cash_phone_step`, `cash_code_step`, `cash_receipt`, `cancellation_{free,deposit_lost,no_refund,changed}`, `damage_claim_{open,disputed}` | light/dark × AR × 1.0/1.3; EN × light; 320dp + 800dp for remaining payment and cancellation |
| Components: `confirm_sheet`, `confirm_dialog{,_destructive}`, `acknowledgement_tracker_states`, `booking_card_needs_action` | light/dark × RTL/LTR × 1.3 |
