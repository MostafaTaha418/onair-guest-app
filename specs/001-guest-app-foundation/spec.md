# Feature Specification: Guest App Foundation (G0)

**Feature Branch**: `001-guest-app-foundation`

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "G0 Foundation of the Guest App: flavors (Staging/Production), design system, core, router + bottom nav shell, auth, i18n/RTL, base CI"

**Sources**: `docs/OnAir Guest App Plan.md` (§3–§6.2, §11, §13, §16, §17 G0),
`docs/UI_UX_DESIGN_SYSTEM.md`, `.specify/memory/constitution.md` v1.0.0.

## Clarifications

### Session 2026-10-26

- Q: How should email verification and password recovery work — a link in the email, or a
  6-digit code the guest types into the app? → A: A 6-digit code sent by email and typed into
  the app, the same way as phone sign-in. No links in G0.
- Q: When a guest signs up with email, should they also enter a phone number at sign-up? → A:
  No. Phone is not asked at email sign-up; it is added and verified before the first booking
  (G2) or from the account (G4). Phone sign-in reaches an email account only if that phone was
  added to it and verified.
- Q: How long should a guest stay signed in if they don't open the app? → A: Automatic sign-out
  after 30 days without opening the app; the server can also end any session at any time.
- Q: Which phone numbers can sign up and sign in — Egypt only, Egypt plus a list, or any
  country? → A: Egypt only (+20) at the start; more countries may be added later by decision.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open the app and move around as a visitor (Priority: P1)

A person installs OnAir and opens it for the first time. They see the branded launch screen,
then land on the Home tab in Arabic, laid out right-to-left, in their device's light or dark
appearance. They can switch between the five main tabs (Home, Search, My Bookings, Favorites,
My Account). Each tab remembers where the person was when they come back to it. Home and Search
are open to everyone; in this phase their content is a placeholder that later phases fill.

**Why this priority**: Every later feature lives inside this shell. Without it nothing else can
be shown, tested, or demonstrated.

**Independent Test**: Install a test build, open it with no account, and move through all five
tabs in both light and dark appearance, checking layout direction, fonts, colors, and that each
tab keeps its own position.

**Acceptance Scenarios**:

1. **Given** a fresh install, **When** the person opens the app, **Then** the launch screen
   appears with no white flash and the Home tab appears within the target time (SC-002).
2. **Given** the person is on Home, **When** they tap each bottom tab in turn, **Then** each tab
   opens, the active tab is visually highlighted, and the tab order runs right-to-left
   (Home first on the right).
3. **Given** the person scrolled down in one tab, **When** they switch to another tab and back,
   **Then** the first tab is shown at the same scroll position.
4. **Given** the device is in dark appearance, **When** the app opens, **Then** every screen uses
   the dark palette from the design system, and switching the device appearance while the app is
   open updates the app without restarting.
5. **Given** the device language is English, **When** the app opens, **Then** the app is still
   shown in Arabic, right-to-left (Arabic is the default until English is enabled).
6. **Given** the device text size is set to its largest value, **When** any foundation screen is
   shown, **Then** text grows up to the supported maximum and no text is cut off or overlaps.

---

### User Story 2 - Create an account and sign in with a phone number (Priority: P1)

A visitor chooses to sign up or sign in with their mobile number. They enter an Egyptian number
(+20, the only country accepted at launch), receive a 6-digit code by SMS, and enter it. The code fills in automatically
when the phone supports it. After success they are signed in and their phone number is marked as
verified. New users also enter their name and accept the Terms and Privacy Policy.

**Why this priority**: Phone sign-in is the main entry path for guests, and a verified phone is
required before the first booking (AC-001). The G0 exit criterion is a guest who can sign up,
sign in, and sign out on Staging.

**Independent Test**: On the Staging build, sign up with a new test phone number, enter the code,
confirm the account shows as signed in with a verified phone, then sign in again with the same
number after signing out.

**Acceptance Scenarios**:

1. **Given** a visitor on the sign-in screen, **When** they enter a number in an invalid format,
   **Then** the send button stays disabled and a clear Arabic message explains the expected
   format, before anything is sent.
2. **Given** a valid number, **When** the visitor taps "send code", **Then** the button disables
   immediately, a code is sent, and the code screen shows a resend countdown whose duration comes
   from the server.
3. **Given** the code screen, **When** the visitor pastes or auto-fills a 6-digit code, **Then**
   all six boxes fill and the code is submitted without extra taps.
4. **Given** a wrong or expired code, **When** it is submitted, **Then** a clear Arabic message is
   shown under the field, read aloud by screen readers, and the visitor can retry or request a new
   code once the countdown ends.
5. **Given** the server has rate-limited this number, **When** the visitor tries again, **Then**
   the app shows how long to wait and keeps the action disabled until then.
6. **Given** any phone number, **When** a code is requested, **Then** the message shown is the
   same whether or not the number already has an account.
7. **Given** a new number, **When** the code is verified, **Then** the visitor completes their name
   and accepts the Terms and Privacy Policy before the account is created.

---

### User Story 3 - Keep the account secure and sign out (Priority: P1)

A signed-in guest closes and reopens the app and is still signed in. If their session can no
longer be renewed, they are told the session ended, asked to sign in again, and returned to the
same screen afterwards. When they sign out, nothing personal is left on the device and the device
stops receiving their notifications.

**Why this priority**: Sessions guard identity and, from G2 onward, bookings and payments.
Getting this wrong is a security failure, not a bug (Constitution IV).

**Independent Test**: Sign in, force-close and reopen the app (still signed in), revoke the
session from the server side (app shows "session ended" and returns to the same screen after
sign-in), then sign out and confirm no personal data remains on the device.

**Acceptance Scenarios**:

1. **Given** a signed-in guest, **When** they force-close and reopen the app, **Then** they are
   still signed in and see no sign-in screen.
2. **Given** a guest who has not opened the app for more than 30 days, **When** they open it,
   **Then** they are shown as signed out with a "session ended" message and can sign in again;
   a guest who opened it within the last 30 days stays signed in.
3. **Given** a session that cannot be renewed, **When** the guest takes any action that needs an
   account, **Then** the app shows a "session ended" message, opens sign-in, and after success
   returns to the screen they were on.
4. **Given** a signed-in guest, **When** they sign out, **Then** their session, cached personal
   data, and in-memory state are removed, the device is unregistered from their notifications,
   and the app returns to the visitor Home tab.
5. **Given** a signed-out device, **When** someone inspects the app's stored preferences, **Then**
   only non-sensitive preferences (language, appearance) are found.

---

### User Story 4 - Sign up and sign in with email and password (Priority: P2)

A visitor who prefers email signs up with name, email, and password, sees a password-strength
hint, accepts the Terms and Privacy Policy, and receives a 6-digit verification code by email,
which they type into the app. They can sign in with email and password, and recover a forgotten
password with a 6-digit code sent by email.

**Why this priority**: An approved second sign-in method, but less common than phone for the
target audience. Phone sign-in alone already meets the G0 exit criterion.

**Independent Test**: On Staging, register with a test email, enter the emailed code, sign in
with the password, then use "forgot?", enter the emailed code, set a new password, and sign in
with it.

**Acceptance Scenarios**:

1. **Given** the email tab, **When** the visitor types a password, **Then** a strength hint
   updates as they type, and passwords below the minimum rule cannot be submitted.
2. **Given** a completed sign-up, **When** the account is created, **Then** a 6-digit code is
   emailed, the app opens the code screen, and the email shows as "not verified" until the
   correct code is entered. The guest can also verify later from the app.
3. **Given** a verification or recovery code screen, **When** the guest enters a wrong or
   expired code, or hits the server's attempt limit, **Then** the same code-screen behaviour as
   phone sign-in applies (clear message, resend countdown, wait time).
4. **Given** wrong credentials, **When** the guest signs in, **Then** one generic message is shown
   that does not reveal whether the email is registered.
5. **Given** "forgot?", **When** the guest submits an email, **Then** the same confirmation message
   is shown whether or not the email is registered, and the code screen opens; after a correct
   code the guest sets a new password that meets FR-025.

---

### User Story 5 - Visitors who reach a members-only area return to it after signing in (Priority: P2)

A visitor taps a tab or action that needs an account (My Bookings, Favorites, My Account, or a
notification link). The app opens sign-in, and after success takes them back to exactly where
they were going.

**Why this priority**: The rule that a visitor returns to the same point after signing in (Guest
Plan §5.2) must be built into navigation from the start; later features (booking from a property
page) depend on it.

**Independent Test**: As a visitor, tap My Bookings, sign in, and confirm the app lands on My
Bookings rather than Home. Repeat with a link to a members-only screen.

**Acceptance Scenarios**:

1. **Given** a visitor, **When** they tap My Bookings, Favorites, or My Account, **Then** sign-in
   opens, and after success the tapped tab is shown.
2. **Given** a visitor, **When** they open a link to a members-only screen, **Then** sign-in opens
   first, and after success the linked screen opens.
3. **Given** a link carrying an item ID, **When** the app opens it, **Then** the ID's format is
   checked first, nothing changes based on the link alone, and an unknown or forbidden item shows
   a neutral "not available" screen that does not reveal whether it exists.
4. **Given** a visitor on sign-in, **When** they cancel, **Then** they return to where they were,
   still as a visitor.

---

### User Story 6 - The team ships separate test and live builds (Priority: P2)

The team produces two installable builds: a test build (Staging) and a live build (Production).
They can be installed side by side on one phone, have different names and icons, and each talks
only to its own environment. The live build contains no secrets beyond the public keys the
constitution allows.

**Why this priority**: All G0 acceptance happens on Staging, and mixing environments risks real
data and real money from G2 onward.

**Independent Test**: Install both builds on one device, confirm different names and icons, sign
in on Staging, and confirm the Production build shows no Staging account or data.

**Acceptance Scenarios**:

1. **Given** both builds installed, **When** the person views the home screen, **Then** the test
   build is clearly labelled "OnAir (Staging)" and the live build "OnAir".
2. **Given** an account created on Staging, **When** the same credentials are used on the live
   build, **Then** they do not work there (environments are fully separate).
3. **Given** a live build, **When** it is scanned for secrets, **Then** no forbidden key patterns
   are found.

---

### User Story 7 - Every change passes the same automated quality checks (Priority: P3)

Every proposed code change is checked automatically for formatting, static analysis, tests
(including visual comparisons in light, dark, right-to-left, and large text), out-of-date
generated code, and leaked secrets. A failing check blocks merging.

**Why this priority**: It protects every later phase, but the app can be demonstrated before it
exists.

**Independent Test**: Open a change that breaks formatting or a test, confirm the checks fail
and merging is blocked; fix it and confirm the checks pass.

**Acceptance Scenarios**:

1. **Given** a change with a formatting error, a failing test, or a committed secret, **When** it
   is proposed, **Then** the automated checks fail and the change cannot be merged.
2. **Given** a clean change, **When** it is proposed, **Then** all checks pass and report results
   on the change.

---

### User Story 8 - Outdated app versions are asked to update (Priority: P3)

When the server says the installed version is no longer supported, the app shows a full-screen
"update required" message with a button to the store and blocks further use.

**Why this priority**: Needed before payment contracts change in later phases; rarely triggered
in G0 itself.

**Independent Test**: Set the minimum supported version on Staging above the installed build and
reopen the app.

**Acceptance Scenarios**:

1. **Given** a minimum supported version newer than the installed build, **When** the app opens or
   returns to the foreground, **Then** the update screen appears and no other screen can be
   reached.
2. **Given** the version check cannot reach the server, **When** the app opens, **Then** the app
   continues normally and checks again next time.

---

### Edge Cases

- No connection when the app opens: the shell still appears, a top banner says there is no
  internet connection, and actions that need the server are disabled with a clear reason.
- A visitor with a non-Egyptian number: the app explains in Arabic that only Egyptian numbers
  are supported for now and offers email sign-up instead.
- Connection drops while sending or verifying a code: the button re-enables with a retry message;
  no duplicate code is sent from a single tap.
- The app is closed on the code screen: on reopening, the guest starts the sign-in step again;
  no partial account is shown as signed in.
- The guest changes the number on the code screen: the previous countdown and code are discarded.
- Repeated wrong codes: after the server limit, the app shows the wait time and disables entry.
- Unexpected server error: a plain Arabic message with "retry" and a reference number the guest
  can give to support.
- Server returns an error code the app does not recognise: shown as the generic unexpected-error
  message with its reference number.
- A guest who registered by email signs in by phone (or the reverse): they reach the same
  account only if that phone (or email) was already added to it and verified. Otherwise a new,
  separate account is created. Adding a second method to an existing account happens before the
  first booking (G2) or in Account settings (G4), not in G0.
- Device time is wrong: countdowns and session handling rely on server-provided durations and
  timestamps, not the device clock alone.
- Screens below 360 pt wide: auth titles use the smaller size from the design system and nothing
  overflows.
- Screen reader on: every icon-only control has a spoken label, and focus moves in right-to-left
  reading order.

## Requirements *(mandatory)*

### Functional Requirements

**Environments & builds**

- **FR-001**: The team MUST be able to produce two builds, Staging and Production, each with its
  own app identifier, display name ("OnAir (Staging)" / "OnAir"), and connection to its own
  environment only, so both can be installed on one device.
- **FR-002**: Builds MUST contain only the public configuration the constitution allows (public
  backend address, public anonymous key, public push config). Environment files MUST NOT be
  stored in the repository.
- **FR-003**: The default placeholder app identifier MUST be replaced with OnAir's final
  identifiers for both builds.

**Visual system**

- **FR-004**: All colors on every screen MUST come from the design-system tokens in
  `UI_UX_DESIGN_SYSTEM.md`, in both light and dark variants. No screen may define its own colors.
- **FR-005**: All text MUST use the Cairo font bundled with the app (weights 400–800), with sizes
  and weights taken from the design system's type scale and named styles.
- **FR-006**: The app MUST follow the device's light/dark setting in this phase, switching live
  when the device setting changes.
- **FR-007**: The design system MUST provide the shared building blocks the foundation screens
  need: primary button (solid and auth-gradient versions), text field (normal, focus, error), 6-box
  code field, bottom navigation bar, section header, and the standard Loading / Empty / Error /
  Offline views, plus a no-connection banner.
- **FR-008**: Error text MUST meet readable contrast in both appearances, using the accessible
  fallbacks in Guest Plan §4.8 until the designer decides.
- **FR-009**: Spacing, corner radius, elevation, and icon values not defined by the design file
  MUST follow Guest Plan §4.5 and be defined in one place so a designer change is a single edit.

**Language, direction & accessibility**

- **FR-010**: The app MUST open in Arabic, right-to-left, regardless of device language, with an
  English translation set prepared but not offered to users until enabled.
- **FR-011**: Every user-facing text MUST come from the translation files; no screen may contain
  hard-coded text. Server error codes MUST map to translated messages; raw server text MUST NOT be
  shown.
- **FR-012**: Layouts MUST mirror correctly in right-to-left: direction-aware arrows flip; other
  icons do not.
- **FR-013**: Text MUST scale with the device setting up to a maximum of 1.3× without breaking
  layouts.
- **FR-014**: Every icon-only control MUST have a spoken label; touch targets MUST be at least
  48×48 points; field errors MUST be visible as text and announced by screen readers.
- **FR-015**: Numbers, amounts, and dates MUST be formatted in one shared place. Amounts are whole
  piasters with a currency (EGP); times are shown in Cairo time regardless of device time zone.

**Navigation shell**

- **FR-016**: The app MUST show a launch screen using the design system's splash gradient and
  OnAir wordmark, with a matching native launch color so no white flash appears.
- **FR-017**: After launch, the app MUST show a bottom navigation with five tabs in this order
  (right to left): Home, Search, My Bookings, Favorites, My Account. Each tab MUST keep its own
  navigation and scroll state.
- **FR-018**: Home and Search MUST be reachable without an account. My Bookings, Favorites, and My
  Account MUST require an account; tapping them as a visitor opens sign-in and returns to the
  tapped tab afterwards.
- **FR-019**: The Home header MUST include a notifications bell entry point (badge count is
  delivered in a later phase).
- **FR-020**: The app MUST open verified OnAir web links (links proven to belong to OnAir's
  domain, which other apps cannot claim) for the screens in Guest Plan §5.3 marked as linkable, validate any ID format before use, never change
  data based on the link alone, and show a neutral "not available" screen when the item cannot
  be loaded.
- **FR-021**: Links to members-only screens opened by a visitor MUST go through sign-in first and
  then open the linked screen.

**Authentication**

- **FR-022**: Visitors MUST be able to sign up and sign in with an Egyptian mobile number (+20)
  and a 6-digit SMS code, with local format checks before sending. No other country code is
  offered or accepted at launch; the server MUST also reject non-Egyptian numbers.
- **FR-023**: The code entry MUST support paste and system auto-fill, show a server-driven resend
  countdown, and offer "change number".
- **FR-024**: Visitors MUST be able to sign up with name, email, and password, sign in with email
  and password, and recover a forgotten password with a 6-digit code sent by email and entered in
  the app. Recovery and verification emails MUST NOT contain links in G0.
- **FR-025**: Passwords MUST meet a minimum rule (at least 8 characters including at least one
  letter and one digit), shown through a live strength hint; the server is the final judge.
- **FR-026**: Sign-up MUST collect the guest's name and explicit acceptance of the Terms of Use
  and Privacy Policy (both reachable as links). Email sign-up MUST NOT ask for a phone number,
  and phone sign-up MUST NOT ask for an email or password.
- **FR-027**: Email sign-up MUST send a 6-digit verification code by email, entered in the app
  using the same code field, countdown, and limits as phone sign-in (FR-023, FR-029); the account
  MUST show email verification status. Unverified email or phone MUST NOT block browsing or signing in; it blocks
  only booking, which a later phase enforces.
- **FR-028**: Messages for code requests, sign-in failures, and password recovery MUST NOT reveal
  whether a phone number or email is registered.
- **FR-029**: When the server rate-limits an attempt, the app MUST show the remaining wait time
  and keep the action disabled until it ends.
- **FR-030**: Any button that sends a request MUST disable on tap and show an in-button loader
  until a response arrives.
- **FR-031**: The app MUST NOT ask for government ID, social sign-in, or anything beyond the
  approved methods (phone + code, email + password).

**Session & device data**

- **FR-032**: Sessions MUST be stored only in the device's secure storage, renewed automatically,
  and kept across app restarts. A session MUST end after 30 days without the app being opened,
  enforced by the server; the server can also end any session at any time.
- **FR-033**: If a session cannot be renewed, the app MUST end it safely, show "session ended",
  and return the guest to the same screen after they sign in again.
- **FR-034**: Signing out MUST remove the session, unregister the device from the guest's push
  notifications, clear cached personal data, and reset all in-memory state.
- **FR-035**: Only non-sensitive preferences (language, appearance, last search) MAY be kept
  outside secure storage.
- **FR-036**: Logs and crash reports MUST NOT contain personal data (phone, email, names) or
  session tokens. Live builds MUST log only warnings and errors.
- **FR-037**: Code entry screens MUST NOT copy codes to the clipboard, and SHOULD hide their
  content in the system's recent-apps preview.
- **FR-038**: A signed-in guest MUST NOT be able to read another guest's account data, even by
  editing requests by hand; this MUST be proven by an automated test on Staging.

**App-wide states & configuration**

- **FR-039**: Every data-driven foundation screen MUST implement Loading (content-shaped
  skeleton), Empty, Error (message, retry, and reference number for unexpected errors), Offline,
  and Success states.
- **FR-040**: The app MUST show a no-connection banner when offline and disable actions that need
  the server, without relying on connectivity status to decide whether a request succeeded.
- **FR-041**: The app MUST read public app configuration (minimum supported version, support
  phone) from the server and show a blocking "update required" screen when the installed version
  is below the minimum.
- **FR-042**: The app MUST recognise every error code listed in Guest Plan §10.3 and map each to a
  translated message.
- **FR-043**: Every request MUST carry a unique reference ID so support can match a guest's
  reported reference number to server records.

**Contracts & quality**

- **FR-044**: The team MUST draft the request/response contracts the foundation needs (sign-up
  and sign-in, session, device registration, app configuration, error shape) and hand them to the
  backend owner; until the real services exist, development and tests MUST run against a local
  mock built from the same contracts.
- **FR-045**: Every proposed change MUST pass automated checks for formatting, static analysis
  with zero warnings, unit, widget, and visual-comparison tests (light, dark, RTL, large text),
  up-to-date generated code, and forbidden secrets. Any failure MUST block merging.
- **FR-046**: Merging to the main line MUST produce a Staging build for internal testers.

### Key Entities

- **Guest Account**: One personal identity per person. Holds name, phone (with verified status),
  email (with verified status), and acceptance of the current Terms and Privacy Policy version.
  At least one of phone or email is present; the other is optional until added later. A phone or
  email belongs to at most one account.
- **Session**: Proof that a guest is signed in on a device. Has a renewal path, an end state
  ("session ended"), and is tied to one device.
- **Verification Code Request**: A one-time code sent to a phone (or email), with a resend
  countdown, an expiry, an attempt limit, and a rate-limit wait time, all decided by the server.
- **Device Registration**: Links a device's notification address to a guest, with platform and
  language; removed at sign-out.
- **App Configuration**: Public settings from the server: minimum supported version, support
  phone number.
- **Environment**: Staging or Production; defines which backend, notifications project, and
  identifiers a build uses.
- **Error Response**: A code, translation key, reference ID, and details; the shared shape for
  every failure the app shows.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On the Staging build, a new tester can sign up by phone, sign out, and sign in again
  in under 3 minutes on the first attempt, with no help.
- **SC-002**: On a mid-range Android phone, the app goes from tap to the Home tab skeleton in under
  2.5 seconds on a cold start.
- **SC-003**: 100% of foundation screens pass visual comparisons in light, dark, right-to-left,
  and 1.3× text size, with no clipped or overlapping text.
- **SC-004**: 0 hard-coded colors, font sizes, or user-facing texts are found on screens by the
  automated checks.
- **SC-005**: 0 forbidden secrets are found in the repository or in either build.
- **SC-006**: The automated isolation test confirms in 100% of runs that a guest cannot read
  another guest's account data.
- **SC-007**: 100% of changes that fail any quality check are blocked from merging.
- **SC-008**: After sign-out, 0 personal data items or session tokens remain on the device.
- **SC-009**: The phone sign-in journey can be completed end to end with a screen reader
  (TalkBack and VoiceOver) without sighted help.
- **SC-010**: In usability checks, at least 90% of testers correctly understand every
  sign-in error message (wrong code, expired code, wait time, no connection) without extra help.

## Assumptions

- This repository is the Guest App itself; the Owner app, Admin web, and backend are separate
  projects, and the backend is the only integration point (Constitution, Master Plan §13.3).
- A Staging backend with phone (SMS) and email sign-in is available for G0 acceptance. Until it
  is, all work proceeds against the local mock (FR-044); the G0 exit criterion waits for it.
- Backend ownership (Guest Plan §2.3) is still open. The guest developer drafts the contracts;
  the backend owner approves and publishes them.
- The OnAir domain for verified links is not decided yet (Guest Plan §19.2). Link handling is
  built and tested with a configurable domain. Email verification and password recovery use
  emailed codes, so they do not depend on the domain and are fully testable in G0.
- Theme follows the device in G0. A manual light/dark/system choice and a language switch belong
  to Account settings (G4).
- Home, Search, My Bookings, Favorites, and My Account show placeholder content in G0; real
  content arrives in G1–G5.
- Western digits (123) are used until the design decision on numerals (Guest Plan §4.9) is made;
  the choice is applied in one place.
- Phone sign-in accepts Egypt (+20) only at launch. Adding countries later is a product decision
  and needs no change to the sign-in flow beyond the list of accepted countries.
- The password rule in FR-025 is a sensible default; the server's rule wins if it differs.
- The crash-monitoring tool is still open (Crashlytics or Sentry). G0 includes a logging layer
  that can connect to either without screen changes.
- Phone verification required before the first booking (AC-001) is enforced in the booking flow
  (G2); G0 only provides the verification capability and status.
- Account settings beyond sign-out (profile edit, sessions list, change password, delete
  account) are out of scope for G0 and belong to G4.
- Certificate pinning is not used in this phase (Guest Plan §11.3).
