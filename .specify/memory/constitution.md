# OnAir Guest App Constitution

This constitution governs the **OnAir Guest App** (تطبيق المستأجر) — the Flutter mobile app
used by guests to discover, book, pay for, and manage short-term apartment stays. Each OnAir app
(Guest, Owner/Office, Admin web) is an independent project in its own repository. The apps share
no code and integrate **only through the OnAir backend** (Supabase + Node services).

**Source priority** (highest first):

1. `docs/OnAir Master Plan.md` — final authority for every business rule.
2. `docs/OnAir Guest App Plan.md` — translates Master Plan rules into guest screens,
   architecture, and tasks.
3. `docs/UI_UX_DESIGN_SYSTEM.md` — authority for colors and typography.

When sources conflict, the higher source wins. Repository layout follows Master Plan §13.3 and
Guest Plan §2.2/§2.4: one repository per app (see "Technology Stack & Repository Constraints").

## Core Principles

### I. Master Plan Fidelity & Guest Scope

- Every feature MUST trace to an approved Master Plan decision or a Guest App Plan item.
  Developers MUST NOT invent business rules, fees, prices, statuses, or policies.
- Plan items tagged **[معتمد]** (approved) MUST NOT be changed by a developer. Items tagged
  **[تطبيق مقترح]** (proposed implementation) MAY be refined through a recorded engineering
  decision. Items tagged **[يُحسم أثناء التنفيذ]** (to be decided) MUST NOT be filled with
  invented values; they stay configurable or blocked until decided.
- The following MUST NOT be built (Guest Plan §1.2): direct guest↔owner chat or messaging
  (AC-047), pay-after-owner-approval, "cash on arrival" at request time, weekday/seasonal
  pricing, service/cleaning/tax fees not in the plan, government ID upload, mandatory OTP or
  photos for check-in, interactive price-pin map, social login, VIP features, offers/discounts.
- Design tokens without a product decision (VIP, Offer, Discount, Social, Auth Card) MAY exist
  in code but MUST NOT drive any feature.

**Rationale:** The guest app is one of three clients over one platform. Rules invented in one
client break consistency, money flows, and trust.

### II. Server Is the Authority (NON-NEGOTIABLE)

> The app displays and requests. The server decides.

- The app MUST NOT compute or decide: final price, totals, deposit/remaining amounts, refund
  amounts, payment success, booking status transitions, or which actions are allowed.
- Available booking actions MUST be rendered from the server's `available_actions`. Hiding a
  button is UX, never security; the server rejects unauthorized requests (AC-007).
- The client is always untrusted. No price, amount, status, or permission sent by the app may
  be relied on by the server.
- Deep links and push payloads MUST NOT change state. IDs from links (`:id`, `intent`) are
  navigation hints only; data is fetched under RLS, and a rejected fetch shows a neutral
  "not available" screen without revealing whether the record exists.
- Guest-side acknowledgements (check-in, check-out) MUST NOT be shown as final until the server
  confirms the resulting state (AC-026/027).

**Rationale:** Money and booking state must have one source of truth. A modified client must
not be able to change either.

### III. Payment Integrity (NON-NEGOTIABLE)

- Returning from the Kashier page is NOT confirmation. The UI MUST show "verifying" until the
  server confirms (AC-015).
- The app MUST send only `quote_id`, `terms_version_id`, and `idempotency_key` — never an
  amount (AC-016).
- Each booking attempt MUST generate one UUID v4 `idempotency_key`, persisted until the attempt
  ends. Retries and double taps MUST reuse it (AC-023).
- Pay buttons MUST disable on first tap until a response arrives.
- The app MUST NOT see, handle, or store card data. Kashier opens in an in-app browser
  (Custom Tabs / SFSafariViewController), not a WebView, unless a recorded decision changes it.
- During `payment_verifying` the app MUST NOT offer "pay again". Verification uses Realtime plus
  backoff polling, with a clear timeout message that tells the guest not to pay again.
- Payment return MUST use verified App Links / Universal Links, not custom URL schemes.
- An open payment intent found on app launch or resume MUST route the guest to verification.

**Rationale:** Double charges and false "paid" states are the most damaging failures this app
can produce.

### IV. Security & Privacy by Default (NON-NEGOTIABLE)

- **Secrets:** The app MAY contain only the Supabase URL, the Supabase **anon key**, the Node API
  base URL, and public Firebase config. `service_role`, Kashier, Resend, SMS, or any provider
  secret MUST NEVER appear in source, assets, or builds. CI MUST scan for forbidden key patterns.
- **Environment files** (`env/*.json`) MUST stay out of Git and be injected by CI secrets.
- **Session:** Tokens MUST be stored only in `flutter_secure_storage` (Keychain
  `first_unlock_this_device` / Android Keystore). `shared_preferences` MAY hold only
  non-sensitive preferences (language, theme, last search).
- **Logout** MUST delete the session, unregister the device push token, clear local caches
  (bookings, notifications), and reset all providers.
- **Network:** HTTPS only (Android cleartext disabled; iOS ATS without exceptions). Every request
  carries a `request_id`. Certificate pinning is deferred until a key-rotation plan exists.
- **Logs & crash reports** MUST NOT contain PII (phone, email, names) or tokens. Release builds
  log `warning`/`error` only. Booking-related reports MAY include IDs only.
- **Push content** MUST NOT contain sensitive data; payload is limited to `type` + `target_id`.
- **Auth UX** MUST NOT reveal whether a phone or email is registered. Server rate limits are
  shown as remaining time with disabled actions. OTPs are never auto-copied to the clipboard.
- **Uploads:** client-side type/size checks for UX only. EXIF (including GPS) MUST be stripped
  before upload. Private attachments use short-lived signed URLs and are never cached
  persistently.
- **Inputs from links** MUST be format-validated (e.g., UUID) before use.
- **Build hardening:** Release builds MUST use `--obfuscate --split-debug-info`, R8 enabled,
  `allowBackup` disabled or excluding secure storage, no debug tools or screens.
- **Privacy:** No location permission in v1. No ad tracking. Analytics only with consent and
  without PII. Store privacy manifests and Data Safety forms MUST match actual behaviour.

**Rationale:** The app handles identity, bookings, and payments for real people. A leak or
spoofed state is a legal and trust failure, not a bug.

### V. Design System Compliance

- All colors MUST come from the `OnAirColors` `ThemeExtension` (light and dark variants) built
  from `docs/UI_UX_DESIGN_SYSTEM.md`. Screens MUST NOT contain `Color(0x...)` literals or raw
  hex values; they read from `context.colors` / `Theme.of(context)`.
- Typography MUST use **Cairo**, bundled as an asset (no runtime font fetching), with only the
  weights in use (400, 500, 600, 700, 800). Text styles come from the design system `TextTheme`
  and `OnAirTextStyles`; screens MUST NOT hard-code font sizes or weights.
- Gradients (Splash, Header, Auth Button, Reviews, FAQ Hero) MUST be used only where the design
  system and Guest Plan §4.3 specify.
- Every screen MUST work in both Light and Dark modes.
- Booking and refund status MUST use `BookingStatusChip` / `RefundStatusChip` with the token
  mapping in Guest Plan §4.6. The refund chip is always separate from the booking chip. Status
  MUST NOT be conveyed by color alone; each chip carries text, preferably an icon.
- Values the design file does not define (spacing on a 4-pt grid, radii, elevation, Material
  Symbols Rounded icons) follow Guest Plan §4.5 as provisional tokens, centralized so a designer
  change is a one-file edit.
- Known contrast issues (Guest Plan §4.8) MUST use the proposed accessible fallbacks until the
  designer decides: Light error text `#C62828`; Dark muted text `#E0E0E0`.
- Reusable UI (buttons, fields, OTP field, cards, chips, nav, state views, countdown, timeline,
  price breakdown) MUST live in the app's design system module, not be re-implemented per
  screen.

**Rationale:** One token source keeps both themes consistent and lets design changes land
without hunting through screens.

### VI. Arabic-First, RTL & Accessibility

- Arabic is the default locale with native RTL. i18n via `.arb` files MUST be in place from the
  start so English can be enabled without refactoring.
- Every user-facing string MUST come from localization files. Hard-coded UI text is forbidden.
  Server error `code`s map to localized messages; raw server text is never shown.
- Layout MUST use directional APIs (`EdgeInsetsDirectional`, `AlignmentDirectional`,
  `start`/`end`), never `left`/`right`. Directional icons mirror; non-directional icons do not.
- Guest copy MUST be plain Arabic without accounting terms (no «قيد»، «ذمة»، «استحقاق»).
- Numbers, money, and dates MUST be formatted in one shared place (`intl`). Money displays in
  EGP; times display in `Africa/Cairo` regardless of device timezone.
- Text scaling MUST NOT be locked. It MAY be clamped (target max ≈1.3) and every screen MUST be
  verified at the largest supported scale.
- Every icon-only control MUST have a `Semantics` label. Touch targets MUST be at least 48×48.
  Field errors MUST be visible as text and announced to screen readers. Focus order MUST be
  logical in RTL.
- The core journey (search → details → booking → payment) MUST be tested with TalkBack and
  VoiceOver before the pilot.

**Rationale:** The audience is Arabic-speaking. RTL and accessibility retrofitted later cost far
more than building them in.

### VII. Layered, Feature-First Architecture

- Code is organized feature-first (`features/<name>/{data,domain,presentation}`).
- Widgets MUST NOT call Supabase, Dio, or any data source directly. Repositories are the only
  layer that knows where data comes from.
- An application/use-case layer is added only when real orchestration exists (e.g., the payment
  journey). Pass-through use cases are forbidden.
- Approved stack: Riverpod (with code generation) for state, `go_router` for navigation, guards,
  and deep links (`StatefulShellRoute` for bottom nav), `freezed` + `json_serializable` for
  immutable models, `supabase_flutter` for auth and RLS reads, `dio` for Node commands.
- **Money** MUST be an integer in the smallest unit (piasters) with a currency code, wrapped in
  a `Money` value object. `double` for money is forbidden.
- **Stay dates** (arrival/departure) MUST be date-only values with no time or timezone.
  Timestamps (deadlines, events) are UTC ISO-8601 from the server.
- Errors follow the unified shape (`code`, `message_key`, `request_id`, `details`). The app MUST
  handle every code listed in Guest Plan §10.3.
- The design system and core (networking, auth/session, errors, Money, date formatting,
  logging, env) are internal modules of this app. They MUST NOT import feature code, so features
  depend on them and never the reverse.
- Adding a dependency requires review of app-size impact, maintenance health, and security.
  Versions are locked via `pubspec.lock`.
- Generated API clients and models MUST NOT be edited by hand.

**Rationale:** Strict layering keeps data access testable and replaceable (mock server →
staging → production) and keeps money and date bugs out of the UI.

### VIII. Complete UX States & Performance

- Every data-driven screen MUST implement Loading (skeleton matching the content shape, not a
  centered spinner), Empty (icon, clear sentence, action), Error (clear message, retry, and the
  `request_id` for unexpected errors), Offline (top banner, cached data, server actions
  disabled), and Success states.
- In-flight actions MUST disable their trigger and show an inline loader to prevent double
  submission.
- A "minimum supported version" check MUST block use with a full-screen update prompt.
- Lists MUST use lazy builders (`ListView.builder` / slivers) and cursor pagination.
- Images MUST be requested at the size they render (`width × devicePixelRatio`) with decode-size
  limits and themed placeholders. Large bundled images are forbidden.
- Requests MUST be cancelled when their screen is disposed. Reference lists are cached long;
  home and bookings use stale-while-revalidate. Queries select only needed columns.
- Realtime subscriptions are allowed only on payment verification and an open booking's
  details, and MUST close on exit.
- Widgets use `const` wherever possible, `select` to narrow rebuilds, small widget classes
  instead of `_buildX()` helpers, and `RepaintBoundary` around animated elements. Countdowns
  rebuild only their text.
- Internal targets (measured in Profile mode on a mid/low-end Android device, reviewed after the
  pilot): cold start to home skeleton < ~2.5 s; scrolling at 60 fps without noticeable jank;
  Android per-ABI size < ~30 MB, with growth tracked every release.

**Rationale:** Guests book on mid-range phones over mobile networks. Missing states and jank read
as a broken app at the moment money is involved.

### IX. Test Discipline & Acceptance Traceability

- Domain value objects (Money, DateRange, night calculation for display), error-code mapping,
  router guards, and payment-flow logic MUST be developed test-first (red → green → refactor).
- Every screen MUST have widget tests covering Loading, Empty, Error, Offline, and Success.
- Design-system components and key screens MUST have golden tests in Light + Dark, RTL, and
  enlarged text.
- Security tests MUST prove: a guest cannot read another guest's booking by ID; a forged deep
  link changes nothing; repeated payment taps create one payment session.
- Each feature MUST list the Master Plan acceptance criteria it covers (Guest Plan §14.2) and
  include tests for them. Booking/payment journeys run end-to-end on Staging with the Kashier
  test account.
- Until real services are ready, development and widget tests run against a local mock server
  built from the same API contracts.

**Rationale:** Payment, isolation, and state rules are only real if a test proves them. Acceptance
criteria are the shared contract with the rest of the team.

## Technology Stack & Repository Constraints

- **Repository scope:** This repository contains the **Guest App only**. The Owner/Office app
  and Admin web are separate projects in separate repositories (project owner, 2026-10-26).
  - This repository MUST NOT depend on code from any other OnAir app repository, and other apps
    do not depend on it. There are no cross-repo shared packages.
  - The **backend is the only integration point**. The guest app talks to the Supabase schema
    (under RLS) and the Node/RPC commands, following the API contracts the backend publishes.
    Dart models/clients generated from those contracts MUST NOT be edited by hand.
  - Booking status names, error codes, and contract shapes come from the backend, so all apps
    stay consistent without sharing code.
- **Platform:** Flutter / Dart (SDK `^3.12.2`), Android and iOS. Other platform folders are not
  release targets for this app.
- **Backend:** Supabase (Postgres, Auth, RLS, Realtime) for reads under RLS; Node.js services
  (or secure RPC) for all sensitive commands; Kashier for payments; FCM/APNs for push;
  Cloudflare for media.
- **Environments:** Staging and Production flavors with separate app IDs, Supabase projects,
  API URLs, Firebase projects, and Kashier modes. Config via `--dart-define-from-file`.
- **Crash monitoring:** exactly one tool for this app, aligned with the team where possible.
  TODO(CRASH_TOOL): Crashlytics or Sentry, to be decided with the team.
- **Open decisions that MUST NOT be invented:** backend ownership (TODO(BACKEND_OWNERSHIP)),
  deep-link domain (TODO(DEEP_LINK_DOMAIN)), numeral style (TODO(DIGITS)), Kashier return-URL
  format and capabilities, support contact details, and the remaining items in Guest Plan §19.
  Code MUST keep these configurable or behind a clear placeholder until decided.

## Development Workflow & Quality Gates

- **Spec-driven flow:** features go through Spec Kit (`/speckit-specify` → `/speckit-plan` →
  `/speckit-tasks` → `/speckit-implement`). Every plan MUST pass the Constitution Check against
  Principles I–IX before design and again before implementation.
- **Delivery order** follows Guest Plan §17 phases: G0 Foundation → G1 Discovery → G2 Booking &
  Payment → G3 Stay & Cancellation → G4 Support & Account → G5 Favorites & Reviews → G6 Pilot
  readiness.
- **CI gates on every PR (all MUST pass):** `dart format --set-exit-if-changed`,
  `flutter analyze` with strict lints and zero warnings, unit + widget + golden tests,
  forbidden-secret scan, and an up-to-date `build_runner` output check.
- **Definition of Done (Guest Plan §20)** — a feature is done only when:
  matches the Master Plan with no invented rules; all UX states implemented; Light, Dark, RTL,
  and large text work; no hard-coded colors, font sizes, or UI strings; no client-side
  money/status/permission decisions; sensitive actions are idempotent and double-tap safe; no PII
  in logs or crash reports; required tests pass and linked ACs are tested; interactive elements
  have semantics; no noticeable jank in Profile mode; PR reviewed; plan/decision docs updated
  when an open point is resolved.
- **Review:** every PR needs review by another developer. Money, payment, or security-related
  changes require an explicit security-focused review. Any change that needs a new or changed
  backend contract MUST be agreed with the backend owner before the app depends on it.
- **Decisions:** resolving any `[يُحسم أثناء التنفيذ]` item or changing a `[تطبيق مقترح]` item
  MUST produce a short decision record and an update to the Guest App Plan.
- **Release:** signed production builds from CI only; obfuscation symbols uploaded; store
  rollout through testing tracks first; signing keys and env files stored only in CI secrets.

## Governance

- This constitution supersedes conflicting practices, conventions, and ad-hoc instructions for
  this repository. It does not override the Master Plan's business decisions; it enforces them.
- **Amendments** require: a written proposal stating the change and its reason, review by at
  least one other team developer (and the project owner for scope or product-facing changes),
  an updated Sync Impact Report, and a migration note for any existing code that no longer
  complies.
- **Versioning** follows semantic versioning:
  MAJOR — a principle removed or redefined in a backward-incompatible way;
  MINOR — a principle or section added, or guidance materially expanded;
  PATCH — clarifications and wording fixes with no change in meaning.
- **Compliance:** every Spec Kit plan runs the Constitution Check; every PR review confirms the
  Definition of Done. Any deviation MUST be justified in the plan's Complexity Tracking table
  with the simpler alternative that was rejected. Unjustified violations block merge.
- **Runtime guidance:** use `docs/OnAir Guest App Plan.md` for day-to-day implementation detail
  and `docs/UI_UX_DESIGN_SYSTEM.md` for visual tokens. Compliance is reviewed at the end of each
  G-phase.

**Version**: 1.0.0 | **Ratified**: 2026-10-26 | **Last Amended**: 2026-10-26
