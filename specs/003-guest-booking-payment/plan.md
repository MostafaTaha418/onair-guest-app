# Implementation Plan: Guest Booking & Payment (G2)

**Branch**: `feature/003-guest-booking-payment` | **Date**: 2026-10-30 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-guest-booking-payment/spec.md`

## Summary

Replace the G1 booking-entry placeholder and the G0 "My Bookings" placeholder with the real
booking experience:

- a verify-before-booking step (email code, plus an Egyptian phone confirmed by an email code);
- the date step with server-disabled days and a server quote;
- the booking summary with quote expiry and re-quote with visible changes;
- paying on the Kashier page in a secure in-app browser, a safe return by verified link or by the
  app coming back to the foreground, and a verification screen that waits for the server
  (notification stream + polling with backoff) and shows one of four outcomes;
- recovery of interrupted payments with one attempt key per attempt and an "unfinished payment"
  banner;
- My Bookings (Current / Past / Cancelled), booking details with status message, payments,
  refund stages, saved terms, timeline, and server-decided actions (only "contact support" is
  acted on in G2);
- an offline copy of bookings, and arrival instructions kept only in encrypted storage;
- push permission at the first successful payment, foreground banners, tap-to-open routing, the
  notification center, and a live unread count on the Home bell.

The app stays a display-and-request client:

- **Server decides:** availability, quote amounts, deposit vs. full payment, payment success,
  booking status, tab grouping, owner deadline, allowed actions, refund stages.
- **How the app talks:** quote, booking reads, and notifications through Supabase RPCs
  (`guest_*`, `common_*`); payment start through the Node route
  `POST /v1/guest/bookings/start-payment` (generated client); the only live stream is Realtime
  on the guest's own `notifications` rows.
- **What the app keeps:** a per-guest JSON cache of bookings (no arrival instructions), arrival
  instructions of confirmed bookings in secure storage, and the open payment attempt record in
  secure storage. All of it is removed at sign-out.

**Backend dependency:** the as-built `guest_get_booking` / `guest_list_bookings` (migration
`20261028182013_guest_booking_core.sql`) do not yet return `available_actions`, payments,
refunds, the saved terms, property card fields, or the G2 tab names, and
`private.booking_available_actions` does not exist yet. The required changes are drafted in
[contracts/supabase-booking.md](contracts/supabase-booking.md) for the backend owner; the app
builds and tests against the mock until they ship.

Details: [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/),
[quickstart.md](quickstart.md).

## Technical Context

**Language/Version**: Dart 3.12.2, Flutter 3.44.3 (stable). SDK constraint `^3.12.2`.

**Primary Dependencies**: Existing G0/G1 stack: `flutter_bloc`, `go_router`, `supabase_flutter`
(RPC + Realtime), `dio` + `retrofit` (generated Node client), `freezed` + `json_serializable`,
`flutter_secure_storage`, `firebase_messaging`, `url_launcher` (in-app browser view),
`app_links`, `uuid`, `connectivity_plus`, `intl`, `timezone`, `path_provider`,
`cached_network_image`. New, reviewed in research R14:
- `app_settings`: opens the device's notification settings from the "Notifications are off"
  notice (FR-030).

**Storage**:
- On-disk JSON cache (existing `JsonFileCache`), one file per signed-in guest: bookings list
  pages and viewed booking details, without arrival instructions.
- `flutter_secure_storage`: arrival instructions per confirmed booking (FR-024a) and the open
  payment attempt record (attempt key, quote, property, booking, started at).
- `shared_preferences`: only the "notification permission already asked" flag (non-sensitive).
- All guest data above is removed at sign-out through the existing `PersonalDataResetter`.
- Server: Supabase Postgres + Node integrations service in `onair-backend` (no changes here).

**Testing**:
- `flutter_test` (unit + widget), `bloc_test` (Cubits), `mocktail`, `fake_async` (polling,
  countdown, quote expiry).
- `alchemist` goldens: Light, Dark, RTL, 1.3× text.
- `integration_test`:
  - mock booking journey (Book now → verify → dates → summary → fake payment page → result);
  - Staging journey with the Kashier test account (AC-014, AC-015, AC-016, AC-023);
  - Staging owner-decision checks with seeded bookings (AC-019 to AC-021, AC-024, AC-042);
  - isolation: another guest's booking ID gives "Not available" (AC-007 support, SC-007).

**Target Platform**: Android 7.0+ (API 24) and iOS 15+.

**Project Type**: Mobile app (single Flutter project at repository root).

**Performance Goals**:
- Verification result visible ≤ 10 s after the server confirms while the screen is open
  (SC-005): driven by the notification stream, polling is only the fallback.
- My Bookings shows cached data ≤ 1 s offline (SC-008).
- Countdown and quote timers rebuild only their text (`RepaintBoundary`, no screen rebuilds).
- 60 fps scrolling over long booking and notification lists (cursor pages, `SliverList`).

**Constraints**:
- Server is the authority for every amount, status, deadline, tab, and action (Constitution II).
- The app never sends an amount; payment start sends only `quote_id`, `terms_hash`, and the
  attempt key (Constitution III, AC-016).
- Return from Kashier is never a confirmation; links and push payloads never change state.
- One Realtime subscription per signed-in guest, on `notifications` only.
- No card data in the app; no WebView for payment.
- Arabic RTL; text scale clamped at 1.3; times in `Africa/Cairo`; money as int piasters.
- Remote mode for bookings depends on backend contract changes (see Summary).

**Scale/Scope**:
- **Screens (8):** Verify-before-booking, Date step, Summary, Verification (payment return),
  My Bookings (3 tabs), Booking details, Notification center, plus the in-app notification
  banner and the unfinished-payment banner.
- **Design-system components:** ~8 new (status chip, refund chip, refund stage tracker,
  countdown text, timeline, amount row, info banner, notice card).
- **Backend calls:** RPCs `guest_quote_booking`, `guest_get_booking`, `guest_list_bookings`,
  `guest_get_property_unavailable_dates` (G1), `common_get_my_context`,
  `common_request_phone_change`, `common_verify_otp`, `common_list_notifications`,
  `common_unread_count`, `common_mark_notifications_read`, `common_register_device` (G0); Node
  `POST /v1/guest/bookings/start-payment`, `POST /v1/otp/send`; Realtime on `notifications`.
- **Pilot volume:** a guest has tens of bookings and hundreds of notifications at most.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | How G2 complies | Status |
|---|---|---|
| I. Master Plan fidelity & scope | Implements decisions 100, 101, 104 and Guest Plan §6.6–§6.8, §6.16, §7, §8, §9 only. Pay-first only; no pay-after-approval, no cash at request time, no fees. No owner chat (AC-047). G3/G4/G5 actions are not shown (Clarification). Open items (Kashier capabilities §19.1, link domain §19.2, polling timing §8.4 proposed) stay configurable. | PASS |
| II. Server is the authority | Quote, amounts, deposit, status, tab, deadline, refund stage, and actions all come from the server. `StayRange.nights` is display-only on the date step. Countdown end triggers a refetch, never a local status change. Links and push payloads are navigation hints; data is fetched under RLS. | PASS |
| III. Payment integrity | Start sends only `quote_id` + `terms_hash` + attempt key; one UUID v4 per attempt, reused on every retry and persisted until a final result. Button disabled on tap. "Verifying" until the server says otherwise; no "Pay again" while verifying. Kashier page in Custom Tabs / SFSafariViewController; card data never touches the app. | PASS |
| IV. Security & privacy | Anon key only. Bookings read only through `guest_*` functions (no direct `bookings` select). Booking IDs from links are UUID-validated; refused fetches show the neutral screen. Arrival instructions only in secure storage, purged on sign-out and on terminal status. Push payload `type` + `target_id` only. Diagnostics carry IDs only. | PASS |
| V. Design system | New chips, stage tracker, countdown, timeline, amount row, banners, and notice live in `lib/design_system/components/` with primitives only; booking status colors from the existing status-chip tokens (Guest Plan §4.6). | PASS |
| VI. Arabic-first, RTL & a11y | All copy in `.arb`, including status messages (§7.2) and per-type notification texts. Countdown announces as text, not per-second live region. Semantics for copy-booking-number, close, bell, and banner actions. Goldens at 1.3×. TalkBack/VoiceOver pass on book → pay → result. | PASS |
| VII. Layered, feature-first | `features/booking` (flow), `features/bookings` (list/details), `features/notifications` (center, banner, routing), `core/realtime`, `core/push` (permission + messages). Widgets → Cubits → repository interfaces; Supabase/Node and mock implementations chosen in `bootstrap`. New error codes through `ErrorMapper`. | PASS |
| State management | Cubits per screen; `BookingFlowCubit` scoped to the `/book/:propertyId` route branch so verify → dates → summary share the draft; `PaymentAttemptCubit` app-scoped (survives navigation and app resume); `UnreadCountCubit` app-scoped. `close()` cancels timers and subscriptions. | PASS |
| VIII. UX states & performance | Skeletons, empty (with "Find an apartment"), error with reference, offline banner with "Last updated", in-button loaders. Stale-while-revalidate for My Bookings. Timers rebuild text only. | PASS |
| IX. Test discipline | Test-first for attempt-key lifecycle, verification outcome mapping, polling backoff, quote-change diff, action filtering, notification routing table, and secure-storage purge rules. Widget tests for every screen state; goldens for new components; Staging tests for AC-014 to AC-024 and AC-042 guest side. Mock follows the same contracts and fixtures. | PASS |
| Repository constraints | No backend files here (AGENTS.md). Required RPC changes are drafted in `contracts/` for the backend owner; the Node contract already matches. | PASS |

No violations. Complexity Tracking is empty.

### Post-design re-check (after Phase 1)

The design artifacts keep every row above at PASS. Points checked specifically:

- **Server authority (II)**: [data-model.md](data-model.md) holds no derived amount. The
  re-quote diff compares two server quotes field by field and only highlights; it never
  computes a new value. Tab membership is the server's `tab` parameter, not a client filter.
- **Payment integrity (III)**: the attempt record is created before the first start request and
  deleted only on a final server outcome, sign-out, or "Try again" (which creates a new key).
  The verification outcome table in data-model §6 never maps a link parameter to a result.
- **Privacy (IV)**: `access_instructions` is stripped from the booking JSON before it reaches
  the file cache; only `ArrivalInstructionsStore` (secure storage) keeps it. Isolation and
  forbidden-field tests are listed in [contracts/supabase-booking.md](contracts/supabase-booking.md) §8.
- **Backend agreement (Workflow)**: Remote mode for My Bookings and the verification outcomes
  depends on deltas D0–D4 in `supabase-booking.md`. The quote and payment start already exist
  and can be exercised on Staging now.

## Project Structure

### Documentation (this feature)

```text
specs/003-guest-booking-payment/
├── plan.md              # This file
├── research.md          # Phase 0: decisions + rationale
├── data-model.md        # Phase 1: entities, validation, state
├── quickstart.md        # Phase 1: setup + validation scenarios
├── contracts/           # Phase 1: draft backend + app contracts
│   ├── supabase-booking.md     # RPCs used, as-built vs required (D0–D5), errors, tests, seed
│   └── app-routes.md           # G2 routes, payment return link, notification routing table
├── checklists/requirements.md
└── tasks.md             # Phase 2 ($speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── app/router/
│   ├── routes.dart                 # + /book/:propertyId/verify, /book/:propertyId/summary,
│   │                               #   /notifications; /book/:propertyId/dates becomes real
│   ├── app_router.dart             # booking branch (ShellRoute scoping BookingFlowCubit),
│   │                               #   real /bookings, /bookings/:id, /payment/return
│   └── notification_router.dart    # NEW: type_key + entity → location (contracts/app-routes §4)
├── core/
│   ├── realtime/notification_stream.dart   # NEW: single per-guest Realtime channel
│   ├── push/push_messages.dart             # NEW: foreground / opened / initial messages
│   ├── push/notification_permission.dart   # NEW: ask once, status, open settings
│   ├── payments/in_app_browser.dart        # NEW: interface over url_launcher in-app view
│   ├── time/countdown.dart                 # NEW: server deadline → remaining (Cairo clock)
│   └── errors/error_mapper.dart            # + G2 codes (contracts/error-codes.md rows)
├── design_system/components/
│   ├── booking_status_chip.dart  refund_status_chip.dart  refund_stage_tracker.dart
│   ├── countdown_text.dart  booking_timeline.dart  amount_row.dart
│   └── info_banner.dart  notice_card.dart
├── features/
│   ├── booking/                    # the flow: verify → dates → summary → pay → verify result
│   │   ├── domain/   booking_draft, booking_quote, quote_change, payment_attempt,
│   │   │             verification_outcome, booking_flow_repository (interface)
│   │   ├── data/     supabase_booking_flow_repository.dart (RPC + Node client),
│   │   │             mock_booking_flow_repository.dart, payment_attempt_store.dart
│   │   └── presentation/ booking_flow_cubit, verify_identity_cubit, payment_attempt_cubit,
│   │                 payment_verification_cubit, verify_identity_screen, dates_screen,
│   │                 summary_screen, payment_return_screen, widgets/
│   ├── bookings/                   # My Bookings + details
│   │   ├── domain/   booking_summary, booking_details, booking_status, booking_action,
│   │   │             payment_line, refund_info, booking_event, bookings_repository
│   │   ├── data/     supabase_bookings_repository.dart, mock_bookings_repository.dart,
│   │   │             bookings_cache.dart, arrival_instructions_store.dart, fixtures/
│   │   └── presentation/ bookings_cubit, booking_details_cubit, bookings_screen,
│   │                 booking_details_screen, unfinished_payment_banner, widgets/
│   ├── notifications/
│   │   ├── domain/   app_notification, notifications_repository
│   │   ├── data/     supabase_notifications_repository.dart, mock_notifications_repository.dart
│   │   └── presentation/ notifications_cubit, unread_count_cubit, notifications_screen,
│   │                 in_app_notification_banner, notifications_off_notice
│   ├── home/presentation/widgets/  # bell count + upcoming card + unfinished banner wired
│   └── account_gate/application/personal_data_resetter.dart  # + bookings/attempt/arrival purge
└── l10n/app_ar.arb, app_en.arb     # + booking, status messages, notification texts

test/                               # mirrors lib/ (unit, widget, goldens)
integration_test/
├── booking_journey_mock_test.dart      # full flow on mock incl. interruptions (US6)
├── booking_payment_staging_test.dart   # Kashier test account: AC-014/015/016/023
├── booking_outcomes_staging_test.dart  # seeded outcomes: AC-019/020/021/024/042
└── booking_isolation_test.dart         # other guest's booking → Not available
```

**Structure Decision**: The single Flutter project is extended in place, keeping the G0/G1
layout. The booking flow (`features/booking`) and the booking records (`features/bookings`) are
separate features because the flow is a short-lived draft scoped to one route branch, while
records are long-lived, cached, and reached from tabs, banners, and notifications.
Notifications get their own feature since the center, banner, unread count, and routing are used
by every later phase. Realtime and push plumbing live in `core/` so features never subscribe on
their own (one channel per guest, Guest Plan §12.3).

## Complexity Tracking

No constitution violations to justify.
