# Feature Specification: Guest Booking & Payment (G2)

**Feature Branch**: `feature/003-guest-booking-payment`

**Created**: 2026-10-30

**Status**: Draft

**Input**: User description: "OnAir Guest App Plan.md" — the next open phase of the plan, G2 Booking
and Payment: choosing dates with a server quote, the booking summary, paying up front on the
Kashier page with a safe return and verification screen and all its edge cases, My Bookings with
booking details, timeline, and server-decided actions, showing the owner's acceptance, rejection,
or expiry with the full refund, and push notifications with an in-app notification center that
opens the right screen.

**Sources**: `docs/OnAir Guest App Plan.md` (§0.3, §1.1–§1.2, §2.7, §5.1–§5.3, §6.5–§6.8, §6.16,
§7, §8, §9, §10, §11.1–§11.5, §12.3, §13, §14.2, §15, §17 G2), `docs/OnAir Master Plan.md`
(decisions 100, 101, 104; AC-001, AC-007, AC-013 to AC-024, AC-042), `docs/UI_UX_DESIGN_SYSTEM.md`,
`.specify/memory/constitution.md`, `specs/001-guest-app-foundation/spec.md` (G0, delivered),
`specs/002-guest-discovery/spec.md` (G1, delivered).

## Clarifications

### Session 2026-10-30

- Q: Does G2 also include the 28 October sign-up rework (email + password + Egyptian phone +
  WhatsApp + one email code, removing phone/SMS sign-in), or does it stay a separate G0 item? →
  A: Separate item on its own branch, outside G2; G2 includes only the verify-before-booking step.
- Q: Where does a booking whose payment is not completed ("payment pending", e.g. failed or
  cancelled payment) appear in My Bookings? → A: Not as a card in any tab; only in an "unfinished
  payment" banner on Home and My Bookings, with its details opened from the banner or from a
  notification.
- Q: How does the G2 app handle server-allowed actions whose flows belong to later phases (pay
  remaining, cancel, check-in, etc. in G3)? → A: They are ignored entirely (not shown) until
  their phase is delivered; in G2 only "contact support" is shown.
- Q: Are arrival instructions (which may include a door code or key location) saved on the device
  for offline viewing, or shown only when online? → A: Saved only for confirmed bookings, in
  encrypted storage on the device, and removed at sign-out or when the booking ends or is
  cancelled.
- Q: If the guest declines notification permission after the first successful payment, what does
  the app do afterwards? → A: It never asks again; a small persistent notice "Notifications are
  off" with a button that opens the device settings appears in the notification center.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Request a booking and pay up front (Priority: P1)

A signed-in guest on an apartment page taps "Book now" (which accepts the terms shown on that
page), picks arrival and departure dates and the number of guests, and taps "Continue". The
server checks the dates and returns the price. The guest sees a summary: the apartment, the
dates and number of nights, the final nightly price, the total, the amount to pay now (deposit
or full amount), any remaining amount and when it is due, the saved terms and cancellation
policy, and a clear note that the request goes to the owner only after payment and is fully
refunded if the owner declines or does not answer within 24 hours. The guest taps "Go to
payment", pays on the Kashier page, and comes back to a verification screen that waits for the
server's answer and then shows the result.

**Why this priority**: This is the platform's core transaction (decisions 100 and 101). Without
it no booking, payment, or owner decision can happen.

**Independent Test**: On Staging (or the local mock) with a verified test guest and a seeded
apartment, go from "Book now" to the Kashier test page, pay with a test card, return, and
confirm the verification screen shows "Payment received and your request was sent to the owner"
only after the server confirms, with the owner's deadline shown.

**Acceptance Scenarios**:

1. **Given** a signed-in, verified guest on an apartment page, **When** they tap "Book now",
   **Then** the date step opens with the dates and guests already chosen on the page (if any),
   and the terms version that was on screen is kept as the accepted one (AC-013).
2. **Given** the date step, **When** it opens, **Then** days the server reports as unavailable
   are disabled, past days cannot be picked, departure must be after arrival, guests cannot
   exceed the apartment's maximum, and the number of nights updates as dates change.
3. **Given** valid dates and guests, **When** the guest taps "Continue", **Then** the app asks
   the server for a quote, and on success shows the summary with every amount exactly as the
   server returned it (AC-014).
4. **Given** the server rejects the quote because the dates are taken or the guest count is too
   high, **When** the answer arrives, **Then** the guest stays on the date step with a clear
   message, and the unavailable days are refreshed.
5. **Given** the summary, **When** the guest taps "Go to payment", **Then** the button is
   disabled at once with a loader, the request carries only the quote and the accepted terms
   (never an amount), and the Kashier page opens in a secure in-app browser with its address
   visible (AC-016).
6. **Given** the guest finishes or leaves the Kashier page, **When** they return to the app,
   **Then** the verification screen shows "Verifying your payment…" and the booking is not shown
   as paid until the server confirms (AC-015).
7. **Given** the server confirms payment and the dates were held, **When** the result arrives,
   **Then** the guest sees success, the owner's response deadline from the server, and a "View
   booking" button.
8. **Given** the server reports the payment failed or was cancelled, **When** the result
   arrives, **Then** the guest sees "The payment was not completed and nothing was charged" and
   a "Try again" button that starts a new payment attempt.
9. **Given** the server reports the payment succeeded but the dates were taken first, **When**
   the result arrives, **Then** the guest sees that the full amount will be refunded and a
   "Find other dates" button (AC-018).
10. **Given** no result arrives within the waiting period, **When** it ends, **Then** the guest
    sees "We have not received payment confirmation yet. Don't worry and don't pay again — we
    will notify you as soon as it is confirmed", with a "Go to My Bookings" button, and no "Pay
    again" button is shown anywhere while the booking is being verified.

---

### User Story 2 - Verify email and phone before the first booking (Priority: P1)

A guest whose email or phone is not yet confirmed taps "Book now". Instead of the date step,
they see a short verification step: they confirm their email and, if needed, add or confirm an
Egyptian phone number (with "This number has WhatsApp?" or an optional separate WhatsApp
number), using one 6-digit code sent to their email. After success they continue straight to the
date step with their apartment, dates, and guests unchanged.

**Why this priority**: The server refuses to start a payment until email and phone are confirmed
(AC-001). Without this step, unverified guests hit a dead end in the core flow.

**Independent Test**: With a test guest whose phone is not confirmed, tap "Book now", complete
the verification with the code from the test inbox, and confirm the date step opens for the same
apartment with the same dates.

**Acceptance Scenarios**:

1. **Given** a guest with an unconfirmed email or phone, **When** they tap "Book now", **Then**
   the verification step opens before the date step.
2. **Given** the verification step, **When** the guest enters a non-Egyptian number or a number
   already used by another account, **Then** the server's refusal is shown as a clear message
   next to the field.
3. **Given** the guest chose "This number has WhatsApp", **When** they try to also enter a
   separate WhatsApp number, **Then** that is not possible.
4. **Given** a correct code, **When** the guest submits it, **Then** they return automatically to
   the date step with their previous choices.
5. **Given** a wrong, expired, or too-frequently requested code, **When** the server refuses,
   **Then** the guest sees a clear message and, when rate-limited, the time to wait with the
   resend button disabled until then.
6. **Given** a guest whose confirmation was lost between steps, **When** the server refuses the
   payment start with "not verified", **Then** the verification step opens and the guest returns
   to the summary afterwards.

---

### User Story 3 - Follow my bookings (Priority: P1)

A signed-in guest opens the "My Bookings" tab and sees their bookings in three tabs — Current,
Past, and Cancelled — each card showing the apartment photo and name, dates, a status badge, and
a refund badge when there is a refund. Opening a booking shows one sentence explaining what is
happening now, the dates and guests, the payments, the refund progress, the address (and the
arrival instructions once confirmed), the terms saved at booking time, the timeline of events,
and only the actions the server allows.

**Why this priority**: After paying, guests need to see that their money and request are safe
and what happens next; this is the main post-payment trust surface (Master Plan 4.7).

**Independent Test**: With a test guest seeded with bookings in each status, open My Bookings,
check each tab's contents and order, open each booking, and compare the status message, amounts,
timeline, and actions to the server data.

**Acceptance Scenarios**:

1. **Given** a guest with bookings, **When** they open My Bookings, **Then** Current holds
   bookings being verified, awaiting the owner, confirmed, or checked in (nearest first); Past
   holds completed stays (newest first); Cancelled holds rejected, expired, cancelled, and
   no-show bookings (newest first).
2. **Given** a booking awaiting the owner, **When** it is shown, **Then** a countdown "The owner
   has until …" uses the deadline from the server, shown in Cairo time.
3. **Given** a tab with no bookings, **When** it is opened, **Then** it shows a clear empty
   message and a "Find an apartment" button.
4. **Given** a booking's details, **When** they open, **Then** the guest sees the booking number
   (copyable), status and refund badges, the status message for that status, arrival,
   departure, nights, guests, check-in and check-out times, total, amount paid and when, any
   remaining amount and its due date, the payment method, and the terms from the booking's saved
   copy — not the apartment's current terms.
5. **Given** a booking that is not yet confirmed, **When** its details are shown, **Then**
   arrival instructions are not shown; once confirmed, they are.
6. **Given** the server's list of allowed actions for a booking, **When** details are shown,
   **Then** only listed actions whose flows are delivered appear (in G2, "contact support"), and
   an action the server did not list never appears (AC-007).
7. **Given** the guest is offline, **When** they open My Bookings or a booking they viewed
   before, **Then** the last saved copy is shown with "Last updated …", and all actions are
   disabled until the connection returns.
8. **Given** a link or notification with a booking ID that is not the guest's or does not exist,
   **When** it is opened, **Then** a neutral "Not available" screen appears without revealing
   whether the booking exists.

---

### User Story 4 - Learn the owner's decision and the full refund (Priority: P2)

A guest waiting for the owner learns the outcome: confirmed, declined, or no answer within 24
hours. When declined, expired, or in a payment conflict, the booking clearly says the full
amount will be refunded and shows the refund's progress until the server confirms the money was
returned.

**Why this priority**: The full refund promise is what makes paying first acceptable to guests
(AC-019 to AC-021). It depends on Stories 1 and 3 existing.

**Independent Test**: Using seeded bookings (or server actions on Staging) move bookings to
confirmed, rejected, and expired, and confirm each booking's message, refund badge, and refund
stages match the server, and that "Refunded" appears only after the server's final check.

**Acceptance Scenarios**:

1. **Given** the owner accepts within 24 hours, **When** the guest opens the booking, **Then**
   it shows "Your booking is confirmed!" and, when there is a remaining amount, how much must be
   paid before check-in (AC-019).
2. **Given** the owner declines, **When** the guest opens the booking, **Then** it says the owner
   declined, that the full amount (shown) will be refunded, and that the OnAir team may contact
   them with an alternative (AC-020).
3. **Given** the 24 hours pass without an answer, **When** the guest opens the booking, **Then**
   it says the owner did not respond and that the full amount (shown) will be refunded (AC-021).
4. **Given** a booking with a refund, **When** its details are shown, **Then** the refund amount
   and its stages — requested, approved, in progress, verified received — are shown separately
   from the booking status, as reported by the server.
5. **Given** a refund in progress, **When** the server has not yet confirmed the final check,
   **Then** the booking never shows "Refunded" (AC-042).

---

### User Story 5 - Get notified and open the right screen (Priority: P2)

After the first successful payment, the app asks — once, with a clear reason — to allow
notifications so the guest knows as soon as the owner responds. Booking and payment updates
reach the guest as push notifications and in the in-app notification center. Tapping any of them
opens the related screen, after sign-in if needed. The bell on Home shows the unread count.

**Why this priority**: Owner decisions happen while the guest is away; notifications close that
loop (AC-024). The center is the source of truth, so the core flow still works without push.

**Independent Test**: On a device with the Staging build, complete a payment, allow
notifications, move the booking to confirmed on the server, and confirm a push arrives, opens the
correct booking from a closed app, and appears in the notification center, with the bell count
updated.

**Acceptance Scenarios**:

1. **Given** the guest's first successful payment result, **When** notification permission has
   not been decided, **Then** the app explains the benefit and asks for permission; if the guest
   declines, the app never asks again, and the notification center shows a small "Notifications
   are off" notice with a button that opens the device settings.
2. **Given** the app is open, **When** a notification arrives, **Then** an in-app banner appears
   and any open screen it concerns (such as the booking or the verification screen) refreshes.
3. **Given** the app is in the background or closed, **When** the guest taps a notification,
   **Then** the app opens the related screen (booking details for booking, payment, and refund
   events), signing in first if needed and then continuing to that screen.
4. **Given** the notification center, **When** it opens, **Then** notifications are listed
   newest first, unread ones are highlighted, more load as the guest scrolls, tapping one opens
   its screen and marks it read, and "Mark all as read" clears the unread state and the bell
   count.
5. **Given** a notification type the app does not recognize, **When** it is shown or tapped,
   **Then** it shows a general "You have a new update" text and opens My Bookings.
6. **Given** a push never arrived, **When** the guest opens the notification center, **Then** the
   update is there, since the center is the source of truth.

---

### User Story 6 - Recover an interrupted payment (Priority: P3)

A guest's payment is interrupted: the app was closed, the network dropped as they tapped "Go to
payment", they pressed back on the Kashier page, or the quote expired while they read the
summary. In every case the app brings them back to a safe, clear state without a double charge.

**Why this priority**: These cases are rare per guest but common across many guests, and a wrong
reaction risks double payment or lost trust (AC-023). The main flow works without them.

**Independent Test**: Reproduce each interruption on Staging or the mock and confirm one payment
session per attempt, the correct screen after each interruption, and no "Pay again" while
verifying.

**Acceptance Scenarios**:

1. **Given** the guest taps "Go to payment" twice quickly or retries after a network error,
   **When** the requests reach the server, **Then** they belong to the same attempt and lead to
   the same payment session — never a second charge (AC-023).
2. **Given** the guest leaves the Kashier page without the app reopening on its own, **When** the
   app returns to the foreground during an open payment attempt, **Then** it goes to the
   verification screen automatically.
3. **Given** the app was closed during payment, **When** the guest opens it again and the server
   reports an open payment attempt, **Then** a banner on Home and My Bookings leads to that
   attempt's status.
4. **Given** the quote expires while the summary is open, **When** the guest taps "Go to payment"
   or the expiry passes, **Then** the app requests a new quote automatically and, if anything
   changed, shows the change clearly and asks the guest to confirm before paying.
5. **Given** the apartment's terms changed after the guest accepted them, **When** the server
   refuses to start payment, **Then** the new terms are shown and the guest must accept them
   again before paying.
6. **Given** a late payment confirmation, **When** the waiting period ends, **Then** the booking
   stays "Verifying payment" in My Bookings and the guest is notified when it is confirmed.

---

### Edge Cases

- The apartment is unpublished between the details page and the quote or payment start: a clear
  "This apartment is no longer available" message with a way back to search (AC-003).
- The guest signs out or the session expires during the flow: the guest signs in again and
  returns to the same step with the same choices; an open payment attempt is still recovered.
- The return link from Kashier carries a status or ID that was tampered with: the app ignores it
  as a fact and only reads the booking status from the server.
- The return link carries a malformed ID: the app ignores it and shows the open attempt (if any)
  or My Bookings.
- Two devices of the same guest: notifications and bookings reflect the same server state on
  both; marking read on one is reflected on the other on next load.
- The server rate-limits payment starts or codes: the wait time is shown and buttons stay
  disabled until it ends.
- The device clock is wrong or in another time zone: deadlines and times are shown in Cairo time
  from server values; the countdown never extends the server's deadline.
- The countdown reaches zero while the screen is open: the booking refreshes from the server
  instead of changing its status locally.
- The guest declined notification permission at system level: the in-app center and bell still
  work, no repeated permission prompts appear, and the "Notifications are off" notice in the
  center lets the guest turn them on from the device settings.
- The guest arrives at the apartment with no connection: the arrival instructions of a confirmed
  booking are still shown from the encrypted copy on the device, with the "Last updated" note.
- A booking is cancelled or ends while the device is offline: its saved arrival instructions are
  removed on the next successful refresh.
- An unexpected server error: an understandable message with "Try again" and a reference number
  for support.
- Large text, dark mode, and right-to-left layout on every new screen do not break or clip
  amounts, dates, or buttons.

## Requirements *(mandatory)*

### Functional Requirements

**Pre-booking verification**

- **FR-001**: Before the date step, the app MUST check whether the guest's email and phone are
  confirmed and, if not, show the verification step; the server's "not verified" refusal at
  payment start MUST also lead to this step (AC-001).
- **FR-002**: The verification step MUST confirm the email and an Egyptian phone number with one
  6-digit code sent to the guest's email, let the guest mark "This number has WhatsApp" or add an
  optional separate WhatsApp number (not both), and show the server's refusals (non-Egyptian
  number, number already used, wrong or expired code, rate limit) as clear messages.
- **FR-003**: After successful verification, the app MUST return the guest to the step they came
  from with the same apartment, dates, guests, and accepted terms.

**Dates and quote**

- **FR-004**: The date step MUST disable days the server reports as unavailable, prevent past
  arrival dates, require departure after arrival, limit guests to the apartment's maximum, and
  show the number of nights as dates change. These checks are for convenience only.
- **FR-005**: "Continue" MUST request a quote from the server with the apartment, dates, guests,
  and accepted terms version, and MUST show the server's refusal reasons (dates unavailable,
  guests exceeded, apartment unavailable) on the date step.
- **FR-006**: "Book now" MUST record the terms version that was displayed as the accepted one
  and carry it through the quote and payment start (AC-013).

**Summary**

- **FR-007**: The summary MUST show the apartment (photo, name, area), dates and nights, final
  nightly price, total, amount due now, remaining amount and its due date (if any), the terms and
  cancellation policy summary, and the fixed notice that the request goes to the owner after
  payment and is fully refunded if declined or unanswered within 24 hours — every value as
  returned by the server.
- **FR-008**: The app MUST NOT compute, adjust, or send any price or amount; all amounts come from
  the server in Egyptian pounds and are displayed exactly (AC-016).
- **FR-009**: When the quote's validity time passes, the app MUST request a new quote before
  payment and, if any value changed, highlight the change and require the guest to confirm.

**Payment**

- **FR-010**: "Go to payment" MUST disable itself immediately until the server answers, send
  only the quote and the accepted terms with a single attempt key that stays the same for every
  retry of that attempt, and open the payment page in a secure in-app browser that shows its
  address (AC-023).
- **FR-011**: The app MUST NOT see, store, or log card details.
- **FR-012**: Returning from the payment page (by link or by the app coming back to the
  foreground during an open attempt) MUST open the verification screen, which shows "Verifying"
  until the server reports the result (AC-015).
- **FR-013**: The verification screen MUST update as soon as the server reports a result for the
  booking and, in case that update is missed, MUST also check with the server again at growing
  intervals for about two minutes. It MUST show one of four
  outcomes: success with the owner's deadline, failed/cancelled with "Try again", conflict with
  full refund and "Find other dates", or the not-yet-confirmed message with "Go to My Bookings".
- **FR-014**: The app MUST NOT offer any way to pay again while a booking is being verified.
- **FR-015**: "Try again" after a failed payment MUST start a new attempt with a new attempt key
  (using a fresh quote when the old one expired).
- **FR-016**: Values carried in the return link MUST be treated as navigation hints only; IDs
  MUST be checked for the correct format, and no status MUST change because of a link.
- **FR-017**: On app start, the app MUST ask the server for any open or unfinished payment of the
  guest and, if found, show an "unfinished payment" banner on Home and My Bookings that opens that
  booking's details (or the verification screen while the payment is still being verified).
- **FR-018**: When the server refuses payment start because the terms changed, the app MUST show
  the new terms and require the guest to accept them before trying again.

**My Bookings and booking details**

- **FR-019**: My Bookings MUST show Current, Past, and Cancelled tabs with the grouping and order
  in User Story 3, loading more bookings as the guest scrolls; which tab a booking belongs to is
  decided by the server. Bookings in "payment pending" MUST NOT appear as cards in any tab; they
  appear only through the unfinished-payment banner (FR-017) and through notifications that open
  their details.
- **FR-020**: Each booking card MUST show the apartment photo and name, dates, a status badge,
  and a refund badge when a refund exists; bookings awaiting the owner MUST show a countdown to
  the server's deadline.
- **FR-021**: Booking details MUST show the sections listed in User Story 3, scenario 4, the
  status message for the current status (Guest Plan §7.2), the refund section when one exists,
  the timeline of guest-visible events in order with times, and a "Need help? Contact OnAir" entry
  linked to the booking.
- **FR-022**: Arrival instructions MUST appear only for confirmed bookings and later stages; the
  address is shown as on the public apartment page.
- **FR-023**: Booking actions MUST come only from the server's list of allowed actions. Action
  codes whose flows are not delivered yet (or are unknown) MUST NOT be shown at all — not
  disabled, not as "coming soon"; in G2 the only action shown is "contact support". Each action
  appears automatically once its phase delivers it.
- **FR-024**: My Bookings and viewed booking details MUST be saved on the device for offline
  display with a "Last updated" note, with actions disabled while offline, and MUST be removed
  at sign-out.
- **FR-024a**: Arrival instructions MUST be saved for offline viewing only for confirmed bookings
  (and later stay stages), only in encrypted storage on the device (never with the regular
  booking cache), and MUST be removed at sign-out and as soon as the server reports the booking
  completed, cancelled, rejected, expired, or no-show.
- **FR-025**: Opening a booking by ID that the server refuses MUST show the neutral "Not
  available" screen.
- **FR-026**: The Home upcoming-booking card (from G1) MUST show the guest's nearest upcoming
  confirmed booking from real booking data and open its details.

**Owner decision and refund display**

- **FR-027**: Confirmed, rejected, expired, and payment-conflict bookings MUST show the messages in
  Guest Plan §7.2, including the full refund amount from the server for rejected, expired, and
  conflict cases.
- **FR-028**: The refund badge and stages MUST be shown separately from the booking status, and
  "Refunded" MUST appear only when the server reports the final check is done (AC-042).
- **FR-029**: Times and deadlines MUST be shown in Cairo time from server values; the app MUST
  NOT compute deadlines or change a status when a countdown ends, and MUST refresh from the
  server instead.

**Notifications**

- **FR-030**: The app MUST ask for notification permission at the first successful payment
  result (if not yet decided) with a short explanation, and MUST NOT ask on first launch. If the
  guest declines (in the app or at system level), the app MUST NOT ask again; instead the
  notification center MUST show a persistent "Notifications are off" notice with a button that
  opens the device's notification settings, hidden again once permission is granted.
- **FR-031**: The device MUST be registered for the guest's notifications when permission is
  granted and kept up to date when the device's notification address changes (unregistering at
  sign-out is delivered by G0).
- **FR-032**: A notification received while the app is open MUST show an in-app banner and
  refresh any open screen it concerns; tapping a notification from the background or a closed
  app MUST open its target screen per Guest Plan §9.3, after sign-in if needed.
- **FR-033**: The notification center MUST list the guest's notifications newest first with
  unread highlighting, load more on scroll, mark a notification read when opened, offer "Mark all
  as read", and show translated texts per notification type with a generic text for unknown
  types that opens My Bookings.
- **FR-034**: The Home bell MUST show the live unread count, updating when new notifications
  arrive or are read.
- **FR-035**: Notification payloads MUST be used only to know the type and target; all details
  MUST be fetched from the server for the signed-in guest.

**General**

- **FR-036**: Every new screen MUST provide loading (shaped skeleton), empty, error (with retry
  and a reference number for unexpected errors), offline, and success states, and in-progress
  actions MUST disable their button with an inline loader.
- **FR-037**: Server error codes MUST map to clear Arabic messages from the translation files;
  raw server text MUST NOT be shown.
- **FR-038**: All new texts MUST come from the translation files and every new screen MUST work
  in light and dark modes, right-to-left, and large text, with screen-reader labels for icon-only
  controls.
- **FR-039**: The app MUST record diagnostic events for payment started, return received,
  payment verified, and verification timed out, containing only identifiers and no personal
  data.
- **FR-040**: The whole flow MUST work against the local mock with the same data shapes as the
  server contract, so screens do not change when switching to the real server.
- **FR-041**: There MUST be no way to message the owner directly anywhere in this flow (AC-047).

### Key Entities

- **Accepted Terms Version**: The version of an apartment's terms the guest saw and accepted by
  tapping "Book now"; carried into the quote and payment start, and saved with the booking.
- **Booking Quote**: The server's priced answer for one apartment, dates, and guests: nights,
  nightly price, total, amount due now, remaining amount and due date, policy summary, terms
  version, and an expiry time.
- **Payment Attempt**: One try to pay a quote, identified by an attempt key the app keeps for all
  retries; leads to one payment page session and one booking.
- **Booking**: The guest's booking as reported by the server: number, apartment, dates, guests,
  status, owner response deadline, saved terms and policy, arrival instructions (after
  confirmation), allowed actions, payments, refund, and timeline.
- **Booking Status**: Server-defined stage: payment pending, verifying payment, awaiting owner,
  confirmed, checked in, completed, rejected, expired, cancelled, no-show, plus the
  payment-conflict scenario.
- **Allowed Action**: A server-provided code for something the guest may do on a booking now
  (e.g., contact support, pay remaining, cancel); only these are displayed.
- **Payment**: Money paid on a booking: amount, status, time, and method.
- **Refund**: Money owed back to the guest: amount and stage (requested, approved, in progress,
  verified), separate from the booking status.
- **Booking Event**: A guest-visible timeline entry with a time.
- **Notification**: A message for the guest with a type, parameters, target, time, and read
  state; the center is the source of truth.
- **Device Registration**: Links the guest's device to their notifications with platform and
  language.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A verified guest can go from "Book now" to the payment page in under 2 minutes in
  usability tests, and 90% of test participants complete a booking request on the first try
  without help.
- **SC-002**: In 100% of tested returns from the payment page without server confirmation, the
  booking stays "Verifying payment" and never shows as paid.
- **SC-003**: In 100% of tests with double taps or retries after network errors, exactly one
  payment session and at most one charge exist per attempt.
- **SC-004**: In 100% of test bookings, the amount charged equals the amount due now shown on the
  summary, and changing the app's request cannot change it.
- **SC-005**: When the server confirms while the verification screen is open, the guest sees the
  result within 10 seconds in 95% of attempts.
- **SC-006**: For every notification type in Guest Plan §9.3 that targets a booking, tapping it
  from a closed app opens the correct booking in 100% of tests, including when sign-in is needed
  first.
- **SC-007**: In 100% of tests, opening another guest's booking by link or by an edited request
  shows "Not available" and reveals nothing about it.
- **SC-008**: My Bookings shows the last saved bookings within 1 second when opened offline.
- **SC-009**: The guest-side parts of AC-001, AC-007, AC-013 to AC-021, AC-023, AC-024, and
  AC-042 pass end to end on Staging (Guest Plan §17 G2 exit criterion).
- **SC-010**: Support requests asking "Did my payment go through?" stay below 5% of bookings
  during the pilot.

## Assumptions

- G0 (feature 001) and G1 (feature 002) are delivered: navigation shell, sign-in, return to the
  same point after sign-in, link handling with a configurable domain, design system, error
  handling, Money and Cairo-time formatting, the local mock, device unregistering at sign-out,
  and "Book now" carrying the shown terms version, dates, and guests.
- The 28 October 2026 sign-up rework (email, password, Egyptian phone, WhatsApp, one email code;
  removing phone/SMS sign-in) is a separate item on its own branch, outside G2 (Clarification
  2026-10-30). G2's verification step follows that decision for any account whose email or phone
  is not confirmed, so it works both before and after the rework lands; changing the sign-up and
  sign-in screens is not part of G2.
- The server owns every price, amount, status, deadline, tab grouping, allowed action, and refund
  stage (Constitution Principle II). Backend functions, the payment webhook, the atomic date hold,
  and the 24-hour timeout live in `onair-backend`; until they exist, the app runs on the mock with
  the same contract (Guest Plan §2.6).
- Kashier account details (return link format, in-app browser support, available wallets, test
  environment) are still open (Guest Plan §19.1). The flow is built and tested on the mock and
  verified on Staging once the test account exists.
- The link domain for the payment return and notification links is still open (Guest Plan
  §19.2); the configurable domain from G0 is used. If the payment page cannot return by link,
  the app's return to the foreground still leads to the verification screen.
- The waiting period on the verification screen is about two minutes with growing intervals
  (Guest Plan §8.4, proposed); the exact timing can change without changing the experience.
- In G2 the only action the app acts on is "contact support", which opens the support entry point
  linked to the booking (full support is G4). Pay remaining, cash confirmation, cancellation,
  check-in, check-out, damage claims, and replacement offers belong to G3; reviews belong to G5.
  Their codes are not shown until those phases deliver them (Clarification 2026-10-30).
- Replacement offers from OnAir after a rejection or expiry are answered in G3; G2 only shows the
  rejection or expiry message that mentions the team may suggest an alternative.
- Notification preferences in settings belong to G4. Booking and payment notifications are
  mandatory and cannot be switched off.
- Push texts carry no sensitive data; the server writes them and the app only displays them.
- The owner's acceptance or rejection depends on the Owner app, and recording a phone decision
  depends on the Admin dashboard (Guest Plan §17 G2); seeded or server-triggered status changes
  are used for testing until they exist.
- Western digits stay in use until the numeral decision (Guest Plan §4.9) is made, as in G0 and
  G1.
