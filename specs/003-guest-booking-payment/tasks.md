---

description: "Task list for Guest Booking & Payment (G2)"
---

# Tasks: Guest Booking & Payment (G2)

**Input**: Design documents from `specs/003-guest-booking-payment/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. Constitution IX requires test-first for the attempt-key lifecycle,
verification outcomes, polling backoff, quote-change diff, action filtering, notification
routing, storage purge rules, and error mapping; widget tests for every screen state; goldens
in Light, Dark, RTL, and 1.3× text; and Staging checks for AC-014 to AC-024 and AC-042.

**Organization**: Grouped by user story (US1–US6 from spec.md), so each story can be built and
checked on its own after Phase 2.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: User story from spec.md (US1–US6)
- Paths are relative to the repository root (single Flutter project)

---

## Implementer Guide (read before any task)

These tasks are written for an implementer who has **not** seen the design discussion. Follow
them literally. Do not invent behaviour, names, fields, or texts that a task does not give. When
a task says "copy the pattern of X", open X first and match its style exactly. When a task gives
a class or method signature, use it **exactly** (same names, same parameter names, same types).

**Before you start any task**

1. Read the task fully, including every bullet.
2. Open every file the task names as "pattern" or "read first".
3. If the task depends on an earlier task (written as "needs T0xx"), check that file exists. If it
   does not, stop and do the earlier task first.

**Commands**

- After every task, run in this order:
  1. `dart format .`
  2. `flutter analyze` (must show **zero** issues, including infos)
  3. the tests the task names (for example `flutter test test/core/errors`)
- After changing `.arb` files, run `flutter gen-l10n`.
- After changing `pubspec.yaml`, run `flutter pub get`.
- Golden tests: `flutter test --tags golden`. Create or regenerate pictures only when the task
  says so: `flutter test --tags golden --update-goldens <file>`.
- At each **Checkpoint**, run the whole suite: `flutter test`.

**Hard rules (CI rejects violations)**

1. No `Color(0x…)`, `Colors.*`, `fontSize:`, or `fontWeight:` outside `lib/design_system/`
   (`tool/check_hardcoded_styles.sh` enforces this).
   - Colors: `context.colors['tokenName']` or getters such as `context.colors.primary`
     (token names: `lib/design_system/tokens/on_air_colors.dart`).
   - Text: `context.textStyles.<name>` or `Theme.of(context).textTheme.<name>`.
   - Spacing and radii: `Dimens.*` (`lib/design_system/tokens/dimens.dart`).
2. Every visible string comes from `AppLocalizations.of(context)` (variable `l10n`). Never type
   Arabic or English text inside a widget. All keys you need are in **Appendix A**.
3. RTL-safe layout: `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`. Never
   `EdgeInsets.only(left:/right:)` or `Alignment.centerLeft`.
4. **Money**: always `Money` (`lib/core/money/money.dart`, integer piasters), shown with
   `MoneyFormatter().format(money)`.
   - Never `double` for money.
   - **Never add, subtract, or multiply amounts.** Every total, deposit, remaining, and refund
     amount comes from the server. The only number the app may compute is the nights label on
     the date step (`StayRange.nights`), for display.
5. Stay dates are `DateOnly` (`lib/core/time/date_only.dart`). Instants from the server
   (deadlines, `created_at`) are `DateTime` in UTC, parsed with `DateTime.parse(...)`, and shown
   in Cairo time with `CairoTime` (`lib/core/time/cairo_time.dart`). Never use
   `DateTime.now()` for a deadline decision; never change a booking status because a timer ended.
6. Layers: Widget → Cubit → repository **interface**. Widgets never call Supabase, Dio, secure
   storage, or repositories directly.
7. Every icon-only button has a `tooltip` and is wrapped in `Semantics(label: …, button: true)`.
   Touch targets ≥ `Dimens.minTouchTarget` (48).
8. Never log names, phones, emails, tokens, card data, or arrival instructions. Log IDs only,
   through `AppLogger` (`lib/core/logging/app_logger.dart`).
9. **Payment rules (non-negotiable)**:
   - The app never sends an amount. Payment start sends only `quote_id`, `terms_hash`, and the
     attempt key (`idempotency_key`).
   - Coming back from the payment page is **not** a confirmation. Only the server's booking
     status decides the outcome.
   - Never show any "Pay again" / "Try again" button while the booking is being verified.
   - Query parameters on the payment-return link (for example `status=success`) are ignored.
10. Booking actions come only from `available_actions`. In G2 only `contact_support` is shown;
    every other code is dropped silently (no disabled button, no "coming soon").
11. Arrival instructions (`access_instructions`) are **never** written to the JSON file cache.
    They go only to `ArrivalInstructionsStore` (secure storage).

**Code style used in this repo (match it)**

- **Models**: hand-written `@immutable final class` with a `const` constructor, a
  `factory X.fromJson(Map<String, dynamic> json)`, and `==`/`hashCode` (use `Object.hash`).
  Copy `lib/features/listings/domain/property_details.dart` (`PolicySummary`) and
  `lib/features/listings/domain/home_feed.dart` (`UpcomingBookingCard`). Do **not** use
  `freezed` for these models.
- **Cubit states**: a `sealed class` with `final class` subclasses. Copy
  `lib/features/property/presentation/property_cubit.dart` (`PropertyState`,
  `PropertyLoading`, `PropertyReady`, `PropertyNotAvailable`, `PropertyFailed`,
  `PropertyOffline`, and its `copyWith` with the `_unset` sentinel).
- **Cubits**: constructor uses the repo's style `required this._repo` for private fields
  (see `PropertyCubit`). Check `if (isClosed) return;` after every `await` and before every
  `emit`. Cancel timers and stream subscriptions in `close()`.
- **Errors**: repositories throw `AppFailure(ApiError)` (`lib/core/errors/api_error.dart`), built
  with `ErrorMapper.fromCode(code, requestId: …)` or `ErrorMapper.noResponse()`. Supabase calls
  are wrapped exactly like `_guard` in `lib/features/listings/data/supabase_listings_repository.dart`.
  Node calls throw `DioException` whose `.error` is an `ApiError` (see `ErrorInterceptor` in
  `lib/core/network/dio_factory.dart`); convert it with
  `on DioException catch (e) { throw AppFailure(e.error is ApiError ? e.error! as ApiError : ErrorMapper.noResponse()); }`.
- **Screens**: show `ErrorView` / `EmptyView` / `LoadingView` / skeletons from
  `lib/design_system/components/state_views.dart` and `skeletons.dart`. For an error, the
  message is `apiErrorMessage(error, l10n)` (`lib/core/errors/error_message.dart`) and the
  reference is `error.requestId`.
- **Widget tests**: pump with `tester.pumpOnAirApp(...)` from `test/helpers/pump_app.dart`
  (extended in T037). Call `await initializeDateFormatting('ar')` (from
  `package:intl/date_symbol_data_local.dart`) in `setUpAll` of every test that shows dates.
- **Unit tests for Cubits**: `bloc_test` (`blocTest<C, S>(...)`), fakes from `test/helpers/`.
  Time-based tests use `fakeAsync` from `package:fake_async/fake_async.dart`.
- **Goldens**: copy `test/design_system/goldens/components_golden_test.dart` (alchemist
  `goldenTest`, Light/Dark × RTL × 1.0/1.3, tag `golden`).
- **Providers**: repositories via `RepositoryProvider` in `lib/bootstrap.dart`; Cubits via
  `BlocProvider` close to the screen that owns them, unless a task says "app-scoped".

**Glossary**

| Term | Meaning |
|---|---|
| Quote | The server's priced answer for one apartment + dates + guests; has an expiry |
| Attempt | One try to pay a quote; identified by one attempt key (UUID v4) reused on every retry |
| Attempt key | The `idempotency_key` sent to payment start |
| Verification screen | `/payment/return`; waits for the server's answer after the payment page |
| Signal | A Realtime notification row arriving for the signed-in guest |
| Mock mode | `BACKEND_MODE=mock`: in-memory backend (`MockBookingServer`), no network |
| Pending tab | Server tab holding only `payment_pending` bookings; used for the banner, never shown as a tab |
| Terminal status | `completed`, `cancelled`, `rejected`, `expired`, `no_show`, `payment_conflict`, `abandoned` |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: dependency, folders, strings, and contract copies used by every later task.

- [x] T001 Add the dependency `app_settings` to `pubspec.yaml` under `dependencies:` in alphabetical order (it goes right after `app_links`). Use the latest stable version that supports Dart 3.12 / Flutter 3.44 (check pub.dev; the version must have been published at least two weeks ago). Run `flutter pub get` and keep the updated `pubspec.lock`. Then open the package README and note in a code comment at the top of `lib/core/push/notification_permission.dart` (created in T086) the exact call that opens the notification settings page (in current versions: `AppSettings.openAppSettings(type: AppSettingsType.notification)`). Done when `flutter pub get` succeeds and `flutter analyze` shows no new issues.
- [x] T002 [P] Copy the drafts for the backend owner:
  - copy `specs/003-guest-booking-payment/contracts/supabase-booking.md` to `contracts/supabase-booking.md`;
  - copy `specs/003-guest-booking-payment/contracts/app-routes.md` to `contracts/app-routes-g2.md`;
  - in both copies, rewrite every relative link so it still works from the `contracts/` folder (for example `../../002-guest-discovery/contracts/app-routes.md` becomes `../specs/002-guest-discovery/contracts/app-routes.md`, and `../../../contracts/error-codes.md` becomes `error-codes.md`);
  - append two lines to `contracts/README.md`: "- `supabase-booking.md` is a G2 draft whose reviewed source is `specs/003-guest-booking-payment/contracts/`." and the same sentence for `app-routes-g2.md`;
  - in `contracts/error-codes.md`, add this row to the table right after the `INVALID_BOOKING_STATE` row: `| \`POLICY_OUT_OF_BOUNDS\` *(new)* | G2 | \`bookingPolicyOutOfBounds\` | السعر مش ثابت على التواريخ دي. جرّب تواريخ تانية أو تواصل مع الدعم. | **yes** |`.
- [x] T003 [P] Create these folders, each with an empty `.gitkeep` file: `lib/features/booking/domain/`, `lib/features/booking/data/`, `lib/features/booking/presentation/widgets/`, `lib/features/bookings/domain/`, `lib/features/bookings/data/fixtures/`, `lib/features/bookings/presentation/widgets/`, `lib/features/notifications/domain/`, `lib/features/notifications/data/`, `lib/features/notifications/presentation/`, `lib/core/realtime/`, `lib/core/payments/`, `lib/core/storage/`, `test/features/booking/domain/`, `test/features/booking/presentation/`, `test/features/bookings/domain/`, `test/features/bookings/data/`, `test/features/bookings/presentation/`, `test/features/notifications/`, `test/core/realtime/`, `test/core/storage/`, `test/core/payments/`. Do not delete existing files in `lib/features/booking/` or `lib/features/bookings/`.
- [x] T004 Add every key in **Appendix A** to `lib/l10n/app_ar.arb` (Arabic text exactly as listed) and `lib/l10n/app_en.arb` (the English text listed). Rules:
  - add keys at the end of each file, before the final `}`; keep valid JSON (commas!);
  - do **not** remove or change existing keys;
  - for every key with `{placeholders}`, add the `"@key"` metadata block shown in Appendix A to `app_ar.arb` only (the template file), with every placeholder typed `String`;
  - run `flutter gen-l10n`.
  Done when `lib/l10n/generated/app_localizations.dart` has a getter or method for every Appendix A key and `flutter analyze` is clean.

**Checkpoint**: `flutter pub get`, `flutter gen-l10n`, and `flutter analyze` all pass.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: error codes, all booking/notification models, repository interfaces, the mock
backend, the Supabase/Node implementations, secure stores, the notification signal stream,
shared UI components, routes, and wiring. Every user story depends on this phase.

**⚠️ CRITICAL**: No user story work starts before this phase is done.

### Tests first (write them, run them, see them fail, then implement)

- [x] T005 [P] Write `test/core/errors/error_mapper_g2_test.dart`. For each pair below, assert `ErrorMapper.fromCode(code)` returns that `ErrorCode` and `messageKey`, and `ErrorMapper.hasCode(code)` is `true`:
  - `ACCOUNT_SUSPENDED` → `ErrorCode.accountSuspended`, `errorAccountSuspended`
  - `PHONE_ALREADY_USED` → `ErrorCode.phoneAlreadyUsed`, `authPhoneAlreadyUsed`
  - `POLICY_OUT_OF_BOUNDS` → `ErrorCode.policyOutOfBounds`, `bookingPolicyOutOfBounds`
  - `CONFLICT` → `ErrorCode.conflict`, `errorConflict`
  - `INVALID_BOOKING_STATE` → `ErrorCode.invalidBookingState`, `bookingStateChanged`
  - `DUPLICATE_OPERATION` → `ErrorCode.duplicateOperation`, `errorDuplicateOperation`
  - `PAYMENT_AMOUNT_MISMATCH` → `ErrorCode.paymentAmountMismatch`, `paymentVerificationIssue`
  Also test `apiErrorMessage` (`lib/core/errors/error_message.dart`) with a real `AppLocalizations` (load it with `await AppLocalizations.delegate.load(const Locale('ar'))`): each of the 7 codes above plus the existing `phoneNotVerified`, `emailNotVerified`, `datesUnavailable`, `guestsExceeded`, `quoteExpired`, `termsChanged`, `rateLimited` (with `retryAfter: Duration(seconds: 90)`), `otpInvalid`, `otpExpired`, `actionNotAllowed` must return the Arabic text of its own key (not `errorUnexpectedNoRef`). For `rateLimited`, expect `l10n.authRateLimited('1:30')` (minutes:seconds, seconds zero-padded). Existing behaviour for `network`, `notFound`, `propertyNotAvailable`, `validationFailed` stays the same.
- [x] T006 [P] Write `test/features/bookings/domain/booking_models_test.dart` (models from T013–T016):
  - `BookingStatus.fromWire` maps each of the 12 strings `payment_pending`, `payment_verifying`, `awaiting_owner`, `payment_conflict`, `confirmed`, `checked_in`, `completed`, `rejected`, `expired`, `cancelled`, `no_show`, `abandoned` to the enum value of the same name in camelCase, and any other string (for example `'weird'`) to `BookingStatus.unknown`;
  - `BookingStatus.confirmed.isTerminal == false`; `isTerminal` is `true` exactly for `completed`, `cancelled`, `rejected`, `expired`, `noShow`, `paymentConflict`, `abandoned`;
  - `BookingStatus.showsArrivalInstructions` is `true` only for `confirmed` and `checkedIn`;
  - `BookingTab.current.wire == 'current'`, `past` → `'past'`, `cancelled` → `'cancelled'`, `pending` → `'pending'`;
  - `RefundStage.fromWire`: `requested`, `approved`, `executed`, `verified`, `failed`, `cancelled`, other → `unknown`;
  - `PaymentState.fromWire`: `pending`, `failed`, `succeeded`, null or other → `pending`;
  - `BookingDetails.fromJson(fixture)` using the **Appendix B** example object: every field equals the JSON value; money fields are `Money` with the minor amounts from the JSON; `accessInstructions` is the string; `availableActions` equals `['contact_support']` (raw codes; filtering happens in `BookingActionRegistry`); `events.length == 2`; `refund` is null when the JSON has `"refund": null`;
  - `BookingDetails.toCacheJson()` returns a map **without** the key `access_instructions`, and `BookingDetails.fromJson(details.toCacheJson())` equals `details.copyWithoutInstructions()`;
  - `BookingSummary.fromJson` for the list item example in Appendix B;
  - `BookingsPage.fromJson({'items': [...], 'next_cursor': null})` has `nextCursor == null`.
- [x] T007 [P] Write `test/features/bookings/domain/booking_action_registry_test.dart`: given codes `['pay_remaining', 'contact_support', 'request_cancellation', 'totally_new']`, `BookingActionRegistry.g2().visible(codes)` returns exactly `[BookingActionCode('contact_support')]`; an empty list returns an empty list; duplicates (`['contact_support','contact_support']`) return one item.
- [x] T008 [P] Write `test/core/time/countdown_test.dart` for `Countdown` (T021), using `fakeAsync` and an injected clock `DateTime Function() now`:
  - deadline 2 h ahead → first value `Duration(hours: 2)`, next tick after 60 s → `Duration(hours: 1, minutes: 59)`;
  - deadline 30 min ahead → ticks every 1 s;
  - deadline in the past → emits `Duration.zero` once and then completes (the stream closes);
  - after `cancel()` nothing more is emitted;
  - `Countdown.format(Duration(hours: 23, minutes: 5)) == '23:05'`, `format(Duration(hours: 1)) == '1:00'`, `format(Duration(minutes: 59, seconds: 9)) == '59:09'`, `format(Duration(seconds: 7)) == '0:07'`.
- [x] T009 [P] Write `test/core/realtime/notification_signal_test.dart`:
  - `NotificationSignal.fromRecord({'id': 'n1', 'type_key': 'booking.confirmed', 'entity_type': 'booking', 'entity_id': 'b0000000-0000-4000-8000-000000000001'})` sets all four fields;
  - `fromRecord` returns `null` when `type_key` or `entity_id` is missing or not a String;
  - `ControllableNotificationSignalSource` (T020): after `start('u1')`, `emit(signal)` reaches a listener of `signals`; after `stop()`, `emit` is ignored; `signals` is a broadcast stream (two listeners both receive).
- [x] T010 [P] Write `test/core/storage/secure_stores_test.dart` using `InMemorySecureStore` (T018):
  - `PaymentAttemptStore`: `read()` is null at first; `save(attempt)` then `read()` returns an equal `PaymentAttempt`; `clear()` makes `read()` null again; a corrupt value (`'not json'` written directly under key `payment_attempt.current`) makes `read()` return null and deletes the key;
  - `ArrivalInstructionsStore`: `write('b1', 'text')` then `read('b1') == 'text'`; `remove('b1')` → null; `clearAll()` removes every key starting with `arrival.` and **keeps** `payment_attempt.current`;
  - `BookingsCache` (uses a temp-directory `JsonFileCache` like `_tempCache()` in `test/helpers/pump_app.dart`): `saveTab(BookingTab.current, [summary])` then `readTab(BookingTab.current)` returns the list and a `fetchedAt`; `saveDetails(details)` then `readDetails(id)` returns details with `accessInstructions == null` even when the saved details had instructions; `clear()` removes everything.
- [x] T011 [P] Write `test/features/bookings/data/mock_booking_server_test.dart` for `MockBookingServer` (T026), created with `latency: Duration.zero` and the fixture loader reading files from disk (`(path) => File(path).readAsString()`):
  - `listBookings(BookingTab.current)` returns only fixtures whose status is `payment_verifying`, `awaiting_owner`, `confirmed`, or `checked_in`, ordered by `check_in` ascending;
  - `past` → only `completed`, newest `check_out` first; `cancelled` → `rejected`, `expired`, `cancelled`, `no_show`, `payment_conflict`, newest first; `pending` → only `payment_pending`; no tab ever returns the `abandoned` fixture;
  - `getBooking('b0000000-0000-4000-8000-0000000000ff')` (unknown) throws `AppFailure` with `ErrorCode.notFound`;
  - `quote(...)` for fixture property `00000000-0000-4000-8000-00000000001f`, 3 nights, 2 guests, terms `mock-terms-1` returns `nights == 3`, `total == nightly × 3` **computed by the mock server**, `payNow` = 25 % of total rounded up to the piaster (fixture policy `deposit_percent_bp: 2500`), `remaining == total − payNow`, `expiresAt` 15 minutes after the injected clock;
  - `quote` with `termsHash: 'old'` throws `ErrorCode.termsChanged`; with 99 guests throws `ErrorCode.guestsExceeded`;
  - `startPayment(quoteId, termsHash, attemptKey)` twice with the **same** `attemptKey` returns the same `bookingId` and `sessionCount(attemptKey) == 1`; a different key on the same (used) quote throws `ErrorCode.quoteExpired`;
  - after `completePayment(bookingId, MockPaymentResult.success)`: `getBooking` reports `awaiting_owner`, `paymentState == succeeded`, an `ownerResponseDeadline` 24 h after the clock, and one `NotificationSignal` with `typeKey 'booking.request_received'` and that `entityId` is emitted on `signals`; `MockPaymentResult.failure` → status `payment_pending`, `paymentState == failed`, signal `payment.failed`; `MockPaymentResult.conflict` → `payment_conflict`, a refund with stage `requested`, signal `booking.payment_conflict`; `MockPaymentResult.silent` → status `payment_verifying` and **no** signal.

### Implementation

- [x] T012 Make T005 pass. In `lib/core/errors/api_error.dart` add these values to `enum ErrorCode`, right before `internal`: `accountSuspended`, `phoneAlreadyUsed`, `policyOutOfBounds`, `conflict`, `invalidBookingState`, `duplicateOperation`, `paymentAmountMismatch`. In `lib/core/errors/error_mapper.dart` add the 7 entries of T005 to `_keys`. In `lib/core/errors/error_message.dart` extend the `switch` so every code listed in T005 returns its own `l10n` getter; `rateLimited` formats `error.retryAfter` as `m:ss` (e.g. 90 s → `1:30`; null → `0:00`) and calls `l10n.authRateLimited(text)`. Keep the default branch `_ => l10n.errorUnexpectedNoRef`. Run `flutter test` (all): any other `switch` over `ErrorCode` that fails to compile must get the new cases mapped to its existing default behaviour.
- [x] T013 [P] Create `lib/features/bookings/domain/booking_status.dart` with:
  - `enum BookingStatus { paymentPending, paymentVerifying, awaitingOwner, paymentConflict, confirmed, checkedIn, completed, rejected, expired, cancelled, noShow, abandoned, unknown }` with `static BookingStatus fromWire(String? value)` (snake_case → value; anything else `unknown`), `String get wire` (back to snake_case; `unknown` → `'unknown'`), `bool get isTerminal` and `bool get showsArrivalInstructions` exactly as in T006;
  - `enum BookingTab { current, past, cancelled, pending }` with `String get wire` = the enum name;
  - `enum RefundStage { requested, approved, executed, verified, failed, cancelled, unknown }` with `fromWire`;
  - `enum PaymentState { pending, failed, succeeded }` with `fromWire` (null/other → `pending`).
- [x] T014 [P] Create `lib/features/bookings/domain/booking_parts.dart` with these `@immutable final class`es (each with `const` constructor, `fromJson`, `toJson`, `==`, `hashCode`):
  - `PaymentLine { String id; String purpose; String method; String status; Money amount; DateTime? paidAt }` — JSON keys `id`, `purpose`, `method`, `status`, `amount_minor`, `paid_at` (ISO string or null; parse with `DateTime.parse`);
  - `RefundInfo { String id; Money amount; RefundStage stage; DateTime? updatedAt }` — keys `id`, `amount_minor`, `status`, `updated_at`;
  - `BookingEvent { String eventType; BookingStatus? toStatus; DateTime createdAt; String? note }` — keys `event_type`, `to_status` (null stays null; otherwise `BookingStatus.fromWire`), `created_at`, `note`;
  - `BookingProperty { String id; String title; ListingImage? coverImage; String areaName; String cityName; String? addressText; String? checkInTime; String? checkOutTime }` — keys `id`, `title`, `cover_image` (use `ListingImage.fromJson` from `lib/features/listings/domain/listing_image.dart`; null allowed), `area_name`, `city_name`, `address_text`, `check_in_time`, `check_out_time`.
  All money uses `Money(json['amount_minor'] as int)`. `toJson` must produce JSON that `fromJson` reads back to an equal object.
- [x] T015 [P] Create `lib/features/bookings/domain/booking_action.dart`:
  - `@immutable final class BookingActionCode { const BookingActionCode(this.value); final String value; static const contactSupport = BookingActionCode('contact_support'); ==/hashCode on value }`;
  - `final class BookingActionRegistry { const BookingActionRegistry(this.supported); final Set<String> supported; factory BookingActionRegistry.g2() => const BookingActionRegistry({'contact_support'}); List<BookingActionCode> visible(List<String> codes) }` — keeps the server order, removes unsupported codes and duplicates. Add a doc comment: "G3/G5 add their codes to `supported`; nothing else changes (FR-023)." Makes T007 pass.
- [x] T016 Create `lib/features/bookings/domain/booking_summary.dart` and `lib/features/bookings/domain/booking_details.dart` (needs T013, T014, T015):
  - `BookingSummary { String id; String code; String propertyId; String title; ListingImage? coverImage; StayRange stay; BookingStatus status; RefundStage? refundStage; DateTime? ownerResponseDeadline; DateTime createdAt }`. JSON keys: `id`, `code`, `property_id`, `title`, `cover_image`, `check_in`, `check_out` (build it with the plain constructor `StayRange(DateOnly.parse(json['check_in'] as String), DateOnly.parse(json['check_out'] as String))` — it does **not** check "today", which matters because past bookings have past dates; never use `StayRange.tryCreate` for server data), `status`, `refund_status` (nullable → `RefundStage.fromWire`), `owner_response_deadline`, `created_at`. Add `toJson()`.
  - `BookingsPage { List<BookingSummary> items; String? nextCursor }` with `fromJson` (keys `items`, `next_cursor`).
  - `BookingDetails` with every field of data-model §8: `id`, `code`, `status`, `property` (`BookingProperty`), `stay`, `nights` (int, from server), `guests` (`guests_count`), `nightly` (`nightly_minor`), `total` (`total_minor`), `payNow` (`pay_now_minor`), `paid` (`paid_minor`), `remaining` (`remaining_minor`), `remainingDueAt` (`remaining_due_at`, nullable), `ownerResponseDeadline` (nullable), `paymentState` (`payment_state`), `payments` (`List<PaymentLine>`), `refund` (`RefundInfo?`), `termsSnapshot` (`PolicySummary?` read from `terms_snapshot.policy_summary`; null when missing — import `PolicySummary` from `lib/features/listings/domain/property_details.dart`), `accessInstructions` (`String?`), `availableActions` (`List<String>`, raw codes), `events` (`List<BookingEvent>`).
  - Methods: `Map<String, dynamic> toCacheJson()` (all fields **except** `access_instructions`), `BookingDetails copyWithoutInstructions()`, `==`/`hashCode`.
  - Never compute an amount. Makes T006 pass.
- [x] T017 [P] Create the repository interfaces (doc comment on each method: "Throws `AppFailure` on error."):
  - `lib/features/bookings/domain/bookings_repository.dart`: `abstract interface class BookingsRepository { Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}); Future<BookingDetails> getBooking(String bookingId); }`
  - `lib/features/notifications/domain/app_notification.dart`: `AppNotification { String id; String typeKey; String category; String entityType; String entityId; Map<String, dynamic> params; DateTime? readAt; DateTime createdAt; bool get isUnread => readAt == null; }` with `fromJson` (keys `id`, `type_key`, `category`, `entity_type`, `entity_id`, `params`, `read_at`, `created_at`) and `copyWith({DateTime? readAt})`;
  - `lib/features/notifications/domain/notifications_repository.dart`: `abstract interface class NotificationsRepository { Future<List<AppNotification>> list({DateTime? before, int limit = 30}); Future<int> unreadCount(); Future<void> markRead(List<String>? ids); }` (`ids == null` means "all").
- [x] T018 [P] Create `lib/core/storage/secure_store.dart`:
  - `abstract interface class SecureStore { Future<String?> read(String key); Future<void> write(String key, String value); Future<void> delete(String key); Future<Map<String, String>> readAll(); }`;
  - `final class FlutterSecureStore implements SecureStore` over `FlutterSecureStorage` with iOS option `KeychainAccessibility.first_unlock_this_device` (copy the options from `lib/core/auth/secure_session_storage.dart`);
  - `final class InMemorySecureStore implements SecureStore` backed by a `Map<String, String>` (used by tests and mock mode).
- [x] T019 [P] Create `lib/features/booking/domain/booking_quote.dart` and `lib/features/booking/domain/booking_flow_repository.dart`:
  - `BookingQuote { String quoteId; String propertyId; StayRange stay; int nights; int guests; Money nightly; Money total; Money payNow; Money remaining; DateTime? remainingDueAt; String termsHash; PolicySummary? policySummary; DateTime expiresAt; bool get isFullPayment => remaining.amountMinor == 0; }` — JSON keys of contracts/supabase-booking.md §2 plus D0 (`remaining_due_at`, `policy_summary`, both optional; `policy_summary` → `PolicySummary.fromJson`). Build the stay with the plain `StayRange(checkIn, checkOut)` constructor. Add `toJson`.
  - `PaymentSessionInfo { String bookingId; String paymentId; Uri paymentUrl; DateTime paymentUrlExpiresAt; }`.
  - `VerificationStatus { bool emailConfirmed; bool phoneConfirmed; String? email; String? phone; bool get isComplete => emailConfirmed && phoneConfirmed; }` — from `common_get_my_context()` JSON: read `email_confirmed` and `phone_confirmed` booleans (missing → false), `email`, `phone`.
  - `PhoneChallenge { String challengeId; Duration? retryAfter; }`.
  - Interface:
    ```dart
    abstract interface class BookingFlowRepository {
      Future<VerificationStatus> verificationStatus();
      Future<BookingQuote> quote({required String propertyId, required StayRange stay, required int guests, required String termsHash});
      Future<PaymentSessionInfo> startPayment({required String quoteId, required String termsHash, required String attemptKey});
      Future<PhoneChallenge> requestPhoneChange({required String phoneE164, required bool hasWhatsapp, String? whatsappE164});
      Future<void> sendCode(String challengeId);
      Future<void> verifyCode({required String challengeId, required String code});
    }
    ```
- [x] T020 [P] Create `lib/core/realtime/notification_signal.dart`:
  - `@immutable final class NotificationSignal { String id; String typeKey; String entityType; String entityId; static NotificationSignal? fromRecord(Map<String, dynamic> record) }` (null when `type_key` or `entity_id` is missing/not String; `id` defaults to `''`, `entity_type` to `''`);
  - `abstract interface class NotificationSignalSource { Stream<NotificationSignal> get signals; Future<void> start(String userId); Future<void> stop(); }`;
  - `final class SupabaseNotificationSignalSource implements NotificationSignalSource` taking a `SupabaseClient`. `start(userId)`: if already started for the same user do nothing; otherwise `stop()` first, then
    ```dart
    _channel = client.channel('guest-notifications-$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert, schema: 'public', table: 'notifications',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
        callback: (payload) { final s = NotificationSignal.fromRecord(payload.newRecord); if (s != null) _controller.add(s); },
      )..subscribe();
    ```
    `stop()`: `await client.removeChannel(_channel!)` when not null, set `_channel = null`. `_controller` is `StreamController<NotificationSignal>.broadcast()`.
  - `final class ControllableNotificationSignalSource implements NotificationSignalSource` for tests and mock mode: `start` sets `_userId`, `stop` clears it, `void emit(NotificationSignal s)` adds only while started.
  Makes T009 pass.
- [x] T021 [P] Create `lib/core/time/countdown.dart`: `final class Countdown { Countdown({required DateTime deadlineUtc, DateTime Function()? now}); Stream<Duration> get remaining; void cancel(); }`. `remaining` emits the time left immediately, then every 60 s while ≥ 1 h is left and every 1 s below 1 h, never negative; it emits `Duration.zero` once when the deadline passes and closes. Default `now` is `() => DateTime.now().toUtc()`. Use one `Timer` at a time (reschedule after each tick). Add `static String format(Duration d)`: `≥ 1 h` → `'H:MM'` (hours not padded, minutes 2 digits, e.g. `23:05`, `1:00`); `< 1 h` → `'M:SS'` (e.g. `59:09`, `0:07`); Western digits. Makes T008 pass.
- [x] T022 Create the three stores (needs T013, T016, T018):
  - `lib/features/booking/data/payment_attempt_store.dart`: `PaymentAttempt { String attemptKey; String quoteId; String propertyId; String termsHash; String? bookingId; String? paymentUrl; DateTime? paymentUrlExpiresAt; DateTime startedAt; PaymentAttempt copyWith({String? bookingId, String? paymentUrl, DateTime? paymentUrlExpiresAt}); toJson; fromJson }` (JSON keys `attempt_key`, `quote_id`, `property_id`, `terms_hash`, `booking_id`, `payment_url`, `payment_url_expires_at`, `started_at`) (put the class in `lib/features/booking/domain/payment_attempt.dart`) and `final class PaymentAttemptStore { PaymentAttemptStore(this._store); static const key = 'payment_attempt.current'; Future<PaymentAttempt?> read(); Future<void> save(PaymentAttempt a); Future<void> clear(); }` — `read` catches any parse error, deletes the key, and returns null.
  - `lib/features/bookings/data/arrival_instructions_store.dart`: `final class ArrivalInstructionsStore { ArrivalInstructionsStore(this._store); static const prefix = 'arrival.'; Future<String?> read(String bookingId); Future<void> write(String bookingId, String text); Future<void> remove(String bookingId); Future<void> clearAll(); }`.
  - `lib/features/bookings/data/bookings_cache.dart`: `final class BookingsCache { BookingsCache(this._cache); }` over a `JsonFileCache` (schema 1, file name given by the caller). Methods: `Future<CachedTab?> readTab(BookingTab tab)`, `Future<void> saveTab(BookingTab tab, List<BookingSummary> items)`, `Future<BookingDetails?> readDetails(String id)` (returns `fetchedAt` too via `CachedDetails { BookingDetails details; DateTime fetchedAt; }`), `Future<void> saveDetails(BookingDetails d)` (stores `d.toCacheJson()` — never the instructions), `Future<void> clear()`. Document layout `{ "tabs": { "current": { "fetched_at": "...", "items": [...] } }, "details": { "<id>": { "fetched_at": "...", "data": {...} } } }`. `CachedTab { List<BookingSummary> items; DateTime fetchedAt; }`. Read the whole document, change one part, write it back.
  Makes T010 pass.
- [x] T023 [P] Create `lib/features/bookings/data/fixtures/bookings.json` and `lib/features/bookings/data/fixtures/notifications.json` exactly as described in **Appendix B**. Add `- lib/features/bookings/data/fixtures/` under `flutter: assets:` in `pubspec.yaml`, right after the listings fixtures line. Run `flutter pub get`.
- [x] T024 [P] Create `lib/features/bookings/data/supabase_bookings_repository.dart` implementing `BookingsRepository`. Copy the structure of `SupabaseListingsRepository` (constructor taking `rpc`, the `_guard` method, `_asMap`, `_asList` — copy `_guard` exactly). Calls:
  - `listBookings(tab, cursor)` → `_rpc('guest_list_bookings', {'p_tab': tab.wire, 'p_cursor': ?cursor})` → `BookingsPage.fromJson(_asMap(response))`;
  - `getBooking(id)` → `_rpc('guest_get_booking', {'p_booking_id': id})`; a `null` response throws `AppFailure(ErrorMapper.fromCode('NOT_FOUND'))`.
- [x] T025 [P] Create `lib/features/notifications/data/supabase_notifications_repository.dart` implementing `NotificationsRepository` with the same `_guard` pattern:
  - `list(before, limit)` → `_rpc('common_list_notifications', {'p_cursor': ?before?.toUtc().toIso8601String(), 'p_limit': limit})`; the response is a JSON array of rows → `AppNotification.fromJson`;
  - `unreadCount()` → `_rpc('common_unread_count', {})` returns an int (it may arrive as `int` or `num`; use `(response as num).toInt()`);
  - `markRead(ids)` → `_rpc('common_mark_notifications_read', {'p_ids': ids})` (send `null` for "all").
- [x] T026 Create `lib/features/bookings/data/mock_booking_server.dart` (needs T016, T017, T019, T020, T022, T023): `final class MockBookingServer implements BookingsRepository, BookingFlowRepository, NotificationsRepository`. It is the in-memory "server" for mock mode, so it **may** compute amounts (it plays the server). Constructor: `MockBookingServer({required ListingsRepository listings, required ControllableNotificationSignalSource signals, Future<String> Function(String path)? loader, Duration latency = const Duration(milliseconds: 300), DateTime Function()? now, bool startVerified = true})`. Behaviour:
  - Loads `bookings.json` and `notifications.json` from `lib/features/bookings/data/fixtures/` on first use (pattern: `MockListingsRepository._load` in `lib/features/listings/data/mock_listings_repository.dart`). Bookings are stored as `Map<String, Map<String, dynamic>>` in the D1 JSON shape so `getBooking` returns `BookingDetails.fromJson`.
  - `listBookings`: tab membership and order from T011; page size 20; `next_cursor` is the index of the next item as a string, or null.
  - `getBooking`: unknown id → `AppFailure(ErrorMapper.fromCode('NOT_FOUND'))`; returns `access_instructions` only for `confirmed`, `checked_in`, `completed`.
  - `verificationStatus`: `startVerified` decides both flags; `verifyCode` with code `'123456'` sets both to true; any other code → `OTP_INVALID`. `requestPhoneChange`: phone must match `^\+201[0125]\d{8}$` else `PHONE_COUNTRY_NOT_SUPPORTED`; `'+201000000000'` → `PHONE_ALREADY_USED`; returns a new challenge id. `sendCode` does nothing.
  - `quote`: loads the property via `listings.property(propertyId)` and uses `details.nightlyPrice` (Money), `details.policy` (`PolicySummary`: `depositType`, `depositPercentBp`, `depositAmount`), `details.maxGuests`, and `details.termsVersion`; validates exactly like contracts §2 (past arrival or departure ≤ arrival or > 90 nights → `VALIDATION_FAILED`; guests < 1 or > `maxGuests` → `GUESTS_EXCEEDED`; `termsHash != details.termsVersion` → `TERMS_CHANGED`; any night in `listings.unavailableNights(...)` → `DATES_UNAVAILABLE`), then computes total = nightly × nights, payNow by policy (`percent`: ceil(total × bp / 10000); `fixed`: min(total, fixed); `full`: total), remaining = total − payNow, expiresAt = now + 15 min (or `quoteTtl` if set by a test through a public `Duration quoteTtl` field). Stores the quote.
  - `startPayment`: same attempt key → same session (count sessions per key in `Map<String,int> _sessionsPerKey`; expose `int sessionCount(String key)`); unknown/used/expired quote with a new key → `QUOTE_EXPIRED`; `termsHash` mismatch → `TERMS_CHANGED`; unverified → `PHONE_NOT_VERIFIED`. Creates a `payment_pending` booking (code `OA-MOCK` + 3 digits), `payment_state: pending`, `available_actions: ['contact_support']`, one event `booking.started`. Returns `PaymentSessionInfo` with `paymentUrl = Uri.parse('https://pay.mock.onair.test/session/<bookingId>')`, expiry now + 30 min.
  - Test/mock controls: `enum MockPaymentResult { success, failure, conflict, silent }`; `Future<void> completePayment(String bookingId, MockPaymentResult result, {Duration signalDelay = Duration.zero})` applies the outcome of T011 (also appends an event and a notification row to the in-memory notifications list) and, after `signalDelay`, calls `signals.emit(...)` (never for `silent`). `void setStatus(String bookingId, String status)` for tests.
  - `NotificationsRepository` methods work on the in-memory list (newest first, `before` filters `created_at <`, `markRead(null)` marks all).
  - Every public method awaits `Future<void>.delayed(latency)` first.
  Makes T011 pass.
- [x] T027 Create `lib/features/booking/data/supabase_booking_flow_repository.dart` implementing `BookingFlowRepository` (needs T019). Constructor `SupabaseBookingFlowRepository({required Future<dynamic> Function(String fn, Map<String, dynamic> params) rpc, required FallbackClient node})` (`FallbackClient` from `package:on_air/core/api/generated/export.dart`). Use the `_guard` pattern for RPCs and the `DioException` conversion from the Implementer Guide for Node calls. Calls:
  - `verificationStatus` → `common_get_my_context` → `VerificationStatus.fromJson`;
  - `quote` → `guest_quote_booking` with `p_property_id`, `p_check_in` (`stay.checkIn.toString()`), `p_check_out`, `p_guests`, `p_terms_hash`;
  - `startPayment` → `node.startBookingPayment(xRequestId: const Uuid().v4(), body: V1GuestBookingsStartPaymentRequestBody(quoteId: quoteId, termsHash: termsHash, idempotencyKey: attemptKey))` → `PaymentSessionInfo(bookingId: s.bookingId, paymentId: s.paymentId, paymentUrl: Uri.parse(s.paymentUrl), paymentUrlExpiresAt: s.paymentUrlExpiresAt)`. Ignore `amountMinor` (display-only, not used);
  - `requestPhoneChange` → `common_request_phone_change` with `p_new_phone`, `p_has_whatsapp`, `p_whatsapp_e164` → read `challenge_id` from the JSON;
  - `sendCode` → `node.sendOtpCode(xRequestId: const Uuid().v4(), body: V1OtpSendRequestBody(challengeId: challengeId))`; a 429 error keeps its `retryAfter`;
  - `verifyCode` → `common_verify_otp` with `p_challenge_id`, `p_code`.
- [x] T028 [P] Create `lib/design_system/components/status_chip.dart`: `enum StatusTone { warning, info, pending, success, badge, completed, rejected, cancelled }` and `final class StatusChip extends StatelessWidget { const StatusChip({required this.label, required this.tone, this.icon, super.key}); }`. Background/text token pairs (light and dark come from the active theme automatically): `warning` → `warningContainer`/`onWarningContainer`; `info` → `infoContainer`/`onInfoContainer`; `pending` → `pendingBackground`/`pendingText`; `success` → `successContainer`/`onSuccessContainer`; `badge` → `badgeNavActive`/`primary`; `completed` → `completedBackground`/`completedText`; `rejected` → `rejectedBackground`/`rejectedText`; `cancelled` → `cancelledBackground`/`cancelledText`. Pill shape (`Dimens` radius used by existing chips in `filter_chip_bar.dart`), horizontal padding `Dimens.space8`, text style `context.textStyles` label/caption style used by `filter_chip_bar.dart`. Optional small icon before the label. The widget is wrapped in `Semantics(label: label)`; the color is never the only signal.
- [x] T029 [P] Create in `lib/design_system/components/`:
  - `countdown_text.dart`: `CountdownText({required Stream<Duration> remaining, required String Function(Duration) format, TextStyle? style})` — a `StreamBuilder` inside a `RepaintBoundary` that shows `format(value)`; it rebuilds only itself;
  - `amount_row.dart`: `AmountRow({required String label, required String value, String? previousValue, bool emphasized = false, bool highlighted = false})` — label at start, value at end; when `previousValue` is set it is shown before the value with `TextDecoration.lineThrough`; `highlighted` uses `warningContainer` background; `emphasized` uses the bold style;
  - `info_banner.dart`: `InfoBanner({required String message, required StatusTone tone, String? actionLabel, VoidCallback? onAction, IconData icon = Icons.info_outline})` — a full-width card using the same token pairs as `StatusChip` with an optional text button at the end;
  - `notice_card.dart`: `NoticeCard({required IconData icon, required String message, String? actionLabel, VoidCallback? onAction})` — neutral `detailCard` background.
- [x] T030 [P] Create in `lib/design_system/components/`:
  - `booking_timeline.dart`: `BookingTimeline({required List<TimelineEntry> entries})` with `@immutable final class TimelineEntry { const TimelineEntry({required this.title, required this.time}); final String title; final String time; }` — a vertical list (dot + line + title + time) built with `Column` (entries are few); RTL-safe;
  - `refund_stage_tracker.dart`: `RefundStageTracker({required List<String> stageLabels, required int currentIndex, bool failed = false})` — horizontal steps; steps ≤ `currentIndex` use `success` colors, later steps `textSecondary`; `failed` paints the current step with `errorText`. Each step label is visible text (not color only).
- [x] T031 Write and run `test/design_system/goldens/booking_components_golden_test.dart` (copy `components_golden_test.dart`): one scenario per component of T028–T030 with sample data (`StatusChip` for all 8 tones, `AmountRow` with and without `previousValue`, `InfoBanner` with an action, `NoticeCard`, `BookingTimeline` with 3 entries, `RefundStageTracker` at index 2 and failed). Generate the pictures with `--update-goldens` once, open them, and check nothing is clipped in Dark and at 1.3×.
- [x] T032 Create `lib/features/bookings/presentation/booking_status_ui.dart` (needs T013): pure functions only, no widgets state:
  - `String bookingStatusLabel(BookingStatus s, AppLocalizations l10n)` → Appendix A keys `bookingStatusPaymentPending` … `bookingStatusUnknown`;
  - `StatusTone bookingStatusTone(BookingStatus s)` → `paymentPending: warning`, `paymentVerifying: info`, `awaitingOwner: pending`, `confirmed: success`, `checkedIn: badge`, `completed: completed`, `rejected | expired | paymentConflict: rejected`, `cancelled | noShow | abandoned | unknown: cancelled` (Guest Plan §4.6);
  - `String refundStageLabel(RefundStage s, AppLocalizations l10n)` → `refundChipRequested` for `requested`, `refundChipInProgress` for `approved | executed`, `refundChipDone` for `verified`, `refundChipProblem` for `failed | cancelled | unknown`;
  - `StatusTone refundStageTone(RefundStage s)` → `requested: warning`, `approved | executed: info`, `verified: completed`, others `rejected`.
  Write `test/features/bookings/presentation/booking_status_ui_test.dart` covering every enum value of both functions.
- [x] T033 Update `lib/app/router/routes.dart` (pattern: the existing constants, regexes, `isRegisteredLocation`, `requiresAccount`, `_validDynamicPath`):
  - constants `bookingVerifyPattern = '/book/:propertyId/verify'`, `bookingSummaryPattern = '/book/:propertyId/summary'`, `notifications = '/notifications'`;
  - regexes `_bookingVerify = RegExp(r'^/book/([^/]+)/verify$')`, `_bookingSummary = RegExp(r'^/book/([^/]+)/summary$')`;
  - add `notifications` to `staticPaths`; add both regexes to `_validDynamicPath`; `requiresAccount` returns true for `notifications` and both new patterns;
  - builders `bookingVerify(String propertyId, {required String returnTo})` → `'/book/$propertyId/verify?returnTo=$returnTo'`, `bookingSummary(String propertyId)`, `bookingDetails(String id) => '/bookings/$id'`, `paymentReturn({String? bookingId})` → `/payment/return` plus `?booking=<id>` when given, `bookingsTab(String tab) => '/bookings?tab=$tab'`;
  - `isLinkablePath` does **not** change (the `/book/` paths stay non-linkable).
  Write `test/app/router/routes_g2_test.dart`: the new paths are registered and need an account; `/book/not-a-uuid/summary` is not registered; `isLinkablePath('/book/<uuid>/summary') == false`; the builders produce the exact strings above.
- [x] T034 Update `lib/app/router/link_parser.dart`: when `link.path == AppRoutes.paymentReturn`, keep only the query key `booking`, and only if its value matches the UUID v4 pattern (reuse the same regex as `AppRoutes` — add a public `static bool isUuidV4(String value)` to `AppRoutes` and use it). Every other key (`status`, `intent`, …) is dropped. Add tests to `test/app/router/link_parser_test.dart` (open the existing file and append): a link with `booking=<uuid>&status=success` becomes `/payment/return?booking=<uuid>`; `booking=bad` becomes `/payment/return`; signed-out users get the login redirect with that destination in `from`.
- [x] T035 Wire everything in `lib/bootstrap.dart` (needs T020–T027):
  - extend the `_Backend` record with `BookingsRepository bookings`, `BookingFlowRepository bookingFlow`, `NotificationsRepository notifications`, `NotificationSignalSource signals`, `SecureStore secureStore`;
  - `_remoteBackend`: create `final dio = createNodeDio(baseUrl: environment.nodeApiBaseUrl, tokens: SupabaseTokenSource(client));` and `final node = FallbackClient(dio);`, then `SupabaseBookingsRepository(rpc: …)`, `SupabaseBookingFlowRepository(rpc: …, node: node)`, `SupabaseNotificationsRepository(rpc: …)`, `SupabaseNotificationSignalSource(client)`, `FlutterSecureStore()`;
  - `_mockBackend`: change it to build the listings mock first, then `final signals = ControllableNotificationSignalSource(); final server = MockBookingServer(listings: listings, signals: signals);` and return `server` for `bookings`, `bookingFlow`, and `notifications`, `signals` for `signals`, and `InMemorySecureStore()` for `secureStore`. Also provide `MockBookingServer` itself with `RepositoryProvider<MockBookingServer?>` (null in remote mode) so the mock payment page (T047) can reach it;
  - create `final bookingsFileCache = await JsonFileCache.appSupport(fileName: 'bookings_cache.json', schema: 1);` and the stores `PaymentAttemptStore(secureStore)`, `ArrivalInstructionsStore(secureStore)`, `BookingsCache(bookingsFileCache)`;
  - add `RepositoryProvider`s for `BookingsRepository`, `BookingFlowRepository`, `NotificationsRepository`, `NotificationSignalSource`, `PaymentAttemptStore`, `ArrivalInstructionsStore`, `BookingsCache`, `BookingActionRegistry` (value `BookingActionRegistry.g2()`);
  - replace `personalDataResetter: const NoopPersonalDataResetter()` with `CompositePersonalDataResetter([bookingsCache.clear, paymentAttempts.clear, arrivalInstructions.clearAll, backend.signals.stop])`.
  Run the app in mock mode (`flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=env/staging.json` with `"BACKEND_MODE": "mock"`) and check it still starts.
- [x] T036 Start and stop the notification signal stream with the session, in `lib/app/app.dart`: in `_OnAirAppState.initState`, add a `StreamSubscription<AuthState>` on `_authCubit.stream` that calls `_signals.start(state.account.id)` when the state is `SignedIn` (`SignedIn.account` is a `GuestAccount`; its `id` is the user ID) and `stop()` when the state is `SignedOut` or `SessionEnded`. Also handle the current state once right after `_authCubit.restore()` finishes in `_initialize`. Cancel the subscription in `dispose`. The `NotificationSignalSource` must be read before `dispose` (store it in a `late final` field in `initState`).
- [x] T037 Extend the test helpers:
  - create `test/helpers/fake_booking_backend.dart` with `FakeBookingBackend` that builds `ControllableNotificationSignalSource()` and `MockBookingServer(listings: FakeListingsRepository() or MockListingsRepository(loader: (p) => File(p).readAsString(), latency: Duration.zero), signals: …, loader: (p) => File(p).readAsString(), latency: Duration.zero, now: () => DateTime.utc(2026, 11, 1, 10))`, plus `InMemorySecureStore`, `PaymentAttemptStore`, `ArrivalInstructionsStore`, and a temp-dir `BookingsCache`;
  - in `test/helpers/pump_app.dart`, add an optional `FakeBookingBackend? bookingBackend` parameter to `pumpOnAirApp`; when given (or by default create one), add `RepositoryProvider`s for every type T035 provides, plus `BlocProvider<ConnectivityCubit>` if it is not already provided (check `fake_connectivity.dart`).
  Run the full suite: existing tests must still pass.

**Checkpoint**: `flutter test` passes (T005–T011 now green), the app starts in mock mode, and
`flutter analyze` is clean. Every user story can start now.

---

## Phase 3: User Story 1 - Request a booking and pay up front (Priority: P1) 🎯 MVP

**Goal**: a verified guest goes from "Book now" through dates, quote, summary, and the payment
page to a verification screen that shows the server's result.

**Independent Test**: mock mode, verified guest (`MockBookingServer(startVerified: true)`):
"Book now" on fixture `00000000-0000-4000-8000-00000000001f` → pick 3 nights → Continue →
summary shows the mock quote → "Go to payment" → mock page "Succeed" → verification screen shows
success with the owner deadline only after the mock signal arrives.

### Tests for User Story 1 (write first, see them fail)

- [x] T038 [P] [US1] Write `test/features/booking/domain/quote_change_test.dart` for `QuoteChange.between(BookingQuote old, BookingQuote next)` (T044): identical amounts/dates/terms → `hasChanges == false`; a different `nightly`, `total`, `payNow`, `remaining`, `remainingDueAt`, or `termsHash` each appears in `changedFields` (`Set<QuoteField>` with values `nightly, total, payNow, remaining, remainingDueAt, termsHash`); `quoteId` and `expiresAt` differences alone are **not** changes. Assert the class has no method returning a computed `Money`.
- [x] T039 [P] [US1] Write `test/features/booking/domain/verification_outcome_test.dart` for `verificationOutcomeFor(BookingDetails d)` (T045) — build details by copying the Appendix B example JSON and changing `status`/`payment_state`:
  - `awaiting_owner`, `confirmed`, `checked_in`, `completed`, `rejected`, `expired`, `cancelled`, `no_show` → `VerificationOutcome.success`;
  - `payment_conflict` → `conflict`;
  - `payment_pending` + `payment_state: failed` → `failed`; `abandoned` → `failed`;
  - `payment_pending` + `payment_state: pending` → `waiting`; `payment_verifying` (any payment_state) → `waiting`; `unknown` → `waiting`.
- [x] T040 [P] [US1] Write `test/features/booking/presentation/payment_attempt_cubit_test.dart` for `PaymentAttemptCubit` (T049) with `FakeBookingBackend` and a `FakeInAppBrowser` (records opened URLs; create it in `test/helpers/fake_in_app_browser.dart`):
  - `pay(quote)` saves a `PaymentAttempt` **before** calling `startPayment` (check the store inside a fake repository that throws on purpose: the attempt must still be in the store);
  - two quick `pay(quote)` calls (second one before the first finishes) call `startPayment` once;
  - `pay(quote)` → network failure (`AppFailure(ErrorMapper.noResponse())`) → `AttemptFailed`; calling `pay(sameQuote)` again sends the **same** attempt key (assert with `server.sessionCount(key) == 1` and the key in the store unchanged);
  - `pay(otherQuote)` (different `quoteId`) uses a **new** key;
  - success emits `AttemptOpened` with the `bookingId`, saves `bookingId` in the store, and opens the browser once with the session URL;
  - `finish()` and `newAttempt()` clear the store and emit `AttemptIdle`;
  - `restore()` with a stored attempt that has a `bookingId` emits `AttemptOpened` without opening the browser.
- [x] T041 [P] [US1] Write `test/features/booking/presentation/booking_flow_cubit_test.dart` for `BookingFlowCubit` (T048) with `FakeBookingBackend`:
  - `load()` emits `load: FlowLoad.ready` with the property, `unavailable` nights for `[today, today+365)`, the initial stay/guests from the constructor, and `termsHash` from the constructor;
  - an unknown property → `FlowLoad.notAvailable`;
  - `canContinue` is false with no stay, with guests > `maxGuests`, or when a night of the stay is unavailable; true otherwise;
  - `requestQuote()` sets `quoting` true then false and stores the server quote; `DATES_UNAVAILABLE` sets `error` and reloads `unavailable`; `GUESTS_EXCEEDED` sets `error`;
  - the cubit never builds a `Money` itself (all amounts in state come from the quote).
- [x] T042 [P] [US1] Write `test/features/booking/presentation/payment_verification_cubit_test.dart` for `PaymentVerificationCubit` (T050) using `fakeAsync`:
  - with a booking in `payment_verifying`, the cubit stays `VerifyWaiting`; a signal with that `entityId` after `server.setStatus(id, 'awaiting_owner')` makes it fetch at once and emit `VerifyResolved(success)` without waiting for the next poll;
  - a signal for a **different** booking ID does not trigger a fetch;
  - with no signal, fetches happen at 2 s, 6 s, 14 s, 30 s, 60 s, 90 s, 120 s after `start()` (cumulative backoff 2, 4, 8, 16, 30, 30, 30); count calls with a counting fake repository;
  - if still waiting after the 120 s fetch → `VerifyTimeout`; no fetch happens after timeout;
  - `NOT_FOUND` → `VerifyNotAvailable`; a network error keeps `VerifyWaiting`;
  - after `close()`, no timer fires (no exception, no emit).
- [x] T043 [P] [US1] Write widget tests (use `pumpOnAirApp` with `FakeBookingBackend`):
  - `test/features/booking/presentation/dates_screen_test.dart`: unavailable days are disabled in the calendar; "Continue" (`ValueKey('dates-continue')`) is disabled until a valid range is picked; the nights label shows `l10n.bookingNightsCount('3')` for 3 nights; tapping Continue shows the button loader and then navigates to the summary route; a `DATES_UNAVAILABLE` error shows `l10n.bookingDatesUnavailable` on the same screen; offline → Continue disabled.
  - `test/features/booking/presentation/summary_screen_test.dart`: shows photo, title, area, the dates, nights, nightly, total, pay-now, remaining + due date (deposit fixture) — each value formatted from the quote with `MoneyFormatter`; for a full-payment quote the remaining row is absent; the 24-hour notice `l10n.bookingSummaryOwnerNotice` is visible; tapping "Go to payment" (`ValueKey('summary-pay')`) disables it immediately and calls the fake browser once.
  - `test/features/booking/presentation/payment_return_screen_test.dart`: one test per outcome — waiting shows `l10n.paymentVerifying` and **no** button with keys `return-try-again`/`summary-pay`; success shows `l10n.paymentSuccessTitle`, the countdown, and `ValueKey('return-view-booking')`; failed shows `l10n.paymentFailedTitle` and `ValueKey('return-try-again')`; conflict shows `l10n.paymentConflictTitle` and `ValueKey('return-find-dates')`; timeout shows `l10n.paymentTimeoutTitle` and `ValueKey('return-go-bookings')`; a link query `status=success` while the server says failed still shows failed.

### Implementation for User Story 1

- [x] T044 [P] [US1] Create `lib/features/booking/domain/quote_change.dart`: `enum QuoteField { nightly, total, payNow, remaining, remainingDueAt, termsHash }` and `@immutable final class QuoteChange { const QuoteChange({required this.previous, required this.next, required this.changedFields}); factory QuoteChange.between(BookingQuote previous, BookingQuote next); bool get hasChanges => changedFields.isNotEmpty; }`. Comparison only — never create a new `Money`. Makes T038 pass.
- [x] T045 [P] [US1] Create `lib/features/booking/domain/verification_outcome.dart`: `enum VerificationOutcome { success, conflict, failed, waiting }` and `VerificationOutcome verificationOutcomeFor(BookingDetails d)` exactly as the table in T039 (data-model §6). Add a doc comment: "Link parameters are never an input (FR-016)." Makes T039 pass.
- [x] T046 [P] [US1] Create `lib/core/payments/in_app_browser.dart`: `abstract interface class InAppBrowser { Future<void> open(Uri url, {required String bookingId}); }` and `final class UrlLauncherInAppBrowser implements InAppBrowser` that calls `launchUrl(url, mode: LaunchMode.inAppBrowserView)` (package `url_launcher`); if it returns false, retry once with `LaunchMode.externalApplication`; if that also fails throw `AppFailure(ErrorMapper.fromCode('INTERNAL'))`. Never use a WebView.
- [x] T047 [US1] Create the mock payment page for mock mode (needs T026, T046):
  - `lib/features/booking/presentation/mock_payment_page.dart`: `MockPaymentPage({required String bookingId, required MockBookingServer server, required void Function(String bookingId) onReturn})` — a `Scaffold` with the title `l10n.mockPaymentTitle` and five full-width buttons with keys `mock-pay-success`, `mock-pay-failure`, `mock-pay-conflict`, `mock-pay-silent`, `mock-pay-close` and labels from Appendix A (`mockPaySuccess`, …). Each button calls `server.completePayment(bookingId, <result>, signalDelay: const Duration(seconds: 2))` (`close` uses `MockPaymentResult.failure`), then `Navigator.of(context).pop()`, then `onReturn(bookingId)`;
  - `lib/features/booking/data/mock_in_app_browser.dart`: `final class MockInAppBrowser implements InAppBrowser { MockInAppBrowser({required GlobalKey<NavigatorState> navigatorKey, required MockBookingServer server, required void Function(String bookingId) onReturn}); }` — `open` pushes `MaterialPageRoute(builder: (_) => MockPaymentPage(...))` on `navigatorKey.currentState!`;
  - in `lib/app/router/app_router.dart`, add an optional parameter `GlobalKey<NavigatorState>? navigatorKey` to `createAppRouter` and pass it to `GoRouter(navigatorKey: navigatorKey, …)`; in `lib/app/app.dart` create `final _rootNavigatorKey = GlobalKey<NavigatorState>();` and pass it;
  - provide `InAppBrowser` from `lib/app/app.dart` (not bootstrap, because it needs the navigator key and the router): in `build`, wrap `MaterialApp.router` with `RepositoryProvider<InAppBrowser>.value(value: _browser)` where `_browser` is created in `initState`: if `context.read<MockBookingServer?>()` is not null → `MockInAppBrowser(navigatorKey: _rootNavigatorKey, server: …, onReturn: (id) => _router.go(AppRoutes.paymentReturn(bookingId: id)))`, else `UrlLauncherInAppBrowser()`. Also accept an optional `InAppBrowser? inAppBrowser` on `OnAirApp` for tests (used first when given).
- [x] T048 [US1] Create `lib/features/booking/presentation/booking_flow_cubit.dart` (needs T019, T044):
  - `enum FlowLoad { loading, ready, notAvailable, failed, offline }`;
  - `@immutable final class BookingFlowState` with fields `FlowLoad load`, `PropertyDetails? property`, `Set<DateOnly> unavailable`, `StayRange? stay`, `int guests`, `String termsHash`, `bool quoting`, `BookingQuote? quote`, `ApiError? error`, `QuoteChange? pendingChange` (used by US6), `bool termsChanged` (used by US6), `bool needsVerification` (used by US2); a `copyWith` using the `_unset` sentinel pattern for nullable fields; and `bool get canContinue` = `load == ready && stay != null && guests >= 1 && guests <= property!.maxGuests && stay!.isSelectable(unavailable) && !quoting`;
  - `final class BookingFlowCubit extends Cubit<BookingFlowState>` with constructor `BookingFlowCubit({required ListingsRepository listings, required BookingFlowRepository flow, required ConnectivityCubit connectivity, required String propertyId, required String termsHash, StayRange? initialStay, int? initialGuests, DateOnly Function()? today})` (store with `required this._…` style). Initial guests = `initialGuests ?? 1`;
  - `Future<void> load()`: offline → `FlowLoad.offline`; else fetch `listings.property(propertyId)` and `listings.unavailableNights(propertyId, today, today.addDays(365))` (use `Future.wait`); `NOT_FOUND`/`PROPERTY_NOT_AVAILABLE` → `notAvailable`; other errors → `failed` with `error`; success → `ready`. (US2 adds the verification check here.)
  - `void setStay(StayRange? stay)`, `void setGuests(int guests)` (clamp 1…maxGuests); both clear `error` and `quote`;
  - `Future<bool> requestQuote()`: returns false without a request when `!canContinue`; sets `quoting: true`; calls `flow.quote(...)`; success → `quote`, `quoting: false`, returns true; `AppFailure` → `error`, `quoting: false`, and for `datesUnavailable` refetches `unavailable`; returns false;
  - `Future<void> retry()` → `load()`.
  Makes T041 pass.
- [x] T049 [US1] Create `lib/features/booking/presentation/payment_attempt_cubit.dart` (needs T022, T046). **App-scoped** (one instance for the whole app). States: `sealed class PaymentAttemptState`; `AttemptIdle`; `AttemptStarting(PaymentAttempt attempt)`; `AttemptOpened(PaymentAttempt attempt)` (has `bookingId`); `AttemptFailed(ApiError error, PaymentAttempt? attempt)`. Constructor `PaymentAttemptCubit({required BookingFlowRepository flow, required PaymentAttemptStore store, required InAppBrowser Function() browser, required AppLogger logger, String Function()? newKey, DateTime Function()? now})` (`newKey` default `const Uuid().v4`; `browser` is a getter function because the browser is created in `app.dart`). Methods:
  - `Future<void> restore()`;
  - `Future<void> pay(BookingQuote quote)`: ignore when the state is `AttemptStarting`; read the store; reuse the stored attempt when `stored.quoteId == quote.quoteId`, otherwise create `PaymentAttempt(attemptKey: newKey(), quoteId, propertyId, termsHash: quote.termsHash, startedAt: now())`; **save before the request**; emit `AttemptStarting`; call `flow.startPayment(...)`; on success save `bookingId`, `paymentUrl`, and `paymentUrlExpiresAt`, log `payment_started booking=<id> key=<first 8 chars>` with `logger.info`, emit `AttemptOpened`, then `await browser().open(session.paymentUrl, bookingId: session.bookingId)`; on `AppFailure` emit `AttemptFailed(error, attempt)` (keep the stored attempt);
  - `Future<void> reopenPage()` — when `AttemptOpened` and `paymentUrlExpiresAt` is after `now()`, open `attempt.paymentUrl` again; otherwise do nothing;
  - `Future<void> finish()` and `Future<void> newAttempt()` — clear the store, emit `AttemptIdle`.
  Never pass an amount anywhere. Do **not** cancel `startPayment` once sent. Makes T040 pass.
- [x] T050 [US1] Create `lib/features/booking/presentation/payment_verification_cubit.dart` (needs T017, T020, T045). States: `VerifyWaiting`; `VerifyResolved(VerificationOutcome outcome, BookingDetails details)`; `VerifyTimeout(String bookingId)`; `VerifyNotAvailable`. Constructor `PaymentVerificationCubit({required BookingsRepository bookings, required NotificationSignalSource signals, required String bookingId, required AppLogger logger, List<Duration> backoff = const [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8), Duration(seconds: 16), Duration(seconds: 30), Duration(seconds: 30), Duration(seconds: 30)]})`. `void start()`: log `payment_return_received booking=<id>`; fetch once immediately; listen to `signals.signals.where((s) => s.entityId == bookingId)` → fetch; schedule the next poll with a single `Timer` using the next backoff step; when all steps are used and the outcome is still `waiting` → emit `VerifyTimeout` and log `payment_verification_timeout`. A fetch is skipped while another is in flight. When the outcome is not `waiting` → emit `VerifyResolved`, log `payment_verified booking=<id> outcome=<name>`, cancel the timer and the subscription. `NOT_FOUND` → `VerifyNotAvailable` (stop everything); network/other errors → stay waiting. `close()` cancels the timer and the subscription. Makes T042 pass.
- [x] T051 [US1] Create `lib/features/booking/presentation/dates_screen.dart` (`DatesScreen`, needs T048). Read first: `lib/features/property/presentation/widgets/property_availability_section.dart` (how `RangeCalendar` is used) and `lib/features/search/presentation/widgets/date_range_sheet.dart`. Layout (`Scaffold`, app bar title `l10n.bookingDatesTitle`):
  - `BlocBuilder<BookingFlowCubit, BookingFlowState>`: `loading` → skeleton (`SkeletonBox` blocks); `notAvailable` → `EmptyView(icon: Icons.home_outlined, message: l10n.propertyNotAvailable)`; `failed` → `ErrorView(message: apiErrorMessage(error, l10n), onRetry: cubit.retry, referenceNumber: error.requestId)`; `offline` → `ErrorView(message: l10n.offline, onRetry: cubit.retry)`;
  - `ready`: the `RangeCalendar` (today = `CairoTime.today()`, `unavailableNights: state.unavailable`, selected range from `state.stay`, `lastSelectableDay: today.addDays(364)`, tap logic copied from the property availability section: first tap sets arrival, second tap after it sets departure, a tap that would include an unavailable night shows `l10n.bookingRangeHasUnavailable` in a `SnackBar` and resets); below it a `CounterStepper` for guests (`min: 1`, `max: property.maxGuests`, label `l10n.searchGuestsLabel`, tooltips `l10n.guestsDecrease`/`l10n.guestsIncrease` — use the keys the G1 search screen uses; open `lib/features/search/presentation/search_screen.dart` to copy them); a text with `l10n.bookingNightsCount('${stay.nights}')` when a stay is picked (every placeholder is a `String`, so convert numbers with string interpolation); an inline error text (`apiErrorMessage`) when `state.error` is set;
  - bottom `BottomActionBar` with `OnAirPrimaryButton(key: ValueKey('dates-continue'), label: l10n.bookingContinue, isLoading: state.quoting, onPressed: state.canContinue && online ? () async { if (await cubit.requestQuote() && context.mounted) context.push(AppRoutes.bookingSummary(propertyId)); } : null)`.
- [x] T052 [US1] Create `lib/features/booking/presentation/summary_screen.dart` (`SummaryScreen`, needs T048, T049). App bar title `l10n.bookingSummaryTitle`. Content from `state.quote` and `state.property` only:
  - header row: `OnAirNetworkImage` of the first property image (look at how `property_card.dart` shows the cover), title, `areaName، cityName`;
  - `AmountRow`s, in this order: `label: l10n.searchDatesLabel` → `DateOnlyFormatter.dayMonth(checkIn) – dayMonth(checkOut)`; `label: l10n.bookingNights` → `l10n.bookingNightsCount('${quote.nights}')`; `label: l10n.searchGuestsLabel` → `'${quote.guests}'`; `l10n.bookingNightlyPrice` → `MoneyFormatter().format(quote.nightly)`, `l10n.bookingTotal` → total (emphasized), `l10n.bookingPayNow` → payNow (emphasized), and only when `!quote.isFullPayment`: `l10n.bookingRemaining` → remaining, and `l10n.bookingRemainingDue(date)` when `remainingDueAt != null` (format the date with `CairoTime` + `DateOnlyFormatter.dayMonth`);
  - policy: a section title `l10n.bookingPolicyTitle` and one line per `policyLines(quote.policySummary ?? state.property!.policy)` rendered with `policyLineText(line, l10n)` (`lib/features/property/presentation/widgets/policy_line_text.dart`);
  - `InfoBanner(tone: StatusTone.info, message: l10n.bookingSummaryOwnerNotice)`;
  - `BlocBuilder<PaymentAttemptCubit, PaymentAttemptState>` for the bottom button `OnAirPrimaryButton(key: ValueKey('summary-pay'), label: l10n.bookingGoToPayment, isLoading: attempt is AttemptStarting, onPressed: online && attempt is! AttemptStarting && state.pendingChange == null ? () => attemptCubit.pay(state.quote!) : null)`;
  - when the attempt state is `AttemptOpened` for this quote, show an `InfoBanner(tone: StatusTone.info, message: l10n.paymentReturnHint, actionLabel: l10n.paymentCheckStatus, onAction: () => context.go(AppRoutes.paymentReturn(bookingId: attempt.attempt.bookingId)))` above the button (iOS fallback, research R4);
  - `BlocListener<PaymentAttemptCubit, PaymentAttemptState>`: `AttemptFailed` → `SnackBar(apiErrorMessage(error, l10n))`.
  If `state.quote == null` (for example after a restart), show `ErrorView(message: l10n.bookingQuoteExpired, onRetry: () => context.pop())`.
- [x] T053 [US1] Create `lib/features/booking/presentation/payment_return_screen.dart` (`PaymentReturnScreen({String? bookingIdFromLink})`, needs T050). Resolve the booking ID: the link's `booking` value if it is a UUID v4 (`AppRoutes.isUuidV4`), else the `bookingId` of `PaymentAttemptCubit`'s `AttemptOpened` state, else redirect with `context.go(AppRoutes.bookingsTab('current'))` in a post-frame callback. Provide `PaymentVerificationCubit` with `BlocProvider(create: (_) => …..start())` keyed by the booking ID. UI (all texts from Appendix A, no back-to-summary button):
  - `VerifyWaiting` → centered `CircularProgressIndicator` (inside `Semantics(label: l10n.paymentVerifying)`) + title `l10n.paymentVerifying` + body `l10n.paymentVerifyingBody`;
  - `VerifyResolved(success)` → success icon, `l10n.paymentSuccessTitle`, `l10n.paymentSuccessBody`, a `CountdownText` fed by `Countdown(deadlineUtc: details.ownerResponseDeadline!)` formatted with `(d) => l10n.ownerDeadlineCountdown(Countdown.format(d))` (only when the deadline is not null; cancel the `Countdown` when the screen is disposed), and `OnAirPrimaryButton(key: ValueKey('return-view-booking'), label: l10n.paymentViewBooking)` → `attemptCubit.finish()` then `context.go(AppRoutes.bookingDetails(id))`;
  - `VerifyResolved(failed)` → `l10n.paymentFailedTitle`, `l10n.paymentFailedBody`, `OnAirPrimaryButton(key: ValueKey('return-try-again'), label: l10n.paymentTryAgain)` → `attemptCubit.newAttempt()` then `context.go('/book/${details.property.id}/dates?checkIn=${details.stay.checkIn}&checkOut=${details.stay.checkOut}&guests=${details.guests}&terms=${Uri.encodeQueryComponent(terms)}')` where `terms` is `attempt.termsHash` when `attemptCubit.state` is `AttemptOpened` or `AttemptFailed` with a non-null attempt — **read it before calling `newAttempt()`** — and empty otherwise (when it is empty, go to `AppRoutes.property(details.property.id)` instead);
  - `VerifyResolved(conflict)` → `l10n.paymentConflictTitle`, `l10n.paymentConflictBody(MoneyFormatter().format(details.paid))`, `OnAirPrimaryButton(key: ValueKey('return-find-dates'), label: l10n.paymentFindOtherDates)` → `attemptCubit.finish()` then `context.go(AppRoutes.property(details.property.id))`;
  - `VerifyTimeout` → `l10n.paymentTimeoutTitle`, `l10n.paymentTimeoutBody`, `OnAirPrimaryButton(key: ValueKey('return-go-bookings'), label: l10n.paymentGoToBookings)` → `context.go(AppRoutes.bookingsTab('current'))` (do **not** clear the attempt);
  - `VerifyNotAvailable` → `NotAvailableScreen` content (`lib/features/app_update/presentation/not_available_screen.dart`).
  The screen ignores every query parameter except `booking`.
- [x] T054 [US1] Wire the routes in `lib/app/router/app_router.dart` (needs T051–T053):
  - remove the `bookingEntryPattern` `GoRoute` and replace it with a `ShellRoute` (`navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'booking')` created once at file level) whose `builder` creates `BlocProvider<BookingFlowCubit>(key: ValueKey(propertyId), create: (context) => BookingFlowCubit(listings: …, flow: context.read<BookingFlowRepository>(), connectivity: …, propertyId: propertyId, termsHash: query['terms'] ?? '', initialStay: StayRange.tryCreate(DateOnly.tryParse(query['checkIn']), DateOnly.tryParse(query['checkOut']), CairoTime.today()), initialGuests: _boundedGuests(query['guests']))..load(), child: child)` — read `propertyId` from `state.pathParameters['propertyId']!` and `query` from `state.uri.queryParameters`;
  - child routes: `GoRoute(path: AppRoutes.bookingEntryPattern, name: 'booking-dates', builder: … DatesScreen(propertyId: id))` and `GoRoute(path: AppRoutes.bookingSummaryPattern, name: 'booking-summary', builder: … SummaryScreen(propertyId: id))` (US2 adds the verify route here);
  - when `termsHash` is empty (someone typed the URL by hand), `DatesScreen` must show `ErrorView(message: l10n.bookingStartFromProperty, onRetry: () => context.go(AppRoutes.property(id)))` instead of the calendar — add this check at the top of `DatesScreen.build`;
  - replace the `paymentReturn` route builder with `PaymentReturnScreen(bookingIdFromLink: state.uri.queryParameters['booking'])` and rename it `payment-return`;
  - delete `lib/features/booking/presentation/booking_entry_placeholder_screen.dart`, `test/features/booking/booking_entry_placeholder_test.dart`, and the `.gitkeep` files in `lib/features/booking/`; then run `grep -rn "BookingEntryPlaceholder" lib test` and update every remaining test (for example `test/app/router/discovery_resume_test.dart`) so it expects `DatesScreen` instead.
- [x] T055 [US1] Make `PaymentAttemptCubit` app-scoped and detect the return to the app, in `lib/app/app.dart` (needs T049):
  - in `initState`, create `_paymentAttemptCubit = PaymentAttemptCubit(flow: context.read<BookingFlowRepository>(), store: context.read<PaymentAttemptStore>(), browser: () => _browser, logger: _logger)` and call `unawaited(_paymentAttemptCubit.restore())` after `_authCubit.restore()` in `_initialize`; add it to `MultiBlocProvider` with `BlocProvider<PaymentAttemptCubit>.value`; close it in `dispose`;
  - add `late final AppLifecycleListener _lifecycle = AppLifecycleListener(onResume: _onResume);` (create in `initState`, dispose in `dispose`). `_onResume`: if `_paymentAttemptCubit.state is AttemptOpened` and the current router location (`_router.routerDelegate.currentConfiguration.uri.path`) is not `/payment/return`, call `_router.go(AppRoutes.paymentReturn(bookingId: (state as AttemptOpened).attempt.bookingId))`;
  - on sign-out the store is cleared by T035's resetter; also call `_paymentAttemptCubit.newAttempt()` when the auth state becomes `SignedOut` (inside the subscription added in T036).
- [x] T056 [US1] Update `lib/features/property/presentation/property_screen.dart` only if needed: "Book now" must still go to `AppRoutes.bookingEntry(id)` with `checkIn`, `checkOut`, `guests`, and `terms` query keys (G1 behaviour). Open the file, confirm the four keys are passed, and add a widget test in `test/features/booking/presentation/book_now_handoff_test.dart` that taps "Book now" for a signed-in guest and expects `DatesScreen` with the same stay and guests preselected.

**Checkpoint**: US1 works end to end in mock mode (Independent Test above); T038–T043 pass.

---

## Phase 4: User Story 2 - Verify email and phone before the first booking (Priority: P1)

**Goal**: an unverified guest is stopped before the date step, confirms email and an Egyptian
phone with one email code, and continues with the same choices.

**Independent Test**: mock mode with `MockBookingServer(startVerified: false)`: "Book now" →
verify screen → phone `01012345678` + "has WhatsApp" → code `123456` → back on the date step with
the same dates and guests.

### Tests for User Story 2

- [x] T057 [P] [US2] Write `test/features/booking/presentation/verify_identity_cubit_test.dart` for `VerifyIdentityCubit` (T059) with `FakeBookingBackend(startVerified: false)` and the existing `FakeAuthRepository` (`test/helpers/fake_auth_repository.dart`):
  - `start()` with email unconfirmed → `VerifyEmailStep(email)`; with email confirmed and phone unconfirmed → `VerifyPhoneStep()`; both confirmed → `VerifyDone`;
  - `submitPhone('0101 234 5678', hasWhatsapp: true, whatsapp: null)` → requests the change with `+201012345678`, sends the code, emits `VerifyCodeStep(challengeId, retryAfter)`;
  - `submitPhone('0123', …)` → `VerifyPhoneStep(error: ErrorCode.phoneCountryNotSupported)` without calling the server (local `EgyptPhone.tryParse` fails → show `l10n.authPhoneCountryNotSupported`);
  - `submitPhone(..., hasWhatsapp: false, whatsapp: '01112345678')` sends `whatsappE164: '+201112345678'`; with `hasWhatsapp: true` any whatsapp value is ignored (sent as null);
  - server `PHONE_ALREADY_USED` → `VerifyPhoneStep(error: phoneAlreadyUsed)`;
  - `submitCode('000000')` → `VerifyCodeStep(error: otpInvalid)`; `submitCode('123456')` → re-checks status → `VerifyDone`;
  - `RATE_LIMITED` with `retryAfter` keeps the code step and exposes `retryAfter`.
- [x] T058 [P] [US2] Write `test/features/booking/presentation/verify_identity_screen_test.dart`: each step renders its fields; the WhatsApp number field is hidden while "This number has WhatsApp" is on; the resend button (`ValueKey('verify-resend')`) is disabled until `retryAfter` passes (use `tester.pump(Duration)`); `VerifyDone` pops the route with `true`.

### Implementation for User Story 2

- [x] T059 [US2] Create `lib/features/booking/presentation/verify_identity_cubit.dart`. States: `VerifyChecking`; `VerifyEmailStep({required String email, ErrorCode? error, bool sending = false, bool codeSent = false, Duration? retryAfter})`; `VerifyPhoneStep({ErrorCode? error, bool sending = false})`; `VerifyCodeStep({required String challengeId, ErrorCode? error, bool verifying = false, Duration? retryAfter})`; `VerifyDone`; `VerifyFailed(ApiError error)`. Constructor `VerifyIdentityCubit({required BookingFlowRepository flow, required AuthRepository auth})`. Methods:
  - `start()` → `flow.verificationStatus()` → first missing step (email before phone) or `VerifyDone`;
  - email step: `sendEmailCode()` → `auth.requestEmailVerification(email)`; `submitEmailCode(code)` → `auth.verifyEmailCode(email, code)` then `start()` again. Use `AuthRepository` directly — **do not** call `AuthCubit` (its states drive the router and would leave the booking flow);
  - phone step: `submitPhone(String raw, {required bool hasWhatsapp, String? whatsapp})` → `EgyptPhone.tryParse` (both numbers) → `flow.requestPhoneChange(phoneE164, hasWhatsapp, whatsappE164: hasWhatsapp ? null : whatsapp?.e164)` → `flow.sendCode(challengeId)` → `VerifyCodeStep`;
  - `resendCode()` → `flow.sendCode(challengeId)`; `submitCode(String code)` → `flow.verifyCode(...)` → `start()`.
  Map `AppFailure` to the `error` of the current step. Makes T057 pass.
- [x] T060 [US2] Create `lib/features/booking/presentation/verify_identity_screen.dart` (`VerifyIdentityScreen`). App bar title `l10n.verifyTitle`; one intro line `l10n.verifyIntro`. Steps:
  - email: shows the email (masked is not required), button `l10n.sendCode` → then `OnAirOtpField` + `l10n.verifyEmailCodeHint`;
  - phone: `OnAirTextField(label: l10n.phoneNumber, hint: l10n.authPhoneHint, keyboardType: TextInputType.phone)`, a `SwitchListTile` `l10n.verifyHasWhatsapp` (default on), and — only when the switch is off — a second `OnAirTextField(label: l10n.verifyWhatsappNumber)`; submit button `l10n.sendCode`;
  - code: `OnAirOtpField(onCompleted: cubit.submitCode)`, text `l10n.verifyCodeSentToEmail`, resend `TextButton(key: ValueKey('verify-resend'))` disabled with `l10n.verifyResendIn(seconds)` while `retryAfter` counts down (use a `Timer.periodic` in the widget state, cancelled in `dispose`);
  - errors under the field via `apiErrorMessage(ApiError(code: error, messageKey: ''), l10n)`;
  - `BlocListener`: `VerifyDone` → `context.pop(true)`.
  Never copy the code to the clipboard. Follow the existing OTP screen look (`lib/features/auth/presentation/otp_screen.dart`).
- [x] T061 [US2] Add the verify route and the two entry points (needs T054, T059, T060):
  - in the booking `ShellRoute` (T054) add `GoRoute(path: AppRoutes.bookingVerifyPattern, name: 'booking-verify', builder: (context, state) => BlocProvider(create: (context) => VerifyIdentityCubit(flow: context.read<BookingFlowRepository>(), auth: context.read<AuthRepository>())..start(), child: const VerifyIdentityScreen()))`;
  - in `BookingFlowCubit.load()` (T048): after the property loads, call `flow.verificationStatus()`; if `!isComplete` emit `needsVerification: true` (errors here are ignored — the server still checks at payment start); add `void verificationDone()` that sets it back to false;
  - in `DatesScreen`: a `BlocListener` that, when `needsVerification` turns true, calls `final ok = await context.push<bool>(AppRoutes.bookingVerify(propertyId, returnTo: 'dates'))`; `ok == true` → `cubit.verificationDone()`; otherwise `context.go(AppRoutes.property(propertyId))`;
  - in `SummaryScreen`: when `PaymentAttemptCubit` emits `AttemptFailed` with `ErrorCode.phoneNotVerified` or `emailNotVerified`, push the verify route with `returnTo: 'summary'` instead of the SnackBar; on `true`, call `attemptCubit.pay(quote)` again (same quote → same key).

**Checkpoint**: US2 Independent Test passes; T057–T058 pass; US1 still passes.

---

## Phase 5: User Story 3 - Follow my bookings (Priority: P1)

**Goal**: My Bookings with Current / Past / Cancelled tabs and a full booking details screen,
offline copies, secure arrival instructions, and only server-allowed actions.

**Independent Test**: mock mode with the Appendix B fixtures: open My Bookings → each tab holds
the right bookings in server order → open the confirmed booking → status message, payments,
saved terms, timeline, instructions, and only "Contact OnAir" → airplane mode → reopen → cached
copy with "Last updated" and instructions still visible.

### Tests for User Story 3

- [x] T062 [P] [US3] Write `test/features/bookings/presentation/bookings_cubit_test.dart` for `BookingsCubit` (T067) with `FakeBookingBackend` and a fake connectivity (`test/helpers/fake_connectivity.dart`):
  - `start(BookingTab.current)` emits the cached items first (when the cache has some, `fromCache: true`), then the server items (`fromCache: false`), and saves them to `BookingsCache`;
  - other tabs load only when selected (`selectTab`); selecting an already-loaded tab does not refetch;
  - `loadMore()` appends the next page and stops when `nextCursor` is null; a second `loadMore()` while one is running is ignored;
  - offline with cache → items + `fromCache: true` + `fetchedAt`; offline without cache → `TabLoad.offline`;
  - the cubit never sorts or filters the server list (the order equals the server order).
- [x] T063 [P] [US3] Write `test/features/bookings/presentation/booking_details_cubit_test.dart` for `BookingDetailsCubit` (T068):
  - confirmed booking with instructions → `DetailsReady.instructions == 'text'`, `ArrivalInstructionsStore.read(id) == 'text'`, and the JSON written to `BookingsCache` has **no** `access_instructions`;
  - after `server.setStatus(id, 'cancelled')` and `refresh()` → the store no longer has the instructions;
  - offline with a cached copy → `DetailsReady(fromCache: true)` and `instructions` read from the store;
  - unknown ID → `DetailsNotAvailable`; a signal for this booking ID triggers a refresh; a signal for another ID does not.
- [x] T064 [P] [US3] Write `test/features/bookings/presentation/bookings_screen_test.dart`: three tabs with labels `bookingsTabCurrent/Past/Cancelled`; each card shows title, dates, and the status chip label; an awaiting-owner card shows the countdown text; an empty tab shows its empty message and a `bookingsFindApartment` button that goes to `/search`; loading shows skeletons; offline with cache shows the `lastUpdated` note; `payment_pending` and `abandoned` fixtures never appear as cards.
- [x] T065 [P] [US3] Write `test/features/bookings/presentation/booking_details_screen_test.dart`: for the confirmed fixture, every section of T071 is present; the copy button puts the booking code on the clipboard (`tester.binding.defaultBinaryMessenger` mock for `SystemChannels.platform`, or read `Clipboard.getData` in the test) and shows `bookingCodeCopied`; instructions are visible; the only action button is `bookingContactSupport`; for the awaiting-owner fixture instructions are **not** shown; for a fixture whose `available_actions` is `['pay_remaining','request_cancellation','contact_support']` still only the support button appears; offline → the support button is disabled; unknown ID → the not-available view.

### Implementation for User Story 3

- [x] T066 [US3] Add display helpers (needs T013, T016, T032):
  - in `lib/core/time/cairo_time.dart` (or a new `lib/core/time/cairo_date_time_formatter.dart`) add `String formatCairoDayMonthTime(DateTime utc)` → `'<day> <Arabic month> – HH:mm'` in Cairo time with Western digits, built with `CairoTime` and the same month names `DateOnlyFormatter` uses; and `String formatCairoTime(DateTime utc)` → `HH:mm`;
  - in `lib/features/bookings/presentation/booking_status_ui.dart` add `String bookingStatusMessage(BookingDetails d, AppLocalizations l10n)` exactly: `paymentPending` → `bookingMsgPaymentPending`; `paymentVerifying` → `bookingMsgPaymentVerifying`; `awaitingOwner` → `bookingMsgAwaitingOwner(formatCairoDayMonthTime(d.ownerResponseDeadline!))` (if the deadline is null, use `bookingMsgAwaitingOwnerNoDeadline`); `confirmed` → `bookingMsgConfirmedWithRemaining(MoneyFormatter().format(d.remaining))` when `d.remaining.amountMinor > 0`, else `bookingMsgConfirmed`; `checkedIn` → `bookingMsgCheckedIn`; `completed` → `bookingMsgCompleted`; `rejected` → `bookingMsgRejected(format(d.paid))`; `expired` → `bookingMsgExpired(format(d.paid))`; `cancelled` → `bookingMsgCancelled`; `noShow` → `bookingMsgNoShow`; `paymentConflict` → `bookingMsgConflict(format(d.paid))`; `abandoned` → `bookingMsgAbandoned`; `unknown` → `bookingMsgUnknown`. The amounts are the server's `paid` / `remaining` values, shown as received (no arithmetic);
  - extend `test/features/bookings/presentation/booking_status_ui_test.dart` with one case per status.
- [x] T067 [US3] Create `lib/features/bookings/presentation/bookings_cubit.dart` (needs T016, T017, T022): `enum TabLoad { initial, loading, ready, failed, offline }`; `@immutable final class TabData { List<BookingSummary> items; String? nextCursor; TabLoad load; ApiError? error; DateTime? fetchedAt; bool fromCache; bool loadingMore; copyWith }`; `@immutable final class BookingsState { BookingTab selected; Map<BookingTab, TabData> tabs; }` (only `current`, `past`, `cancelled` keys — never `pending`). `BookingsCubit({required BookingsRepository bookings, required BookingsCache cache, required ConnectivityCubit connectivity})` with `start(BookingTab initial)`, `selectTab(BookingTab tab)`, `refresh()` (selected tab), `loadMore()`. Behaviour exactly as T062. Use a sequence number per tab to drop stale responses (G1 research R12 pattern: `SearchCubit` in `lib/features/search/presentation/search_cubit.dart`).
- [x] T068 [US3] Create `lib/features/bookings/presentation/booking_details_cubit.dart` (needs T016, T020, T022). States: `DetailsLoading`; `DetailsReady({required BookingDetails details, required String? instructions, required DateTime fetchedAt, required bool fromCache})`; `DetailsNotAvailable`; `DetailsFailed(ApiError error)`; `DetailsOffline`. Constructor `BookingDetailsCubit({required BookingsRepository bookings, required BookingsCache cache, required ArrivalInstructionsStore arrival, required NotificationSignalSource signals, required ConnectivityCubit connectivity, required String bookingId})`. `load()`: emit cached details (+ stored instructions) first if present; then, when online, fetch; on success `cache.saveDetails(details)`; if `details.status.showsArrivalInstructions && details.accessInstructions != null` → `arrival.write(id, text)`; if `details.status.isTerminal` → `arrival.remove(id)`; emit `DetailsReady(details: details.copyWithoutInstructions(), instructions: <fresh text or stored text when the status still shows instructions, else null>, fetchedAt: now, fromCache: false)`. Subscribe to signals with `entityId == bookingId` → `refresh()`. `NOT_FOUND` → `DetailsNotAvailable`. Makes T063 pass.
- [x] T069 [P] [US3] Create `lib/features/bookings/presentation/widgets/booking_card.dart`: `BookingCard({required BookingSummary booking, required VoidCallback onTap})` — `Card` with the cover image (`OnAirNetworkImage`, look at `property_card.dart`), title, `DateOnlyFormatter.dayMonth(checkIn) – dayMonth(checkOut)`, `StatusChip(label: bookingStatusLabel(...), tone: bookingStatusTone(...))`; for `awaitingOwner` with a deadline, a `CountdownText` (remaining from a `Countdown` created in a `StatefulWidget` state and cancelled in `dispose`, formatted with `l10n.ownerDeadlineCountdown(Countdown.format(d))`). The whole card is one `InkWell` with `Semantics(button: true, label: '<title>، <status label>')`. (US4 adds the refund chip.)
- [x] T070 [US3] Create `lib/features/bookings/presentation/bookings_screen.dart` (`BookingsScreen({BookingTab initialTab = BookingTab.current})`) replacing the placeholder: `DefaultTabController` with 3 tabs (labels Appendix A); each tab body is a `RefreshIndicator` + `CustomScrollView` with a `SliverList.builder` of `BookingCard` (tap → `context.push(AppRoutes.bookingDetails(id))`), loading skeletons (3 `SkeletonBox(height: 96)`), `EmptyView(icon: Icons.event_busy, message: <tab empty key>, action: OnAirPrimaryButton(label: l10n.bookingsFindApartment, onPressed: () => context.go(AppRoutes.search)))`, `ErrorView` for failures, an offline `EmptyView(icon: Icons.wifi_off, message: l10n.offline)` without cache, and — when `fromCache` — a small note `l10n.lastUpdated(formatCairoDayMonthTime(fetchedAt))` above the list. Load more when the scroll reaches 80 % (`ScrollNotification`). Delete `lib/features/bookings/presentation/bookings_placeholder_screen.dart` and its tests; update tests that referenced it.
- [x] T071 [US3] Create `lib/features/bookings/presentation/booking_details_screen.dart` (`BookingDetailsScreen({required String bookingId})`). For `DetailsReady`, a `CustomScrollView` with these sections, in this order (titles from Appendix A):
  1. header: cover image, title, area/city; a row with `l10n.bookingCode`, the code, and an `IconButton(tooltip: l10n.bookingCopyCode, icon: Icons.copy)` → `Clipboard.setData(ClipboardData(text: code))` + `SnackBar(l10n.bookingCodeCopied)`; `StatusChip` for the status (US4 adds the refund chip next to it);
  2. `NoticeCard(icon: Icons.info_outline, message: bookingStatusMessage(details, l10n))`;
  3. stay (`bookingStayTitle`): `AmountRow`s for arrival, departure (`DateOnlyFormatter.dayMonth`), `bookingNights` → `details.nights`, guests, and check-in/out times when present;
  4. payments (`bookingPaymentsTitle`): total, `bookingPaid` → paid, remaining + `bookingRemainingDue(date)` when `remaining > 0`; then one line per `PaymentLine`: method label (`kashier` → `paymentMethodCard`, `cash` → `paymentMethodCash`, other → `paymentMethodCard`), amount, status label (`succeeded` → `paymentLineSucceeded`; `failed | cancelled | expired` → `paymentLineFailed`; anything else → `paymentLinePending`), and `paidAt` formatted when present. No accounting words;
  5. (US4 inserts the refund section here);
  6. address (`bookingAddressTitle`): `details.property.addressText` when not null; then, only when `state.instructions != null` **and** `details.status.showsArrivalInstructions`, a sub-title `bookingArrivalInstructions` and the text (selectable);
  7. saved terms (`bookingSavedTermsTitle`): `policyLines(details.termsSnapshot!)` with `policyLineText` — skip the section when `termsSnapshot` is null;
  8. timeline (`bookingTimelineTitle`): `BookingTimeline(entries: details.events.map((e) => TimelineEntry(title: e.toStatus != null ? bookingStatusLabel(e.toStatus!, l10n) : l10n.bookingEventGeneric, time: formatCairoDayMonthTime(e.createdAt))))`;
  9. actions: for each code in `context.read<BookingActionRegistry>().visible(details.availableActions)` — in G2 only `contact_support` → `OutlinedButton(key: ValueKey('action-contact_support'), child: Text(l10n.bookingContactSupport), onPressed: online ? () => context.push('/support/new?booking=${details.id}') : null)`;
  10. when `fromCache`, the note `l10n.lastUpdated(...)` at the top.
  Other states: `DetailsLoading` → skeletons; `DetailsNotAvailable` → the content of `NotAvailableScreen`; `DetailsFailed` → `ErrorView` with reference; `DetailsOffline` → `ErrorView(message: l10n.offline, onRetry: cubit.load)`. Pull-to-refresh calls `refresh()`.
- [x] T072 [US3] Wire routes and support (needs T067–T071):
  - `lib/app/router/app_router.dart`: the bookings branch builds `BlocProvider(create: (context) => BookingsCubit(...)..start(_tabFrom(state.uri.queryParameters['tab'])), child: BookingsScreen(initialTab: …))` where `_tabFrom` maps `'past'`/`'cancelled'` to those tabs and anything else to `current`; replace the `linked-booking` route (`bookingDetailsPattern`) builder with `BlocProvider(create: (context) => BookingDetailsCubit(..., bookingId: state.pathParameters['id']!)..load(), child: BookingDetailsScreen(bookingId: id))` and rename it `booking-details`. Keep it outside the shell (as today) so notifications can open it from anywhere;
  - `lib/features/support/presentation/support_entry_placeholder_screen.dart`: add an optional `String? bookingId` parameter, shown the same way `propertyId` is; in the `supportNew` route read `state.uri.queryParameters['booking']` (only when it is a UUID v4) and pass it.
- [x] T073 [US3] Add goldens `test/features/bookings/goldens/bookings_goldens_test.dart` (copy `test/features/home/goldens/home_goldens_test.dart`): My Bookings with the Current tab loaded, and the details screen for the confirmed fixture, in Light/Dark × 1.0/1.3. Generate once with `--update-goldens` and inspect for clipping.

**Checkpoint**: US3 Independent Test passes; T062–T065 pass; US1 and US2 still pass.

---

## Phase 6: User Story 4 - Learn the owner's decision and the full refund (Priority: P2)

**Goal**: confirmed / rejected / expired / conflict bookings explain the outcome and the full
refund, and refund progress is shown apart from the booking status, with "Refunded" only after
the server's final check.

**Independent Test**: mock mode: open the rejected, expired, conflict, and cancelled fixtures →
each shows its message with the paid amount and a refund section whose stage matches the
fixture; only the `verified` refund shows `refundChipDone`.

### Tests for User Story 4

- [x] T074 [P] [US4] Write `test/features/bookings/presentation/refund_display_test.dart` (widget): for each refund fixture (`requested`, `approved`, `executed`, `verified`) the details screen shows the refund section with `refundAmount` = the fixture amount, `RefundStageTracker.currentIndex` = 0/1/2/3, and the chip label `refundChipRequested` / `refundChipInProgress` / `refundChipInProgress` / `refundChipDone`; `refundChipDone` and `refundStageVerified` appear **only** for `verified` (AC-042); a `failed` refund shows `refundChipProblem` and `refundProblemHint`; a booking card in the Cancelled tab with a refund shows the refund chip next to the status chip; the rejected fixture's message contains the formatted paid amount (AC-020) and the expired one too (AC-021); the confirmed fixture shows `bookingMsgConfirmedWithRemaining` (AC-019).

### Implementation for User Story 4

- [x] T075 [US4] Add the refund UI (needs T071, T069):
  - `lib/features/bookings/presentation/widgets/refund_section.dart`: `RefundSection({required RefundInfo refund})` with title `refundTitle`, an `AmountRow(label: l10n.refundAmount, value: MoneyFormatter().format(refund.amount))`, and `RefundStageTracker(stageLabels: [l10n.refundStageRequested, l10n.refundStageApproved, l10n.refundStageExecuting, l10n.refundStageVerified], currentIndex: switch (refund.stage) { requested => 0, approved => 1, executed => 2, verified => 3, _ => 0 }, failed: refund.stage == RefundStage.failed || refund.stage == RefundStage.cancelled)`; when failed, add `NoticeCard(icon: Icons.support_agent, message: l10n.refundProblemHint)`;
  - insert it into `BookingDetailsScreen` as section 5 when `details.refund != null`;
  - add `StatusChip(label: refundStageLabel(...), tone: refundStageTone(...))` next to the status chip in the details header and in `BookingCard` when `refund`/`refundStage` is not null.
  Makes T074 pass.
- [x] T076 [US4] Extend the goldens in `test/features/bookings/goldens/bookings_goldens_test.dart` (T073) with the conflict fixture (refund `executed`) and the cancelled fixture (refund `verified`); regenerate only those pictures.

**Checkpoint**: US4 Independent Test passes; T074 passes.

---

## Phase 7: User Story 5 - Get notified and open the right screen (Priority: P2)

**Goal**: push permission at the first successful payment, foreground banners, tap-to-open
routing (also from a closed app), the notification center, and a live unread count on the bell.

**Independent Test**: mock mode with `ControllablePushMessageSource` (tests) or the mock server's
signals: pay successfully → the permission sheet appears once → the bell shows the unread
count → open the center → tap `booking.request_received` → the booking opens and the count drops.

### Tests for User Story 5

- [ ] T077 [P] [US5] Write `test/app/router/notification_router_test.dart` for `NotificationRouter.locationFor(typeKey, entityType, entityId)` (T083): every row of contracts/app-routes.md §4 — booking/payment/cash/stay/refund/damage/review types with a valid UUID → `/bookings/<id>`; `support.staff_replied` → `/support/new`; `account.phone_changed` → `/account`; an unknown type, an invalid ID (`'x'`), or `entityType` other than the expected one → `/bookings`.
- [ ] T078 [P] [US5] Write `test/features/notifications/notification_texts_test.dart`: for each of the 31 type keys in Appendix A §"Notification texts", `notificationText(typeKey, l10n)` returns that type's title and body; `'something.new'` returns `notifGenericTitle` / `notifGenericBody`.
- [ ] T079 [P] [US5] Write `test/features/notifications/notifications_cubit_test.dart` for `NotificationsCubit` (T087): `load()` shows newest first; `loadMore()` passes `before = last.createdAt`; `open(n)` marks it read locally and calls `markRead([id])` once (a failure does not undo the navigation result); `markAllRead()` calls `markRead(null)` and sets every item's `readAt`; a new signal triggers a reload of the first page.
- [ ] T080 [P] [US5] Write `test/features/notifications/unread_count_cubit_test.dart` for `UnreadCountCubit` (T088): starts at the server count after `refresh()`; each signal adds 1 immediately and then refreshes from the server; `markedRead(n)` subtracts n but never below 0; sign-out (`reset()`) sets 0.
- [ ] T081 [P] [US5] Write `test/features/notifications/push_permission_coordinator_test.dart` for `PushPermissionCoordinator` (T089) with `FakeNotificationPermission` and `SharedPreferences.setMockInitialValues({})`: status `notDetermined` and flag unset → shows the sheet; "Enable" → `request()` called, flag set, and `DeviceRegistrationService.registerAfterSignIn()` called when granted; "Later" → flag set, no request; a second call never shows the sheet; status `denied` or `granted` → no sheet.
- [ ] T082 [P] [US5] Write widget tests: `test/features/notifications/notifications_screen_test.dart` (list order, unread highlight, tap opens the router location and marks read, "Mark all as read", empty view, the "Notifications are off" `NoticeCard` with a button calling `openSettings()` when status is `denied` and hidden when `granted`) and `test/features/notifications/in_app_banner_test.dart` (a foreground `PushMessage` shows the banner with the type's title for 4 s; tapping it navigates to the router location; an unknown type shows the generic title).

### Implementation for User Story 5

- [ ] T083 [P] [US5] Create `lib/app/router/notification_router.dart`: `abstract final class NotificationRouter { static String locationFor(String typeKey, String entityType, String entityId); }` implementing contracts/app-routes.md §4 exactly with G2 targets: prefixes `booking.`, `payment.`, `cash.`, `stay.`, `refund.`, `damage.`, `review.` → `AppRoutes.bookingDetails(entityId)` when `AppRoutes.isUuidV4(entityId)`; `support.` → `AppRoutes.supportNew`; `account.` → `AppRoutes.account`; anything else or invalid ID → `AppRoutes.bookings`. (`entityType` is accepted for later phases; in G2 it is not used for routing — document that.) Makes T077 pass.
- [ ] T084 [P] [US5] Create `lib/features/notifications/presentation/notification_texts.dart`: `({String title, String body}) notificationText(String typeKey, AppLocalizations l10n)` — a `switch` over the 31 type keys returning the Appendix A `notif…Title` / `notif…Body` getters; default → generic. Makes T078 pass.
- [ ] T085 [P] [US5] Create `lib/core/push/push_messages.dart`: `@immutable final class PushMessage { const PushMessage({required this.type, required this.targetId}); final String type; final String targetId; static PushMessage? fromData(Map<String, dynamic> data) }` (reads only `type` and `target_id`; null if either is missing); `abstract interface class PushMessageSource { Stream<PushMessage> get foreground; Stream<PushMessage> get opened; Future<PushMessage?> initial(); }`; `FirebasePushMessageSource` (`FirebaseMessaging.onMessage`, `FirebaseMessaging.onMessageOpenedApp`, `FirebaseMessaging.instance.getInitialMessage()`, each mapped through `fromData(message.data)` and skipping nulls); `NoopPushMessageSource` (empty streams, null). Create `test/helpers/controllable_push_message_source.dart` with two `StreamController.broadcast()` and a settable `initialMessage`.
- [ ] T086 [P] [US5] Create `lib/core/push/notification_permission.dart`: put the `app_settings` call noted in T001 in the header comment; `enum PushPermission { notDetermined, granted, denied }`; `abstract interface class NotificationPermission { Future<PushPermission> status(); Future<PushPermission> request(); Future<void> openSettings(); }`; `FirebaseNotificationPermission` (`FirebaseMessaging.instance.getNotificationSettings()` / `requestPermission()` mapping `AuthorizationStatus.authorized` and `provisional` → granted, `denied` → denied, `notDetermined` → notDetermined; `openSettings` → the `app_settings` call); `FakeNotificationPermission` (in-memory, settable `current` and `answer`, counts `requestCalls` and `openSettingsCalls`) — used by mock mode and tests.
- [ ] T087 [US5] Create `lib/features/notifications/presentation/notifications_cubit.dart` (needs T017, T020): states `NotificationsLoading`, `NotificationsReady({required List<AppNotification> items, required bool hasMore, required bool loadingMore})`, `NotificationsFailed(ApiError)`, `NotificationsOffline`. Constructor with `NotificationsRepository`, `NotificationSignalSource`, `ConnectivityCubit`, and `UnreadCountCubit`. Methods `load()`, `loadMore()` (`hasMore` is false when a page returns fewer than 30 items), `Future<String> open(AppNotification n)` (marks read locally, calls `markRead([n.id])` ignoring errors, calls `unread.markedRead(1)` if it was unread, returns `NotificationRouter.locationFor(...)`), `markAllRead()`. Reload the first page on each signal. Makes T079 pass.
- [ ] T088 [US5] Create `lib/features/notifications/presentation/unread_count_cubit.dart` (`Cubit<int>`, **app-scoped**): constructor with `NotificationsRepository` and `NotificationSignalSource`; `refresh()` → `unreadCount()` (errors ignored); listens to signals → `emit(state + 1)` then `refresh()`; `markedRead(int n)`; `reset()` → 0. Create it in `lib/app/app.dart` `initState`, provide it in `MultiBlocProvider`, call `refresh()` on `SignedIn` and on app resume (`_onResume` from T055), `reset()` on `SignedOut`, close in `dispose`. Makes T080 pass.
- [ ] T089 [US5] Create `lib/features/notifications/presentation/push_permission_coordinator.dart`: `final class PushPermissionCoordinator { PushPermissionCoordinator({required NotificationPermission permission, required DeviceRegistrationService? devices, Future<SharedPreferences> Function()? prefs}); static const askedKey = 'push_permission_asked'; Future<void> maybeAskAfterFirstSuccess(BuildContext context); }` — shows a `showModalBottomSheet` with `pushPermissionTitle`, `pushPermissionBody`, and buttons `pushPermissionEnable` (`ValueKey('push-enable')`) / `pushPermissionLater` (`ValueKey('push-later')`), as in T081. Add `'push_permission_asked'` to `SignOutService.preservedPreferenceKeys` in `lib/features/account_gate/application/sign_out_service.dart` (it holds no personal data). Provide the coordinator from `lib/bootstrap.dart` (remote: `FirebaseNotificationPermission()`; mock: `FakeNotificationPermission(answer: PushPermission.granted)`) together with `RepositoryProvider<NotificationPermission>`. Makes T081 pass.
- [ ] T090 [US5] Create `lib/features/notifications/presentation/notifications_screen.dart` and route it: app bar title `l10n.notifications` with an action `TextButton(l10n.notificationsMarkAllRead)`; a `FutureBuilder` on `NotificationPermission.status()` that shows `NoticeCard(icon: Icons.notifications_off_outlined, message: l10n.notificationsOffNotice, actionLabel: l10n.notificationsOpenSettings, onAction: permission.openSettings)` when `denied` (re-check status when the app resumes, using an `AppLifecycleListener` in the screen state); a `SliverList.builder` of tiles (title/body from `notificationText`, time `formatCairoDayMonthTime(createdAt)`, unread tiles with background `context.colors['badgeNavActive']`); tap → `final location = await cubit.open(n); if (context.mounted) context.push(location);`; empty → `EmptyView(icon: Icons.notifications_none, message: l10n.notificationsEmpty)`. In `app_router.dart` add a root-level `GoRoute(path: AppRoutes.notifications, name: 'notifications', builder: … BlocProvider(create: (c) => NotificationsCubit(...)..load(), child: const NotificationsScreen()))`.
- [ ] T091 [US5] Wire the bell in `lib/features/home/presentation/widgets/home_header.dart`: keep the key `notifications-button`; wrap the icon in `Badge(isLabelVisible: count > 0, label: Text(count > 99 ? '99+' : '$count'))` using `BlocBuilder<UnreadCountCubit, int>` (only when the user is signed in — read `AuthCubit` state; visitors see no badge); `onPressed` → `context.push(AppRoutes.notifications)` (the router sends visitors to sign-in and back); `Semantics` label `l10n.unreadBadge('$count')` when count > 0. Update the existing home header tests that expected the old SnackBar.
- [ ] T092 [US5] Handle push messages in `lib/app/app.dart` (needs T083–T085): read `PushMessageSource` from context in `initState` (provide it in bootstrap: remote `FirebasePushMessageSource()`, mock `NoopPushMessageSource()`; `OnAirApp` also accepts an optional `PushMessageSource? pushMessages` for tests);
  - `opened` stream and `initial()` (call `initial()` once at the end of `_initialize`) → `_router.push(NotificationRouter.locationFor(m.type, '', m.targetId))` — the redirect handles sign-in and comes back;
  - `foreground` stream → show `InAppNotificationBanner` (create `lib/features/notifications/presentation/in_app_notification_banner.dart`: a `Material` card at the top with the type's title from `notificationText`, auto-hidden after 4 s, tap → `_router.push(location)`, a close `IconButton` with tooltip `l10n.close`); keep the current banner in a `ValueNotifier<PushMessage?>` in the app state and render it in the existing `Stack` inside `MaterialApp.router`'s `builder` (under the offline banner). Do **not** add a local-notification package. Cancel subscriptions in `dispose`.
- [ ] T093 [US5] In `PaymentReturnScreen` (`lib/features/booking/presentation/payment_return_screen.dart`, T053), when the state first becomes `VerifyResolved(success)`, call `context.read<PushPermissionCoordinator>().maybeAskAfterFirstSuccess(context)` once (guard with a `bool _asked` in the widget state).

**Checkpoint**: US5 Independent Test passes; T077–T082 pass; earlier stories still pass.

---

## Phase 8: User Story 6 - Recover an interrupted payment (Priority: P3)

**Goal**: every interruption ends in a clear, safe state without a second charge: the
unfinished-payment banner, quote expiry with visible changes, changed terms, and retries.

**Independent Test**: mock mode: open the payment page → kill the app → reopen → banner on Home
and My Bookings opens the attempt; separately set `quoteTtl` to 1 minute, wait on the summary →
changed rows highlighted and "Confirm new amounts" required.

### Tests for User Story 6

- [ ] T094 [P] [US6] Write `test/features/bookings/presentation/unfinished_payment_cubit_test.dart` for `UnfinishedPaymentCubit` (T097): `refresh()` with a `payment_pending` booking on the server → `UnfinishedSome(booking)` (newest); none → `UnfinishedNone`; a stored attempt whose booking is no longer pending **and** not `payment_verifying` → the store is cleared; a stored attempt whose booking is still pending → kept; `targetFor(booking)` returns `/payment/return?booking=<id>` when the stored attempt has that booking ID, else `/bookings/<id>`; sign-out → `UnfinishedNone`.
- [ ] T095 [P] [US6] Write `test/features/booking/presentation/booking_flow_interruptions_test.dart` (`fakeAsync`): with `quoteTtl` 2 min, after `requestQuote()` the cubit calls `refreshQuote()` automatically 30 s before expiry; if the new quote differs, `pendingChange` is set and `canPay` is false until `acceptChange()`; identical → no `pendingChange`; `onPaymentError(quoteExpired)` triggers `refreshQuote()`; `onPaymentError(termsChanged)` reloads the property and sets `termsChanged: true`; `acceptNewTerms()` sets `termsHash` to the new `property.termsVersion`, clears `termsChanged`, and re-quotes; the timer is cancelled on `close()`.
- [ ] T096 [P] [US6] Write widget tests: `test/features/bookings/presentation/unfinished_payment_banner_test.dart` (banner visible on Home and My Bookings for `UnfinishedSome`, hidden for `UnfinishedNone`, tap goes to `targetFor`) and `test/features/booking/presentation/summary_interruptions_test.dart` (changed rows show the old value struck through and `highlighted: true`; the pay button is disabled until `quoteConfirmNew` is tapped; `termsChangedNotice` with the new policy lines and the `termsAcceptNew` button; double tap on pay → one session).

### Implementation for User Story 6

- [ ] T097 [US6] Create `lib/features/bookings/presentation/unfinished_payment_cubit.dart` (**app-scoped**): states `UnfinishedNone`, `UnfinishedSome(BookingSummary booking)`. Constructor `UnfinishedPaymentCubit({required BookingsRepository bookings, required PaymentAttemptStore attempts})`. `refresh()`: `bookings.listBookings(BookingTab.pending)` → newest item or none; then reconcile the stored attempt: if it has a `bookingId` that is not in the pending list, fetch `getBooking(bookingId)`; if that status is not `paymentVerifying`, `attempts.clear()` (on `NOT_FOUND` also clear). Errors are ignored (keep the previous state). `Future<String> targetFor(BookingSummary b)` as in T094. `reset()` → `UnfinishedNone`. In `lib/app/app.dart` create/provide/close it like `UnreadCountCubit` and call `refresh()` on `SignedIn`, on app resume, and after `PaymentAttemptCubit` emits `AttemptIdle`. Makes T094 pass.
- [ ] T098 [US6] Create `lib/features/bookings/presentation/widgets/unfinished_payment_banner.dart`: `BlocBuilder<UnfinishedPaymentCubit, …>` → `InfoBanner(tone: StatusTone.warning, message: l10n.unfinishedPaymentBanner, actionLabel: l10n.unfinishedPaymentOpen, onAction: () async { final target = await cubit.targetFor(b); if (context.mounted) context.push(target); })`, nothing for `UnfinishedNone`. Insert it at the top of `HomeScreen` (above the first section; open `lib/features/home/presentation/home_screen.dart` and add it as the first sliver, only for signed-in users) and at the top of `BookingsScreen` (above the tabs).
- [ ] T099 [US6] Extend `BookingFlowCubit` in `lib/features/booking/presentation/booking_flow_cubit.dart` (T048): a `Timer? _expiryTimer` set after every successful quote to fire at `quote.expiresAt − 30 s` (use the injected clock `DateTime Function() now`, default `DateTime.now().toUtc()`; if that moment has passed, fire on the next microtask) → `refreshQuote()`; `Future<void> refreshQuote()` re-requests the quote with the same inputs and, when `QuoteChange.between(old, next).hasChanges`, sets `pendingChange`; `void acceptChange()` clears it; `bool get canPay => quote != null && pendingChange == null && !termsChanged`; `Future<void> onPaymentError(ApiError e)` → `quoteExpired`: `refreshQuote()`; `termsChanged`: reload `listings.property(propertyId)` into `property` and set `termsChanged: true`; `Future<void> acceptNewTerms()` → `termsHash = property.termsVersion`, `termsChanged: false`, `requestQuote()`. Cancel `_expiryTimer` in `close()`. Makes T095 pass.
- [ ] T100 [US6] Update `SummaryScreen` in `lib/features/booking/presentation/summary_screen.dart` (T052): pay button uses `state.canPay`; when `pendingChange != null` show `InfoBanner(tone: StatusTone.warning, message: l10n.quoteChangedNotice)`, give every changed `AmountRow` its `previousValue` (old formatted amount) and `highlighted: true`, and show `OnAirPrimaryButton(key: ValueKey('quote-confirm-new'), label: l10n.quoteConfirmNew, onPressed: cubit.acceptChange)` instead of the pay button; when `termsChanged` show `NoticeCard(message: l10n.termsChangedNotice)`, the new policy lines (`policyLines(state.property!.policy)`), and `OnAirPrimaryButton(key: ValueKey('terms-accept-new'), label: l10n.termsAcceptNew, onPressed: cubit.acceptNewTerms)`. In the `PaymentAttemptCubit` listener, `AttemptFailed` with `quoteExpired` or `termsChanged` → `flowCubit.onPaymentError(error)` (no SnackBar); `rateLimited` → SnackBar with `apiErrorMessage` (it includes the wait time).
- [ ] T101 [US6] Write `integration_test/booking_journey_mock_test.dart` (mock mode, `app.main` of the staging entrypoint is not needed — pump `OnAirApp` with the mock backend like `test/helpers/mock_journey.dart`): sign in (mock), Book now → dates → summary → pay → mock "Succeed" → success; then a second journey with "Fail" → "Try again" → dates screen with the same stay; then "Never answer" → timeout after the backoff (use a shortened backoff injected through a test-only provider override) → My Bookings shows the booking in Current; then simulate a restart by rebuilding the app with the same `InMemorySecureStore` → the unfinished banner appears. Run with `flutter test integration_test/booking_journey_mock_test.dart`.

**Checkpoint**: all six stories work in mock mode; `flutter test` is green.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Staging checks, goldens for the new screens, accessibility, docs, and the final
gates.

- [ ] T102 [P] Write `integration_test/booking_payment_staging_test.dart` (remote mode; skip with `markTestSkipped('remote mode + Kashier test account required')` when `BACKEND_MODE` is mock or `KASHIER_TEST` is not set in `env/staging.json`): sign in with the seeded verified guest; quote a seeded deposit apartment; start payment twice with the same attempt key and assert the same `bookingId` (AC-023); open the page and wait for a tester to complete the test card (or use the provider's test automation if documented); assert the verification screen reaches success only after the server status changes (AC-015) and the charged amount equals the quote's pay-now (read `paid` from `getBooking`) (AC-016).
- [ ] T103 [P] Write `integration_test/booking_outcomes_staging_test.dart` (remote; skips like T102): for seeded bookings in `confirmed`, `rejected`, `expired`, `payment_conflict`, and refunds in each stage, open details and assert the message, refund stage, and that "Refunded" appears only for `verified` (AC-019, AC-020, AC-021, AC-042); assert the guest's notification center contains the matching notification rows (AC-024).
- [ ] T104 [P] Write `integration_test/booking_isolation_test.dart` (remote; skips like T102): signed in as guest A, open `/bookings/<guest B's seeded booking id>` → the not-available view; `BookingsRepository.getBooking(<B id>)` throws `ErrorCode.notFound`; the list for every tab contains no B booking (SC-007).
- [ ] T105 [P] Add screen goldens in `test/features/booking/goldens/booking_flow_goldens_test.dart`: dates screen (range picked), summary (deposit quote), summary with `pendingChange`, and the payment-return screen in each of the five states — Light/Dark × 1.0/1.3. Add `test/features/notifications/goldens/notifications_goldens_test.dart` for the center with unread items and the off notice. Generate once and inspect.
- [ ] T106 [P] Accessibility pass: run the app with TalkBack (Android) and VoiceOver (iOS) through Book now → verify → dates → summary → pay → result → My Bookings → details → notifications. Every control must be announced with a meaningful label; the countdown must not announce every second (wrap it in `ExcludeSemantics` and expose a `Semantics(label: <deadline text>)` on its container instead). Record results in `docs/qa/g2-accessibility.md` (copy the layout of `docs/qa/` G1 files if present).
- [ ] T107 Remove the G1 placeholder strings that are no longer used from `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`: run `grep -rn "bookingEntryComingSoon\|bookingEntryTermsCarried\|bookingEntryTitle" lib test`; delete each key (and its `@` block) from both `.arb` files only if nothing references it; run `flutter gen-l10n`.
- [ ] T108 Update `docs/OnAir Guest App Plan.md` §17 G2: tick the six G2 items, and add a status note under them in the same style as the G1 note: "**حالة G2 (<date>):** …" listing what is done in mock mode and what remote mode waits for (contract deltas D0–D4 in `contracts/supabase-booking.md`, the Kashier test account and return link, Staging seed). Do not change any other section.
- [ ] T109 Final gates, in order: `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`, `flutter test --tags golden`, `bash tool/check_hardcoded_styles.sh`. Then run quickstart scenarios 1–25 in mock mode (`specs/003-guest-booking-payment/quickstart.md`) and record pass/fail per scenario in `docs/qa/g2-quickstart-results.md`. Every failure must be fixed or listed with its reason.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: needs Setup. **Blocks every user story.**
- **US1 (Phase 3)**: needs Phase 2. The MVP.
- **US2 (Phase 4)**: needs Phase 2 and the booking `ShellRoute` + screens of US1 (T048, T051, T052, T054), because it plugs into them.
- **US3 (Phase 5)**: needs Phase 2 only. Can run in parallel with US1/US2.
- **US4 (Phase 6)**: needs US3 (T069, T071).
- **US5 (Phase 7)**: needs Phase 2; T093 needs US1's T053; T091 touches the Home header only.
- **US6 (Phase 8)**: needs US1 (T048, T049, T052) and US3 (T070) for the banner placement.
- **Polish (Phase 9)**: needs every story you ship.

### Within each story

- Tests first; they must fail before the implementation task they name.
- Models/domain → cubits → screens → routing/wiring.
- Run `flutter test` at every checkpoint.

### Same-file warnings (do not run these in parallel)

- `lib/app/app.dart`: T036, T047, T055, T088, T092, T097 — do them one at a time, in order.
- `lib/app/router/app_router.dart`: T047, T054, T061, T072, T090.
- `lib/bootstrap.dart`: T035, T089, T092.
- `lib/features/booking/presentation/summary_screen.dart`: T052, T061, T100.
- `lib/features/booking/presentation/booking_flow_cubit.dart`: T048, T061, T099.
- `lib/features/bookings/presentation/booking_details_screen.dart`: T071, T075.

## Parallel Example: Phase 2

```text
Together (different files): T005, T006, T007, T008, T009, T010, T011
Then together: T013, T014, T015, T017, T018, T019, T020, T021
Then together: T024, T025, T028, T029, T030
```

## Parallel Example: User Story 1

```text
Tests together: T038, T039, T040, T041, T042, T043
Domain together: T044, T045, T046
Then in order: T047 → T048 → T049 → T050 → T051 → T052 → T053 → T054 → T055 → T056
```

## Parallel Example: User Story 3 and User Story 5 (two implementers)

```text
Implementer A: T062–T073 (US3), then T074–T076 (US4)
Implementer B: T077–T086 (US5 tests + core), then T087–T093
```

---

## Implementation Strategy

### MVP first (User Story 1)

1. Phase 1 → Phase 2 (checkpoint: full suite green, app starts in mock mode).
2. Phase 3 (US1) → run the US1 Independent Test in mock mode.
3. Stop and demo: a verified guest can book and pay in mock mode, and the quote/start-payment
   calls already work on Staging.

### Incremental delivery

1. US2 (verification gate) — needed before real guests can pay (AC-001).
2. US3 (My Bookings) — needs backend delta D1/D2 for remote mode; mock first.
3. US4 (refund display) — small, on top of US3.
4. US5 (notifications) — can start right after Phase 2.
5. US6 (interruptions) — last; it hardens US1.
6. Phase 9 — Staging checks once the backend deltas and seed exist.

---

## Notes

- `[P]` tasks touch different files and have no dependency on an unfinished task.
- Commit after each task (or each small group) with a clear English message; do not commit
  generated goldens you did not inspect.
- Never edit files in `lib/core/api/generated/` by hand.
- Never add backend files (SQL, migrations, Node code) to this repository (AGENTS.md).
- If a task seems to need a value the docs do not give (a fee, a price rule, a status), stop and
  ask — do not invent it (Constitution I).

---

## Appendix A — Localization keys

Add to `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`. Placeholders are always `String`. For
each key with placeholders, add to `app_ar.arb` a metadata block like:

```json
"bookingNightsCount": "عدد الليالي: {count}",
"@bookingNightsCount": { "placeholders": { "count": { "type": "String" } } },
```

### Errors

| Key | Arabic | English |
|---|---|---|
| `errorAccountSuspended` | الحساب موقوف. تواصل مع خدمة العملاء. | Your account is suspended. Please contact support. |
| `authPhoneAlreadyUsed` | الرقم ده مستخدم في حساب تاني. | This number is already used by another account. |
| `bookingPolicyOutOfBounds` | السعر مش ثابت على التواريخ دي. جرّب تواريخ تانية أو تواصل مع الدعم. | The price is not fixed for these dates. Try other dates or contact support. |
| `errorConflict` | البيانات اتغيرت. حدّث الصفحة وجرّب تاني. | The data changed. Refresh and try again. |
| `bookingStateChanged` | حالة الحجز اتغيرت. حدّث الصفحة. | The booking status changed. Please refresh. |
| `errorDuplicateOperation` | العملية دي اتعملت قبل كده. | This operation was already done. |
| `paymentVerificationIssue` | فيه مشكلة في التحقق من الدفع. فريقنا هيتواصل معاك. | There is an issue verifying the payment. Our team will contact you. |
| `close` *(add only if missing)* | إغلاق | Close |

### Dates and summary

| Key | Arabic | English |
|---|---|---|
| `bookingDatesTitle` | اختار التواريخ | Choose dates |
| `bookingRangeHasUnavailable` | الفترة دي فيها يوم مش متاح. اختار تواريخ تانية. | This range includes an unavailable day. Choose other dates. |
| `bookingNightsCount` `{count}` | عدد الليالي: {count} | Nights: {count} |
| `bookingContinue` | متابعة | Continue |
| `bookingStartFromProperty` | ابدأ الحجز من صفحة الشقة. | Start the booking from the apartment page. |
| `bookingSummaryTitle` | ملخص الحجز | Booking summary |
| `bookingNights` | الليالي | Nights |
| `bookingNightlyPrice` | سعر الليلة | Price per night |
| `bookingTotal` | الإجمالي | Total |
| `bookingPayNow` | المطلوب دفعه دلوقتي | Due now |
| `bookingRemaining` | المتبقي | Remaining |
| `bookingRemainingDue` `{date}` | يتسدد قبل {date} | Due before {date} |
| `bookingPolicyTitle` | الشروط وسياسة الإلغاء | Terms and cancellation policy |
| `bookingSummaryOwnerNotice` | هيتبعت طلبك للمالك بعد الدفع. لو رفض أو مردّش خلال 24 ساعة هيترد لك المبلغ بالكامل. | Your request goes to the owner after payment. If they decline or do not reply within 24 hours, you get a full refund. |
| `bookingGoToPayment` | اذهب للدفع | Go to payment |
| `paymentReturnHint` | لو خلّصت الدفع، اضغط هنا عشان نتحقق منه. | If you finished paying, tap here so we can check it. |
| `paymentCheckStatus` | تحقق من الدفع | Check payment |

### Payment return

| Key | Arabic | English |
|---|---|---|
| `paymentVerifying` | جارٍ التحقق من الدفع… | Verifying your payment… |
| `paymentVerifyingBody` | ده ممكن ياخد دقايق. هنبلغك أول ما يتأكد. | This can take a few minutes. We will notify you once it is confirmed. |
| `paymentSuccessTitle` | تم الدفع وأُرسل طلبك للمالك | Payment received and your request was sent to the owner |
| `paymentSuccessBody` | التواريخ محجوزة لك لحد ما المالك يرد. | The dates are held for you until the owner replies. |
| `ownerDeadlineCountdown` `{time}` | المالك قدامه {time} للرد | The owner has {time} to reply |
| `paymentViewBooking` | عرض الحجز | View booking |
| `paymentFailedTitle` | لم تكتمل عملية الدفع | The payment was not completed |
| `paymentFailedBody` | ولم يُخصم أي مبلغ. | Nothing was charged. |
| `paymentTryAgain` | حاول مرة أخرى | Try again |
| `paymentConflictTitle` | التواريخ اتحجزت قبل اكتمال دفعتك | These dates were booked before your payment completed |
| `paymentConflictBody` `{amount}` | هيترد لك المبلغ بالكامل ({amount}). | You will get a full refund ({amount}). |
| `paymentFindOtherDates` | ابحث عن تواريخ تانية | Find other dates |
| `paymentTimeoutTitle` | لسه موصلناش تأكيد الدفع | We have not received payment confirmation yet |
| `paymentTimeoutBody` | متقلقش ومتدفعش تاني. هنبلغك أول ما يتأكد. | Don't worry and don't pay again. We will notify you once it is confirmed. |
| `paymentGoToBookings` | اذهب لحجوزاتي | Go to My Bookings |

### Mock payment page (mock mode only)

| Key | Arabic | English |
|---|---|---|
| `mockPaymentTitle` | صفحة دفع تجريبية | Test payment page |
| `mockPaySuccess` | دفع ناجح | Succeed |
| `mockPayFailure` | فشل الدفع | Fail |
| `mockPayConflict` | دفع ناجح بتواريخ محجوزة | Succeed with conflict |
| `mockPaySilent` | الخادم ما يردش | Server never answers |
| `mockPayClose` | إغلاق الصفحة | Close the page |

### Verification before booking

| Key | Arabic | English |
|---|---|---|
| `verifyTitle` | تأكيد بياناتك | Confirm your details |
| `verifyIntro` | قبل أول حجز لازم نأكد بريدك ورقم موبايلك بكود يوصلك على البريد. | Before your first booking we confirm your email and mobile number with a code sent to your email. |
| `verifyEmailCodeHint` | اكتب الكود اللي وصلك على البريد | Enter the code sent to your email |
| `verifyHasWhatsapp` | الرقم ده عليه واتساب | This number has WhatsApp |
| `verifyWhatsappNumber` | رقم الواتساب (اختياري) | WhatsApp number (optional) |
| `verifyCodeSentToEmail` | بعتنا كود من 6 أرقام على بريدك. | We sent a 6-digit code to your email. |
| `verifyResend` | ابعت الكود تاني | Resend code |
| `verifyResendIn` `{seconds}` | تقدر تبعت الكود تاني بعد {seconds} ثانية | You can resend in {seconds} s |

### My Bookings

| Key | Arabic | English |
|---|---|---|
| `bookingsTabCurrent` | الحالية | Current |
| `bookingsTabPast` | السابقة | Past |
| `bookingsTabCancelled` | الملغاة | Cancelled |
| `bookingsEmptyCurrent` | مفيش حجوزات حالية. | No current bookings. |
| `bookingsEmptyPast` | مفيش إقامات سابقة. | No past stays. |
| `bookingsEmptyCancelled` | مفيش حجوزات ملغاة. | No cancelled bookings. |
| `bookingsFindApartment` | ابحث عن شقة | Find an apartment |
| `lastUpdated` `{time}` | آخر تحديث: {time} | Last updated: {time} |

### Booking status labels (Guest Plan §4.6)

| Key | Arabic | English |
|---|---|---|
| `bookingStatusPaymentPending` | بانتظار إتمام الدفع | Payment not completed |
| `bookingStatusPaymentVerifying` | جارٍ التحقق من الدفع | Verifying payment |
| `bookingStatusAwaitingOwner` | بانتظار تأكيد المالك | Awaiting owner |
| `bookingStatusPaymentConflict` | التواريخ اتحجزت قبلك | Dates taken first |
| `bookingStatusConfirmed` | حجز مؤكد | Confirmed |
| `bookingStatusCheckedIn` | إقامة جارية | Stay in progress |
| `bookingStatusCompleted` | إقامة مكتملة | Stay completed |
| `bookingStatusRejected` | رفض المالك | Declined by owner |
| `bookingStatusExpired` | انتهت مهلة التأكيد | Owner did not reply |
| `bookingStatusCancelled` | ملغي | Cancelled |
| `bookingStatusNoShow` | لم يحضر | No-show |
| `bookingStatusAbandoned` | لم يكتمل | Not completed |
| `bookingStatusUnknown` | تحديث على الحجز | Booking update |

### Booking status messages (Guest Plan §7.2)

| Key | Arabic | English |
|---|---|---|
| `bookingMsgPaymentPending` | لم يكتمل الدفع بعد. تقدر تكمّل الدفع عشان طلبك يتبعت للمالك. | Payment is not completed yet. Complete it to send your request to the owner. |
| `bookingMsgPaymentVerifying` | نتحقق من عملية الدفع. قد يستغرق ذلك دقائق، وسنبلغك فور التأكيد. | We are verifying your payment. This can take minutes; we will notify you once confirmed. |
| `bookingMsgAwaitingOwner` `{deadline}` | تم الدفع وأُرسل طلبك للمالك. المالك لديه حتى {deadline} للرد. التواريخ محجوزة لك حتى ذلك الحين. | Paid and sent to the owner. The owner has until {deadline} to reply. The dates are held for you until then. |
| `bookingMsgAwaitingOwnerNoDeadline` | تم الدفع وأُرسل طلبك للمالك. التواريخ محجوزة لك لحد ما يرد. | Paid and sent to the owner. The dates are held for you until they reply. |
| `bookingMsgConfirmed` | تم تأكيد حجزك! | Your booking is confirmed! |
| `bookingMsgConfirmedWithRemaining` `{amount}` | تم تأكيد حجزك! يجب سداد {amount} قبل الاستلام. | Your booking is confirmed! {amount} must be paid before check-in. |
| `bookingMsgCheckedIn` | نتمنى لك إقامة سعيدة. | Enjoy your stay. |
| `bookingMsgCompleted` | اكتملت إقامتك. شاركنا رأيك! | Your stay is complete. Tell us how it went! |
| `bookingMsgRejected` `{amount}` | اعتذر المالك عن قبول الطلب. سيتم رد كامل المبلغ ({amount}). سيتواصل معك فريق OnAir وقد يقترح بديلًا إن رغبت. | The owner declined. You will get a full refund ({amount}). The OnAir team may contact you with an alternative. |
| `bookingMsgExpired` `{amount}` | لم يرد المالك خلال 24 ساعة. سيتم رد كامل المبلغ ({amount}). | The owner did not reply within 24 hours. You will get a full refund ({amount}). |
| `bookingMsgCancelled` | تم إلغاء الحجز. | The booking was cancelled. |
| `bookingMsgNoShow` | تم تسجيل عدم الحضور. للاستفسار تواصل مع الدعم. | A no-show was recorded. Contact support with any questions. |
| `bookingMsgConflict` `{amount}` | تم حجز هذه التواريخ قبل اكتمال دفعتك. سيتم رد المبلغ بالكامل ({amount}). | These dates were booked before your payment completed. You will get a full refund ({amount}). |
| `bookingMsgAbandoned` | لم يكتمل الدفع ولم يُخصم أي مبلغ. | The payment was not completed and nothing was charged. |
| `bookingMsgUnknown` | فيه تحديث على حجزك. للاستفسار تواصل مع الدعم. | There is an update on your booking. Contact support with any questions. |

### Booking details

| Key | Arabic | English |
|---|---|---|
| `bookingCode` | رقم الحجز | Booking number |
| `bookingCopyCode` | نسخ رقم الحجز | Copy booking number |
| `bookingCodeCopied` | تم نسخ رقم الحجز | Booking number copied |
| `bookingStayTitle` | الإقامة | Stay |
| `bookingArrival` | الوصول | Arrival |
| `bookingDeparture` | المغادرة | Departure |
| `bookingCheckInTime` | وقت الاستلام | Check-in time |
| `bookingCheckOutTime` | وقت المغادرة | Check-out time |
| `bookingPaymentsTitle` | المدفوعات | Payments |
| `bookingPaid` | المدفوع | Paid |
| `paymentMethodCard` | بطاقة / محفظة | Card / wallet |
| `paymentMethodCash` | نقدًا | Cash |
| `paymentLineSucceeded` | تم | Done |
| `paymentLinePending` | قيد التنفيذ | In progress |
| `paymentLineFailed` | لم يكتمل | Not completed |
| `bookingAddressTitle` | العنوان | Address |
| `bookingArrivalInstructions` | تعليمات الوصول | Arrival instructions |
| `bookingSavedTermsTitle` | الشروط وقت الحجز | Terms at booking time |
| `bookingTimelineTitle` | سجل الحجز | Booking history |
| `bookingEventGeneric` | تحديث على الحجز | Booking update |
| `bookingContactSupport` | تحتاج مساعدة؟ تواصل مع OnAir | Need help? Contact OnAir |

### Refund

| Key | Arabic | English |
|---|---|---|
| `refundChipRequested` | تم طلب الاسترداد | Refund requested |
| `refundChipInProgress` | الاسترداد قيد التنفيذ | Refund in progress |
| `refundChipDone` | تم رد المبلغ | Refunded |
| `refundChipProblem` | مشكلة في الاسترداد | Refund issue |
| `refundTitle` | الاسترداد | Refund |
| `refundAmount` | مبلغ الاسترداد | Refund amount |
| `refundStageRequested` | طُلب | Requested |
| `refundStageApproved` | اعتُمد | Approved |
| `refundStageExecuting` | قيد التنفيذ | In progress |
| `refundStageVerified` | تم التحقق من وصوله | Received |
| `refundProblemHint` | فيه مشكلة في الاسترداد. فريق OnAir بيتابعها، وتقدر تتواصل مع الدعم. | There is an issue with the refund. The OnAir team is on it; you can contact support. |

### Interruptions

| Key | Arabic | English |
|---|---|---|
| `unfinishedPaymentBanner` | عندك دفع لم يكتمل. | You have an unfinished payment. |
| `unfinishedPaymentOpen` | عرض | View |
| `quoteChangedNotice` | السعر اتحدّث. راجع المبالغ الجديدة قبل الدفع. | The price was updated. Review the new amounts before paying. |
| `quoteConfirmNew` | أكّد المبالغ الجديدة | Confirm new amounts |
| `termsChangedNotice` | الشروط اتحدّثت. راجعها ووافق عليها للمتابعة. | The terms were updated. Review and accept them to continue. |
| `termsAcceptNew` | أوافق على الشروط الجديدة | I accept the new terms |

### Notifications

| Key | Arabic | English |
|---|---|---|
| `notificationsMarkAllRead` | تحديد الكل كمقروء | Mark all as read |
| `notificationsEmpty` | مفيش إشعارات لسه. | No notifications yet. |
| `notificationsOffNotice` | الإشعارات مقفولة. فعّلها عشان تعرف فورًا لما المالك يرد. | Notifications are off. Turn them on to know as soon as the owner replies. |
| `notificationsOpenSettings` | فتح الإعدادات | Open settings |
| `pushPermissionTitle` | فعّل الإشعارات | Turn on notifications |
| `pushPermissionBody` | عشان تعرف فورًا لما المالك يرد على طلبك. | So you know as soon as the owner replies to your request. |
| `pushPermissionEnable` | فعّل | Turn on |
| `pushPermissionLater` | مش دلوقتي | Not now |
| `unreadBadge` `{count}` | {count} إشعار غير مقروء | {count} unread notifications |

### Notification texts (one title + body per type; no placeholders)

Key pattern: `notif` + the type key in CamelCase without dots/underscores + `Title`/`Body`
(e.g. `booking.request_received` → `notifBookingRequestReceivedTitle`).

| Type key | Title (ar) | Body (ar) | Title (en) | Body (en) |
|---|---|---|---|---|
| `booking.request_received` | تم الدفع وأُرسل طلبك | المالك هيرد خلال 24 ساعة. اضغط للتفاصيل. | Request sent | The owner replies within 24 hours. Tap for details. |
| `booking.confirmed` | تم تأكيد حجزك ✓ | اضغط للتفاصيل. | Booking confirmed ✓ | Tap for details. |
| `booking.rejected` | المالك اعتذر عن الطلب | هيترد لك المبلغ بالكامل. اضغط للتفاصيل. | Request declined | You will get a full refund. Tap for details. |
| `booking.expired` | المالك مردّش في المهلة | هيترد لك المبلغ بالكامل. اضغط للتفاصيل. | No reply in time | You will get a full refund. Tap for details. |
| `booking.payment_conflict` | التواريخ اتحجزت قبل دفعتك | هيترد لك المبلغ بالكامل. اضغط للتفاصيل. | Dates taken first | You will get a full refund. Tap for details. |
| `booking.cancelled_by_guest` | تم إلغاء حجزك | اضغط للتفاصيل. | Booking cancelled | Tap for details. |
| `booking.cancelled_by_platform` | OnAir ألغت الحجز | اضغط للتفاصيل. | Booking cancelled by OnAir | Tap for details. |
| `booking.replacement_offered` | عندك عرض بديل | اضغط لمراجعة العرض. | Alternative offer | Tap to review the offer. |
| `booking.no_show_recorded` | تم تسجيل عدم الحضور | اضغط للتفاصيل. | No-show recorded | Tap for details. |
| `booking.reopened` | تم إعادة فتح الحجز | اضغط للتفاصيل. | Booking reopened | Tap for details. |
| `payment.failed` | لم يكتمل الدفع | ولم يُخصم أي مبلغ. | Payment not completed | Nothing was charged. |
| `payment.remaining_due` | تذكير بسداد المتبقي | لازم يتسدد قبل الاستلام. | Remaining amount due | Pay it before check-in. |
| `payment.remaining_paid` | تم سداد المتبقي | اضغط للتفاصيل. | Remaining amount paid | Tap for details. |
| `cash.confirmation_requested` | أكّد الدفع النقدي | الكود على بريدك. | Confirm cash payment | The code is in your email. |
| `cash.payment_confirmed` | تم تأكيد الدفع النقدي | اضغط للإيصال. | Cash payment confirmed | Tap for the receipt. |
| `stay.checkin_reminder` | ميعاد وصولك قرّب | اضغط للتفاصيل. | Check-in is soon | Tap for details. |
| `stay.checkout_reminder` | ميعاد المغادرة قرّب | اضغط للتفاصيل. | Check-out is soon | Tap for details. |
| `stay.host_handover_confirmed` | المالك أكّد تسليم الشقة | أكّد استلامك من التطبيق. | Owner confirmed handover | Confirm you received the apartment. |
| `stay.checked_in` | بدأت إقامتك | نتمنى لك إقامة سعيدة. | Your stay started | Enjoy your stay. |
| `stay.completed` | اكتملت إقامتك | شاركنا رأيك! | Your stay is complete | Tell us how it went! |
| `damage.claim_opened` | فيه مطالبة على حجزك | اضغط للمراجعة. | A claim was opened | Tap to review. |
| `damage.resolved` | تم البت في المطالبة | اضغط للتفاصيل. | Claim resolved | Tap for details. |
| `refund.requested` | تم طلب الاسترداد | اضغط للتفاصيل. | Refund requested | Tap for details. |
| `refund.executed` | الاسترداد قيد التنفيذ | اضغط للتفاصيل. | Refund in progress | Tap for details. |
| `refund.verified` | تم رد المبلغ | اضغط للتفاصيل. | Refund received | Tap for details. |
| `support.staff_replied` | رد جديد من خدمة العملاء | اضغط للقراءة. | New reply from support | Tap to read. |
| `support.case_resolved` | تم حل حالتك | اضغط للتفاصيل. | Your case is resolved | Tap for details. |
| `review.approved` | تم نشر تقييمك | شكرًا لمشاركتك. | Your review is published | Thanks for sharing. |
| `review.rejected` | تقييمك مش هيتنشر | اضغط للتفاصيل. | Your review was not published | Tap for details. |
| `account.phone_changed` | تم تغيير رقم الموبايل | لو مش انت، تواصل مع الدعم. | Mobile number changed | If this wasn't you, contact support. |
| `account.password_changed` | تم تغيير كلمة المرور | لو مش انت، تواصل مع الدعم. | Password changed | If this wasn't you, contact support. |
| *(generic)* `notifGenericTitle` / `notifGenericBody` | عندك تحديث جديد | اضغط للتفاصيل. | You have a new update | Tap for details. |

---

## Appendix B — Mock fixtures

### `lib/features/bookings/data/fixtures/bookings.json`

A JSON **array** of booking objects in the D1 shape (contracts/supabase-booking.md §4). The first
object, exactly (this is "the Appendix B example" used by tests):

```json
{
  "id": "b0000000-0000-4000-8000-000000000001",
  "code": "OA-MOCK001",
  "status": "confirmed",
  "property": {
    "id": "00000000-0000-4000-8000-00000000001f",
    "title": "شقة 3 غرف للتجربة",
    "cover_image": { "variants": [ { "width": 320, "url": "https://cdn.mock.onair.test/310-320.jpg" }, { "width": 720, "url": "https://cdn.mock.onair.test/310-720.jpg" } ], "blurhash": null },
    "area_name": "المعادي", "city_name": "القاهرة",
    "address_text": "شارع 9، المعادي، القاهرة",
    "check_in_time": "14:00", "check_out_time": "12:00"
  },
  "check_in": "2026-11-20", "check_out": "2026-11-23", "nights": 3, "guests_count": 2,
  "nightly_minor": 150000, "total_minor": 450000, "pay_now_minor": 112500,
  "paid_minor": 112500, "remaining_minor": 337500, "remaining_due_at": "2026-11-19T22:00:00Z",
  "currency": "EGP",
  "owner_response_deadline": null,
  "payment_state": "succeeded",
  "payments": [
    { "id": "c0000000-0000-4000-8000-000000000001", "purpose": "initial", "method": "kashier", "status": "succeeded", "amount_minor": 112500, "paid_at": "2026-10-28T09:00:00Z" }
  ],
  "refund": null,
  "terms_snapshot": { "policy_summary": { "deposit_type": "percent", "deposit_percent_bp": 2500, "deposit_amount_minor": null, "free_cancellation_hours": 72 } },
  "access_instructions": "المفتاح مع حارس العمارة. اطلب منه باسم الحجز.",
  "available_actions": ["contact_support"],
  "events": [
    { "event_type": "booking.started", "to_status": "payment_pending", "created_at": "2026-10-28T08:55:00Z", "note": null },
    { "event_type": "booking.confirmed", "to_status": "confirmed", "created_at": "2026-10-28T12:00:00Z", "note": null }
  ],
  "created_at": "2026-10-28T08:55:00Z"
}
```

Then add these objects (same shape; copy the first one and change only what the row says;
`payment_state` is `succeeded` unless stated; `refund` is null unless stated; refund `amount_minor`
always equals `paid_minor`; `access_instructions` is null for every row except 01 and 04; every
`available_actions` is `["contact_support"]` unless stated; IDs end with the two-digit number;
property IDs `…1f`, `…20`, `…21`, `…22` are G1 fixture apartments):

| # | status | property | check_in → check_out | nightly / total / pay_now / paid / remaining | other fields |
|---|---|---|---|---|---|
| 02 | `awaiting_owner` | `…20` | 2026-11-10 → 2026-11-12 | 120000 / 240000 / 60000 / 60000 / 180000 | `owner_response_deadline: "2026-11-02T10:00:00Z"` |
| 03 | `payment_verifying` | `…21` | 2026-12-01 → 2026-12-05 | 100000 / 400000 / 100000 / 0 / 400000 | `payment_state: "pending"` |
| 04 | `checked_in` | `…22` | 2026-10-29 → 2026-11-02 | 90000 / 360000 / 360000 / 360000 / 0 | `access_instructions: "الدور الثالث، شقة 7."`, `available_actions: ["pay_remaining", "request_cancellation", "contact_support"]` |
| 05 | `completed` | `…1f` | 2026-09-10 → 2026-09-13 | 150000 / 450000 / 450000 / 450000 / 0 | — |
| 06 | `rejected` | `…20` | 2026-11-15 → 2026-11-17 | 120000 / 240000 / 60000 / 60000 / 180000 | refund `{"id": "d…06", "amount_minor": 60000, "status": "requested", "updated_at": "2026-10-27T10:00:00Z"}` |
| 07 | `expired` | `…21` | 2026-11-18 → 2026-11-20 | 100000 / 200000 / 50000 / 50000 / 150000 | refund status `approved` |
| 08 | `cancelled` | `…22` | 2026-10-05 → 2026-10-07 | 90000 / 180000 / 180000 / 180000 / 0 | refund status `verified` |
| 09 | `no_show` | `…1f` | 2026-10-01 → 2026-10-03 | 150000 / 300000 / 75000 / 75000 / 225000 | — |
| 10 | `payment_conflict` | `…20` | 2026-11-25 → 2026-11-27 | 120000 / 240000 / 60000 / 60000 / 180000 | refund status `executed` |
| 11 | `payment_pending` | `…21` | 2026-12-10 → 2026-12-12 | 100000 / 200000 / 50000 / 0 / 200000 | `payment_state: "failed"`, `payments[0].status: "failed"`, `paid_at: null` |
| 12 | `abandoned` | `…22` | 2026-12-20 → 2026-12-22 | 90000 / 180000 / 45000 / 0 / 180000 | `payment_state: "failed"` |
| 13 | `completed` | `…21` | 2026-08-01 → 2026-08-04 | 100000 / 300000 / 300000 / 300000 / 0 | — |

Use `created_at` values that make the "newest first" orders unambiguous (row number × 1 hour
after `2026-10-20T00:00:00Z`), and timeline `events` that end with an event whose `to_status`
equals the row's status. Refund IDs: `d0000000-0000-4000-8000-0000000000NN`.

**List item example** (what `guest_list_bookings` returns per item, used by T006):

```json
{ "id": "b0000000-0000-4000-8000-000000000002", "code": "OA-MOCK002", "property_id": "00000000-0000-4000-8000-000000000020", "title": "شقة 3 غرف", "cover_image": null, "check_in": "2026-11-10", "check_out": "2026-11-12", "status": "awaiting_owner", "refund_status": null, "owner_response_deadline": "2026-11-02T10:00:00Z", "created_at": "2026-10-20T02:00:00Z" }
```

`MockBookingServer` builds list items from the stored booking objects (`property.title`,
`property.cover_image`, `refund.status`).

### `lib/features/bookings/data/fixtures/notifications.json`

A JSON array of 6 rows in the `notifications` shape (contracts §5), user = the mock guest, IDs
`e0000000-0000-4000-8000-0000000000NN`, newest first by `created_at`:

| # | type_key | entity_id (booking) | read_at |
|---|---|---|---|
| 01 | `booking.request_received` | …02 | null |
| 02 | `booking.confirmed` | …01 | null |
| 03 | `booking.rejected` | …06 | null |
| 04 | `refund.verified` | …08 | `"2026-10-29T10:00:00Z"` |
| 05 | `payment.failed` | …11 | `"2026-10-29T09:00:00Z"` |
| 06 | `something.new` (unknown type) | …01 | `"2026-10-28T09:00:00Z"` |

Every row has `category: "booking"`, `priority: "normal"`, `entity_type: "booking"`,
`title_key` and `body_key` equal to the `type_key`, and `params: {}`.
