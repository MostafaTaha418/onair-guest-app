# Feature Specification: Guest Support & Account (G4)

**Feature Branch**: `feature/006-guest-support-account`

**Created**: 2026-11-16

**Status**: Draft

**Input**: User description: "006 من البلان بتاع المشروع بتاعي docs\OnAir Guest App Plan.md" — the next
spec after S005 per Guest Plan §17 ("G4/G5/G6 بيتنفذوا بعدها في Specs 006 وما بعدها"), i.e. **G4 —
الدعم والحساب (P0 للدعم الأساسي)**: support cases, a new case with attachments, replies, FAQ; account,
settings, security and sessions; account deletion.

In short: a signed-in guest can reach OnAir customer service from inside the app (open a case about a
booking, payment, refund or apartment problem, attach photos or a PDF, follow the conversation and
reply), read the FAQ without signing in, call support, and manage their own account: name,
notification preferences, language, appearance, password, active sessions, legal pages, sign out, and
deleting the account in a way that satisfies the app stores while keeping financial records.

**Sources**: `docs/OnAir Guest App Plan.md` (§1.1, §2.7.2, §2.7.3, §5.1–§5.3, §6.2.4, §6.2.6, §6.2.9,
§6.5, §6.8, §6.13, §6.16, §6.17, §6.18, §9.3, §11.1, §11.8, §13, §17 G4, §19 items 4–7, §20),
`docs/OnAir Master Plan.md` (§2.2, §16.1, §16.2; AC-047; decision 102), `docs/OnAir Backend Master
Plan.md` (§4.6 `faq_items`, §5.1 profiles + account deletion, §9.5 notification preferences, §10
support cases / case messages / attachments, §11 common functions), `DESIGN.md`,
`docs/design_reference/README.md` and its screenshots, `.specify/memory/constitution.md`,
`specs/005-guest-social-sign-in/spec.md` (sign-in method row, phone change, `hasPassword`, delivered).

## Clarifications

### Session 2026-11-16

- Q: In «الأمان», does the guest see a list of every signed-in device and end any one of them, or only
  one «sign out of all other devices» button? → A: A full list (device type, platform, last activity,
  «الجهاز ده» marker) with ending each other device individually, plus one button for all others.
- Q: After the guest confirms deletion with the email code, is the account deleted immediately or kept
  in a grace period during which they can undo it? → A: Deleted immediately after the correct code; no
  grace period and no undo.
- Q: Is adding, changing or removing a profile photo part of this release, or deferred with an
  initials avatar meanwhile? → A: Deferred until after launch; the account shows the name's initials
  only.
- Q: Can the guest reply to a case marked «اتحلّت», reopening it, or must they open a new case? → A:
  Replying to a resolved case is allowed and the server reopens it; only «مقفولة» cases refuse replies.
- Q: After a password change, do the account's other signed-in devices sign out automatically, or does
  the guest choose? → A: All other devices sign out automatically; the current device stays signed in.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Follow and reply to my support cases (Priority: P1)

A signed-in guest opens «الدعم» from «حسابي» (or from a notification). The support home shows a header
in the FAQ Hero gradient, «حالاتي» with open cases first, a «حالة جديدة» button and the FAQ entry. Each
case shows its number (e.g. SC-1042), type, status in plain words (مفتوحة / قيد المتابعة / مستني ردك /
اتحلّت / مقفولة), linked booking if any, and when it was last updated. Opening a case shows the
conversation between the guest and OnAir customer service only, oldest to newest, with attachments.
The guest writes a reply, optionally attaches files, and sends it. A new reply from OnAir appears in the
open case without leaving the screen.

**Why this priority**: Support is the only channel between the guest and OnAir (no direct contact with
the owner, AC-047), and many existing screens (booking details, damage dispute, «الرقم مش عليه واتساب»,
code-sending block) already send the guest to «كلّم الدعم». Today those land on a placeholder.

**Independent Test**: With a guest that has three cases (one waiting for the guest, one resolved, one
closed), open the support home, check the order and statuses, open the waiting case, send a reply with
one photo, and receive a staff reply while the case is open.

**Acceptance Scenarios**:

1. **Given** a guest with open and finished cases, **When** they open the support home, **Then** open
   cases (مفتوحة / قيد المتابعة / مستني ردك) are listed first, newest activity first, followed by the
   finished ones, and more cases load as they scroll.
2. **Given** a case with messages from the guest, OnAir and internal staff notes, **When** the guest
   opens it, **Then** they see only their own messages and OnAir's replies to them; internal notes and
   anything exchanged with the owner never appear.
3. **Given** the guest types a reply, **When** they tap «إرسال» twice quickly or while it is sending,
   **Then** exactly one reply is created and the button shows progress until it finishes.
4. **Given** the case is open on screen, **When** OnAir replies, **Then** the reply appears within a few
   seconds without pulling to refresh, and the case status updates if it changed.
5. **Given** a case marked «مقفولة», **When** the guest opens it, **Then** the reply box is replaced by
   «الحالة دي اتقفلت» and «افتح حالة جديدة», which pre-links the same booking.
6. **Given** a «support.staff_replied» or «support.case_resolved» notification, **When** the guest taps
   it, **Then** the matching case opens directly (after sign-in if needed).
7. **Given** a link to a case that does not belong to the guest or does not exist, **When** it opens,
   **Then** the guest sees «الحالة دي مش موجودة» with a way back to support, and nothing about the case
   is revealed.
8. **Given** a case marked «اتحلّت», **When** the guest sends a reply, **Then** the reply is added, the
   case returns to an open status shown in the list and details, and OnAir is notified as for any reply.

---

### User Story 2 - Open a new support case (Priority: P1)

The guest taps «حالة جديدة», picks a type (حجز، دفع، استرداد، مشكلة في الشقة، أخرى), optionally links one
of their bookings, writes what happened, optionally attaches photos or a PDF, and sends. They land on
the new case with its number and a confirmation that OnAir will reply. When the guest comes from a
booking («تحتاج مساعدة؟ تواصل مع OnAir»), from an apartment page («لديك سؤال؟ تواصل مع OnAir») or from
another screen that offers «كلّم الدعم», the booking or apartment is linked and a fitting type is
preselected automatically.

**Why this priority**: Without opening a case the guest cannot report a payment, refund or apartment
problem at all; it is the core of "basic support" that the plan marks P0.

**Independent Test**: From a booking's details tap «تواصل مع OnAir», confirm the booking is linked, send
a description with two photos, and verify the case appears at the top of «حالاتي» with the booking.

**Acceptance Scenarios**:

1. **Given** the new case form, **When** the description is empty or shorter than the minimum, **Then**
   «إرسال» stays disabled and the field explains what is missing; the type is required.
2. **Given** the guest opened the form from a booking, **When** the form appears, **Then** that booking
   is linked (and can be removed) and the type is preselected as «حجز».
3. **Given** the guest attaches photos, **When** they are added, **Then** each shows a thumbnail, size
   and upload progress, photos are reduced in size before upload, and any file can be removed before
   sending.
4. **Given** a file of an unsupported type or over the size limit, **When** the guest picks it, **Then**
   it is refused with the allowed types and limit, and the rest of the form stays as it was.
5. **Given** one attachment fails to upload, **When** the guest is on the form, **Then** that file shows
   «فشل الرفع» with «إعادة المحاولة» or «إزالة», and «إرسال» waits until every file is uploaded or removed.
6. **Given** the guest taps «إرسال» several times quickly or the connection drops and they retry,
   **Then** only one case is created.
7. **Given** the guest leaves the form with text or files on it, **When** they press back, **Then** they
   are asked whether to discard the draft.

---

### User Story 3 - FAQ and calling support (Priority: P1)

Anyone, signed in or browsing as a visitor, can open «الأسئلة الشائعة» and read questions and answers
in the app language, grouped and searchable. OnAir can update the content without a new app release.
From the support home, the FAQ and the account-suspended screen the guest can tap «اتصل بخدمة العملاء»
to call the support number published by OnAir, with the working hours shown when OnAir provides them.

**Why this priority**: The FAQ answers the most common questions without creating a case, and the call
button is the fallback when something is urgent (arrival day, payment stuck).

**Independent Test**: As a visitor (not signed in), open the FAQ from the account tab, search a word,
expand an answer, switch the app to English and see the English content, then tap the call button and
see the phone dialer with the support number.

**Acceptance Scenarios**:

1. **Given** a visitor, **When** they open the FAQ, **Then** it opens without asking them to sign in.
2. **Given** published FAQ items, **When** the guest types in the search field, **Then** only matching
   questions/answers remain, and «مفيش نتايج» appears with «افتح حالة جديدة» when nothing matches.
3. **Given** the FAQ was loaded before, **When** the guest opens it offline, **Then** the last loaded
   content shows with a notice that it may be out of date.
4. **Given** OnAir has not published a support number, **When** the guest looks for the call button,
   **Then** it is hidden rather than broken.
5. **Given** the device cannot place calls (e.g. a tablet), **When** the guest taps the call button,
   **Then** the number is shown so it can be copied.

---

### User Story 4 - Delete my account (Priority: P1)

From «حسابي» → «حذف الحساب», the guest reads what deletion means in plain words: personal data (name,
email, phone, favorites, preferences) is removed or anonymized, past bookings and payments are
kept without personal data as the law requires, and it cannot be undone. They confirm, receive a
6-digit code on their account email, enter it, and are signed out on this device with a confirmation
that the account was deleted. If they have an active booking or a refund still in progress, deletion is
refused with the reason and what to do.

**Why this priority**: Apple and Google require in-app account deletion for any app that lets people
create an account; the app cannot be published without it.

**Independent Test**: With a guest that has only completed stays, request deletion, enter the email
code, verify the session ends and signing in again with the same email fails as a non-existent account;
repeat with a guest that has an upcoming confirmed booking and verify deletion is refused.

**Acceptance Scenarios**:

1. **Given** a guest with no active booking and no pending refund, **When** they confirm deletion and
   enter the correct code, **Then** the account is deleted, every session of the account ends, this
   device returns to the home screen as a visitor, and «حسابك اتحذف» is shown once.
2. **Given** a guest with an active booking (awaiting payment, awaiting the owner, confirmed, in stay)
   or a refund not yet completed, **When** they open «حذف الحساب» or confirm it, **Then** deletion is
   refused with the specific reason, a link to the blocking booking and «كلّم الدعم».
3. **Given** the code screen, **When** the code is wrong, expired or out of attempts, **Then** the guest
   sees the same messages and resend waiting time the app already uses for email codes, driven by the
   server.
4. **Given** a Google or Apple account (including an Apple «Hide My Email» address), **When** it
   requests deletion, **Then** the code is sent to the account email exactly as for email accounts.
5. **Given** the guest taps «احذف حسابي» or «تأكيد» repeatedly, **Then** only one deletion request and
   one code are sent.
6. **Given** deletion succeeded, **When** the device had a registered notification token, **Then** no
   further notifications reach this device for that account.

---

### User Story 5 - Profile, language, appearance, legal and sign-out (Priority: P2)

«حسابي» becomes the full account and settings screen: profile (name with an initials avatar, email,
sign-in method, phone/WhatsApp number with «متأكد» and «تغيير» — the last two already delivered in S005),
«الإشعارات», «اللغة» (العربية / English), «المظهر» (فاتح / داكن / حسب الجهاز), «الأمان», «الدعم»,
«الأسئلة الشائعة», «الشروط والأحكام», «سياسة الخصوصية», «حذف الحساب» and «تسجيل الخروج», with the
settings icon tones from the design (Danger tone for deletion and sign-out). The guest can edit their
name. Profile photos are not part of this release.

**Why this priority**: These are everyday settings the plan lists for the account tab; the app works
without them, but the guest needs them before the pilot.

**Independent Test**: Change the name, switch to English and dark mode, restart the app and verify all
three persist and the initials avatar follows the new name; open the terms and privacy pages; sign out and verify the account data
is gone from the device.

**Acceptance Scenarios**:

1. **Given** the edit-name field, **When** the name is shorter than 2 or longer than 80 characters,
   **Then** saving is disabled with the reason; a valid name is saved once even on repeated taps.
2. **Given** the guest saved a new name, **When** they return to «حسابي», **Then** the name and the
   initials avatar show the new name, and no photo option is offered.
3. **Given** the guest switches the language, **When** the choice is saved, **Then** the whole app
   switches language and direction (RTL/LTR) immediately, the choice survives a restart, and the
   account's language for emails and notifications follows it.
4. **Given** the guest picks «حسب الجهاز», **When** the device theme changes, **Then** the app follows
   it; picking فاتح or داكن overrides the device.
5. **Given** a visitor (not signed in), **When** they open the account tab, **Then** they see sign-in /
   create account, plus language, appearance, FAQ, terms and privacy — but nothing that needs an account.
6. **Given** the guest taps «تسجيل الخروج», **When** they confirm, **Then** the session, this device's
   notification registration and cached personal data are cleared, and they stay on a visitor screen.

---

### User Story 6 - Security: password and active sessions (Priority: P2)

Under «الأمان», a guest who signs in with email and password can change their password by entering
the current one and a new one. A Google/Apple guest without a password does not see this option. Every
guest sees «الأجهزة المسجّل دخولها»: each active session with device type, platform, approximate last
activity and «الجهاز ده» on the current one. They can sign out any other session, or «تسجيل الخروج
من كل الأجهزة التانية» at once.

**Why this priority**: Session control and password change are security basics listed in the plan
(§11.1); they matter most when a phone is lost, which is rare but serious.

**Independent Test**: Sign in on two devices, open the sessions list on device A, end device B's
session, and verify device B is returned to the sign-in screen with «انتهت الجلسة» on its next action;
change the password on A and verify the old password stops working.

**Acceptance Scenarios**:

1. **Given** an email + password guest, **When** they enter the wrong current password, **Then** the
   change is refused with «كلمة المرور الحالية غلط», and repeated failures follow the server's limits.
2. **Given** the new password does not meet the rules used at registration, **When** the guest types
   it, **Then** the rule that fails is shown and saving stays disabled.
3. **Given** the password was changed, **When** the change succeeds, **Then** the guest stays signed in
   on this device, every other session ends, and the guest receives the «تم تغيير كلمة المرور» notice.
4. **Given** a Google/Apple guest with no password, **When** they open «الأمان», **Then** the password
   row is absent and only sessions appear.
5. **Given** the sessions list, **When** the guest ends a session, **Then** it disappears from the list
   after the server confirms; the current device cannot be ended from the list (sign-out is used instead).
6. **Given** a session ended from another device or by OnAir, **When** this device next opens the
   app, or within a minute while it is open, **Then** it signs out safely with «انتهت الجلسة» and can return to the same screen after
   signing in again.

---

### User Story 7 - Notification preferences (Priority: P3)

Under «الإشعارات» in settings, the guest sees notification categories (e.g. reminders, support
replies, reviews, account security) with switches per channel (إشعارات الجهاز، البريد). Booking and
money notifications that cannot be turned off are shown locked with «إشعارات ضرورية للحجز والدفع ومش
بتتقفل». In-app notifications in the notifications center are always kept.

**Why this priority**: Useful for comfort but not needed for any booking or support journey; the
server already sends mandatory notifications regardless.

**Independent Test**: Turn off push for support replies, have OnAir reply to a case, and verify the reply
appears in the notifications center but no push arrives; verify a booking confirmation still arrives as
push even when its category is shown locked.

**Acceptance Scenarios**:

1. **Given** the preferences screen, **When** it loads, **Then** each category shows its current state
   per channel from the server, and mandatory ones are visibly locked and cannot be toggled.
2. **Given** the guest toggles a switch, **When** the server confirms, **Then** the switch keeps its new
   state; if the save fails, it returns to the previous state with an error and «إعادة المحاولة».
3. **Given** the device has notifications blocked for the app, **When** the guest opens this screen,
   **Then** a notice explains that device notifications are off and offers to open the device settings.

---

### Edge Cases

- **Offline**: support home, a case and preferences show the last loaded data with an offline notice;
  sending a case, reply, deletion or setting change is blocked with «مفيش اتصال» and the typed text and
  chosen files are kept on screen (never written to permanent storage).
- **Session expires mid-action** (sending a reply, deleting): the guest signs in again and returns to the
  same screen; an unsent reply's text is still there if the app was not closed.
- **Case changes while open**: OnAir closes the case while the guest is typing; sending is refused by
  the server and the screen updates to the closed state, keeping the typed text visible. If OnAir only
  resolves it, the reply is still sent and reopens the case.
- **Attachment links**: attachment previews use short-lived links; an expired link is fetched again on
  tap instead of showing a broken image; attachments are never saved to the gallery automatically.
- **Large files / slow network**: an upload can be cancelled; leaving the screen cancels pending uploads.
- **Unknown case type or status** from the server: shown with a neutral label instead of failing.
- **Deletion race**: a booking becomes active (e.g. a payment completes) between opening the deletion
  screen and entering the code; the server refuses and the app shows the blocking reason.
- **Deletion code block**: the email-code resend wait and limits are shown from the server's times.
- **Suspended account**: account-gated screens keep showing the suspended notice (already delivered);
  it offers the FAQ and the call button but not new cases.
- **Incomplete account** (phone not confirmed, S005): support cases and account settings stay behind
  «أكّد رقمك»; the FAQ stays open; «إلغاء» there is still sign-out.
- **Deep links to support routes** for a visitor: sign-in first, then the same case or form opens.
- **Large text, narrow and wide screens, keyboard**: the reply box stays above the keyboard, long case
  messages wrap, and settings rows do not truncate meaning at the largest supported text size.
- **Name with only spaces or emojis-only**: trimmed and validated the same way as at registration.

## Requirements *(mandatory)*

### Functional Requirements

**Support — cases (US1, US2)**

- **FR-001**: The app MUST show a support home with «حالاتي», a «حالة جديدة» action and an entry to the
  FAQ, reachable from «حسابي», from notifications and from every existing «كلّم الدعم» / «تواصل مع
  OnAir» entry point.
- **FR-002**: The case list MUST show open cases (open, in progress, waiting for the guest) before
  finished ones (resolved, closed), each with case number, type, status label, linked booking if any and
  last activity time in Cairo time, and MUST load further pages on scroll.
- **FR-003**: Case details MUST show only messages visible to the guest (theirs and OnAir's replies to
  them) and their attachments; internal notes and owner-side messages MUST never be requested or shown.
- **FR-004**: The guest MUST be able to reply with text and optional attachments on any case that is
  not closed, including resolved ones; a reply on a resolved case reopens it (the server sets the new
  status and the app shows it). A closed case MUST offer «افتح حالة جديدة» pre-linked to the same
  booking instead of a reply box.
- **FR-005**: New OnAir replies and status changes on an open case MUST appear without manual refresh;
  the list MUST refresh when the guest returns to it.
- **FR-006**: The new-case form MUST require a type from: حجز، دفع، استرداد، مشكلة في الشقة، أخرى, and a
  description of at least 10 and at most 4000 characters; linking one of the guest's bookings is
  optional.
- **FR-007**: Entering support from a booking or an apartment page MUST link that booking or apartment
  and preselect a fitting type; the guest MUST be able to remove the link.
- **FR-008**: Cases created by the system for the guest (e.g. a disputed damage claim) MUST appear in
  «حالاتي» with their own type label and behave like any other case.
- **FR-009**: Sending a case or a reply MUST create exactly one record per intent, regardless of
  repeated taps, retries after a dropped connection, or app backgrounding during the request.
- **FR-010**: The app MUST never offer a direct channel to the apartment owner; all contact goes through
  OnAir (AC-047).

**Attachments (US1, US2)**

- **FR-011**: Attachments MUST be limited to photos and PDF files within the server's size and count
  limits; the app MUST check type and size before uploading and MUST show the server's refusal if it
  disagrees.
- **FR-012**: Photos MUST be reduced in size before upload; each file MUST show progress and allow
  cancel, retry and remove; a case or reply MUST NOT be sent while any attached file is still uploading
  or failed.
- **FR-013**: Attachments MUST be stored privately and viewed only through short-lived links; the app
  MUST NOT keep those links or downloaded files in permanent storage.

**FAQ and calling (US3)**

- **FR-014**: The FAQ MUST be readable without an account, show the content in the app language,
  support search, and come from the server so it can change without a new release.
- **FR-015**: The FAQ MUST show the last loaded content when offline, marked as possibly out of date.
- **FR-016**: The app MUST offer a call button to the support number published by OnAir (with working
  hours when published) on the support home, the FAQ and the suspended-account screen, and MUST hide it
  when no number is published.

**Account deletion (US4)**

- **FR-017**: «حذف الحساب» MUST explain, before any action, what is deleted or anonymized, what is kept
  without personal data (bookings and payment records), and that it cannot be undone.
- **FR-018**: Deletion MUST require a 6-digit code sent to the account email, using the same code
  screen, wait times and limits as the app's other email codes.
- **FR-019**: When the server reports an active booking or a pending refund, the app MUST refuse
  deletion with the specific reason, a link to the blocking item and «كلّم الدعم».
- **FR-020**: After successful deletion the app MUST end the local session, remove this device's
  notification registration, clear cached personal data, return to the visitor home and show a one-time
  confirmation.
- **FR-021**: Deletion MUST be available to email, Google and Apple accounts alike.
- **FR-021a**: Deletion MUST take effect immediately once the correct code is entered; there is no grace
  period and no way to undo it from the app, and the confirmation step MUST say so before the code is
  sent.

**Profile and settings (US5)**

- **FR-022**: «حسابي» MUST show name with an initials avatar, email, sign-in method, and the
  confirmed phone/WhatsApp number with «تغيير» (delivered in S005), plus rows for notifications,
  language, appearance, security, support, FAQ, terms, privacy, account deletion and sign-out.
- **FR-023**: The guest MUST be able to edit their name (2–80 characters after trimming). Profile
  photo upload is out of scope for this release; the avatar is the name's initials.
- **FR-024**: The guest MUST be able to choose Arabic or English; the app MUST switch language and text
  direction immediately, remember the choice on the device, and update the account's language used for
  emails and notifications when signed in.
- **FR-025**: The guest MUST be able to choose light, dark or follow-device appearance, remembered on
  the device.
- **FR-026**: Terms and privacy MUST open the current published versions in the app language.
- **FR-027**: Sign-out MUST ask for confirmation, then clear the session, this device's notification
  registration, provider sign-in state (Google) and all cached personal data.
- **FR-028**: A visitor's account tab MUST show sign-in / create account, language, appearance, FAQ,
  terms and privacy only.

**Security and sessions (US6)**

- **FR-029**: Accounts that have a password MUST be able to change it by entering the current and new
  password; the new password MUST follow the registration rules; accounts without a password MUST NOT
  see this option.
- **FR-030**: After a password change, every other session of the account MUST end and the account
  MUST receive the mandatory «تم تغيير كلمة المرور» notice.
- **FR-031**: The app MUST list the account's active sessions with device type, platform, approximate
  last activity and a «الجهاز ده» marker, and MUST allow ending any other session individually or all
  other sessions at once.
- **FR-032**: When the current session has been ended elsewhere, the app MUST sign out safely with
  «انتهت الجلسة» and allow returning to the same screen after signing in.

**Notification preferences (US7)**

- **FR-033**: The app MUST show notification categories with per-channel switches (device push, email),
  loaded from and saved to the server; in-app notifications are always on.
- **FR-034**: Mandatory booking and payment notifications MUST appear locked with an explanation and
  MUST NOT be switchable.
- **FR-035**: A failed save MUST revert the switch and show an error with retry; when device
  notifications are blocked for the app, the screen MUST say so and offer the device settings.

**Cross-cutting**

- **FR-036**: Every action that sends something (case, reply, upload, name, password, session
  end, preference, deletion) MUST be protected against duplicate submission and show loading, disabled,
  error and success states.
- **FR-037**: All screens MUST follow `DESIGN.md` and the design reference screenshots, and MUST work in
  light and dark mode, Arabic (RTL) and English (LTR), at the largest supported text size, on narrow and
  wide screens, with the keyboard open, and with screen readers (labels for every control).
- **FR-038**: Support and account screens that need an account MUST stay behind sign-in, the
  phone-confirmation gate for incomplete accounts and the suspended-account notice; the FAQ, language,
  appearance, terms and privacy MUST stay public.
- **FR-039**: Unexpected errors MUST show a friendly message with the request reference so support can
  trace it; no personal data is written to logs or crash reports.
- **FR-040**: Every server rule (case ownership, attachment limits, deletion blockers, mandatory
  notifications, password rules, session ownership) MUST be enforced by the server; the app's checks
  exist for clarity only.

### Key Entities

- **Support case**: a conversation the guest opens with OnAir — number, type, status, optional linked
  booking or apartment, created and last-activity times, and resolution when finished.
- **Case message**: one message in a case — author side (guest or OnAir), text, time, attachments;
  only messages meant for the guest are visible.
- **Attachment**: a private photo or PDF belonging to a case or message — type, size, upload state;
  viewed only through a short-lived link.
- **FAQ item**: a question and answer in Arabic and English with an order, published by OnAir.
- **Support contact**: the published phone number and optional working hours.
- **Guest profile**: name, email, sign-in methods, whether a password exists,
  confirmed phone/WhatsApp number, language, status.
- **Notification preference**: category × channel → on/off, with mandatory categories locked.
- **Active session**: one signed-in device for the account — device type, platform, last activity,
  current or not.
- **Deletion request**: the guest's request to delete the account, confirmed by an email code, either
  completed or refused with a blocking reason (active booking, pending refund).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A guest can open a new case with a description and two photos in under 2 minutes from
  the booking details screen.
- **SC-002**: In testing, 100% of rapid repeated taps on send (case, reply, deletion, password, session
  end) produce exactly one result.
- **SC-003**: An OnAir reply appears in an open case within 5 seconds of being sent, without manual
  refresh, in 95% of attempts on a normal connection.
- **SC-004**: 0 internal notes or owner-side messages are visible to the guest in any test case,
  including deep links to cases the guest does not own.
- **SC-005**: A guest with no active booking can complete account deletion (read, confirm, enter code)
  in under 3 minutes, and after it no session of that account works on any device.
- **SC-006**: 100% of deletion attempts with an active booking or pending refund are refused with a
  visible reason.
- **SC-007**: 0 mandatory booking or payment notifications can be switched off from the app.
- **SC-008**: A visitor can read and search the FAQ without signing in, and the FAQ opens with content
  in under 2 seconds when it was loaded before.
- **SC-009**: Every new screen passes review in light and dark mode, Arabic and English, the largest
  supported text size and a narrow phone width, with no clipped or overlapping content.
- **SC-010**: After ending a session from another device, the ended device returns to sign-in on its
  next app open, or within 1 minute while the app is open, in 100% of tests.

## Assumptions

- **Scope** is Guest Plan §17 G4 only. Favorites and reviews (G5) and pilot readiness (G6) are later
  specs. Phone number change and the sign-in-method row were delivered in S005 and are reused, not
  rebuilt; the password row's visibility now uses the account's "has password" flag from S005.
- **Changing the account email** is out of scope (not in the plan); the email is shown read-only.
- **Guest case types** offered in the form are the five in Guest Plan §6.17; other server types (damage
  dispute, complaint, stay exception…) can appear in the list when the system creates them.
- **Reply on resolved cases** (clarified 2026-11-16) is allowed and reopens the case; only closed cases
  refuse replies. The backend must reopen a resolved case on a guest reply.
- **Attachment limits** (Guest Plan §19 item 4 still open): defaults are photos (JPEG, PNG, HEIC/HEIF,
  sent as compressed JPEG) and PDF, up to 5 files per case or reply, photos up to 10 MB and PDFs up to
  15 MB (the platform's current upload setting); the server's limits are final and the app shows its
  refusal.
- **Support number and hours** (§19 item 5) come from the server's public app configuration; the call
  button hides until they are published.
- **English** (§19 item 6): the language switch is shipped; if English is not enabled at launch, the
  switch can be hidden by configuration without code changes.
- **Account deletion** follows the backend plan: request → email code → server anonymizes personal data
  and keeps financial records without personal data; the legal retention period (§19 item 7) is the
  server's responsibility and the explanation text will be confirmed with legal review before launch.
  Deletion is immediate after the code with no grace period (clarified 2026-11-16).
- **Active booking** for deletion means any booking not yet finished (awaiting payment, awaiting the
  owner, confirmed, in stay, or with an open damage claim); the server decides and returns the reason.
- **Password rules** are the same as at registration; repeated wrong current passwords follow the
  server's sign-in limits.
- **Sessions** (clarified 2026-11-16): the server must provide the list of the account's sessions and
  the ability to end one or all others — this is a new backend dependency not yet in the Backend Master
  Plan; a password change ends every other session automatically (clarified 2026-11-16).
- **Notification categories** come from the server with their mandatory flag; the app does not hard-code
  which ones are mandatory.
- **Profile photo** is deferred until after launch (clarified 2026-11-16); this release shows the name's
  initials and needs no photo upload support from the backend.
- **Dependencies (backend repository, not here)**: published support, FAQ, preference, profile update,
  upload and deletion functions per the Backend Master Plan §10–§11, plus anything missing for listing
  and ending sessions and changing the password with the current one.
  Until they are ready, every journey works in the app's mock mode, as in previous specs.
