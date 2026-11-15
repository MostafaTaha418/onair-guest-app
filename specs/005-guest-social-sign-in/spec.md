# Feature Specification: Guest Sign-in with Google / Apple + Mandatory Phone Confirmed on WhatsApp (S005)

**Feature Branch**: `feature/005-guest-social-sign-in`

**Created**: 2026-11-12 · **Updated**: 2026-11-13 (phone confirmed by WhatsApp code; resend ladder and
anti-spam block; same step for email registration)

**Status**: Draft

**Input**: User description: "Spec 005 — الدخول بـ Google / Apple مع رقم هاتف إجباري يتأكد بكود
(guest-social-sign-in). المرجع: docs/OnAir Guest App Plan.md الأقسام 6.2.6–6.2.9 و17 (S005)، والقرار
docs/decisions/D-002-social-sign-in-phone-gate.md." — update 2026-11-13: "تأكيد رقم الهاتف عن طريق otp
باستخدام خدمة واتساب بيزنس الرسمية من ميتا بحيث يتم توليد الرمز في الباك اند وارسالة عبر واتساب بيزنس
والمستخدم يأكده من واتساب ... لا يتم ارسال رمز اخر الا بعد 30 ثانية ثم 5 دقائق ثم ساعة ثم 24 ساعة ...
واذا تخطى عدد ارسال 10 مرات ... حظر لمدة اسبوع ... وحتى لو مسح التطبيق وثبته تاني برضو يفضل واخد حظر".

In short: a guest can sign in or register with one tap using Google or Apple. Every new account
(Google/Apple, or email + password after the email is confirmed) must then enter an Egyptian mobile
number and confirm it with a 6-digit code that the backend generates and sends to that number on
WhatsApp through Meta's official WhatsApp Business service. Without the correct code the number is
never saved and the account is not registered. Code resends follow a growing wait ladder, and more
than 10 sends block code sending for 7 days in a way that survives reinstalling the app.

**Sources**: `docs/OnAir Guest App Plan.md` (§1.1, §1.3, §2.2, §2.3, §2.7.3, §5.2, §5.3,
§6.2.1–§6.2.9, §6.18, §10.2–§10.3, §11.1, §11.8, §13, §14.2 S005-1…S005-8, §17 S005, §19 items
10–15, §20), `docs/decisions/D-002-social-sign-in-phone-gate.md`, `docs/OnAir Master Plan.md`
(§2.2, §2.3, §16.1; AC-001), `DESIGN.md`, `docs/design_reference/README.md` and its screenshots,
`docs/UI_UX_DESIGN_SYSTEM.md`, `.specify/memory/constitution.md`,
`specs/001-guest-app-foundation/spec.md` (existing email + password sign-in, delivered).

## Clarifications

### Session 2026-11-13

- Q: What does a guest whose number is not on WhatsApp (and who has no other WhatsApp number) do
  to finish registering? → A: No alternative; they must use a number that is on WhatsApp. The app
  says so clearly and offers «كلّم الدعم».
- Q: Must existing guests whose phone was confirmed earlier by email code re-confirm it on
  WhatsApp? → A: No. They stay as they are; WhatsApp applies only when they change the number.
- Q: What happens when someone signs in with Google/Apple using the email of an email + password
  registration whose email was never confirmed? → A: Every sign-in method needs a confirmed email,
  and Google/Apple emails are already confirmed, so the provider sign-in wins: the unconfirmed
  registration is discarded (its password removed) and the guest continues as a Google/Apple
  account to «أكّد رقمك». No one gets in without a confirmed phone.
- Q: Does «المتابعة بـ Apple» also appear on Android in this release? → A: No, iOS only; Android
  shows Google only.
- Q: When do the WhatsApp send counter and resend ladder start over for a guest who is not blocked?
  → A: After a successful confirmation, after a block ends, or after 7 days with no send request.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign in or register with Google (Priority: P1)

A guest on the sign-in or create-account screen sees, under the email and password fields, an
«أو» divider and a «المتابعة بـ Google» button. They tap it, pick their Google account in the
system sheet, and are signed in without typing anything. If the account is new (or never finished
registering) they go straight to «أكّد رقمك» (User Story 3). If the account is complete they land
back exactly where they were before signing in (the same apartment and selected dates, for example).

**Why this priority**: Google works on Android and iOS and is the fastest way for most guests to
get an account. It is the core value of this feature.

**Independent Test**: With the mock backend, tap «المتابعة بـ Google» from the sign-in screen opened
by «احجز الآن» on an apartment, choose a test account that is already complete, and confirm the
guest returns to the same apartment, signed in, without seeing any email or password field.

**Acceptance Scenarios**:

1. **Given** the sign-in or create-account screen, **When** it opens, **Then** under the email form
   there is an «أو» divider and a «المتابعة بـ Google» button that follows Google's official button
   style (logo and wording) in light and dark mode, with a touch target of at least 48 high.
2. **Given** the guest taps «المتابعة بـ Google», **When** the request is in flight, **Then** the
   tapped button shows an inline loader, all sign-in buttons are disabled, and further taps send
   nothing.
3. **Given** a Google account that has never used OnAir, **When** sign-in succeeds, **Then** the
   guest goes directly to «أكّد رقمك» and cannot reach any account-only screen before finishing it.
4. **Given** a Google account whose OnAir account is complete, **When** sign-in succeeds, **Then**
   the guest returns to the screen and context that sent them to sign-in (or Home).
5. **Given** the guest closes or cancels the Google sheet, **When** they return to the app, **Then**
   they stay on the same screen with the buttons enabled again and **no error message**.
6. **Given** no connection or a rejected sign-in, **When** the attempt fails, **Then** a clear Arabic
   message is shown without technical details and the guest can try again.

---

### User Story 2 - Sign in or register with Apple on iOS (Priority: P1)

On an iPhone the guest also sees «المتابعة بـ Apple». The flow is the same as User Story 1. Apple may
share the guest's real email or a private relay address, and shares the name only the first time.

**Why this priority**: Apple requires apps that offer third-party sign-in on iOS to also offer Sign
in with Apple, so the iOS release depends on it.

**Independent Test**: On an iOS build with the mock backend, sign in with Apple as a new user who
chose "Hide My Email" and did not share a name; confirm «أكّد رقمك» asks for the name and shows the
relay email as the account email.

**Acceptance Scenarios**:

1. **Given** the app runs on iOS, **When** the sign-in or create-account screen opens, **Then** a
   «المتابعة بـ Apple» button following Apple's official style is shown with the Google button.
2. **Given** the app runs on Android, **When** the same screens open, **Then** only the Google
   button is shown in this release.
3. **Given** a new Apple user who shared their name, **When** «أكّد رقمك» opens, **Then** the name
   is pre-filled and editable; **given** no name was shared (or Apple no longer sends it), **Then**
   the name field is empty and required.
4. **Given** an Apple user who hid their email, **When** «أكّد رقمك» opens, **Then** the relay
   address is shown as the account email.
5. **Given** the guest cancels the Apple sheet, **When** they return, **Then** nothing changes and no
   error is shown.

---

### User Story 3 - Mandatory «أكّد رقمك» step (Priority: P1)

Right after a first Google/Apple sign-in (or right after a new email account confirms its email),
the guest sees «أكّد رقمك»: their account email (read only), an Egyptian mobile number field with
the hint «هنبعتلك كود على واتساب الرقم ده», and — only if missing — their name and agreement to the
Terms and Privacy Policy. There is no "skip" or "later". Until the number is confirmed (User Story 4)
the account is incomplete: the guest can still browse Home, Search and apartment details like a
visitor, but any account-only screen or action brings them back here. Leaving the step signs them
out.

**Why this priority**: Every OnAir guest account must have a confirmed Egyptian phone number
(AC-001, D-002).

**Independent Test**: Sign in with a new mock Google account, then try to open Favorites, My
Bookings, Notifications, Account, «احجز الآن», and a booking deep link; confirm each leads back to
«أكّد رقمك». Tap back, confirm the sign-out dialog, and confirm the guest is a visitor again on the
screen they came from.

**Acceptance Scenarios**:

1. **Given** a signed-in incomplete account, **When** the guest opens any account-only screen or
   action (booking, favorites, My Bookings, notifications, support, account, or a deep link to any
   of them), **Then** they are taken to «أكّد رقمك», and after completing it they continue to the
   place they were trying to reach.
2. **Given** an incomplete account, **When** the guest opens Home, Search, apartment details, the
   gallery, reviews or the FAQ, **Then** these work as for a visitor.
3. **Given** the number field, **When** the guest types, **Then** it is checked locally as an
   Egyptian mobile number (+20); a non-Egyptian or malformed number shows a field error saying only
   Egyptian numbers are supported for now, and «متابعة» stays disabled until the form is valid.
4. **Given** the account already has a name and accepted Terms (email registration), **When** the
   step opens, **Then** only the number is asked for.
5. **Given** the guest taps back or «إلغاء», **When** the dialog «لو خرجت، التسجيل مش هيكمل» is
   confirmed, **Then** the guest is signed out and returns as a visitor to where they were; if they
   dismiss the dialog they stay with their entries intact.
6. **Given** the guest closes the app on this step (or on the code step), **When** they open it
   again, **Then** they are still signed in, land on «أكّد رقمك» from the start, and no number is
   pre-filled — but any resend wait or block still applies (User Story 5).
7. **Given** the server answers any action from an incomplete account with "profile incomplete" or
   "phone not verified", **When** the app receives it, **Then** it routes the guest to «أكّد رقمك»
   instead of showing a generic error.

---

### User Story 4 - Confirm the number with a WhatsApp code (Priority: P1)

After «متابعة», the server checks the number, generates a 6-digit code and sends it to that number on
WhatsApp from OnAir's official WhatsApp Business account. The guest sees «بعتنا كود على واتساب
{الرقم}» with an «افتح واتساب» button, opens the message, taps its «نسخ الكود» button, comes back and
pastes the code. On success the number (and the name/Terms if they were asked) is saved and the
account becomes complete. If the correct code is never entered, the number is not stored on the
account at all.

**Why this priority**: Confirming the number on the number itself is the only real proof the guest
owns it, and it is the condition for the account to exist (AC-001, D-002).

**Independent Test**: With the mock backend, submit a number, enter a wrong code, then close the app;
reopen and confirm the account is still incomplete with no phone. Repeat with the correct code and
confirm the phone shows as confirmed and the guest continues to where they were going.

**Acceptance Scenarios**:

1. **Given** a valid form, **When** the guest taps «متابعة», **Then** the button disables at once
   with an inline loader, one request is sent, and on success the code screen opens showing the
   number the code was sent to and when a new code can be requested.
2. **Given** the number is used by another account, **When** the server rejects it, **Then** the
   guest stays on the form with a field error that the number is already used and no code is sent.
3. **Given** the Terms changed between showing and sending, **When** the server rejects it, **Then**
   the latest Terms are shown and the guest must agree again.
4. **Given** the code screen, **When** it opens, **Then** it supports 6 digits, paste and
   one-time-code autofill, offers «افتح واتساب» and «تعديل الرقم» (back to the form with the
   previous entries), and shows the resend countdown given by the server.
5. **Given** WhatsApp reports that the message could not be delivered because the number is not on
   WhatsApp, **When** the code screen learns it (within about a minute), **Then** it shows «الرقم ده
   مش عليه واتساب. استخدم رقم عليه واتساب» with «تعديل الرقم».
6. **Given** a wrong or expired code, **When** the guest submits it, **Then** a clear message is shown
   and the account stays incomplete with no phone stored; after 5 wrong attempts the code stops
   working and the guest must request a new one.
7. **Given** the correct code, **When** it is accepted, **Then** the number (marked as the guest's
   WhatsApp number), its confirmation time, and the name/Terms if asked are saved at once, the
   account is complete, a short welcome message shows, and the guest continues where they were
   going.
8. **Given** another account confirmed the same number between sending and confirming, **When** the
   guest submits the correct code, **Then** it is rejected as "number already used", nothing is
   saved, and the guest returns to the form.
9. **Given** any button in this flow, **When** the guest double-taps it, **Then** only one request is
   sent.

---

### User Story 5 - Resend ladder and anti-spam block (Priority: P1)

If the code does not arrive, the guest can ask for a new one, but only after a waiting time that
grows: 30 seconds after the first send, 5 minutes after the second, 1 hour after the third, 24 hours
after the fourth, then alternating 1 hour and 24 hours. After 10 sends, any further request blocks
code sending for 7 days. The block follows the account, the phone number and the device, so it is
not lifted by reinstalling the app, creating a new Google account on the same phone, or trying the
same number from another phone.

**Why this priority**: Each WhatsApp message costs money and an unprotected code endpoint is a
classic abuse target (flooding someone's number, draining the messaging budget). The owner set
these exact limits.

**Independent Test**: In mock mode, request codes repeatedly and confirm each countdown matches the
ladder; request an 11th time and confirm the 7-day block message with its end date; reinstall the
app (or sign in with another mock Google account on the same device) and confirm the block is still
shown.

**Acceptance Scenarios**:

1. **Given** a code was just sent, **When** the guest looks at «إعادة الإرسال», **Then** it is
   disabled with a countdown to the time the server allows: 30 s after send 1, 5 min after send 2,
   1 h after send 3, 24 h after send 4, then 1 h and 24 h alternately (after sends 5, 6, 7, 8, 9).
2. **Given** a wait of an hour or more, **When** the countdown shows, **Then** it reads in plain
   Arabic hours/minutes (e.g., «تقدر تطلب كود جديد بعد ساعة») and the guest may leave and return;
   the countdown resumes from the server's time, not from the device clock alone.
3. **Given** 10 codes have been sent, **When** the guest (or anyone using the same account, number
   or device) requests another one, **Then** no code is sent and the screen shows «اتوقف إرسال
   الأكواد مؤقتًا لحد {التاريخ}. لو محتاج مساعدة كلّم الدعم» with the block end time in Cairo time,
   and all send buttons stay disabled until then.
4. **Given** a blocked device, **When** the app is deleted and reinstalled, or a different Google/
   Apple account is used on it, **Then** the block still applies.
5. **Given** a blocked phone number, **When** someone tries to confirm it from another account or
   device, **Then** the block still applies to that number.
6. **Given** a request that does not come from a genuine, unmodified OnAir app, **When** it asks to
   send a code, **Then** it is rejected and no WhatsApp message is sent.
7. **Given** a number is confirmed successfully, the 7-day block ends, or 7 days pass with no send
   request, **When** the guest needs a code again later (e.g., to change the number), **Then** the
   ladder starts again from the beginning.
8. **Given** a request is sent before the allowed time (e.g., from a modified client), **When** the
   server receives it, **Then** it is rejected with the time it will be allowed and nothing is sent.

---

### User Story 6 - Email registration and phone change use the same WhatsApp step (Priority: P2)

A guest who registers with email + password now fills in only name, email, password and Terms,
confirms the email with the email code as today, and then goes to the same «أكّد رقمك» step. The
«الرقم ده عليه واتساب؟» switch and the separate WhatsApp number are removed. Changing the phone
number later from the account sends the code to the new number on WhatsApp with the same ladder and
block rules; the old number keeps working until the new one is confirmed.

**Why this priority**: One consistent, trustworthy way to confirm a phone across the app. Existing
email registration keeps working until this lands, so it can follow the P1 stories.

**Independent Test**: Register a new mock email account, confirm the email code, and confirm the app
goes to «أكّد رقمك» asking only for the number; finish with the WhatsApp code. Then change the number
from the account and confirm the code goes to the new number on WhatsApp.

**Acceptance Scenarios**:

1. **Given** the create-account screen, **When** it opens, **Then** it asks for name, email,
   password and Terms only — no phone, no WhatsApp question.
2. **Given** a new email account confirmed its email, **When** the email code is accepted, **Then**
   the guest goes to «أكّد رقمك» (number only) and the account stays incomplete until the WhatsApp
   code is confirmed.
3. **Given** an existing account whose phone was confirmed earlier by email code, **When** the guest
   signs in, **Then** nothing changes and no re-confirmation is asked.
4. **Given** the guest changes their number from the account, **When** they submit the new number,
   **Then** the code goes to the new number on WhatsApp under the same ladder and block rules, and
   the old number stays on the account until the new code is confirmed.

---

### User Story 7 - One personal account across sign-in methods (Priority: P2)

A guest who already has a complete email + password account later taps «المتابعة بـ Google» with the
same email. They land in their existing account with its phone, bookings and favorites.

**Why this priority**: The Master Plan requires one personal account per person (§2.2).

**Independent Test**: With a mock complete email account, sign in with Google using the same email
and confirm the existing bookings and phone appear and no «أكّد رقمك» step is shown.

**Acceptance Scenarios**:

1. **Given** an existing complete account whose email is confirmed, **When** the guest signs in with
   Google or Apple using the same email, **Then** they enter that same account directly.
2. **Given** an email + password registration whose email was **never confirmed**, **When** someone
   signs in with Google or Apple using the same email, **Then** the provider sign-in succeeds, the
   unconfirmed registration is discarded (its password no longer works), no second account exists,
   and the guest continues to «أكّد رقمك».
3. **Given** the forgot-password flow, **When** a guest enters the email of an account that has no
   password, **Then** the same neutral message as for any email is shown.

---

### User Story 8 - Account screen for Google / Apple users (Priority: P3)

In «البيانات الشخصية» a Google/Apple user sees how they sign in next to their email; «تغيير كلمة
المرور» is hidden for accounts without a password; signing out also clears the Google account choice.

**Why this priority**: Avoids confusing actions but does not block registration or booking.

**Independent Test**: Sign in with a complete mock Google account, open profile and security
screens, confirm the sign-in method is shown and «تغيير كلمة المرور» is hidden; sign out and confirm
the next Google sign-in shows the account picker.

**Acceptance Scenarios**:

1. **Given** a complete account, **When** the guest opens «البيانات الشخصية», **Then** they see the
   sign-in method (Google / Apple / البريد), email, and the confirmed phone (which is also the
   WhatsApp number).
2. **Given** an account with no password, **When** the guest opens security settings, **Then**
   «تغيير كلمة المرور» is not shown.
3. **Given** the guest signs out, **When** sign-out finishes, **Then** the usual sign-out cleanup
   happens and the next Google sign-in shows the account picker.

### Edge Cases

- The WhatsApp message arrives late, after the guest already asked for a resend: only the **latest**
  code is valid; earlier codes stop working once a new one is sent, and the code screen says
  «استخدم آخر كود وصلك».
- The guest edits the number after a code was sent: the old code no longer works, the new number
  gets a new code, and the ladder continues (the step count is per account, number and device, so
  changing the number does not reset it).
- The device clock is wrong: countdowns and block dates come from the server's times.
- The guest is offline when tapping «متابعة» or «إعادة الإرسال»: the offline message is shown and
  nothing is counted as a send.
- WhatsApp delivery status never arrives: the code screen keeps the normal resend option once the
  wait ends; no false "not on WhatsApp" message is shown.
- A failed delivery (number not on WhatsApp) still counts as a send, so the service cannot be used to
  probe which numbers exist.
- The guest started «احجز الآن» with selected dates as a visitor, signed in with Google as a new
  user, and confirmed the number: they return to the same apartment with the same dates.
- An incomplete account is never completed: the server removes it after a retention period, but the
  send counters and any block on the number and device remain until they expire.
- Support lifts a block manually: the next request is allowed immediately and the ladder restarts.
- A guest who registered with Apple on an iPhone later uses an Android phone (no Apple button): they
  can sign in with Google if it uses the same confirmed email, or use «نسيت كلمة المرور» to receive
  an email code (Apple's relay forwards it) and set a password for the same account.
- Large text, narrow and wide screens, the on-screen keyboard, light and dark mode, Arabic RTL and
  English LTR all keep the buttons, form, countdown and block message fully usable.

## Requirements *(mandatory)*

### Functional Requirements

**Sign-in with Google / Apple**

- **FR-001**: The sign-in and create-account screens MUST offer «المتابعة بـ Google» on Android and
  iOS, and «المتابعة بـ Apple» on iOS only, under an «أو» divider below the email + password form.
- **FR-002**: The social buttons MUST follow Google's and Apple's official sign-in button guidelines
  while fitting the OnAir auth screens' layout, spacing and typography.
- **FR-003**: Signing in with Google or Apple MUST NOT ask for an email or a password.
- **FR-004**: The app MUST use the platform's native Google/Apple sign-in sheet (not an embedded web
  page) and MUST NOT store, display or log the provider's identity token.
- **FR-005**: Cancelling the provider sheet MUST return the guest to the same screen with no error.
- **FR-006**: A failed sign-in MUST show a short localized message with no technical details and
  allow retrying.
- **FR-007**: While a sign-in request is in flight, all sign-in actions MUST be disabled, the tapped
  button MUST show an inline loader, and repeated taps MUST NOT start a second request.
- **FR-008**: After a successful sign-in to a complete account, the guest MUST return to the screen
  and context that sent them to sign-in.

**Mandatory «أكّد رقمك» step**

- **FR-009**: Every new account (Google/Apple, or email + password after its email is confirmed)
  MUST be **incomplete** until a phone number is confirmed by WhatsApp code; there MUST be no way to
  skip or postpone it.
- **FR-010**: The app MUST open «أكّد رقمك» immediately after sign-in to an incomplete account and
  after a new email account confirms its email.
- **FR-011**: While the account is incomplete, every account-only screen, action and deep link MUST
  lead to «أكّد رقمك»; after completion the guest MUST continue to the requested destination.
  Visitor screens (Home, Search, results, apartment details, gallery, reviews, FAQ) MUST keep
  working.
- **FR-012**: «أكّد رقمك» MUST show the account email (read only) and ask for an Egyptian mobile
  number (required) with the hint that the code will be sent on WhatsApp; it MUST ask for the name
  (2–80 characters, pre-filled from the provider when available) and Terms/Privacy agreement only
  when the account does not have them yet.
- **FR-013**: The form MUST validate locally (name length, Egyptian number format), show field errors
  as text announced by screen readers, and keep «متابعة» disabled until valid. The server decides.
- **FR-014**: Leaving «أكّد رقمك» MUST ask for confirmation and, if confirmed, sign the guest out and
  return them as a visitor to where they were.
- **FR-015**: The app MUST NOT keep the entered number in any local storage or cache.

**WhatsApp code**

- **FR-016**: The 6-digit code MUST be generated by the backend, stored only in a non-reversible
  form, and sent to the entered number on WhatsApp through Meta's official WhatsApp Business service
  using an approved authentication message in the guest's language with a «نسخ الكود» button and a
  "do not share this code" notice. The app never generates or receives the code itself.
- **FR-017**: Before sending, the server MUST check that the account is incomplete (or is changing
  its number), the number is Egyptian and not used by another account, the Terms version is current
  when sent, and that the resend and block rules (FR-024–FR-031) allow a send.
- **FR-018**: A code MUST be valid for 10 minutes and allow 5 wrong attempts; after that, or once a
  newer code is sent, it MUST stop working.
- **FR-019**: The code screen MUST show the number the code was sent to, «افتح واتساب», «تعديل الرقم»,
  paste and one-time-code autofill, and the resend countdown from the server's next-allowed time.
- **FR-020**: The app MUST show «الرقم ده مش عليه واتساب. استخدم رقم عليه واتساب» with «تعديل
  الرقم» and «كلّم الدعم» when the server reports the message could not be delivered for that
  reason, checking the delivery status for about one minute after sending. There is no other way to
  confirm a number (no manual, voice, SMS or email alternative).
- **FR-021**: Only a correct, unexpired, latest code MUST save the number (marked as the WhatsApp
  number), its confirmation time, and the name/Terms if asked, all at once, and mark the account
  complete.
- **FR-022**: Before the correct code, the number MUST NOT be stored on the guest's account in any
  form; a wrong, expired or abandoned code MUST leave the account incomplete with no phone.
- **FR-023**: The server MUST check that the number is not used by another account both when sending
  and when confirming; if it became used in between, nothing is saved.

**Resend ladder and anti-spam**

- **FR-024**: The minimum wait before the next send MUST be: 30 seconds after send 1, 5 minutes
  after send 2, 1 hour after send 3, 24 hours after send 4, then 1 hour and 24 hours alternately
  after sends 5–9. These values MUST be server settings, not app constants.
- **FR-025**: After 10 sends, any further send request MUST be refused and MUST start a 7-day block
  on code sending; the server returns the block end time.
- **FR-026**: Send counts, waits and blocks MUST be tracked on three keys at once — the account, the
  phone number, and the device — and the strictest one applies to every request.
- **FR-027**: The device key MUST survive deleting and reinstalling the app and switching accounts on
  the same device, and MUST be stored by the server only in a non-reversible form and used only for
  abuse prevention.
- **FR-028**: Code-send requests MUST be accepted only from genuine, unmodified OnAir app installs;
  other requests MUST be refused without sending.
- **FR-029**: The platform MUST have a per-network-address request limit on code sending and a global
  daily cap on WhatsApp code messages that pauses sending and alerts the admins when reached.
- **FR-030**: Failed deliveries MUST count as sends.
- **FR-031**: Counters and the ladder MUST reset only after a successful confirmation, after a block
  ends, or after 7 consecutive days without any send request (no daily reset); blocks MUST be recorded for admins, who can lift one
  manually with a written reason.
- **FR-032**: The app MUST display only the server's next-allowed and block-end times (in Cairo time
  for dates, plain Arabic durations for waits) and MUST disable send buttons until then.

**Email registration and phone change**

- **FR-033**: The email create-account form MUST ask only for name, email, password and Terms; the
  «الرقم ده عليه واتساب؟» question and separate WhatsApp number MUST be removed from the app.
- **FR-034**: After a new email account confirms its email, the guest MUST go through «أكّد رقمك»
  (number only).
- **FR-035**: Accounts whose phone was confirmed before this feature (by email code) MUST NOT be
  asked to confirm again, at sign-in or before booking; they use the WhatsApp code only if they
  change the number later.
- **FR-036**: Changing the phone number from the account MUST send the code to the new number on
  WhatsApp under FR-016–FR-032; the old number MUST stay until the new one is confirmed.

**Server enforcement**

- **FR-037**: The server MUST reject every account action from an incomplete account (other than
  confirming the number, signing out and deleting the account) with "profile incomplete", and booking
  quotes and payment starts without a confirmed phone with "phone not verified". The app MUST route
  both to «أكّد رقمك».
- **FR-038**: Incomplete accounts that are never completed MUST be removed by the server after the
  retention period in Assumptions, without removing send counters or blocks.

**One account per person**

- **FR-039**: Google/Apple sign-in with the email of an existing account whose email is confirmed MUST
  open that same account.
- **FR-040**: Every sign-in method MUST require a confirmed email (Google/Apple emails count as
  confirmed by the provider). Google/Apple sign-in with the email of an email + password
  registration whose email was never confirmed MUST take over that email: the unconfirmed
  registration and its password are discarded, no second account is created, and the guest
  continues to «أكّد رقمك».
- **FR-041**: Password recovery for an account without a password MUST show the same neutral message
  as for any email and work the same way (email code, then a new password), so a Google/Apple guest
  can add a password to the same account.

**Account screens**

- **FR-042**: «البيانات الشخصية» MUST show the sign-in method (Google, Apple or email).
- **FR-043**: «تغيير كلمة المرور» MUST be hidden for accounts without a password.
- **FR-044**: Sign-out MUST also clear the Google account choice on the device.

**Quality**

- **FR-045**: All new and changed screens MUST follow `DESIGN.md`, `docs/design_reference/` and the
  design system; work in light and dark mode, Arabic RTL and English LTR, narrow and wide screens, the
  maximum supported text size and with the keyboard open; have semantic labels and logical focus
  order; and implement loading, error and offline states.
- **FR-046**: All new strings MUST be localized (Arabic and English); no raw provider or server text
  is shown.
- **FR-047**: Every flow MUST work fully in mock mode with the same contract shape as the real
  backend, including: new/returning-incomplete/complete accounts, cancelled sheet, number used,
  number not on WhatsApp, wrong/expired code, the full resend ladder, the 7-day block, a rejected
  (non-genuine) request, and the unconfirmed-email collision.

### Key Entities

- **Guest account**: the person's single OnAir account — email, name, status (**incomplete** /
  **active**, plus existing suspended/deleted), sign-in methods (email + password, Google, Apple),
  whether it has a password, phone number (also the WhatsApp number) with confirmation time,
  accepted Terms version, language. An incomplete account has no phone.
- **Phone confirmation request**: short-lived; holds the number (and name/Terms if asked), the
  channel (WhatsApp), the code in non-reversible form, attempts, expiry, the WhatsApp message
  reference and its delivery status. Its data is written to the account only on the correct code.
- **Send limit record**: one per key (account, phone number, device — numbers and devices stored in
  non-reversible form); holds sends in the current cycle, ladder step, next allowed send time, block
  end time and last send time.
- **Sign-in identity**: links the account to Google, Apple or email + password; identities with the
  same confirmed email belong to the same account.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A returning guest with a complete Google/Apple account signs in with no typing in at
  most 2 taps after opening the sign-in screen.
- **SC-002**: A new guest goes from tapping «المتابعة بـ Google» to a complete account (including
  copying the WhatsApp code) in under 2 minutes in usability testing.
- **SC-003**: 95% of WhatsApp codes reach a number that is on WhatsApp within 30 seconds (measured
  from delivery statuses on Staging).
- **SC-004**: 100% of new accounts that can reach booking, favorites, My Bookings, notifications,
  support or account screens have a phone confirmed by WhatsApp code (verified by attempting each as
  an incomplete account, including crafted server requests).
- **SC-005**: 0 accounts have a stored phone number that was not confirmed by the correct code.
- **SC-006**: In tests, no account, number or device can receive more than 10 codes before a 7-day
  block, and no send happens before the ladder allows it — including after reinstalling the app,
  switching accounts on the device, or using the number from another device.
- **SC-007**: 0 WhatsApp messages are sent for requests that do not come from a genuine app install.
- **SC-008**: 0 duplicate accounts are created when Google/Apple is used with an existing account's
  email.
- **SC-009**: Rapid repeated taps on any button in these flows never produce more than one request,
  and cancelling the Google/Apple sheet never shows an error.
- **SC-010**: All new screens pass the existing quality checks (light/dark, Arabic/English,
  narrow/wide, maximum text size, keyboard open) with no clipped or hidden controls.

## Assumptions

- **Email + password stays** next to Google/Apple; only its phone part moves to «أكّد رقمك».
- **WhatsApp is the only channel for confirming a phone.** No SMS (cancelled platform-wide) and no
  email fallback; a guest whose number is not on WhatsApp must use one that is. Codes for email
  confirmation, password recovery, cash-payment confirmation and account deletion stay on email.
- **The confirmed phone is the guest's WhatsApp number**; the separate WhatsApp number concept is
  dropped for new confirmations (existing stored values are left as they are).
- **Copy-code first**: the WhatsApp message has a «نسخ الكود» button and the guest pastes the code.
  Android one-tap/zero-tap autofill from WhatsApp is a later improvement (Guest Plan §19 item 14).
- **Apple on iOS only in this release** (Guest Plan §19 item 10).
- **Unconfirmed-email collision: the confirmed provider email wins** (FR-040, clarified
  2026-11-13; Guest Plan §19 item 11).
- **Incomplete accounts are removed after 7 days** without completion (§19 item 13).
- **Initial values for the per-address limit and global daily cap** (e.g., 20 requests / 10 minutes
  per address) are set on Staging and tuned after the pilot (§19 item 15).
- **Device key**: on iOS a random identifier kept in the system keychain (survives reinstall); on
  Android the platform's per-app device identifier (survives reinstall, changes only on factory
  reset). App genuineness is proven with the platform attestation services already available through
  the app's Firebase projects. Both are disclosed in the privacy policy and store privacy forms.
- **Existing confirmed accounts** are not asked to confirm again.
- **Booking rules are unchanged**: a complete account books exactly as before (AC-001 is met at
  registration).
- **Backend dependencies (in the separate `onair-backend` repository, not here)**: Google and Apple
  enabled in the authentication service; an incomplete account status with the phone empty only in
  that status; phone confirmation requests with a WhatsApp channel and delivery status; the send
  limit records and server settings for the ladder, limit, block and daily cap; WhatsApp sending,
  delivery-status webhook and app-genuineness checks in the existing `onair-api` Worker (no new
  Worker); rejecting incomplete accounts; the current-context read returning status, sign-in methods
  and password presence; cleanup of old incomplete accounts. Until these exist the feature runs in
  mock mode with the same contract shape.
- **Manual setup by account owners** (not code): Meta Business verification, WhatsApp Business
  account and sender number, approved Arabic/English authentication template, permanent access
  token, payment method and webhook; Cloudflare Worker secrets and a rate-limiting rule; Firebase App
  Check for both platforms and both environments; Google Cloud OAuth clients and Apple Sign in
  setup; registering the email domain with Apple's private relay. Only public identifiers go into
  the app's environment files.
- **Governance**: constitution amended to v2.1.0 (2026-11-13) per D-002 — Google/Apple sign-in is
  allowed and the WhatsApp confirmation and anti-abuse rules are part of Principles II and IV. The
  Master Plan (§2.3, AC-001 wording) and Backend Master Plan (§5.1–§5.2) still need the same update
  by the team.
