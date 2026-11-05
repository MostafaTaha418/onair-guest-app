# Feature Specification: Guest Stay & Cancellation (G3)

**Feature Branch**: `feature/004-guest-stay-cancellation`

**Created**: 2026-11-05

**Status**: Draft

**Input**: User description: "الجزء اللي عليه الدور في الخطة بتاع المشروع بس تأكد من ان التصميمات ماشيه
بنفس النهج اللي التطبيق ماشي بيه وراجع ملفات التصميم والاسكرين شوتس يعني عايز التكملة تكون زي التصميم
الحالي اللي هو UI التطبيق واعمل طبعا برانش جديد للمشروع" — the next open phase of the plan, G3
Stay and Cancellation: paying the remaining amount online, confirming a cash payment with a code
sent to the guest's email, "I received the apartment" and "I left the apartment", cancelling
with a server preview and following the refund stages, answering a damage claim, and answering a
replacement offer. Every new screen must look and behave like the current app UI.

**Sources**: `docs/OnAir Guest App Plan.md` (§0.3, §1.1–§1.2, §6.8–§6.13, §7, §8, §9.3, §10.2,
§13, §14.2, §17 G3, §20), `docs/OnAir Master Plan.md` (§5.5, §6.1–§6.4, §7.1–§7.5, §8.3;
AC-007, AC-025 to AC-038, AC-042, AC-047), `DESIGN.md`, `docs/design_reference/README.md` and
its screenshots, `docs/UI_UX_DESIGN_SYSTEM.md`, `.specify/memory/constitution.md`,
`specs/003-guest-booking-payment/spec.md` (G2, delivered).

## Clarifications

### Session 2026-11-05

- Q: Should the guest attach photos to a damage-claim dispute in G3, bringing private uploads
  forward from G4, or send a written reason only? → A: Written reason only in G3; attachments are
  added to disputes when G4 delivers private uploads.
- Q: When the guest starts a cash confirmation, can they change the amount or is it fixed to the
  server's remaining amount? → A: Fixed to the server's remaining amount (read-only); the guest
  enters only the collector's phone number. No partial cash payments.
- Q: In My Bookings, does a booking that needs the guest's action show a button on its card (as
  in screenshot 23) or keep the current tap-to-open card? → A: Keep the current card and add only
  a small "Needs your action" line naming the first server action; all actions stay in booking
  details.
- Q: Where does the guest find a damage claim and a cash receipt later (after answering or if the
  notification is missed)? → A: From booking details: a "Damage claim" card with its status for
  every claim (open or closed) that opens the claim screen, and each confirmed cash payment in
  the payments section opens its receipt.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pay the remaining amount online (Priority: P1)

A guest with a confirmed booking who paid only the deposit opens the booking and sees how much
is left, when it is due, and that it must be paid before receiving the apartment. They tap "Pay
the remaining amount", review a short screen with the amount and due date exactly as the server
sent them, and pay on the same Kashier page used for the first payment. They come back to the
same verification screen, which waits for the server, then shows that the remaining amount was
paid and the booking's payments are updated.

**Why this priority**: A deposit-only booking cannot start its stay until the rest is paid and
verified (AC-025). Without this flow guests with deposits cannot check in through the app.

**Independent Test**: With a seeded confirmed deposit-only booking, open its details, start the
remaining payment, pay on the test (or mock) page, return, and confirm the booking shows the
remaining amount as paid only after the server confirms.

**Acceptance Scenarios**:

1. **Given** a confirmed booking whose allowed actions include "pay remaining", **When** the
   guest opens its details, **Then** the payments section shows the remaining amount, its due
   date in Cairo time, and the note "The remaining amount must be paid before you receive the
   apartment", and a primary "Pay the remaining amount" action is visible.
2. **Given** the remaining-payment screen, **When** it opens, **Then** it shows the apartment,
   the dates, the total, what was already paid, the remaining amount, and its due date exactly
   as the server returned them, and, when the server also allows a cash payment for this
   booking, a second option "I paid / will pay in cash" that leads to the cash confirmation
   (User Story 2).
3. **Given** the guest taps "Pay online", **When** the request is sent, **Then** the button is
   disabled at once with a loader, the request carries only the booking and a single attempt key
   (never an amount), and the payment page opens in the secure in-app browser.
4. **Given** the guest returns from the payment page, **When** the verification screen opens,
   **Then** it behaves as in G2 (verifying, then success, failure with "Try again", or the
   not-yet-confirmed message) and never offers to pay again while verifying.
5. **Given** the server confirms the remaining payment, **When** the guest opens the booking,
   **Then** the remaining amount shows as paid, the new payment appears with its time and method,
   and "Pay the remaining amount" is no longer shown.
6. **Given** a "remaining amount due" reminder notification, **When** the guest taps it, **Then**
   the remaining-payment screen for that booking opens (after sign-in if needed), or the booking
   details when the server no longer allows the payment.

---

### User Story 2 - Confirm a cash payment with an email code (Priority: P1)

A guest pays the remaining amount in cash to the owner or an authorized collector. Either the
guest starts the confirmation by entering the collector's phone number (the amount is the
remaining amount from the server and cannot be changed), or the
collector records the payment from the owner app and the guest receives a notification. In both
cases a code arrives at the guest's email; the guest enters it, reads a clear statement "I
confirm I handed X EGP in cash to …", and confirms. They then see an in-app receipt and the
booking's payments are updated.

**Why this priority**: Cash is an approved way to pay the remaining amount, but it only counts
when the guest confirms it with an independent email code (AC-037). It protects guests from a
collector claiming money that was never paid and keeps a correct cash payment valid (AC-038).

**Independent Test**: With a seeded booking where cash is allowed and an authorized test
collector, start a cash confirmation from the app, enter the code from the test inbox, and
confirm the receipt appears and the payments section updates; repeat from the collector side
using the "confirm your cash payment" notification.

**Acceptance Scenarios**:

1. **Given** a booking whose allowed actions include "confirm cash payment", **When** the guest
   chooses to confirm a cash payment, **Then** a form asks only for the phone number of the
   person who received the cash, and shows the remaining amount from the server as a read-only
   value that cannot be changed.
2. **Given** the guest enters a phone number that is not an Egyptian mobile number, **When** they
   submit, **Then** a clear error appears under the field and nothing is sent.
3. **Given** the server reports that the person is not authorized to collect for this apartment,
   **When** the answer arrives, **Then** the guest sees "This person is not authorized to collect
   payments for this apartment. Don't hand over cash and contact OnAir", with a "Contact support"
   button.
4. **Given** an authorized collector, **When** the server accepts, **Then** a code is sent to the
   guest's email and the code step opens, showing the masked email, the collector's name as
   returned by the server, and the amount.
5. **Given** a "confirm your cash payment" notification from the collector side, **When** the
   guest taps it, **Then** the same code step opens directly with the amount and collector from
   the server, after sign-in if needed.
6. **Given** the code step, **When** the guest enters the 6-digit code and taps "I confirm I paid",
   **Then** the button is disabled at once, and on success an in-app receipt shows the amount,
   the collector, the date and time in Cairo time, and a receipt reference.
7. **Given** a wrong or expired code, too many attempts, or too-frequent resend requests,
   **When** the server refuses, **Then** the guest sees a clear message and, when rate-limited,
   the remaining wait time with the resend button disabled until then.
8. **Given** a confirmed cash payment, **When** the guest opens the booking, **Then** the
   payment shows as "Paid in cash" and nothing about the collector's internal handover is shown.

---

### User Story 3 - Confirm receiving and leaving the apartment (Priority: P1)

On arrival day the guest opens their confirmed booking and taps "I received the apartment". A
short confirmation sheet asks "Did you actually receive the apartment?" with no code and no
required photos. After confirming, the booking says it is waiting for the owner's handover
confirmation until both sides have confirmed, then shows "Stay in progress". At the end of the
stay the guest taps "I left the apartment" in the same way, sees "Waiting for the owner to confirm
receiving the apartment" until the owner confirms, and then sees "Stay completed".

**Why this priority**: Check-in and check-out are the two moments that start and end a real stay;
both sides must confirm (AC-026, AC-027). Without them no paid stay can progress in the app.

**Independent Test**: With a seeded confirmed, fully paid booking on its arrival date, confirm
receipt in the app, confirm the waiting message, trigger the owner's confirmation (seed or owner
app), and confirm the booking becomes "Stay in progress"; repeat for leaving.

**Acceptance Scenarios**:

1. **Given** a booking whose allowed actions include "confirm check-in", **When** the guest taps
   "I received the apartment", **Then** a bottom sheet asks for confirmation with "Yes, I received
   it" and "Not yet", and nothing is sent until the guest confirms.
2. **Given** the guest confirms, **When** the server accepts, **Then** the booking shows "Waiting
   for the owner to confirm the handover" until the server reports the stay in progress; the app
   never shows "Stay in progress" on its own (AC-026).
3. **Given** the owner already confirmed the handover (a "the owner handed over the apartment —
   confirm you received it" notification), **When** the guest confirms, **Then** the booking
   shows "Stay in progress" as soon as the server reports it.
4. **Given** a deposit-only booking whose remaining amount is not verified, **When** its details
   are shown, **Then** "I received the apartment" is not shown, and the remaining-amount note and
   "Pay the remaining amount" are shown instead (AC-025).
5. **Given** a stay in progress whose allowed actions include "confirm check-out", **When** the
   guest taps "I left the apartment" and confirms, **Then** the booking shows "Waiting for the
   owner to confirm receiving the apartment" until the server reports the stay completed (AC-027).
6. **Given** an open damage claim on the booking, **When** the guest confirms leaving, **Then**
   leaving is not blocked by the claim (AC-036).
7. **Given** the server reports the stay completed, **When** the guest opens the booking, **Then**
   it shows "Your stay is complete" and, only if the server allows it, an invitation to review
   (the review flow itself is G5).
8. **Given** a full-price booking whose guest is late, **When** the arrival time passes, **Then**
   the app shows no "no-show" or cancellation by itself; it only shows what the server reports
   (AC-033).

---

### User Story 4 - Cancel a booking with a clear preview and follow the refund (Priority: P1)

A guest who can no longer travel opens their booking and taps "Cancel booking". Before anything
happens, the app asks the server what would be refunded and shows it in plain words, for example
"3,600 EGP will be refunded. The 1,000 EGP deposit is not refundable because free cancellation
ended on …". The guest may choose a reason, then confirms with a clearly destructive button. The
booking becomes cancelled, and its refund badge and stages show progress until the server
confirms the money reached the guest.

**Why this priority**: Cancellation and refunds are where trust is won or lost. The guest must
see the exact server-calculated result before deciding (AC-030 to AC-032) and must never see
"Refunded" before the money is verified (AC-042).

**Independent Test**: With seeded bookings in the free-cancellation window, after it, and more
than 24 hours after the scheduled check-in for a fully paid booking, open each cancellation
preview and confirm the amounts and explanation match the server; cancel one and follow its
refund stages to "Refund received".

**Acceptance Scenarios**:

1. **Given** a booking whose allowed actions include "request cancellation", **When** the guest
   taps "Cancel booking", **Then** the cancellation screen asks the server for a preview and
   shows a loading shape until it arrives.
2. **Given** the preview, **When** it is shown, **Then** the guest sees the amount to be refunded,
   any non-refundable amount, and the server's reason in plain Arabic, with every amount exactly
   as returned (free cancellation → full refund, AC-030; after free cancellation → only the
   deposit is lost, AC-031; fully paid and more than 24 hours after the scheduled check-in → no
   refund, AC-032).
3. **Given** the preview, **When** the guest picks an optional reason and taps "Confirm
   cancellation", **Then** a final confirmation dialog repeats the refund amount, and only after
   that the request is sent, carrying the refund amount the guest saw.
4. **Given** the server answers that the cancellation terms changed since the preview, **When**
   the answer arrives, **Then** the new preview is shown with the changes highlighted and the
   guest must confirm again.
5. **Given** a successful cancellation, **When** the guest returns to the booking, **Then** it
   shows "Booking cancelled", the refund badge, and the refund stages "Requested → Approved → In
   progress → Received", and the booking moves to the Cancelled tab.
6. **Given** a refund in any stage before the server's final check, **When** it is shown,
   **Then** it never shows "Refunded" or "Received"; that appears only when the server reports
   the final check done (AC-042).
7. **Given** the guest taps "Keep my booking" or goes back, **When** they leave the cancellation
   screen, **Then** nothing is sent and the booking is unchanged.

---

### User Story 5 - Answer a damage claim (Priority: P2)

After a stay, the owner reports damage. The guest gets a notification and opens a claim screen
showing the description, the claimed amount, and any evidence photos. The screen says clearly
"No amount will be deducted without your agreement or a decision from OnAir". The guest either
agrees, or disputes with a written reason, in which case the claim goes to OnAir for mediation
and its support case number is shown.

**Why this priority**: Claims are rarer than payments and stays but must be handled fairly
(AC-036). They depend on stays existing (User Story 3).

**Independent Test**: With a seeded claim on a completed booking, open it from the notification,
check the description, amount, and evidence, then agree on one claim and dispute another, and
confirm each result matches the server.

**Acceptance Scenarios**:

1. **Given** a "damage claim opened" notification, **When** the guest taps it, **Then** the claim
   screen for that booking opens, after sign-in if needed.
2. **Given** the claim screen, **When** it opens, **Then** it shows the description, the claimed
   amount from the server, evidence photos (opened full-screen on tap, loaded through temporary
   private links), the claim's status, and the "No amount will be deducted…" notice.
3. **Given** the guest taps "I agree", **When** they confirm in a dialog that repeats the amount,
   **Then** the agreement is sent once and the claim shows the server's new status.
4. **Given** the guest taps "I dispute", **When** they submit without a reason, **Then** an error
   appears under the reason field; with a reason, the dispute is sent once and the claim shows
   "Under review by OnAir" with the support case number from the server.
5. **Given** a claim already answered or resolved, **When** it is opened, **Then** it shows the
   answer, the outcome when the server provides one, and no answer buttons.

---

### User Story 6 - Answer a replacement offer from OnAir (Priority: P2)

After an owner declines or does not answer in time, OnAir's team may offer another apartment.
The booking shows an "Alternative offer from OnAir" card with the offered apartment, dates, and
any price difference, and two buttons: "I accept" and "No, I want my refund". Nothing changes
without the guest's explicit answer.

**Why this priority**: It is optional and depends on the support team creating offers, but it
gives declined guests a path to still travel (Master Plan §5.1 item 12).

**Independent Test**: With a seeded rejected booking carrying a replacement offer, open the
booking from the "alternative offer" notification, accept one offer and decline another, and
confirm each booking reflects the server's answer.

**Acceptance Scenarios**:

1. **Given** a booking with an open replacement offer, **When** its details are shown, **Then**
   an "Alternative offer from OnAir" card shows the offered apartment (photo, name, area), the
   dates, and any price difference exactly as the server sent it, labelled in plain words (for
   example "You will pay 500 EGP more" or "500 EGP will be refunded to you").
2. **Given** the guest taps "I accept", **When** they confirm in a dialog that repeats any
   difference, **Then** the answer is sent once and the booking shows the server's result.
3. **Given** the guest taps "No, I want my refund", **When** they confirm, **Then** the answer is
   sent once, the offer card disappears, and the refund continues as before.
4. **Given** the offer has expired or was withdrawn, **When** the guest tries to answer, **Then**
   a clear message appears and the booking refreshes.
5. **Given** a "replacement offer" notification, **When** the guest taps it, **Then** the booking
   details open scrolled to the offer card.

---

### Edge Cases

- The server's allowed actions change while a screen is open (for example the owner confirms
  handover, or the deadline passes): the screen refreshes from the server and buttons appear or
  disappear accordingly; the app never decides availability from local time.
- A request is sent and the connection drops before the answer: the action stays disabled, the
  guest sees a retry option, and a retry reuses the same attempt key so the action happens once.
- The guest double-taps any confirm button (pay, confirm cash, check-in, check-out, cancel,
  agree, dispute, accept, decline): exactly one request is sent.
- The guest is offline: the screens show the last saved copy where one exists, all actions are
  disabled with an offline notice, and the cancellation preview and code entry are not available.
- The remaining payment is started but an earlier remaining-payment attempt is still being
  verified: the app opens the verification screen instead of starting a new payment.
- The guest receives a cash code but then closes the app: reopening from the notification or the
  booking returns to the code step while the server still allows it.
- The remaining amount changes on the server between opening the cash form and submitting (for
  example an online payment landed): the server's refusal is shown, the booking refreshes, and
  the form shows the new amount or closes if nothing is left.
- A cancellation is requested at the moment free cancellation ends: the server's preview check
  decides; if it changed, the guest sees the new preview before anything happens.
- The booking was cancelled by OnAir, marked no-show, or reopened by an authorized person: the
  booking shows the matching message from the server and its notification opens the booking
  (AC-034, AC-035).
- Evidence photos fail to load or their temporary links expire: a themed placeholder with a retry
  appears, and reopening the claim fetches fresh links.
- A link or notification points to a booking, claim, or offer that is not the guest's or does not
  exist: the neutral "Not available" screen appears.
- An unknown action code appears in the server's list: it is not shown.

## Requirements *(mandatory)*

### Functional Requirements

**Allowed actions**

- **FR-001**: The app MUST show, on booking details, only the actions in the server's allowed
  actions list whose flows exist: "pay remaining", "confirm cash payment", "request
  cancellation", "confirm check-in", "confirm check-out", "respond to damage claim", and
  "contact support" (G2). "Write review" stays hidden until G5. Unknown codes MUST NOT be shown.
- **FR-002**: Every action that changes money or booking state MUST disable its trigger on the
  first tap until the server answers, MUST show progress in place without resizing, and MUST
  carry a single attempt key that stays the same for every retry of that action.
- **FR-003**: When an action succeeds or fails, the app MUST refresh the booking from the server;
  it MUST NOT change any status, amount, or allowed action on its own.
- **FR-003a**: Booking cards in My Bookings MUST keep the current tap-to-open design with no
  action buttons. When the server lists an action that needs the guest (any delivered action
  except "contact support"), the card MUST add one small labelled line, such as "Needs your
  action: pay the remaining amount", naming the first such action in the server's order; it
  disappears when the server no longer lists one.

**Remaining payment**

- **FR-004**: Booking details MUST show the remaining amount, its due date, and the note that it
  must be paid before receiving the apartment whenever the server reports a remaining amount.
- **FR-005**: The remaining-payment screen MUST show the apartment, dates, total, paid amount,
  remaining amount, and due date exactly as returned by the server, and MUST offer "Pay online"
  and, only when the server allows it, the cash option.
- **FR-006**: "Pay online" MUST send only the booking and an attempt key, open the payment page in
  the same secure in-app browser as G2, and lead back to the same verification screen and
  outcomes as G2 (verifying, success, failed with "Try again", not-yet-confirmed), with no way to
  pay again while verifying.
- **FR-007**: The app MUST NOT compute or send any payment amount for the remaining payment.

**Cash confirmation**

- **FR-008**: The guest-started cash flow MUST collect only the collector's Egyptian mobile
  number, show the server's remaining amount as a read-only value (the guest cannot enter or
  change an amount, and the app sends no amount of its own), validate the number's format
  before sending, and show the server's "not authorized" refusal with a "Contact support" action.
- **FR-009**: After the server accepts, the app MUST request the email code and show the code
  step with the masked email, the collector's display name, and the amount from the server.
- **FR-010**: The collector-started flow MUST open the same code step from the "confirm your cash
  payment" notification or from booking details, using only server data.
- **FR-011**: The code step MUST use the app's existing 6-digit code field, show a statement "I
  confirm I handed {amount} in cash to {name}", require an explicit confirm tap, handle wrong,
  expired, and rate-limited codes with clear messages and a resend countdown, and MUST NOT copy
  the code to the clipboard.
- **FR-012**: A successful confirmation MUST show an in-app receipt (amount, collector, Cairo date
  and time, reference) and update the booking's payments; the app MUST NOT show anything about the
  collector's internal handover (AC-038). Each confirmed cash payment line in booking details MUST
  open the same receipt again at any time.

**Check-in and check-out**

- **FR-013**: "I received the apartment" and "I left the apartment" MUST open a confirmation bottom
  sheet with no code and no required photos, and MUST send the confirmation only after the guest
  confirms.
- **FR-014**: After the guest's confirmation, the booking MUST show the waiting message ("Waiting
  for the owner to confirm the handover" / "Waiting for the owner to confirm receiving the
  apartment") until the server reports the new status; "Stay in progress" and "Stay completed"
  MUST appear only from the server (AC-026, AC-027).
- **FR-015**: Booking details MUST show the guest's own acknowledgement and the owner's
  acknowledgement as separate, labelled steps when the server provides them.
- **FR-016**: After the stay is completed, the booking MUST show the completion message and the
  review invitation only if the server lists the review action (the review screen itself is G5).

**Cancellation and refund**

- **FR-017**: "Cancel booking" MUST first request a cancellation preview and show the refundable
  amount, any non-refundable amount, and the server's reason in plain Arabic, with no amount
  computed by the app.
- **FR-018**: The cancellation MUST offer an optional reason from a fixed list plus "Other", a
  clearly destructive "Confirm cancellation" button, a final confirmation dialog repeating the
  refund amount, and a "Keep my booking" exit that sends nothing.
- **FR-019**: The cancellation request MUST carry the refund amount the guest saw; if the server
  answers that the terms changed, the app MUST show the new preview, highlight what changed, and
  require a new confirmation.
- **FR-020**: Cancelled bookings MUST show the cancellation message, the refund badge separate
  from the status badge, and the refund stages "Requested → Approved → In progress → Received"
  using the existing refund tracker; "Received"/"Refunded" MUST appear only after the server's
  final check (AC-042).

**Damage claims**

- **FR-021**: The claim screen MUST show the description, the claimed amount, evidence photos
  through temporary private links that are never saved on the device, the claim status, and the
  notice "No amount will be deducted without your agreement or a decision from OnAir".
- **FR-022**: The guest MUST be able to agree (with a confirmation dialog repeating the amount) or
  dispute with a required written reason; a dispute MUST show the support case number returned
  by the server.
- **FR-023**: In G3 a dispute MUST accept a written reason only, with no attachment picker or
  "coming soon" placeholder; optional evidence attachments are added to disputes when G4
  delivers private uploads (Clarification 2026-11-05). The guest can still send evidence through
  the dispute's support case once G4 is delivered.
- **FR-024**: Answered or resolved claims MUST show the answer and outcome without answer
  buttons, and the guest's stay completion MUST NOT depend on the claim (AC-036).
- **FR-024a**: Booking details MUST show a "Damage claim" card for every claim on the booking,
  open or closed, with its amount and status badge, opening the claim screen; the card stays
  after the claim is answered or resolved.

**Replacement offer**

- **FR-025**: A booking with an open replacement offer MUST show an "Alternative offer from OnAir"
  card with the offered apartment, dates, and any price difference worded in plain language from
  server values, and two answers: "I accept" and "No, I want my refund".
- **FR-026**: Each answer MUST be confirmed in a dialog, sent once, and followed by a refresh;
  expired or withdrawn offers MUST show a clear message.

**Status messages and notifications**

- **FR-027**: Booking details and cards MUST show the server status messages for the stay and
  cancellation stages (Guest Plan §7.2), including "stay in progress", "stay completed",
  "cancelled" with its refund details, "cancelled by OnAir", "no-show recorded", and "booking
  reopened".
- **FR-028**: The following notifications MUST open the right screen after sign-in if needed:
  remaining amount due → remaining-payment screen; remaining paid, cash receipt, check-in and
  check-out reminders, handover confirmed, stay started/completed, cancellation, no-show,
  reopened, and every refund stage → booking details; cash confirmation requested → cash code
  step; damage claim opened/resolved → claim screen; replacement offered → booking details at the
  offer card.
- **FR-029**: IDs from links and notifications MUST be format-checked and treated as navigation
  hints only; anything the server refuses MUST show the neutral "Not available" screen.

**Design consistency (current app UI)**

- **FR-030**: All UI in this feature follows the root DESIGN.md tokens, components, and
  interaction rules in Arabic/English, RTL/LTR, light/dark, narrow/wide layouts, enlarged text,
  keyboard, loading/empty/error states, accessibility, and repeated-tap protection.
- **FR-031**: New screens MUST reuse the existing app look rather than introduce a new one: the
  same top bar with a title and mirrored back chevron, warm page background with 16dp side
  gutter, surface cards with 16dp corners, section titles in the existing style, amounts in the
  existing label/value rows, notices in the existing coloured notice cards (info, warning,
  success, neutral), status and refund badges from the existing chips, the existing refund
  stage tracker and timeline, the existing 6-digit code field, a sticky bottom action bar for
  the main action, 24dp-corner bottom sheets, and the existing skeleton, empty, error, and
  offline views.
- **FR-032**: Each booking details screen MUST present at most one filled primary action at a
  time (chosen from the server's list in the order the server gives), with any other allowed
  actions as outlined or text buttons; cancellation and "I dispute" MUST use the destructive
  colour and never be the filled primary button.
- **FR-033**: Visual direction MUST follow the design reference screenshots for the matching
  patterns — reservation cards and status badges (images 11 and 23; their on-card action buttons
  are not adopted, see FR-003a), confirmation dialog (image
  15), payment option and amount summary cards (images 2, 20, 30) — translated to the app's tokens,
  Arabic copy, and EGP prices, without copying their English text, dollar amounts, or features
  the product does not have. Any intended difference MUST be noted in the change description.
- **FR-034**: Copy MUST follow the app's current tone (plain Egyptian Arabic as in existing
  booking screens), with no accounting terms, and every text MUST come from the translation files
  in Arabic and English.

**General**

- **FR-035**: Every new screen MUST provide loading (shaped skeleton), error (with retry and a
  reference number for unexpected errors), offline, and success states; server error codes MUST
  map to clear translated messages and raw server text MUST NOT be shown.
- **FR-036**: Every icon-only control MUST have a screen-reader label, touch targets MUST be at
  least 48×48dp, and field errors MUST be shown as text and announced.
- **FR-037**: Every flow in this feature MUST work against the local mock with the same data shapes
  as the server contract, so screens do not change when switching to the real server.
- **FR-038**: The app MUST record diagnostic events for remaining payment started/verified, cash
  confirmation started/confirmed, check-in/check-out confirmed, cancellation previewed/confirmed,
  claim answered, and offer answered, containing only identifiers and no personal data.
- **FR-039**: There MUST be no way to message the owner or collector directly anywhere in these
  flows (AC-047).

### Key Entities

- **Remaining Payment**: The amount left after the deposit with its due date, as reported by the
  server; paid online through a payment attempt or in cash through a cash confirmation.
- **Cash Confirmation**: A guest's confirmation that they handed cash to an authorized collector:
  collector display name, amount, status, a code challenge sent to the guest's email, and a
  receipt once confirmed.
- **Cash Receipt**: Proof shown to the guest after a confirmed cash payment: amount, collector,
  time, and reference.
- **Stay Acknowledgement**: A guest's or owner side's confirmation of handover (check-in) or
  return (check-out), with time; the stay status changes only when the server says both sides (or
  an authorized exception) are done.
- **Cancellation Preview**: The server's answer for "what happens if I cancel now": refundable
  amount, non-refundable amount, reason, and the policy snapshot it is based on.
- **Refund**: Money owed back to the guest with its stage (requested, approved, in progress,
  received), separate from the booking status.
- **Damage Claim**: An owner's claim on a booking: description, amount, evidence, status, the
  guest's answer (agree/dispute with reason), and outcome; disputes link to a support case.
- **Replacement Offer**: An alternative from OnAir after a rejection or expiry: offered apartment,
  dates, price difference, expiry, and the guest's answer.
- **Allowed Action**: A server-provided code for what the guest may do on a booking now; only
  delivered codes are displayed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A guest with a deposit-only booking can go from booking details to the payment page
  for the remaining amount in under 1 minute, and 90% of test participants complete it without
  help.
- **SC-002**: In 100% of tests, a deposit-only booking never offers "I received the apartment"
  until the server reports the remaining amount verified (AC-025).
- **SC-003**: In 100% of tests, a cash payment shows as paid only after the guest enters a correct
  email code, and a collector's record alone never marks it paid (AC-037).
- **SC-004**: In 100% of tests, "Stay in progress" and "Stay completed" appear only after the
  server reports both confirmations or an authorized exception (AC-026, AC-027).
- **SC-005**: In 100% of cancellation tests, the refund shown before confirming equals the refund
  the server applies, or the guest is shown the new amount and asked again.
- **SC-006**: In 100% of tests with double taps or retries after network errors, each action is
  applied exactly once.
- **SC-007**: In 100% of tests, a refund shows "Received" only after the server's final check
  (AC-042).
- **SC-008**: Every new screen passes visual review against the current app in light and dark
  modes, Arabic and English, at 1.3× text, and on narrow (320dp) and wide (tablet) widths, with no
  new colours, fonts, or corner sizes outside the design system.
- **SC-009**: For every notification type in FR-028, tapping it from a closed app opens the
  correct screen in 100% of tests, including when sign-in is needed first.
- **SC-010**: The guest-side parts of AC-025 to AC-038 and AC-042 pass end to end on Staging
  (Guest Plan §17 G3 exit criterion).

## Assumptions

- G0, G1, and G2 (features 001–003) and the UI refresh are delivered and merged into `develop`:
  booking details with allowed actions, the secure payment page and verification screen, the
  refund section and tracker, notifications and their routing, the 6-digit code field, and the
  shared design system components.
- The server owns every amount, deadline, status, allowed action, cancellation result, refund
  stage, collector authorization, and claim outcome (Constitution Principle II). The backend
  functions listed in Guest Plan §10.2 for G3 live in `onair-backend`; until they exist, the app
  runs on the mock with the same contract (Guest Plan §2.6). Contract additions found during
  planning are proposed to the backend owner, not built here.
- Cash confirmations always cover the full remaining amount reported by the server; partial cash
  payments are not supported (Clarification 2026-11-05).
- Cancellation reasons are a short fixed list (change of plans, found another place, travel
  problem, other) used for reporting only; they never affect the refund.
- The review screen is G5; G3 only shows the invitation when the server lists the action. Full
  support (case list, replies) is G4; G3 uses the existing "contact support" entry linked to the
  booking and shows the case number returned for a dispute.
- Owner-side handover, receipt, cash recording, and claims come from the Owner app; refund stages
  and replacement offers come from the Admin dashboard (Guest Plan §17 G3). Seeded or
  server-triggered changes are used for testing until those apps exist.
- Western digits stay in use until the numeral decision (Guest Plan §4.9) is made, as in earlier
  phases.
- Screenshots are a visual reference only (docs/design_reference/README.md); they do not
  authorize payment choices, VIP badges, or other features the product has not approved.
