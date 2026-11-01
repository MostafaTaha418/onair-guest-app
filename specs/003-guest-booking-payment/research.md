# Research: Guest Booking & Payment (G2)

Phase 0 output. Each decision records what was chosen, why, and what else was considered.
The Technical Context had no open `NEEDS CLARIFICATION` items (the five spec clarifications of
2026-10-30 settled scope, the unfinished-payment display, later-phase actions, offline arrival
instructions, and declined push permission). The topics below are design choices needed before
Phase 1. Backend facts come from the read-only checkout of `onair-backend` (contracts `rpc.md`,
`node-api.openapi.yaml`, migration `20261028182013_guest_booking_core.sql`).

## R1. Which backend calls the flow uses

- **Decision**:
  - Quote: RPC `guest_quote_booking(p_property_id, p_check_in, p_check_out, p_guests,
    p_terms_hash)` (exists).
  - Payment start: Node `POST /v1/guest/bookings/start-payment` with `quote_id`, `terms_hash`,
    `idempotency_key` → `PaymentSession` (exists; it calls `guest_start_booking` with the
    guest's session and creates the Kashier session). Called through the generated Retrofit
    client in `lib/core/api/generated/`.
  - Reads: `guest_get_booking(p_booking_id)` and `guest_list_bookings(p_tab, p_cursor)` (exist,
    but need the changes in R2).
  - Unavailable days: `guest_get_property_unavailable_dates` (G1).
  - Verification step: `common_get_my_context()`, Supabase Auth email OTP (G0),
    `common_request_phone_change` → `POST /v1/otp/send` → `common_verify_otp`.
- **Rationale**: These are the names in the Backend Master Plan §12 and the generated catalog.
  The Node route is the only place that can create the Kashier session (provider secret); the app
  never calls `guest_start_booking` directly, so a booking without a session cannot be created
  from the app.
- **Alternatives considered**: calling `guest_start_booking` then a separate "create session"
  route — two round trips and a window with an orphan booking; rejected.

## R2. Gap between the as-built booking reads and G2 needs

- **Decision**: Draft six contract deltas (D0–D5) for the backend owner
  ([contracts/supabase-booking.md](contracts/supabase-booking.md) §4):
  - **D0** `guest_quote_booking` adds `remaining_due_at` and `policy_summary`.
  - **D1** `guest_get_booking` adds `available_actions`, property card fields (cover image,
    area/city, address text, check-in/out times), `remaining_minor` + `remaining_due_at`,
    `payments[]`, `refund` (amount + stage), `terms_snapshot` (policy summary shown at booking),
    and a guest-safe `payment_state` (`pending` / `failed` / `succeeded`).
  - **D2** `guest_list_bookings` adds `title`, `cover_image`, `refund_status`, the owner
    deadline, and accepts the G2 tab values `current`, `past`, `cancelled`, `pending`.
  - **D3** `private.booking_available_actions(booking_id, 'guest')` exists and feeds D1/D2.
  - **D4** A notification row is written for `payment.failed` and for the `awaiting_owner` /
    `payment_conflict` transitions with `entity_type = 'booking'` (already in the matrix; needs
    confirmation that the Realtime row is inserted for the guest audience).
  - **D5** `guest_list_bookings` page size and cursor documented (as-built: 30, `created_at`).
- **Rationale**: The as-built `guest_get_booking` returns only core fields and events;
  `private.booking_available_actions` is named in the Backend Master Plan §6 but no migration
  defines it. The as-built tabs are `upcoming` (awaiting_owner, confirmed, checked_in), `past`
  (completed + all cancelled-like) and `pending` (payment_pending, payment_verifying), which do
  not match the spec's Current / Past / Cancelled with "verifying" in Current.
- **Alternatives considered**:
  - Re-grouping tabs in the app from `p_tab = null`: the app would decide grouping
    (Constitution II) and paging would break across tabs; rejected.
  - Deriving actions in the app from status: forbidden (Constitution II, AC-007).
- **Interim**: The mock implements D1–D3 exactly. Remote mode for My Bookings is switched on
  only after D1–D3 are deployed; quote and payment start can be tested on Staging now.

## R3. Tab mapping

- **Decision** (requested in D2): `current` = `payment_verifying`, `awaiting_owner`,
  `confirmed`, `checked_in` (nearest check-in first); `past` = `completed` (newest first);
  `cancelled` = `rejected`, `expired`, `cancelled`, `no_show`, `payment_conflict` (newest first);
  `pending` = `payment_pending` only, used by the unfinished-payment banner. `abandoned` (never
  paid, timed out) appears nowhere.
- **Rationale**: Matches Guest Plan §6.7 and the clarification that unfinished payments are a
  banner, not a card. `payment_conflict` was paid and is being refunded, so the guest must find
  it; it belongs with the other "did not happen" outcomes.
- **Alternatives considered**: showing `abandoned` in Cancelled — nothing was charged and it
  would add noise; rejected.

## R4. Opening the Kashier page and returning

- **Decision**: Open `payment_url` with `url_launcher` in `LaunchMode.inAppBrowserView`
  (Chrome Custom Tabs on Android, `SFSafariViewController` on iOS) behind an `InAppBrowser`
  interface. Return is detected two ways:
  1. the verified link `https://<LINK_DOMAIN>/payment/return?booking=<uuid>` handled by the G0
     link pipeline; and
  2. `AppLifecycleState.resumed` while a payment attempt is open → go to `/payment/return`.
  Both lead to the same screen, which reads status from the server only.
- **Rationale**: Guest Plan §8.3 recommends in-app browser (visible address, no app access to
  page content, 3-D Secure and bank apps work). `url_launcher` is already a dependency.
- **Alternatives considered**: WebView (some banks block it, address hidden, app can read the
  page); custom scheme `onair://` (any app can claim it). Both rejected.
- **Open**: Kashier return URL format and Custom Tabs support (Guest Plan §19.1). If the return
  link cannot be configured, the lifecycle path alone still works.

## R5. Attempt key and the open-attempt record

- **Decision**: Generate one UUID v4 (`uuid` package) when the guest first taps "Go to payment"
  for a quote, and save a `PaymentAttempt` record in `flutter_secure_storage` before sending the
  request: `{attemptKey, quoteId, propertyId, termsHash, bookingId?, paymentUrl?, startedAt}`.
  Every retry (double tap, network error, app restart) reuses the key. The record is deleted on
  a final outcome (success, conflict, or failed + "Try again"), on sign-out, or when the server's
  `pending` tab no longer lists the booking. "Try again" creates a new key (and a new quote if
  the old one expired).
- **Rationale**: AC-023 requires the same key across retries, including after the app is
  killed. The record holds a booking ID tied to a person, so it is not a "non-sensitive
  preference" and does not go to `shared_preferences` (Constitution IV).
- **Server is still the source of truth**: on app start the app asks `guest_list_bookings('pending')`
  (and `current` for `payment_verifying`) and reconciles the local record with it; the banner is
  driven by the server answer, not by the local record alone.
- **Alternatives considered**: key per booking screen visit (breaks after restart); key in memory
  only (breaks after kill); rejected.

## R6. Verification screen: stream + polling

- **Decision**: `PaymentVerificationCubit` listens to the app-wide `NotificationStream`
  (R9) and refetches `guest_get_booking` when a row arrives with `entity_id = booking_id`. In
  parallel it polls with backoff 2 s, 4 s, 8 s, 16 s, 30 s, 30 s, 30 s (≈ 120 s total), each
  poll skipped if a fetch is in flight. Outcome mapping (data-model §6) uses only server fields
  `status` and `payment_state`.
- **Rationale**: Guest Plan §8.4. Realtime is fast (SC-005) but can drop; polling bounds the
  wait. Two minutes matches the plan's proposal and is a single constant.
- **Alternatives considered**: Realtime on `bookings` (no direct select — margin columns);
  polling only (slow, more load); rejected.

## R7. Quote expiry and re-quote

- **Decision**: The summary keeps the server's `expires_at`. Before sending payment start, and
  when a local timer reaches `expires_at - 30 s`, the app requests a new quote with the same
  inputs. A `QuoteChange` compares old and new quotes field by field (nightly, total, pay now,
  remaining, due date, terms hash); any difference is highlighted and "Go to payment" requires
  an explicit "Confirm new amounts". `QUOTE_EXPIRED` from payment start triggers the same path.
- **Rationale**: FR-009, Guest Plan §6.6 step 2 and §8.5. The 30 s margin absorbs device clock
  skew; the server still rejects an expired quote.
- **Alternatives considered**: computing remaining time from device clock only (skew); silent
  re-quote (violates "show changes before paying"); rejected.

## R8. Verify-before-booking step

- **Decision**: Route `/book/:propertyId/verify` (Guest Plan names it `verify-phone`; renamed
  because it also covers email). Entry check uses `common_get_my_context()` flags. Email: the G0
  email-code screen in "verify" mode. Phone: number + "has WhatsApp" toggle or optional WhatsApp
  number → `common_request_phone_change` → `POST /v1/otp/send` → code → `common_verify_otp`.
  The step returns to the location it came from (dates or summary) with the draft unchanged; a
  `PHONE_NOT_VERIFIED` / `EMAIL_NOT_VERIFIED` error at payment start opens it with
  `returnTo=summary`.
- **Rationale**: Clarification 2026-10-30 (sign-up rework is separate); the RPCs already exist.
  Reusing the G0 OTP widget keeps rate-limit and resend behaviour identical.
- **Alternatives considered**: sending guests to the account screen (loses the flow); rejected.

## R9. One notification stream per guest

- **Decision**: `core/realtime/notification_stream.dart` opens one Supabase Realtime channel on
  `public.notifications` filtered by `user_id = auth.uid()` after sign-in, closes it at sign-out,
  and exposes a broadcast `Stream<NotificationSignal>` (`id`, `typeKey`, `entityType`,
  `entityId`). Consumers: `UnreadCountCubit`, `PaymentVerificationCubit`, the open
  `BookingDetailsCubit`, and `NotificationsCubit`. RLS limits rows to the guest.
- **Rationale**: Guest Plan §12.3 (one subscription). `notifications` is already in the
  `supabase_realtime` publication (migration `20261028182417`).
- **Alternatives considered**: a channel per screen (many sockets, missed events between
  screens); rejected.

## R10. Push messages, permission, and routing

- **Decision**:
  - Permission: `FirebaseMessaging.requestPermission()` (covers iOS and Android 13+
    `POST_NOTIFICATIONS`) called once, after the first success outcome, behind a short
    explanation sheet. A preference flag records that it was asked. If denied (in-app or
    system), never ask again; the notification center shows a notice with a button that opens
    the device's notification settings (`app_settings`), hidden once
    `getNotificationSettings()` reports authorized.
  - Registration: on grant, call the existing `DeviceRegistrationService.registerAfterSignIn()`;
    token refresh is already handled (G0).
  - Foreground (`onMessage`): show `InAppNotificationBanner` (overlay, auto-dismiss) and emit a
    signal so open screens refresh. No local-notification package.
  - Opened (`onMessageOpenedApp`, `getInitialMessage`): `NotificationRouter` maps `type` +
    `target_id` to a location ([contracts/app-routes.md](contracts/app-routes.md) §4); the G0
    redirect enforces sign-in and returns to it.
- **Rationale**: FR-030 to FR-035 and the clarification on declined permission. Push is a hint;
  the center is the source of truth.
- **Alternatives considered**: `flutter_local_notifications` for foreground (system banner while
  the app is open is noisy and adds a dependency); `permission_handler` (larger; only "open
  settings" is needed); rejected.

## R11. Notification texts

- **Decision**: ARB keys `notif<TypeCamel>Title` / `notif<TypeCamel>Body` (e.g.
  `notifBookingConfirmedTitle`) built from `type_key` by a fixed table in
  `NotificationTexts`, with `params` passed as ARB placeholders; amounts in params are minor
  units formatted by `Money`. Unknown types → `notifGenericTitle` / `notifGenericBody`
  ("عندك تحديث جديد") and open My Bookings.
- **Rationale**: Guest Plan §9.3 (`notif_<type>_title/body`) adapted to the project's camelCase
  ARB convention; the server sends keys and params, not text.
- **Alternatives considered**: showing server `title_key` raw (not translated); rejected.

## R12. Server-driven actions in G2

- **Decision**: `BookingActionRegistry` maps action codes to a label, icon, and handler. In G2
  it registers only `contact_support` (opens the G1 support entry point with the booking
  linked). Unknown and unregistered codes are dropped silently (logged at debug with the code
  only). Later phases register their codes; no server change is needed to show them.
- **Rationale**: Clarification 2026-10-30, FR-023.
- **Alternatives considered**: disabled "coming soon" buttons; rejected by the clarification.

## R13. Offline copies and secure arrival instructions

- **Decision**:
  - `BookingsCache` (existing `JsonFileCache`, file name keyed by a hash of the user ID): first
    page of each tab and every viewed booking's details, with `access_instructions` removed
    before writing, plus `fetchedAt`.
  - `ArrivalInstructionsStore` (`flutter_secure_storage`, key `arrival.<bookingId>`): written
    only when the server returns instructions for a booking in `confirmed` / `checked_in`;
    deleted when a refresh reports `completed`, `cancelled`, `rejected`, `expired`, or
    `no_show`; all keys with the prefix deleted at sign-out by `PersonalDataResetter`.
- **Rationale**: Clarification 2026-10-30 (option A), Constitution IV (logout clears bookings
  caches). Instructions may contain door codes, so they never touch the plain file cache.
- **Alternatives considered**: encrypting the whole cache file (key management for no gain);
  rejected.

## R14. New dependency review

- **Decision**: add `app_settings` (opens app notification settings on Android and iOS; small,
  no permissions, platform channels only). Version pinned at implementation after checking the
  latest stable release and its last-published date, as required by the dependency rule.
- **Rationale**: Only "open notification settings" is missing; `url_launcher` cannot open the
  Android app-notification screen reliably.
- **Alternatives considered**: `permission_handler` (much larger surface); custom platform
  channel (more code to maintain); rejected.

## R15. Countdown and Cairo time

- **Decision**: `Countdown` takes the server `owner_response_deadline` (UTC) and emits remaining
  time each minute (each second under 1 hour) from `CairoTime.now()`; `CountdownText` rebuilds
  only itself inside a `RepaintBoundary`. At zero the owning Cubit refetches the booking.
- **Rationale**: FR-029, Guest Plan §12.4; the deadline is never computed or extended locally.

## R16. Diagnostics

- **Decision**: `AppLogger` breadcrumbs (and the `CrashReporter` interface from G0) for
  `payment_started`, `payment_return_received`, `payment_verified`,
  `payment_verification_timeout`, each with `booking_id`, `request_id`, and the attempt key's
  first 8 characters only.
- **Rationale**: FR-039, Guest Plan §15; no personal data.

## R17. Stale responses and request cancellation

- **Decision**: Same as G1 R12: each Cubit tags requests with a sequence number and drops
  results that arrive after `close()` or after a newer request; Dio calls to Node use a
  `CancelToken` cancelled in `close()`, except payment start, which is never cancelled once sent
  (its answer must update the attempt record).
- **Rationale**: Constitution VIII; cancelling a sent payment start could lose the booking ID
  while the server already created it.
