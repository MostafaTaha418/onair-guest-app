---

description: "Task list for Guest Stay & Cancellation (G3)"
---

# Tasks: Guest Stay & Cancellation (G3)

**Input**: Design documents from `specs/004-guest-stay-cancellation/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. Constitution IX requires test-first coverage of:
- action filtering and the primary-action choice;
- the remaining-payment attempt and its outcome;
- the cash flow states;
- the cancellation preview diff;
- idempotency-key reuse;
- notification routing;
- the evidence-never-on-disk rule;
- error mapping.

It also requires widget tests for every screen state, goldens in Light, Dark, RTL, and 1.3×
text, and journeys on the mock.

**Organization**: Grouped by user story (US1–US6 from spec.md), so each story can be built and
checked on its own after Phase 2.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: User story from spec.md (US1–US6)
- Paths are relative to the repository root (single Flutter project)

---

## Implementer Guide (read before any task)

These tasks are written for an implementer who has **not** seen the design discussion. Follow
them literally:
- Do not invent behaviour, names, fields, texts, colours, or sizes that a task does not give.
- When a task says "copy the pattern of X", open X first and match its style exactly.
- When a task gives a class, method, or parameter name, use it **exactly**.
- If something is truly missing, stop and write a short note in the task's PR description
  instead of guessing.

**Before you start any task**

1. Read the task fully, including every bullet.
2. Open every file the task names as "pattern" or "read first".
3. If the task says "needs T0xx", check that the earlier task is done (its file exists and its
   tests pass). If not, do the earlier task first.

**Commands (run after every task, in this order)**

1. `dart format .`
2. `flutter analyze`. It must show **zero** issues, including infos.
3. The tests the task names, for example `flutter test test/features/stay/domain`.

Additional commands:
- After changing `.arb` files, run `flutter gen-l10n`.
- **Goldens:**
  - run `flutter test --tags golden`;
  - create or regenerate pictures **only** when the task says so:
    `flutter test --tags golden --update-goldens <file>`.
- At each **Checkpoint**, run the whole suite: `flutter test`.

**Hard rules (CI rejects violations)**

1. **No style literals outside the design system.** No `Color(0x…)`, `Colors.*`, `fontSize:`,
   or `fontWeight:` outside `lib/design_system/` (`tool/check_hardcoded_styles.sh` enforces
   this).
   - **Colors:** `context.colors.primary`, `.surface`, `.textPrimary`, `.textSecondary`,
     `.border`, `.errorText`, or `context.colors['warning']` / `['success']` (token names in
     `lib/design_system/tokens/on_air_colors.dart`).
   - **Text:** `Theme.of(context).textTheme.<name>` with `.copyWith(color: …)` only.
   - **Spacing and radii:** `Dimens.*` (`lib/design_system/tokens/dimens.dart`):
     `space4…space48`, `screenSide`, `radiusChip` (8), `radiusField` (12), `radiusButton` (12),
     `radiusCard` (16), `radiusSheet` (24), `minTouchTarget` (48).
2. **Every visible string comes from `AppLocalizations.of(context)`** (variable `l10n`). Never
   type Arabic or English text in a widget. All new keys are in **Appendix A**.
3. **RTL-safe layout:** `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`. Never
   `EdgeInsets.only(left:/right:)`, `Alignment.centerLeft`, or `TextAlign.left`.
4. **Money:**
   - Always use `Money` (`lib/core/money/money.dart`, integer piasters), shown with
     `MoneyFormatter().format(money)`.
   - **Never add, subtract, or multiply amounts in app code** (the mock server in
     `lib/features/*/data/mock_*` is the only exception, because it plays the server).
   - The only allowed transform is the sign split of an offer difference in T013, done once
     while parsing.
5. **Instants:**
   - Server instants are UTC `DateTime` from `DateTime.parse`, shown with
     `formatCairoDayMonthTime(utc)` or `formatCairoTime(utc)`
     (`lib/core/time/cairo_date_time_formatter.dart`).
   - Stay dates are `DateOnly`, shown with `DateOnlyFormatter.dayMonth(date)`.
   - Never decide anything from `DateTime.now()` except countdown display.
6. **Layers:** Widget → Cubit → repository **interface**. Widgets never call Supabase, Dio,
   secure storage, or a repository directly.
7. **Accessibility:**
   - Every icon-only button has a `tooltip` and sits in `Semantics(label: …, button: true)`.
   - Touch targets are at least `Dimens.minTouchTarget` (48).
8. **Logging:** never log names, phones, emails, codes, notes, tokens, or file URLs. Log IDs
   only, through `AppLogger.info` (`lib/core/logging/app_logger.dart`).
9. **Server decides:**
   - Booking actions come **only** from `details.availableActions`, filtered by
     `BookingActionRegistry.visible(...)`.
   - Never show a disabled or "coming soon" button for an action the server did not send.
   - Never change a status, amount, or action locally after a command. Always call the details
     Cubit's `refresh()`.
10. **Double-tap safety:** every confirm button is disabled while its Cubit is in a
    `…Submitting` state. A second call to the same Cubit method while submitting must return
    immediately (guard with a private `bool _busy`).
11. **Private files:**
    - Evidence images and their URLs are **never** written to disk or to the JSON cache.
    - Use `Image.network` (not `OnAirNetworkImage`, not `CachedNetworkImage`) for evidence.
12. **The emailed code** is never copied to the clipboard, never logged, and never kept after
    the screen closes.

**Code style used in this repo (match it)**

- **Models:** hand-written `@immutable final class` with a `const` constructor,
  `factory X.fromJson(Map<String, dynamic> json)`, and `==` / `hashCode` with `Object.hash` /
  `Object.hashAll`. Copy `lib/features/bookings/domain/booking_parts.dart` (`PaymentLine`,
  `RefundInfo`). Do **not** use `freezed`.
- **Enums from the wire:** a `static X fromWire(String? value)` with an `unknown` fallback and a
  `String get wire`. Copy `BookingStatus` in `lib/features/bookings/domain/booking_status.dart`.
- **Cubit states:** a `sealed class` with `final class` subclasses. Copy
  `lib/features/bookings/presentation/booking_details_cubit.dart`.
- **Cubits:**
  - private fields use the constructor style `required this._repo`;
  - check `if (isClosed) return;` after every `await` and before every `emit`;
  - cancel timers and subscriptions in `close()`.
- **Errors:**
  - repositories throw `AppFailure(ApiError)` (`lib/core/errors/api_error.dart`);
  - Supabase calls are wrapped exactly like `_guard` in
    `lib/features/booking/data/supabase_booking_flow_repository.dart`;
  - Node calls catch `DioException` exactly like `startPayment` in the same file;
  - UI messages use `apiErrorMessage(error, l10n)` (`lib/core/errors/error_message.dart`).
- **Screens:**
  - use `ErrorView`, `EmptyView`, `OfflineBanner` (`lib/design_system/components/state_views.dart`)
    and skeletons from `lib/design_system/components/skeletons.dart`;
  - the app bar is `AppBar(title: Text(l10n.<title>))`, as in
    `lib/features/booking/presentation/payment_return_screen.dart`.
- **Widget tests:**
  - pump with `tester.pumpOnAirApp(...)` from `test/helpers/pump_app.dart` (G3 parameters
    added in T024);
  - call `await initializeDateFormatting('ar')` (from `package:intl/date_symbol_data_local.dart`)
    in `setUpAll` when dates are shown.
- **Cubit tests:** `bloc_test` (`blocTest<C, S>(...)`) and `fakeAsync` from
  `package:fake_async/fake_async.dart` for timers.
- **Goldens:**
  - component goldens copy `test/design_system/goldens/booking_components_golden_test.dart`;
  - screen goldens copy `test/features/bookings/goldens/bookings_goldens_test.dart` (alchemist
    `goldenTest`, tag `golden`, variants `light_RTL`, `dark_RTL`, `light_RTL_1_3x`,
    `dark_RTL_1_3x`).

**Visual rules for G3 (the user asked that G3 look exactly like the current app)**

- Read `DESIGN.md`, `docs/design_reference/README.md`, and
  [contracts/ui-screens.md](contracts/ui-screens.md) before any UI task.
- Build every screen only from: `AmountRow`, `NoticeCard`, `InfoBanner`, `StatusChip`,
  `RefundStageTracker`, `BookingTimeline`, `BottomActionBar`, `OnAirPrimaryButton`,
  `OnAirTextField`, `OnAirOtpField`, `CountdownText`, `Card`, `OutlinedButton`, `TextButton`,
  and the three new components from T026–T028.
- Page padding is `EdgeInsetsDirectional.all(Dimens.screenSide)`. The gap between sections is
  `Dimens.space16`. Section titles use `textTheme.titleMedium` with `color:
  context.colors.textPrimary`, exactly as in `booking_details_screen.dart`.
- A screen has at most **one** filled button (`OnAirPrimaryButton`):
  - cancel and dispute buttons are never filled;
  - they are `OutlinedButton` or `TextButton` with `foregroundColor: context.colors.errorText`.
- Surface cards: `Card` (the theme already gives the 16dp radius and surface colour). Do not
  build your own `Container` with a border radius for a card.

**Glossary**

| Term | Meaning |
|---|---|
| Remaining amount | What is left to pay after a deposit; the server sends it as `remaining_minor` |
| Attempt key / action key | A UUID v4 sent as `idempotency_key`; reused when the same action is retried |
| Pending cash | A cash payment waiting for the guest's emailed code (`pending_cash` in booking JSON) |
| Acknowledgement | One side's confirmation of check-in or check-out (guest or host), with a time |
| Preview | The server's "what if I cancel now" answer: refund, non-refundable part, and case |
| Primary action | The first server action that is not cancel, damage claim, or support; shown as the filled button |
| Mock mode | `BACKEND_MODE=mock`: in-memory backend (`MockBookingServer` + `MockStayServer`), no network |
| G3 fixtures | Extra mock bookings in `bookings_g3.json`, loaded only when `includeG3Fixtures` is true |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: contract copies, folders, strings, and icons used by every later task.

- [X] T001 [P] Copy the G3 drafts for the backend owner into the repo's `contracts/` folder:
  - copy `specs/004-guest-stay-cancellation/contracts/supabase-stay.md` to `contracts/supabase-stay.md`;
  - copy `specs/004-guest-stay-cancellation/contracts/app-routes.md` to `contracts/app-routes-g3.md`;
  - copy `specs/004-guest-stay-cancellation/contracts/ui-screens.md` to `contracts/ui-screens-g3.md`;
  - in the three copies, rewrite every relative link so it works from `contracts/`. For example, `../../003-guest-booking-payment/contracts/app-routes.md` becomes `app-routes-g2.md`, and `../data-model.md` becomes `../specs/004-guest-stay-cancellation/data-model.md`;
  - append three lines to `contracts/README.md`, one per file: "- `<file>` is a G3 draft whose reviewed source is `specs/004-guest-stay-cancellation/contracts/`."
  - in `contracts/error-codes.md`:
    - replace the Arabic text of the `COLLECTOR_NOT_AUTHORIZED` row with `الشخص ده مش مفوّض يستلم فلوس للشقة دي. متسلّمش كاش وكلّم OnAir.`;
    - add these three rows right after the `CASH_NOT_ALLOWED` row:
      - `| \`CASH_AMOUNT_CHANGED\` *(new)* | G3 | \`stayCashAmountChanged\` | المبلغ المتبقي اتغير. راجع المبلغ الجديد. | no |`
      - `| \`CLAIM_ALREADY_ANSWERED\` *(new)* | G3 | \`claimAlreadyAnswered\` | المطالبة دي اتردّ عليها قبل كده. | no |`
      - `| \`OFFER_NOT_AVAILABLE\` *(new)* | G3 | \`offerNotAvailable\` | العرض ده مبقاش متاح. | no |`

  Done when the three files exist and every link opens.
- [X] T002 [P] Create these folders, each with an empty `.gitkeep` file:
  - `lib/features/stay/domain/`, `lib/features/stay/data/`, `lib/features/stay/data/fixtures/`;
  - `lib/features/stay/presentation/remaining_payment/`, `lib/features/stay/presentation/cash/`,
    `lib/features/stay/presentation/stay_ack/`, `lib/features/stay/presentation/cancellation/`,
    `lib/features/stay/presentation/claims/`, `lib/features/stay/presentation/offer/`;
  - `test/features/stay/domain/`, `test/features/stay/data/`, `test/features/stay/presentation/`,
    `test/features/stay/goldens/`.

  Then add `- lib/features/stay/data/fixtures/` to the `assets:` list in `pubspec.yaml`, right after `- lib/features/bookings/data/fixtures/`. Run `flutter pub get`.
- [X] T003 Add every key in **Appendix A**:
  - `lib/l10n/app_ar.arb` gets the Arabic text exactly as listed, and `lib/l10n/app_en.arb` gets
    the English text.
  - **Placement:** add keys at the end of each file, before the final `}`. Keep valid JSON
    (commas!).
  - **Existing keys:** do **not** remove or rename them. The only existing key whose value
    changes is `stayCollectorNotAuthorized` (new text in Appendix A, both files).
  - **Placeholders:** for every key with `{placeholders}`, add the `"@key"` metadata block to
    `app_ar.arb` only, with each placeholder typed `String`. Copy the format of the existing
    `"@bookingRemainingDue"` block.
  - Run `flutter gen-l10n`.

  Done when `lib/l10n/generated/app_localizations.dart` has a member for every Appendix A key and `flutter analyze` is clean.
- [X] T004 [P] In `lib/design_system/icons/app_icons.dart`, add these constants, keeping the file's alphabetical order:
  - `static const IconData cash = LucideIcons.banknote;`
  - `static const IconData cancelOutline = CupertinoIcons.xmark_circle;`
  - `static const IconData keyOutline = LucideIcons.keyRound;`
  - `static const IconData photoStack = CupertinoIcons.photo_on_rectangle;`
  - `static const IconData radioChecked = CupertinoIcons.largecircle_fill_circle;`
  - `static const IconData receipt = LucideIcons.receipt;`
  - `static const IconData warningOutline = CupertinoIcons.exclamationmark_triangle;`

  Done when `flutter analyze` is clean.

**Checkpoint**: `flutter pub get`, `flutter gen-l10n`, and `flutter analyze` all pass.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: error codes, the booking model additions, the stay repository and its mock and
Supabase versions, the action key store, routes, notification routing, the three shared
components, the action launcher, and the details-screen action area. Every user story depends on
this phase.

**⚠️ CRITICAL**: No user story work starts before this phase is done.

### Tests first (write them, run them, see them fail, then implement)

- [X] T005 [P] Write `test/core/errors/error_mapper_g3_test.dart`. For each row, assert `ErrorMapper.fromCode(code).code` and `.messageKey`, and `ErrorMapper.hasCode(code) == true`:
  - `CANCELLATION_TERMS_CHANGED` → `ErrorCode.cancellationTermsChanged`, `cancellationTermsChanged`
  - `REMAINING_NOT_PAID` → `ErrorCode.remainingNotPaid`, `stayRemainingNotPaid`
  - `CASH_NOT_ALLOWED` → `ErrorCode.cashNotAllowed`, `stayCashNotAllowed`
  - `CASH_AMOUNT_CHANGED` → `ErrorCode.cashAmountChanged`, `stayCashAmountChanged`
  - `CLAIM_ALREADY_ANSWERED` → `ErrorCode.claimAlreadyAnswered`, `claimAlreadyAnswered`
  - `OFFER_NOT_AVAILABLE` → `ErrorCode.offerNotAvailable`, `offerNotAvailable`
  - `COLLECTOR_NOT_AUTHORIZED` → `ErrorCode.collectorNotAuthorized`, `stayCollectorNotAuthorized` (already mapped; keep the assertion)

  In a second `group('apiErrorMessage')`, load `AppLocalizations` for `ar` with `await AppLocalizations.delegate.load(const Locale('ar'))`. Assert that `apiErrorMessage` returns the matching l10n getter for each of the seven codes above. For example, `apiErrorMessage(ErrorMapper.fromCode('CASH_NOT_ALLOWED'), l10n) == l10n.stayCashNotAllowed`.
- [X] T006 [P] Write `test/features/bookings/domain/booking_action_g3_test.dart`:
  - (a) `BookingActionRegistry.g3().visible([...])` keeps server order and drops unknown codes and `write_review`. Input `['write_review','request_cancellation','pay_remaining','x_unknown','contact_support','pay_remaining']` → values `['request_cancellation','pay_remaining','contact_support']`.
  - (b) `BookingActionRegistry.g2()` still returns only `contact_support` for the same input.
  - (c) `firstGuestAction(registry.visible(codes))` returns the first code that is not `contact_support`, `request_cancellation`, or `respond_damage_claim`. Expected results:
    - `['request_cancellation','confirm_checkin','pay_remaining']` → `confirm_checkin`;
    - `['request_cancellation','contact_support']` → `null`;
    - `['respond_damage_claim']` → `null`.
  - (d) `needsActionCode(registry.visible(codes))` returns the first code that is not `contact_support`. Expected results:
    - `['contact_support','request_cancellation']` → `request_cancellation`;
    - `['respond_damage_claim','contact_support']` → `respond_damage_claim`;
    - `['contact_support']` → `null`.
- [X] T007 [P] Write `test/features/bookings/domain/booking_details_g3_test.dart`. Build a JSON map by copying the first object of `lib/features/bookings/data/fixtures/bookings.json`, then add these G3 fields, copied from Appendix B.1:
  - `acknowledgements` from `…022`;
  - `pending_cash` from `…028`;
  - `damage_claims` from `…025`;
  - `replacement_offer` from `…026`;
  - `"cancellation": {"cancelled_at": "2026-10-31T10:00:00Z", "by_scope": "guest", "reason_code": "change_of_plans"}`;
  - `"pending_remaining_payment_id": "c0000000-0000-4000-8000-000000000099"`;
  - the cash `payments` line with its `receipt` from `…022`. Assert:
  - (a) every new field parses to the values in the map;
  - (b) a JSON **without** any G3 field parses with `acknowledgements` all-null and `keyLeftSafe == false`, `pendingCash == null`, `damageClaims` empty, `replacementOffer == null`, `cancellation == null`, `pendingRemainingPaymentId == null`;
  - (c) `toCacheJson()` keeps all G3 fields **except** `pending_cash.challenge_id` (assert the key is absent), and `BookingDetails.fromJson(details.toCacheJson())` gives `pendingCash!.challengeId == ''`;
  - (d) `ReplacementOffer` with `price_difference_minor: 50000` gives `direction == OfferDirection.guestPays` and `difference == const Money(50000)`; `-50000` gives `OfferDirection.guestRefunded` and `Money(50000)`; `0` gives `OfferDirection.none`;
  - (e) `DamageClaimStatus.fromWire('in_mediation') == DamageClaimStatus.inMediation`, and `'??'` gives `unknown`.
- [X] T008 [P] Write `test/features/stay/data/action_attempt_store_test.dart` using `InMemorySecureStore` (`lib/core/storage/secure_store.dart`) and a counter-based `newKey`:
  - (a) `keyFor('cancel','b1')` twice returns the same key, and `newKey` was called once;
  - (b) after `clear('cancel','b1')`, `keyFor` returns a new key;
  - (c) `keyFor('cancel','b1')` and `keyFor('cancel','b2')` differ;
  - (d) `clearAll()` deletes every key starting with `action_attempt.` and leaves a key `payment_attempt.current` untouched.
- [X] T009 [P] Write `test/app/router/notification_router_g3_test.dart`. Use `const id = 'b0000000-0000-4000-8000-000000000020'` and `const claim = 'e0000000-0000-4000-8000-000000000001'`, and assert `NotificationRouter.locationFor(type, entityType, entityId, params: …)`:
  - `('payment.remaining_due','booking',id)` → `/bookings/$id/remaining-payment`
  - `('cash.confirmation_requested','booking',id)` → `/bookings/$id/cash-confirm`
  - `('cash.payment_confirmed','payment',pay, params: {'booking_id': id})` → `/bookings/$id/receipts/$pay` (with `pay = 'c0000000-0000-4000-8000-000000000099'`)
  - `('cash.payment_confirmed','',pay)` (push: no params) → `/bookings`
  - `('damage.claim_opened','damage_claim',claim)` → `/damage-claims/$claim`
  - `('damage.resolved','',claim)` (push: empty entity type) → `/damage-claims/$claim`
  - `('booking.replacement_offered','booking',id)` → `/bookings/$id?focus=offer`
  - `('refund.verified','booking',id)` → `/bookings/$id?focus=payments`
  - `('stay.completed','booking',id)` → `/bookings/$id`
  - `('damage.claim_opened','damage_claim','not-a-uuid')` → `/bookings`
- [X] T010 [P] Write `test/app/router/routes_g3_test.dart`. Using a valid UUID v4 `id`, `pay`, and `claim`, assert:
  - `isRegisteredLocation`, `requiresAccount`, and `isLinkablePath` are true for `/bookings/$id/cash-confirm`, `/bookings/$id/receipts/$pay`, and `/damage-claims/$claim`;
  - `/bookings/$id/cancel` is registered and requires an account, but `isLinkablePath` is **false**;
  - each of these paths with `not-a-uuid` in an ID position is not registered;
  - the builders return the exact strings: `AppRoutes.remainingPayment(id)`, `cashConfirm(id)`, `receipt(id, pay)`, `cancelBooking(id)`, `damageClaim(id, claim)`, `damageClaimResolver(claim)`, `bookingDetailsFocus(id, 'offer') == '/bookings/$id?focus=offer'`.

### Implementation

- [X] T011 Add the G3 error codes (needs T003; makes T005 pass):
  - in `lib/core/errors/api_error.dart`, add to `enum ErrorCode` (before `internal`): `cancellationTermsChanged, remainingNotPaid, cashNotAllowed, cashAmountChanged, claimAlreadyAnswered, offerNotAvailable`;
  - in `lib/core/errors/error_mapper.dart`, add `_keys` entries for the six codes in T005 with those ARB keys;
  - in `lib/core/errors/error_message.dart`, add switch arms before `_ =>`: each new code → its l10n getter, and `ErrorCode.collectorNotAuthorized => l10n.stayCollectorNotAuthorized`.
- [X] T012 Extend the action registry in `lib/features/bookings/domain/booking_action.dart` (makes T006 pass):
  - add constants on `BookingActionCode`: `payRemaining('pay_remaining')`, `confirmCashPayment('confirm_cash_payment')`, `requestCancellation('request_cancellation')`, `confirmCheckin('confirm_checkin')`, `confirmCheckout('confirm_checkout')`, `respondDamageClaim('respond_damage_claim')`;
  - add `factory BookingActionRegistry.g3() => const BookingActionRegistry({'contact_support','pay_remaining','confirm_cash_payment','request_cancellation','confirm_checkin','confirm_checkout','respond_damage_claim'});`;
  - add top-level functions:
    - `BookingActionCode? firstGuestAction(List<BookingActionCode> visible)`: the first element whose value is not `contact_support`, `request_cancellation`, or `respond_damage_claim`, else `null`;
    - `BookingActionCode? needsActionCode(List<BookingActionCode> visible)`: the first element whose value is not `contact_support`, else `null`.
- [X] T013 Create `lib/features/bookings/domain/booking_stay_parts.dart` with the G3 parts of a booking, exactly as data-model §1–§4, §7, and §8 describe. Copy the model style of `booking_parts.dart`. Every class gets `fromJson`, `toJson`, `==`, and `hashCode`.

  | Class | Fields | JSON keys and notes |
  |---|---|---|
  | `StayAcknowledgements` | `guestCheckInAt`, `hostCheckInAt`, `guestCheckOutAt`, `hostCheckOutAt` (`DateTime?`), `keyLeftSafe` (`bool`) | `guest_checkin_at`, `host_checkin_at`, `guest_checkout_at`, `host_checkout_at`, `key_left_safe`. Add `static const empty = StayAcknowledgements(keyLeftSafe: false)` (other fields default null) and `bool get hasAny`. |
  | `CashRequest` | `paymentId`, `challengeId`, `collectorDisplayName`, `amount` (`Money`), `maskedEmail`, `codeExpiresAt` (`DateTime?`), `retryAfterSeconds` (`int`, default 0), `origin` (`CashOrigin` enum `guest`/`collector`/`unknown` with `fromWire`) | `payment_id`, `challenge_id`, `collector_display_name`, `amount_minor`, `masked_email`, `code_expires_at`, `retry_after_seconds`, `origin`. `fromJson` reads a missing `challenge_id` as `''`. `toCacheJson()` writes everything **except** `challenge_id`. |
  | `CashReceipt` | `receiptNo`, `collectorDisplayName`, `confirmedAt` (`DateTime`) | `receipt_no`, `collector_display_name`, `confirmed_at` |
  | `DamageClaimSummary` | `id`, `amount` (`Money`), `status` (`DamageClaimStatus`), `createdAt` | `DamageClaimStatus` values: `open`, `guestAccepted` (`guest_accepted`), `guestDisputed` (`guest_disputed`), `inMediation` (`in_mediation`), `resolved`, `withdrawn`, `unknown`, with `fromWire` and `wire`. |
  | `ReplacementOffer` | `id`, `status` (`OfferStatus`: `pending`, `accepted`, `declined`, `expired`, `withdrawn`, `unknown`), `propertyId`, `propertyTitle`, `areaName`, `coverImage` (`ListingImage?`), `stay` (`StayRange`), `difference` (`Money`), `direction` (`OfferDirection`: `guestPays`, `guestRefunded`, `none`), `expiresAt` (`DateTime?`) | Read `offered_property.{id,title,area_name,cover_image}`, `check_in`, `check_out`, `expires_at`. Read `price_difference_minor` once: `raw > 0` → `guestPays`; `raw < 0` → `guestRefunded`; else `none`. Set `difference: Money(raw.abs())` (this sign split is the only allowed transform). `toJson` writes `price_difference_minor` back with the sign restored from `direction`. |
  | `CancellationInfo` | `cancelledAt`, `byScope` (`String`), `reasonCode` (`String?`) | `cancelled_at`, `by_scope`, `reason_code` |

  Also add `CashReceipt? receipt` to `PaymentLine` in `booking_parts.dart`: parse `json['receipt']` when present, write it in `toJson`, and include it in `==` / `hashCode`.
- [X] T014 Extend `BookingDetails` in `lib/features/bookings/domain/booking_details.dart` (needs T013; makes T007 pass):
  - add fields `StayAcknowledgements acknowledgements`, `CashRequest? pendingCash`, `String? pendingRemainingPaymentId`, `List<DamageClaimSummary> damageClaims`, `ReplacementOffer? replacementOffer`, `CancellationInfo? cancellation`;
  - **`fromJson`:** missing → `StayAcknowledgements.empty`, null, empty list, null, null;
  - **`toCacheJson`:** writes them with the same JSON keys, and `pending_cash` through `CashRequest.toCacheJson()`;
  - **`copyWithoutInstructions`:** copies them;
  - **Equality:** add them to `==` and `hashCode`.

  Then extend `BookingSummary` in `lib/features/bookings/domain/booking_summary.dart` with `List<String> availableActions`. Read `json['available_actions']` (missing → `const []`), write it in `toJson`, and add it to `==` / `hashCode`. In `MockBookingServer._summaryOf` (`lib/features/bookings/data/mock_booking_server.dart`), pass `'available_actions': json['available_actions']`.

  Run `flutter test test/features/bookings`. All old tests must still pass.
- [X] T015 Create `lib/features/stay/domain/` files with the exact types in **Appendix C** (copy the code there exactly):
  - `cancellation_preview.dart`: `PolicyCase`, `CancellationPreview`, `PreviewChange`, `CancellationReason`;
  - `damage_claim.dart`: `EvidenceRef`, `ClaimResponse`, `ClaimResolution`, `DamageClaim`, `ClaimDecision`, `ClaimLimits`;
  - `stay_results.dart`: `CancellationResult`, `ClaimAnswerResult`, `OfferAnswerResult`, `FileUrl`;
  - `stay_repository.dart`: the `StayRepository` interface.

  Write `test/features/stay/domain/stay_models_test.dart` covering:
  - `fromJson` of each model, using the JSON in Appendix C comments;
  - `PreviewChange.between(old, new)` flags only the changed fields;
  - `ClaimLimits.validDisputeNote`: `'   short  '` → false, 10 characters → true, 1001 characters → false.
- [X] T016 [P] Create `lib/features/stay/data/action_attempt_store.dart` (makes T008 pass):
  ```dart
  final class ActionAttemptStore {
    ActionAttemptStore(this._store, {String Function()? newKey}) : _newKey = newKey ?? (() => const Uuid().v4());
    static const prefix = 'action_attempt.';
    final SecureStore _store;
    final String Function() _newKey;
    Future<String> keyFor(String action, String entityId); // read '$prefix$action.$entityId' or create, save, return
    Future<void> clear(String action, String entityId);
    Future<void> clearAll(); // readAll(), delete each key that startsWith(prefix)
  }
  ```
  Action names used later: `cancel`, `claim_answer`, `offer_answer`, `cash_start`.
- [X] T017 Make two `MockBookingServer` helpers public in `lib/features/bookings/data/mock_booking_server.dart`, so the stay mock (T019) can reuse them:
  - rename `_appendEvent` to `appendEvent` (same body);
  - change `_notify(String typeKey, String bookingId, Duration signalDelay)` into a public `Future<void> notifyGuest(String typeKey, String entityId, {String entityType = 'booking', Map<String, dynamic> params = const {}, Duration signalDelay = Duration.zero})`. The inserted row uses `entityType` and `params`, and the emitted `NotificationSignal` uses `entityType` and `entityId`. Update every old call site to the new name.
  - add a constructor parameter `this.includeG3Fixtures = true` (field `final bool includeG3Fixtures;`). In the `bookings` getter, after loading `bookings.json`, also load `$_fixturesRoot/bookings_g3.json` the same way when `includeG3Fixtures` is true, and add its entries to the same map.

  Run `flutter test test/features/bookings`. It must pass unchanged.
- [X] T018 [P] Create the mock fixtures:
  - `lib/features/bookings/data/fixtures/bookings_g3.json`, with the JSON array in **Appendix B.1** copied exactly;
  - `lib/features/stay/data/fixtures/claims.json`, with **Appendix B.2** copied exactly.

  Validate both with `python -m json.tool <file>` (or any JSON validator).
- [X] T019 Create `lib/features/stay/data/mock_stay_server.dart` (needs T015–T018):
  - **Declaration:** `final class MockStayServer implements StayRepository` with constructor `MockStayServer({required MockBookingServer bookings, Future<String> Function(String path)? loader, this.latency = const Duration(milliseconds: 300), DateTime Function()? now})`. Copy the `loader` / `latency` / `now` pattern of `MockBookingServer`.
  - **Claims:** loads `lib/features/stay/data/fixtures/claims.json` lazily into `Map<String, Map<String, dynamic>>` keyed by `id`.
  - **Behaviour:** every method follows **Appendix D** exactly: mock constants, the JSON fields it changes on the booking map from `await bookings.bookings`, and the notification it emits via `bookings.notifyGuest`.
  - **Owner-side helpers:** add the public methods listed in Appendix D §8 for tests and the mock tools.
  - **Tests:** write `test/features/stay/data/mock_stay_server_test.dart`. Build the server like `FakeBookingBackend` does (zero latency, fixed clock `DateTime.utc(2026, 11, 1, 10)`, file loader) and test one success and one error case per method in Appendix D.
- [X] T020 Create `lib/features/stay/data/supabase_stay_repository.dart` (needs T015):
  - **Declaration:** `final class SupabaseStayRepository implements StayRepository` with the same constructor shape as `SupabaseBookingFlowRepository` (`rpc` + `FallbackClient node`). Copy its `_guard` method exactly.
  - **Calls:** each method calls exactly the RPC or Node route in [contracts/supabase-stay.md §1](contracts/supabase-stay.md), with parameter names `p_booking_id`, `p_expected_refund_minor`, `p_reason`, `p_reason_note`, `p_idempotency_key`, `p_collector_phone`, `p_expected_amount_minor`, `p_payment_id`, `p_challenge_id`, `p_code`, `p_claim_id`, `p_decision`, `p_note`, `p_attachment_ids` (always `<String>[]`), `p_offer_id`, `p_accept`.
  - **Responses:** parse each with the Appendix C `fromJson`.
  - **`sendCashCode`:** calls `_node.sendOtpCode(xRequestId: const Uuid().v4(), body: V1OtpSendRequestBody(challengeId: challengeId))`.
  - **`fileUrl`:** calls `_node.getFileUrl(xRequestId: const Uuid().v4(), attachmentId: id)` and returns `FileUrl(url: Uri.parse(r.url), expiresAt: r.expiresAt)`.
  - **Node errors:** catch `DioException` exactly as `startPayment` does.
  - **Not here:** `confirmCheckIn` / `confirmCheckOut` call `guest_confirm_checkin` / `guest_confirm_checkout` with `p_booking_id` and return the response string. No unit test is needed for this class (network). It is covered by the Staging journey in T090.
- [X] T021 [P] Add G3 routes in `lib/app/router/routes.dart` (makes T010 pass):
  - patterns: `cashConfirmPattern = '/bookings/:id/cash-confirm'`, `receiptPattern = '/bookings/:id/receipts/:paymentId'`, `cancelBookingPattern = '/bookings/:id/cancel'`, `damageClaimResolverPattern = '/damage-claims/:claimId'`;
  - matching private `RegExp`s, copying `_remainingPayment`;
  - wire them into `_validDynamicPath` and `requiresAccount`, and into `isLinkablePath` for every new pattern **except** `cancel`;
  - builders: `remainingPayment(String id)`, `cashConfirm(String id)`, `receipt(String id, String paymentId)`, `cancelBooking(String id)`, `damageClaim(String id, String claimId)`, `damageClaimResolver(String claimId)`, `bookingDetailsFocus(String id, String focus) => '/bookings/$id?focus=$focus'`.
- [X] T022 [P] Update `lib/app/router/notification_router.dart` (makes T009 pass):
  - add a named parameter `Map<String, dynamic> params = const {}` to `locationFor`;
  - before the generic booking-prefix branch, add these rules **in this order** (every ID must pass `AppRoutes.isUuidV4`, else return `AppRoutes.bookings`):
    1. `typeKey.startsWith('damage.')` → `AppRoutes.damageClaimResolver(entityId)`;
    2. `typeKey == 'cash.payment_confirmed'` → if `params['booking_id']` is a String UUID → `AppRoutes.receipt(params['booking_id'], entityId)`, else `AppRoutes.bookings`;
    3. `typeKey == 'payment.remaining_due'` → `AppRoutes.remainingPayment(entityId)`;
    4. `typeKey == 'cash.confirmation_requested'` → `AppRoutes.cashConfirm(entityId)`;
    5. `typeKey == 'booking.replacement_offered'` → `AppRoutes.bookingDetailsFocus(entityId, 'offer')`;
    6. `typeKey.startsWith('refund.')` → `AppRoutes.bookingDetailsFocus(entityId, 'payments')`.
  - In `lib/features/notifications/presentation/notifications_cubit.dart`, pass `params: notification.params`. Leave the push call sites in `lib/app/app.dart` unchanged (push has no params).

  Run `flutter test test/app test/features/notifications`.
- [X] T023 Register the G3 routes in `lib/app/router/app_router.dart` (needs T021). For now each builder returns `const NotAvailableScreen()`, and each story replaces its own builder later:
  - `AppRoutes.cashConfirmPattern` (name `cash-confirm`);
  - `AppRoutes.receiptPattern` (name `cash-receipt`);
  - `AppRoutes.cancelBookingPattern` (name `cancel-booking`);
  - `AppRoutes.damageClaimResolverPattern` (name `damage-claim-resolver`).

  Place them right after the existing `AppRoutes.damageClaimPattern` route. Do not change the existing remaining-payment and damage-claim routes yet.
- [X] T024 Wire the stay layer (needs T016, T019, T020):
  - **Bootstrap types:** in `lib/bootstrap.dart`, add `StayRepository stay` and `MockStayServer? mockStay` to the `_Backend` record typedef.
  - **Remote backend:** `_remoteBackend` sets `stay: SupabaseStayRepository(rpc: rpc, node: FallbackClient(dio))` and `mockStay: null`.
  - **Mock backend:** `_mockBackend` creates `final stay = MockStayServer(bookings: server);` and sets `stay: stay, mockStay: stay`.
  - **Bootstrap providers:** create `final actionAttempts = ActionAttemptStore(backend.secureStore);`. Add `RepositoryProvider<StayRepository>.value(value: backend.stay)`, `RepositoryProvider<MockStayServer?>.value(value: backend.mockStay)`, and `RepositoryProvider<ActionAttemptStore>.value(value: actionAttempts)`. Change the `BookingActionRegistry` provider value to `BookingActionRegistry.g3()`. Add `actionAttempts.clearAll` to the `CompositePersonalDataResetter([...])` list.
  - **Fake backend:** in `test/helpers/fake_booking_backend.dart`:
    - add constructor parameters `bool includeG3Fixtures = false` (pass it to `MockBookingServer`) and `BookingActionRegistry? actionRegistry`;
    - create `stay = MockStayServer(bookings: server, loader: <same file loader>, latency: Duration.zero, now: () => DateTime.utc(2026, 11, 1, 10))` and `actionAttempts = ActionAttemptStore(secureStore)`;
    - in `appProviders()`, use `actionRegistry ?? BookingActionRegistry.g2()` and add the three new providers.
  - **Pump helper:** in `test/helpers/pump_app.dart`, add the same three providers from `backend`, and make the `BookingActionRegistry` provider use `backend.actionRegistry ?? BookingActionRegistry.g2()` (store `actionRegistry` as a public field on `FakeBookingBackend`).

  Run `flutter test`. Every existing test must still pass, because the old tests keep `g2()` and no G3 fixtures.
- [X] T025 [P] Write `test/design_system/goldens/stay_components_golden_test.dart` (copy `booking_components_golden_test.dart`, tag `golden`). Cover `OnAirConfirmSheet`, `OnAirConfirmDialog` (normal and `destructive: true`), and `AcknowledgementTracker` (states: guest-only, host-only, both, with `note`) in light/dark × RTL/LTR × 1.0/1.3. Use literal Arabic strings in the test file only (tests may contain text).
- [X] T026 [P] Create `lib/design_system/components/on_air_confirm_sheet.dart`:
  - **Class:** `final class OnAirConfirmSheet extends StatelessWidget` with constructor `({required this.title, required this.body, required this.confirmLabel, required this.cancelLabel, required this.onConfirm, this.isLoading = false, this.extraActionLabel, this.onExtraAction, super.key})`.
  - **Layout:** `SafeArea` → `Padding(EdgeInsetsDirectional.fromSTEB(Dimens.screenSide, Dimens.space8, Dimens.screenSide, Dimens.space16))` → `Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch)`. The column contains:
    1. a centered drag handle `SizedBox(width: 40, height: 4)` with `DecoratedBox(color: context.colors.border, borderRadius: BorderRadius.circular(Dimens.radiusChip))`;
    2. `Dimens.space16`;
    3. the title (`textTheme.titleMedium`, `textPrimary`, `Semantics(header: true)`);
    4. `Dimens.space8`;
    5. the body (`textTheme.bodyMedium`, `textSecondary`);
    6. `Dimens.space24`;
    7. `OnAirPrimaryButton(label: confirmLabel, onPressed: isLoading ? null : onConfirm, isLoading: isLoading)`;
    8. `Dimens.space8`;
    9. `TextButton(onPressed: isLoading ? null : () => Navigator.of(context).pop(), child: Text(cancelLabel))`;
    10. when `extraActionLabel != null`, another `TextButton` for it.
  - **Helper:** `static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder})`. It calls `showModalBottomSheet<T>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: false, shape: const RoundedRectangleBorder(borderRadius: BorderRadiusDirectional.vertical(top: Radius.circular(Dimens.radiusSheet))), backgroundColor: context.colors.surface, builder: builder)`.
- [X] T027 [P] Create `lib/design_system/components/on_air_confirm_dialog.dart` (pattern: reference image 15, restyled):
  - **Class:** `final class OnAirConfirmDialog extends StatelessWidget` with `({required this.title, required this.body, required this.confirmLabel, required this.cancelLabel, this.destructive = false, super.key})`.
  - **`build`:** returns `AlertDialog(backgroundColor: context.colors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusCard)), title: Text(title), content: Text(body), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelLabel)), TextButton(style: destructive ? TextButton.styleFrom(foregroundColor: context.colors.errorText) : null, onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel))])`.
  - **Helper:** `static Future<bool> ask(BuildContext context, {required String title, required String body, required String confirmLabel, required String cancelLabel, bool destructive = false})`. It returns `await showDialog<bool>(...) ?? false`.
- [X] T028 [P] Create `lib/design_system/components/acknowledgement_tracker.dart`:
  - **Classes:** `final class AckStep { const AckStep({required this.label, required this.statusText, required this.done}); final String label; final String statusText; final bool done; }` and `final class AcknowledgementTracker extends StatelessWidget` with `({required this.title, required this.steps, this.note, super.key})`.
  - **Layout:** a `Card` → `Padding(all: Dimens.space16)` → `Column`:
    - the title in `titleMedium`;
    - for each step, a `Row`:
      - an `Icon(step.done ? AppIcons.checkCircle : AppIcons.schedule, color: step.done ? context.colors['success'] : context.colors.textSecondary, size: 20)`;
      - `Dimens.space8`;
      - an `Expanded` `Column` with `step.label` in `labelLarge` and `step.statusText` in `bodySmall` / `textSecondary`;
    - `Dimens.space8` between rows;
    - when `note != null`, a final `Row` with `AppIcons.keyOutline` and the note in `bodySmall`.
  - **Semantics:** wrap the whole card in `MergeSemantics`.
  - **Done when:** T025 passes after `flutter test --tags golden --update-goldens test/design_system/goldens/stay_components_golden_test.dart`. Review every generated picture and check that nothing overflows at 1.3×.
- [X] T029 Create `lib/features/bookings/presentation/booking_action_ui.dart` with:
  - `String bookingActionLabel(BookingActionCode code, AppLocalizations l10n)`, mapping:
    - `pay_remaining` → `actionPayRemaining`;
    - `confirm_cash_payment` → `actionConfirmCash`;
    - `request_cancellation` → `actionCancelBooking`;
    - `confirm_checkin` → `actionConfirmCheckin`;
    - `confirm_checkout` → `actionConfirmCheckout`;
    - `respond_damage_claim` → `actionRespondClaim`;
    - `contact_support` → `bookingContactSupport`;
    - anything else → `bookingContactSupport`.
  - `Future<bool> launchBookingAction(BuildContext context, BookingDetails details, BookingActionCode code)`, following [contracts/app-routes.md §4](contracts/app-routes.md):
    - route actions call `final r = await context.push<bool>(...)` and return `r ?? false`;
    - `contact_support` → `context.push(AppRoutes.supportNew + '?booking=${details.id}')` and returns `false`;
    - `respond_damage_claim` → the first claim in `details.damageClaims` with `status == DamageClaimStatus.open`, or `false` if none;
    - `confirm_checkin` / `confirm_checkout` → call `showCheckInSheet(context, details)` / `showCheckOutSheet(context, details)`. These functions are created in US3 (T060). Until then, make them top-level stubs in `lib/features/stay/presentation/stay_ack/stay_ack_sheets.dart` that return `Future.value(false)`.
  - Write `test/features/bookings/presentation/booking_action_ui_test.dart` covering every label mapping.
- [X] T030 Restructure the action area of `lib/features/bookings/presentation/booking_details_screen.dart` (needs T012, T029). Read the whole file first. Change only what is listed:
  - (a) Convert `BookingDetailsScreen` to a `StatefulWidget`. Add an optional constructor parameter `String? focus`. In `app_router.dart`, pass `focus: state.uri.queryParameters['focus']` for the details route, accepting only `offer`, `claims`, and `payments`, else `null`.
  - (b) Create three `GlobalKey`s (`_offerKey`, `_claimsKey`, `_paymentsKey`) and pass them down to `_DetailsList`. After the **first** `DetailsReady` frame, if `focus` matches, call `Scrollable.ensureVisible(key.currentContext!, duration: Duration.zero)` once (guard with a `bool _focused`).
  - (c) Compute `final visible = registry.visible(details.availableActions);` and `final primary = firstGuestAction(visible);`.
  - (d) If `primary != null` and the state is `DetailsReady`, set `Scaffold.bottomNavigationBar` to:
    ```dart
    BottomActionBar(
      leading: const SizedBox.shrink(),
      action: OnAirPrimaryButton(
        key: ValueKey('primary-${primary.value}'),
        label: bookingActionLabel(primary, l10n),
        onPressed: online ? () => _run(primary) : null,
      ),
    )
    ```
    `_run` calls `launchBookingAction`, and if it returns `true`, calls `cubit.refresh()` and shows `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.stayActionDone)))`.
  - (e) Replace the current `for (final action in …visible(...))` block at the end of the list with:
    - every visible action except `primary`, `request_cancellation`, and `contact_support` as an `OutlinedButton` (key `action-<value>`) with its label, calling `_run`;
    - then the existing contact-support `OutlinedButton` exactly as today, only if `contact_support` is visible, keeping key `action-contact_support`;
    - then, only if `request_cancellation` is visible, a `TextButton` (key `action-request_cancellation`) with `style: TextButton.styleFrom(foregroundColor: context.colors.errorText)` and label `l10n.actionCancelBooking`.

    All buttons are disabled when offline.
  - (f) Leave every other section unchanged. Stories add their sections in their own tasks.

  Run `flutter test test/features/bookings` and `flutter test --tags golden test/features/bookings`. The existing details goldens must **not** change, because fixture booking 1 has only `contact_support` and the tests use `g2()`. If they change, you broke (e) — fix it, and do not update the goldens.
- [X] T031 Add the "Needs your action" line to `lib/features/bookings/presentation/widgets/booking_card.dart` (needs T012, T014):
  - read `context.read<BookingActionRegistry>()` and compute `final code = needsActionCode(registry.visible(booking.availableActions));`;
  - when `code != null`, insert after the dates `Text` (before the `Dimens.space8` gap) a `Padding(top: Dimens.space4)` → `Row` with `Icon(AppIcons.infoOutline, size: 16, color: context.colors['warning'])`, `Dimens.space4`, and `Flexible(child: Text(l10n.bookingNeedsAction(bookingActionLabel(code, l10n)), style: textTheme.labelMedium?.copyWith(color: context.colors['warning'])))`;
  - append `، ${l10n.bookingNeedsAction(...)}` to the card's `Semantics.label` when the line is shown;
  - no buttons on the card (Clarification).

  Add a widget test `test/features/bookings/presentation/widgets/booking_card_needs_action_test.dart`: with `g3()` and `availableActions: ['contact_support','pay_remaining']`, the text `l10n.bookingNeedsAction(l10n.actionPayRemaining)` is shown; with `['contact_support']`, it is not; with `g2()`, it is never shown.

**Checkpoint**: `flutter analyze` is clean, `flutter test` passes, and the existing goldens are unchanged. The app runs in mock mode, and the G3 fixture bookings appear in My Bookings with the "Needs your action" line.

---

 ## Phase 3: User Story 1 - Pay the remaining amount online (Priority: P1) 🎯 MVP

**Goal**: A guest with a confirmed, deposit-only booking pays the rest online through the same
payment page and verification screen as G2. The booking shows "paid" only after the server says
so (AC-025).

**Independent Test**: In mock mode, open booking `…020` (Appendix B.1). Tap "ادفع المبلغ
المتبقي", then pay on the mock page with "Succeed". The verification screen shows "تم سداد
المتبقي", and the details payments section shows the remaining line as paid, with no
"pay remaining" action left.

### Tests for User Story 1 (write first, see them fail)

- [X] T032 [P] [US1] Write `test/features/booking/domain/payment_attempt_remaining_test.dart`:
  - (a) `PaymentAttempt.remaining(attemptKey: 'k', bookingId: 'b', startedAt: t)` has `kind == PaymentKind.remaining`, `quoteId == ''`, `propertyId == ''`, `termsHash == ''`, `paymentId == null`;
  - (b) its `toJson()` has `'kind': 'remaining'`, and `fromJson(toJson())` gives an equal object;
  - (c) a JSON **without** `kind` (copy the map from `test/core/storage/secure_stores_test.dart` `_attempt()`) parses with `kind == PaymentKind.initial`;
  - (d) `copyWith(paymentId: 'p')` keeps `kind`.
- [X] T033 [P] [US1] Write `test/features/booking/domain/remaining_outcome_test.dart` for `remainingOutcomeFor(String paymentId)`, which returns a `VerificationOutcome Function(BookingDetails)`. Build details from fixture booking `…020` with one `payments` line whose `id == 'p1'` and set its `status` to each value:

  | Status of line `p1` | Expected outcome |
  |---|---|
  | `succeeded` | `success` |
  | `failed`, `cancelled`, `expired` | `failed` |
  | `pending`, `verifying` | `waiting` |
  | no line with id `p1` | `waiting` |

  Also assert that the booking `status` is ignored: `confirmed` with a `succeeded` line still gives `success`.
- [X] T034 [P] [US1] Extend `test/features/booking/presentation/payment_attempt_cubit_test.dart` with a new `group('payRemaining')`, copying the existing `pay` tests' fakes:
  - (a) the record is saved **before** the repository call, with `kind: remaining` and `bookingId`;
  - (b) a second call while starting does nothing (one repository call);
  - (c) a stored remaining attempt for the **same** booking reuses its `attemptKey`, while a stored attempt for another booking or kind gets a new key;
  - (d) success saves `paymentId`, `paymentUrl`, and `paymentUrlExpiresAt`, emits `AttemptOpened`, and opens the browser once;
  - (e) an `AppFailure(CONFLICT)` emits `AttemptFailed` with code `conflict`.
- [X] T035 [P] [US1] Write `test/features/stay/presentation/remaining_payment_cubit_test.dart` for `RemainingPaymentCubit` (T042), using `FakeBookingBackend(includeG3Fixtures: true)`:
  - (a) `load()` for `…020` emits `RemainingLoading`, then `RemainingReady(details, cashAllowed: true)`, where `cashAllowed` is whether `confirm_cash_payment` is visible;
  - (b) for booking `…023` (no `pay_remaining`), it emits `RemainingNotAllowed`;
  - (c) when the details have `pendingRemainingPaymentId != null` (set it on the fixture map in the test through `await backend.server.bookings`), it emits `RemainingGoVerify(bookingId)`;
  - (d) offline with no cache emits `RemainingOffline`;
  - (e) `NOT_FOUND` (unknown UUID) emits `RemainingNotAvailable`.
- [X] T036 [P] [US1] Write `test/features/stay/presentation/remaining_payment_screen_test.dart` (pump with `pumpOnAirApp`, a backend with `includeG3Fixtures: true` and `actionRegistry: BookingActionRegistry.g3()`):
  - (a) Ready shows the property title, `AmountRow`s for `l10n.bookingTotal`, `l10n.bookingPaid`, `l10n.bookingRemaining`, and `l10n.remainingDueLabel` with the fixture values, plus the `InfoBanner` text `l10n.remainingNote`;
  - (b) with cash allowed, two option cards are shown (`l10n.remainingOptionOnline`, `l10n.remainingOptionCash`), the online option is selected by default, and the bar button reads `l10n.remainingPayButton(<formatted remaining>)`;
  - (c) selecting cash changes the button to `l10n.remainingCashButton`;
  - (d) for a booking without cash (`…023` with `pay_remaining` added in the test), there are no option cards;
  - (e) tapping pay twice quickly results in one start (assert `backend.server.remainingStarts == 1`; the counter is added in T038).

### Implementation for User Story 1

- [X] T037 [US1] Extend `PaymentAttempt` in `lib/features/booking/domain/payment_attempt.dart` (makes T032 pass):
  - add `enum PaymentKind { initial, remaining }` in the same file;
  - add constructor parameters `this.kind = PaymentKind.initial` and `this.paymentId` (type `String?`);
  - add `factory PaymentAttempt.remaining({required String attemptKey, required String bookingId, required DateTime startedAt}) => PaymentAttempt(attemptKey: attemptKey, quoteId: '', propertyId: '', termsHash: '', bookingId: bookingId, startedAt: startedAt, kind: PaymentKind.remaining);`;
  - in `fromJson`, read `kind` (`'remaining'` → remaining, anything else or missing → initial) and `payment_id`;
  - in `toJson`, write `'kind': kind.name` and `'payment_id': paymentId`;
  - `copyWith` gains `String? paymentId` and keeps `kind`;
  - add `kind` and `paymentId` to `==` and `hashCode`.

  Old call sites keep compiling, because the new parameters are optional. Run `flutter test test/features/booking test/core/storage`.
- [X] T038 [US1] Add the remaining-payment start:
  - (a) In `lib/features/booking/domain/booking_flow_repository.dart`, add to the interface: `Future<PaymentSessionInfo> startRemainingPayment({required String bookingId, required String attemptKey});` with the doc comment "Sends only the booking and the attempt key — never an amount (Constitution III)."
  - (b) In `lib/features/booking/data/supabase_booking_flow_repository.dart`, implement it by copying `startPayment`. Call `_node.startRemainingPayment(xRequestId: const Uuid().v4(), bookingId: bookingId, body: V1GuestBookingsBookingIdRemainingPaymentRequestBody(idempotencyKey: attemptKey))`.
  - (c) In `lib/features/bookings/data/mock_booking_server.dart`, add `int remainingStarts = 0;` and implement `startRemainingPayment` following **Appendix D §1**.
  - (d) In the same file, at the **top** of `completePayment`, add the remaining branch from Appendix D §1. If the booking has a `payments` line with `purpose == 'remaining'` and `status == 'pending'`, complete **that** line and return without running the initial-payment switch.
  - (e) Any other class that `implements BookingFlowRepository` under `test/helpers/` must get the method (throw `UnimplementedError()` if it is unused).
- [X] T039 [US1] In `lib/features/booking/domain/verification_outcome.dart`, add `VerificationOutcome Function(BookingDetails) remainingOutcomeFor(String paymentId)` exactly as the table in T033 (makes T033 pass). Do not change `verificationOutcomeFor`.
- [X] T040 [US1] Add `Future<void> payRemaining(String bookingId)` to `PaymentAttemptCubit` in `lib/features/booking/presentation/payment_attempt_cubit.dart` (makes T034 pass). Copy the body of `pay(...)` with these differences:
  - **Reused record:** a stored attempt is reused only when `stored.kind == PaymentKind.remaining && stored.bookingId == bookingId`. Otherwise create `PaymentAttempt.remaining(attemptKey: _newKey(), bookingId: bookingId, startedAt: _now())`.
  - **Start call:** call `_flow.startRemainingPayment(bookingId: bookingId, attemptKey: attempt.attemptKey)`.
  - **After success:** save `attempt.copyWith(paymentId: session.paymentId, paymentUrl: session.paymentUrl.toString(), paymentUrlExpiresAt: session.paymentUrlExpiresAt)`.
  - **Log line:** `'remaining_payment_started booking=$bookingId key=${attempt.attemptKey.substring(0, 8)}'`.
- [X] T041 [US1] Teach the verification screen about remaining payments:
  - (a) In `lib/features/booking/presentation/payment_verification_cubit.dart`, add an optional constructor parameter `VerificationOutcome Function(BookingDetails)? outcomeFor`, stored as `_outcomeFor = outcomeFor ?? verificationOutcomeFor`. Use `_outcomeFor(details)` instead of `verificationOutcomeFor(details)` in `_fetch`.
  - (b) In `lib/features/booking/presentation/payment_return_screen.dart`, read the attempt from `attemptState` (`AttemptOpened` or `AttemptReturned`). If `attempt.kind == PaymentKind.remaining && attempt.paymentId != null`, pass `outcomeFor: remainingOutcomeFor(attempt.paymentId!)` to the cubit. Also pass a new `isRemaining` flag down to `_ReturnBody`.
  - (c) In `_ReturnBodyState.build`, when `isRemaining`:
    - `VerificationOutcome.success` shows a new `_RemainingSuccess`, which copies `_Success` **without** the deadline countdown, with title `l10n.remainingPaidTitle`, body `l10n.remainingPaidBody`, and the button `l10n.paymentViewBooking` → `finish()` then `context.go(AppRoutes.bookingDetails(details.id))`;
    - `failed` shows a new `_RemainingFailed`, which copies `_Failed` with title `l10n.paymentFailedTitle`, body `l10n.remainingFailedBody`, and the button `l10n.paymentTryAgain` → `await attemptCubit.newAttempt();` then `context.go(AppRoutes.remainingPayment(details.id))`;
    - in the listener, run the `finish()` call on success for both kinds, but run the push-permission ask only when not `isRemaining`.
  - (d) In `lib/features/bookings/presentation/unfinished_payment_cubit.dart` `_reconcileAttempt`, when `attempt.kind == PaymentKind.remaining`, clear the record only on `NOT_FOUND` or when `remainingOutcomeFor(attempt.paymentId ?? '')(details) != VerificationOutcome.waiting`. Do not use the `paymentVerifying` rule for remaining attempts.
  - (e) Add tests:
    - in `test/features/booking/presentation/payment_return_screen_test.dart`, a remaining attempt whose line becomes `succeeded` shows `l10n.remainingPaidTitle` and no deadline text, and a `failed` line shows `l10n.remainingFailedBody`, with "Try again" navigating to `/bookings/<id>/remaining-payment`;
    - in `test/features/bookings/presentation/unfinished_payment_cubit_test.dart`, a remaining attempt with a `pending` line is **not** cleared.
- [X] T042 [US1] Create `lib/features/stay/presentation/remaining_payment/remaining_payment_cubit.dart` (makes T035 pass):
  - **States:** `RemainingLoading`, `RemainingReady({required BookingDetails details, required bool cashAllowed})`, `RemainingGoVerify(String bookingId)`, `RemainingNotAllowed`, `RemainingNotAvailable`, `RemainingOffline`, `RemainingFailed(ApiError error)`.
  - **Constructor:** `RemainingPaymentCubit({required this._bookings, required this._registry, required this._connectivity, required this._bookingId})` (types: `BookingsRepository`, `BookingActionRegistry`, `ConnectivityCubit`, `String`).
  - **`load()`:**
    1. If `!_connectivity.state.isOnline`, emit `RemainingOffline`.
    2. Otherwise call `_bookings.getBooking(id)`.
    3. If `details.pendingRemainingPaymentId != null`, emit `RemainingGoVerify(id)`.
    4. Else, with `visible = _registry.visible(details.availableActions)`: if `!visible.contains(BookingActionCode.payRemaining)`, emit `RemainingNotAllowed`.
    5. Else emit `RemainingReady(details: details, cashAllowed: visible.contains(BookingActionCode.confirmCashPayment))`.

    `ErrorCode.notFound` → `RemainingNotAvailable`, and other errors → `RemainingFailed`.
- [X] T043 [US1] Create `lib/features/stay/presentation/remaining_payment/remaining_payment_screen.dart` (layout: [contracts/ui-screens.md §3](contracts/ui-screens.md); makes T036 pass):
  - **Class:** `RemainingPaymentScreen({required String bookingId})`, a `StatefulWidget` holding `bool _cash = false`.
  - **App bar:** `AppBar(title: Text(l10n.remainingTitle))`.
  - **Body, `RemainingReady`:** a `ListView` with padding `EdgeInsetsDirectional.all(Dimens.screenSide)` containing, separated by `Dimens.space16`:
    1. **Property row:** copy the image + title + area part of `_Header` in `booking_details_screen.dart`, with a 64×64 image.
    2. **Amount card:** a `Card` with `Padding(all: Dimens.space16)` and `AmountRow`s for `l10n.bookingTotal`, `l10n.bookingPaid`, `l10n.bookingRemaining` (`emphasized: true`), and `l10n.remainingDueLabel` (value `formatCairoDayMonthTime(details.remainingDueAt!)`, row omitted when null).
    3. **Note:** `InfoBanner(message: l10n.remainingNote, tone: StatusTone.info)`.
    4. **Options (only when `cashAllowed`):** a section title `l10n.remainingChooseMethod` (`titleMedium`, `textPrimary`), then two option cards. Each is a private `_OptionCard({required String label, required bool selected, required VoidCallback onTap})`: a `Card` with `color: selected ? context.colors['badgeNavActive'] : context.colors.surface`, an `InkWell` with the `Dimens.radiusCard` border radius, a `ConstrainedBox(minHeight: Dimens.minTouchTarget)`, and a `Row` with the label (`bodyLarge`), `Spacer`, and `Icon(selected ? AppIcons.radioChecked : AppIcons.radioButtonUnchecked, color: selected ? context.colors.primary : context.colors.textSecondary)`. Wrap it in `Semantics(selected: selected, button: true, label: label)`.

    Every value comes from `details`. Never compute.
  - **Bottom bar:** `bottomNavigationBar: BottomActionBar(leading: const SizedBox.shrink(), action: …)`:
    - online selected → `OnAirPrimaryButton(key: const ValueKey('remaining-pay'), label: l10n.remainingPayButton(MoneyFormatter().format(details.remaining)), isLoading: attemptState is AttemptStarting, onPressed: () => context.read<PaymentAttemptCubit>().payRemaining(details.id))`;
    - cash selected → `OnAirPrimaryButton(key: const ValueKey('remaining-cash'), label: l10n.remainingCashButton, onPressed: () => context.push(AppRoutes.cashConfirm(details.id)))`. Until US2 is done, this route shows `NotAvailableScreen`, which is expected.
  - **Listeners:** a `BlocListener<PaymentAttemptCubit, PaymentAttemptState>`:
    - `AttemptFailed` with `error.code == ErrorCode.conflict` → `context.go(AppRoutes.paymentReturn(bookingId: widget.bookingId))`;
    - other `AttemptFailed` → `SnackBar(content: Text(apiErrorMessage(error, l10n)))`.

    A `BlocListener<RemainingPaymentCubit, …>`:
    - `RemainingGoVerify` → `context.go(AppRoutes.paymentReturn(bookingId: id))`;
    - `RemainingNotAllowed` → `context.go(AppRoutes.bookingDetails(id))`, then show `SnackBar(l10n.stayStepNotAvailable)`.
  - **Other states:**
    - loading → a skeleton (copy `_DetailsSkeleton` from the details screen into this file as `_RemainingSkeleton`);
    - `RemainingFailed` → `ErrorView(message: apiErrorMessage(...), onRetry: cubit.load, referenceNumber: error.requestId)`;
    - `RemainingOffline` → `ErrorView(message: l10n.stayNeedsConnection, onRetry: cubit.load)`;
    - `RemainingNotAvailable` → `EmptyView(icon: AppIcons.infoOutline, message: l10n.notAvailable)`.
  - **Route:** in `app_router.dart`, replace the `remainingPaymentPattern` builder (`NotAvailableScreen`) with a `BlocProvider<RemainingPaymentCubit>` (create + `unawaited(cubit.load())`) around `RemainingPaymentScreen(bookingId: id)`, copying the booking-details route.
- [X] T044 [US1] In `booking_details_screen.dart`, inside the payments section right after the remaining `AmountRow`s, add `const SizedBox(height: Dimens.space8)` and `InfoBanner(message: l10n.remainingNote, tone: StatusTone.info)`. Show them **only** when `registry.visible(details.availableActions).contains(BookingActionCode.payRemaining)`. Add widget tests in `test/features/bookings/presentation/booking_details_screen_test.dart`: with `g3()` and booking `…020`, the banner and the primary button `primary-pay_remaining` are shown; with `g2()`, neither is.
- [X] T045 [P] [US1] Write `test/features/stay/goldens/remaining_payment_golden_test.dart` (copy `test/features/bookings/goldens/bookings_goldens_test.dart`). It renders:
  - `RemainingPaymentScreen` for `…020` (cash allowed, online selected) in the four standard variants, plus `light_RTL` at widths 320 and 800 (files `remaining_payment_<variant>`, `remaining_payment_light_RTL_w320`, `remaining_payment_light_RTL_w800`);
  - booking details for `…020` with `g3()` (files `booking_details_deposit_<variant>`).

  Generate with `--update-goldens` and review each image against [contracts/ui-screens.md §1 and §3](contracts/ui-screens.md): no overflow, one filled button, and the same paddings as the G2 `booking_details_confirmed` golden.
- [X] T046 [US1] Create `test/helpers/stay_journey.dart` with `Future<void> runRemainingPaymentJourney(WidgetTester tester)`, copying the style and app setup of `test/helpers/booking_journey.dart`, with `FakeBookingBackend(includeG3Fixtures: true, actionRegistry: BookingActionRegistry.g3())`. The steps:
  1. Open `/bookings/b0000000-0000-4000-8000-000000000020`.
  2. Tap `primary-pay_remaining`.
  3. Tap `remaining-pay`.
  4. On the mock page, tap its success button.
  5. Expect `l10n.remainingPaidTitle`.
  6. Tap `l10n.paymentViewBooking`.
  7. Expect no `primary-pay_remaining`.

  Then:
  - create `test/features/journey/stay_journey_test.dart` with `testWidgets('remaining payment', runRemainingPaymentJourney)`;
  - create `integration_test/stay_journey_mock_test.dart`, copying `integration_test/booking_journey_mock_test.dart` and calling the same function.

**Checkpoint**: US1 works end to end in mock mode. `flutter test` passes, and all goldens are
reviewed.

---

## Phase 4: User Story 2 - Confirm a cash payment with an email code (Priority: P1)

**Goal**: The guest confirms a cash payment for the full remaining amount with a code sent to
their email, from either entry (guest-started or collector-started). They then see a receipt
that can be reopened from details (AC-037, AC-038).

**Independent Test**: In mock mode, open booking `…020`, tap "ادفع المبلغ المتبقي", and choose
"دفعت أو هدفع كاش":
- type `0100` → field error;
- type `01099999999` → not-authorized warning;
- type `01000000001` → code step;
- enter `000000` → error, then `123456` with the statement checked → receipt.

Back in details, the cash line opens the same receipt. For the collector-started entry, open
`…028`: its primary action opens the code step directly.

### Tests for User Story 2

- [X] T047 [P] [US2] Write `test/features/stay/presentation/cash_confirm_cubit_test.dart` for `CashConfirmCubit` (T050), using `FakeBookingBackend(includeG3Fixtures: true, actionRegistry: BookingActionRegistry.g3())`. Cover every transition of data-model §2:
  - (a) `load()` for `…020` (no pending cash, cash allowed) emits `CashPhoneEntry(amount: Money(337500))`;
  - (b) for `…028` (pending cash), it emits `CashCodeEntry` with `request.collectorDisplayName == 'أحمد م.'`, and **no** `sendCashCode` call happens (assert `backend.stay.codesSent == 0`);
  - (c) `submitPhone('0100')` emits `CashPhoneEntry(phoneError: true)` with no repository call;
  - (d) `submitPhone('01099999999')` emits `CashNotAuthorized`;
  - (e) `submitPhone('01000000001')` emits `CashStarting`, then `CashCodeEntry`, `backend.stay.codesSent == 1`, and the start received `expectedAmount == Money(337500)` (assert `backend.stay.lastExpectedAmount`);
  - (f) calling `submitPhone` again while starting does nothing;
  - (g) `confirm('000000')` emits `CashCodeEntry` with `error.code == ErrorCode.otpInvalid`;
  - (h) `confirm('123456')` emits `CashConfirming`, then `CashDone`;
  - (i) `resend()` when `backend.stay.rateLimitNextSend = true` emits `CashCodeEntry` with `resendAvailableAt == now + 30 s`;
  - (j) after `backend.stay.changeAmountOnce('…020')`, `submitPhone(valid)` reloads and emits `CashPhoneEntry` with the new amount;
  - (k) a network error on start (`backend.stay.failNextWithNetwork = true`) keeps the key, and the retry sends the same `idempotencyKey` (assert `backend.stay.lastCashStartKey` is equal both times).
- [X] T048 [P] [US2] Write `test/features/stay/presentation/cash_confirm_screen_test.dart`:
  - (a) the phone step shows the amount read-only, inside `Semantics` with label `l10n.cashAmountLocked`, with no editable field for the amount (`find.byType(TextField)` finds exactly one, the phone);
  - (b) an invalid phone shows `l10n.cashPhoneInvalid`;
  - (c) not authorized shows the `InfoBanner` text `l10n.stayCollectorNotAuthorized` and an `OutlinedButton` with `l10n.cashContactSupport`;
  - (d) the code step shows `l10n.cashCodeSent('g***@mock.onair.test')`;
  - (e) the confirm button is disabled until 6 digits are entered **and** the statement checkbox is checked;
  - (f) a double tap on confirm makes one confirm call (`backend.stay.cashConfirms == 1`);
  - (g) while waiting to resend, the resend button shows `l10n.cashResendIn('0:30')`;
  - (h) no clipboard write happens (record calls on `SystemChannels.platform` with `tester.binding.defaultBinaryMessenger.setMockMethodCallHandler` and assert none is `Clipboard.setData`).

  Also write `test/features/stay/presentation/cash_receipt_screen_test.dart`: for `…022`, the receipt shows the amount, collector, date, and receipt number `R-2026-000123`, and the copy icon puts the receipt number on the clipboard (this copy **is** allowed, because it is not the code).

### Implementation for User Story 2

- [X] T049 [US2] Create `lib/features/stay/presentation/cash/cash_texts.dart` with `String formatWait(Duration d)`, copying `_waitText` in `lib/core/errors/error_message.dart` (`m:ss`, for example 90 s → `1:30`).
- [X] T050 [US2] Create `lib/features/stay/presentation/cash/cash_confirm_cubit.dart` (makes T047 pass):
  - **States:**
    - `CashLoading`;
    - `CashPhoneEntry({required Money amount, bool phoneError = false, ApiError? error})`;
    - `CashStarting({required Money amount})`;
    - `CashNotAuthorized({required Money amount})`;
    - `CashNotAllowed`;
    - `CashCodeEntry({required CashRequest request, ApiError? error, DateTime? resendAvailableAt})`;
    - `CashConfirming({required CashRequest request})`;
    - `CashDone({required String paymentId})`;
    - `CashOffline`, `CashNotAvailable`, `CashFailed(ApiError error)`.
  - **Constructor:** `CashConfirmCubit({required this._bookings, required this._stay, required this._attempts, required this._registry, required this._connectivity, required this._logger, required this._bookingId, DateTime Function()? now})`.
  - **`load()`:** if offline, emit `CashOffline`. Otherwise `getBooking` (`notFound` → `CashNotAvailable`, other errors → `CashFailed`):
    1. if `details.pendingCash != null`, emit `CashCodeEntry(request: pendingCash, resendAvailableAt: pendingCash.retryAfterSeconds > 0 ? now + seconds : null)`;
    2. else, if `confirm_cash_payment` is visible, emit `CashPhoneEntry(amount: details.remaining)` and remember `_amount = details.remaining`;
    3. else emit `CashNotAllowed`.
  - **`submitPhone(String raw)`:**
    1. guard `_busy`;
    2. `EgyptPhone.tryParse(raw)` (`lib/features/auth/domain/egypt_phone.dart`) — if null, emit `CashPhoneEntry(amount: _amount, phoneError: true)` and return;
    3. `key = await _attempts.keyFor('cash_start', _bookingId)`;
    4. emit `CashStarting(amount: _amount)`;
    5. `request = await _stay.startCashConfirmation(bookingId: _bookingId, collectorPhoneE164: phone.e164, expectedAmount: _amount, idempotencyKey: key)`;
    6. `await _attempts.clear('cash_start', _bookingId)`;
    7. log `'cash_confirm_started booking=$_bookingId payment=${request.paymentId}'`;
    8. `await _stay.sendCashCode(request.challengeId)`;
    9. emit `CashCodeEntry(request: request)`.

    Error handling (by `failure.error.code`):

    | Error | What to do |
    |---|---|
    | `collectorNotAuthorized` | clear the key, emit `CashNotAuthorized(amount: _amount)` |
    | `cashNotAllowed` | clear the key, emit `CashNotAllowed` |
    | `cashAmountChanged` | clear the key, call `load()` |
    | `network` | keep the key, emit `CashPhoneEntry(amount: _amount, error: failure.error)` |
    | `rateLimited` (thrown by `sendCashCode`) | emit `CashCodeEntry(request: request, resendAvailableAt: now + (error.retryAfter ?? 30 s))` |
    | anything else | clear the key, emit `CashPhoneEntry(amount: _amount, error: failure.error)` |
  - **`resend()`:** guard `_busy`, call `sendCashCode(current.request.challengeId)`, then emit `CashCodeEntry(request:, resendAvailableAt: null)`. On `rateLimited`, set `resendAvailableAt` as above.
  - **`confirm(String code)`:**
    1. guard `_busy` and `code.length == 6`;
    2. emit `CashConfirming(request:)`;
    3. `await _stay.confirmCashPayment(paymentId:, challengeId:, code: code)`;
    4. log `'cash_confirmed booking=$_bookingId payment=${request.paymentId}'`;
    5. emit `CashDone(paymentId: request.paymentId)`.

    Any `AppFailure` → `CashCodeEntry(request:, error: failure.error)`.
- [X] T051 [US2] Create `lib/features/stay/presentation/cash/cash_confirm_screen.dart` (layout: [contracts/ui-screens.md §4](contracts/ui-screens.md); makes T048 pass):
  - **App bar:** `l10n.cashTitle`.
  - **Phone step (`CashPhoneEntry` / `CashStarting` / `CashNotAuthorized`):** a `ListView` holding:
    1. a `Card` with `Semantics(label: l10n.cashAmountLocked, child: Padding(all: Dimens.space16, child: Row([Icon(AppIcons.lockOutlineRounded, size: 20), SizedBox(width: Dimens.space8), Expanded(child: AmountRow(label: l10n.cashAmountLabel, value: fmt(amount), emphasized: true))])))`;
    2. `OnAirTextField(controller: _phone, label: l10n.cashPhoneLabel, hint: l10n.cashPhoneHint, keyboardType: TextInputType.phone, errorText: phoneError ? l10n.cashPhoneInvalid : null, textInputAction: TextInputAction.done, autofillHints: const [AutofillHints.telephoneNumber])`;
    3. `InfoBanner(message: l10n.cashWarning, tone: StatusTone.warning, icon: AppIcons.warningOutline)`;
    4. when `error != null`, the error text in `bodySmall` / `errorText` inside `Semantics(liveRegion: true)`;
    5. for `CashNotAuthorized` only, `InfoBanner(message: l10n.stayCollectorNotAuthorized, tone: StatusTone.warning)` and `OutlinedButton(onPressed: () => context.push('${AppRoutes.supportNew}?booking=$id'), child: Text(l10n.cashContactSupport))`.

    Bar: `OnAirPrimaryButton(key: ValueKey('cash-send'), label: l10n.cashSendCode, isLoading: state is CashStarting, onPressed: () => cubit.submitPhone(_phone.text))`.
  - **Code step (`CashCodeEntry` / `CashConfirming`):** a `ListView` holding:
    1. `NoticeCard(icon: AppIcons.mailOutlineRounded, message: l10n.cashCodeSent(request.maskedEmail))`;
    2. a `Card` with `AmountRow(l10n.cashAmountLabel, fmt(request.amount))` and `AmountRow(l10n.cashCollectorLabel, request.collectorDisplayName)`;
    3. `OnAirOtpField(onCompleted: (_) {}, onChanged: (v) => setState(() => _code = v))`;
    4. when `error != null`, the error text (`apiErrorMessage`) in `errorText` colour inside `Semantics(liveRegion: true)`;
    5. the resend `TextButton`. While `resendAvailableAt != null && now < resendAvailableAt`, it is disabled and its child is `CountdownText(remaining: _resendCountdown.remaining, format: (d) => l10n.cashResendIn(formatWait(d)))`. Create a `Countdown(deadlineUtc: resendAvailableAt)` when the state arrives, cancel it in `dispose`, and `setState` when it reaches zero. Otherwise the child is `Text(l10n.cashResend)` with `onPressed: cubit.resend`;
    6. `CheckboxListTile(value: _agreed, onChanged: (v) => setState(() => _agreed = v ?? false), title: Text(l10n.cashStatement(fmt(request.amount), request.collectorDisplayName)), controlAffinity: ListTileControlAffinity.leading)`.

    Bar: `OnAirPrimaryButton(key: ValueKey('cash-confirm'), label: l10n.cashConfirmButton, isLoading: state is CashConfirming, onPressed: _code.length == 6 && _agreed && state is! CashConfirming ? () => cubit.confirm(_code) : null)`.
  - **Listener:**
    - `CashDone` → `context.pushReplacement(AppRoutes.receipt(id, paymentId))`;
    - `CashNotAllowed` → `context.go(AppRoutes.bookingDetails(id))` plus `SnackBar(l10n.stayStepNotAvailable)`.
  - **Other states:** offline, failed, and not available use the same widgets as T043.
  - **Code handling:** keep the code in a private field only, never log it, and clear `_code` in `dispose`.
- [X] T052 [US2] Create the receipt:
  - **Cubit:** `lib/features/stay/presentation/cash/cash_receipt_cubit.dart` with states `ReceiptLoading`, `ReceiptReady({required PaymentLine line})`, `ReceiptMissing`, and constructor `({required this._bookings, required this._cache, required this._connectivity, required this._bookingId, required this._paymentId})`. `load()` reads `_cache.readDetails(id)` first; if online, it calls `getBooking` instead. It then finds the line with `id == paymentId && receipt != null`, and emits `ReceiptMissing` if there is none.
  - **Screen:** `lib/features/stay/presentation/cash/cash_receipt_screen.dart` (layout: [contracts/ui-screens.md §5](contracts/ui-screens.md)), a `ListView` holding:
    1. a centered `Icon(AppIcons.checkCircle, size: 64, color: context.colors['success'])`;
    2. a `Text(l10n.receiptTitle)` in `titleLarge`, centered;
    3. a `Card` with `AmountRow`s for `l10n.cashAmountLabel` / `fmt(line.amount)`, `l10n.cashCollectorLabel` / `receipt.collectorDisplayName`, `l10n.receiptDate` / `formatCairoDayMonthTime(receipt.confirmedAt)`, and a `Row` with `Expanded(AmountRow(l10n.receiptNumber, receipt.receiptNo))` plus `IconButton(icon: const Icon(AppIcons.copy), tooltip: l10n.bookingCopyCode, onPressed: copy + SnackBar(l10n.receiptCopied))`.

    Bar: `OnAirPrimaryButton(label: l10n.receiptBack, onPressed: () => context.go(AppRoutes.bookingDetails(id)))`. `ReceiptMissing` → `context.go(AppRoutes.bookingDetails(id))`.
- [X] T053 [US2] In `app_router.dart`, replace the T023 placeholders:
  - `cashConfirmPattern` → `BlocProvider<CashConfirmCubit>` (+ `unawaited(cubit.load())`) around `CashConfirmScreen(bookingId: id)`;
  - `receiptPattern` → `BlocProvider<CashReceiptCubit>` (+ `load()`) around `CashReceiptScreen(bookingId: id, paymentId: state.pathParameters['paymentId']!)`.

  Read every dependency with `context.read<…>()`.
- [X] T054 [US2] In `booking_details_screen.dart`:
  - (a) Wrap the whole payments section (from the `bookingPaymentsTitle` text to the last payment line) in `KeyedSubtree(key: _paymentsKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [...]))`.
  - (b) For each payment line where `line.method == 'cash' && line.receipt != null`, wrap its `AmountRow` in `Semantics(button: true, label: l10n.receiptShow, child: InkWell(onTap: () => context.push(AppRoutes.receipt(details.id, line.id)), child: Row([Expanded(AmountRow(...)), const Icon(AppIcons.chevronLeft, size: 16)])))`. Use `AppIcons.chevronLeft` because in RTL "forward" points left. In LTR (English), use `AppIcons.chevronRight`, choosing by `Directionality.of(context) == TextDirection.rtl`.
  - (c) Add a widget test: booking `…022` → tap the cash line → the receipt screen shows `R-2026-000123`.
- [X] T055 [P] [US2] Write `test/features/stay/goldens/cash_golden_test.dart` covering the phone step (`…020`), the not-authorized state, the code step (`…028`, with a 30 s resend wait), and the receipt (`…022`) in the four standard variants. Generate and review the images against [contracts/ui-screens.md §4–§5](contracts/ui-screens.md).
- [X] T056 [US2] Add `runCashJourney` to `test/helpers/stay_journey.dart` (the Independent Test above, both entries), and call it from `test/features/journey/stay_journey_test.dart` and `integration_test/stay_journey_mock_test.dart`.

**Checkpoint**: US1 + US2 pass. A cash payment is recorded only after the guest enters the code.

---

## Phase 5: User Story 3 - Confirm receiving and leaving the apartment (Priority: P1)

**Goal**: "استلمت الشقة" and "غادرت الشقة" through a confirmation sheet with no code and no
photos. Details show who confirmed and who is pending, and the status changes only when the
server reports it (AC-025 to AC-027, AC-036).

**Independent Test**: In mock mode, open booking `…021` and tap "استلمت الشقة" → "أيوه،
استلمتها". The tracker shows "أنت: أكّد …" and "المالك: مستني التأكيد". Next, use the mock tool
"المالك أكّد التسليم". The status becomes "إقامة جارية". Repeat the same steps for leaving on
`…022`.

### Tests for User Story 3

- [X] T057 [P] [US3] Write `test/features/stay/presentation/stay_ack_cubit_test.dart` for `StayAckCubit` (T059):
  - (a) `confirmCheckIn()` on `…021` emits `AckSubmitting`, then `AckDone(newStatus: 'confirmed')`, and the mock booking map now has `acknowledgements.guest_checkin_at` set;
  - (b) a second call while submitting does nothing;
  - (c) on `…020` (remaining unpaid), it emits `AckFailed` with `ErrorCode.remainingNotPaid`;
  - (d) `confirmCheckOut()` on `…022` emits `AckDone`;
  - (e) a network error (`backend.stay.failNextWithNetwork = true`) emits `AckFailed(network)`, and the next call reaches the repository again.
- [X] T058 [P] [US3] Extend `test/features/bookings/presentation/booking_status_ui_test.dart`. For `bookingStatusMessage(details, l10n)`:

  | Status | Acknowledgements | Expected message |
  |---|---|---|
  | `confirmed` | `guestCheckInAt` set | `l10n.bookingMsgWaitingHandover` |
  | `confirmed` | only `hostCheckInAt` set | `l10n.bookingMsgHostHandedOver` |
  | `checked_in` | `guestCheckOutAt` set | `l10n.bookingMsgWaitingCheckout` |
  | `cancelled` | `cancellation.byScope == 'platform'` | `l10n.bookingMsgCancelledByPlatform` |
  | `cancelled` | `byScope == 'guest'` | `l10n.bookingMsgCancelledByGuest` |
  | `confirmed` | last event type `booking.reopened`, no acknowledgements | `l10n.bookingMsgReopened` |

  All existing cases must keep their old messages.

  For `ackStepsFor(details, l10n)` (T061):
  - it returns `null` when `!acknowledgements.hasAny` and the status is not `completed`;
  - it returns the title `l10n.ackTitleCheckin` and two steps in `confirmed` with any check-in time;
  - it returns `l10n.ackTitleCheckout` in `checked_in` with any check-out time;
  - `note == l10n.ackKeyLeftSafe` only when `keyLeftSafe`.

### Implementation for User Story 3

- [X] T059 [US3] Create `lib/features/stay/presentation/stay_ack/stay_ack_cubit.dart` (makes T057 pass):
  - **States:** `AckIdle`, `AckSubmitting`, `AckDone(String newStatus)`, `AckFailed(ApiError error)`.
  - **Constructor:** `StayAckCubit({required this._stay, required this._logger, required this._bookingId})`.
  - **Methods:** `confirmCheckIn()` and `confirmCheckOut()`. Each guards `_busy`, emits `AckSubmitting`, calls the repository, logs `'checkin_confirmed booking=$_bookingId'` / `'checkout_confirmed booking=$_bookingId'`, and emits `AckDone` or `AckFailed`.
- [X] T060 [US3] Replace the stubs in `lib/features/stay/presentation/stay_ack/stay_ack_sheets.dart` with real `Future<bool> showCheckInSheet(BuildContext context, BookingDetails details)` and `Future<bool> showCheckOutSheet(...)`:
  - **Sheet:** each returns `await OnAirConfirmSheet.show<bool>(context, builder: (_) => BlocProvider(create: (_) => StayAckCubit(stay: context.read(), logger: context.read(), bookingId: details.id), child: _AckSheetBody(checkIn: true|false, bookingId: details.id))) ?? false`. Read the providers from the **outer** `context` before opening the sheet.
  - **`_AckSheetBody`:** uses a `BlocConsumer<StayAckCubit, StayAckState>`:
    - **Content:** `OnAirConfirmSheet` with title, body, and confirm from Appendix A (`checkinSheetTitle` / `checkinSheetBody` / `checkinSheetConfirm`, or the `checkout…` keys), `cancelLabel: l10n.sheetNotYet`, `isLoading: state is AckSubmitting`, and `onConfirm: checkIn ? cubit.confirmCheckIn : cubit.confirmCheckOut`.
    - **Check-in only:** `extraActionLabel: l10n.checkinProblem`, `onExtraAction: () { final router = GoRouter.of(context); Navigator.pop(context, false); router.push('${AppRoutes.supportNew}?booking=$bookingId'); }`.
    - **`AckFailed`:** add an optional `String? errorText` parameter to `OnAirConfirmSheet` (T026's file). When it is not null, it renders under the body in `bodySmall` / `errorText` with `Semantics(liveRegion: true)`. Pass `apiErrorMessage(error, l10n)`.
    - **Listener:** `AckDone` → `Navigator.pop(context, true)`.
- [X] T061 [US3] Update `lib/features/bookings/presentation/booking_status_ui.dart` (makes T058 pass):
  - (a) In `bookingStatusMessage`, before the `switch`:
    1. if status is `confirmed`, `acknowledgements.guestCheckInAt != null`, and `hostCheckInAt == null` → `bookingMsgWaitingHandover`;
    2. if status is `confirmed`, `hostCheckInAt != null`, and `guestCheckInAt == null` → `bookingMsgHostHandedOver`;
    3. if status is `checkedIn` and `guestCheckOutAt != null` → `bookingMsgWaitingCheckout`;
    4. if status is `cancelled` and `cancellation?.byScope == 'platform'` → `bookingMsgCancelledByPlatform`; if `== 'guest'` → `bookingMsgCancelledByGuest`;
    5. if status is `confirmed`, `!acknowledgements.hasAny`, and `details.events.isNotEmpty && details.events.last.eventType == 'booking.reopened'` → `bookingMsgReopened`.

    Check the `BookingEvent` field name in `booking_parts.dart` before using it.
  - (b) Add a top-level function:
    ```dart
    ({String title, List<AckStep> steps, String? note})? ackStepsFor(BookingDetails details, AppLocalizations l10n)
    ```
    following data-model §4:
    - **Check-out tracker:** used when `(status == checkedIn && (guestCheckOutAt != null || hostCheckOutAt != null)) || status == completed`.
      - Title: `l10n.ackTitleCheckout`.
      - Steps: `AckStep(label: l10n.ackYou, statusText: guestCheckOutAt == null ? l10n.ackWaiting : l10n.ackConfirmedAt(formatCairoDayMonthTime(guestCheckOutAt!)), done: guestCheckOutAt != null)`, and the same for `l10n.ackOwner` with `hostCheckOutAt`.
      - Note: `keyLeftSafe ? l10n.ackKeyLeftSafe : null`.
      - **Fallback:** when `completed` with both times null, return `null`.
    - **Check-in tracker:** used when `(status == confirmed || status == checkedIn)` and `guestCheckInAt != null || hostCheckInAt != null`. Title `l10n.ackTitleCheckin`, with the check-in fields and `note: null`.
    - Otherwise return `null`.
- [X] T062 [US3] In `booking_details_screen.dart`, right after the status `NoticeCard`, add:
  ```dart
  if (ackStepsFor(details, l10n) case final ack?) ...[
    const SizedBox(height: Dimens.space16),
    AcknowledgementTracker(title: ack.title, steps: ack.steps, note: ack.note),
  ],
  ```
  Add widget tests to `booking_details_screen_test.dart` (backend `includeG3Fixtures: true`, `g3()`):
  - `…021` shows `primary-confirm_checkin`;
  - tapping it opens a sheet with `l10n.checkinSheetTitle`;
  - "لسه" closes it with no repository call (`backend.stay.checkIns == 0`);
  - "أيوه، استلمتها" calls it once, closes the sheet, refreshes, and shows the tracker with `l10n.ackYou` and `l10n.ackOwner`;
  - `…020` shows **no** `primary-confirm_checkin`.
- [X] T063 [P] [US3] Write `test/features/stay/goldens/stay_ack_golden_test.dart` covering:
  - the check-in sheet over `…021`;
  - booking details with the waiting-handover tracker (`…021` after `backend.stay.confirmCheckIn`);
  - the in-stay booking with the checkout tracker and the key note (`…022` after `backend.stay.ownerConfirmsCheckout(id, keyLeftSafe: true)`, with no guest checkout).

  Use the four standard variants. Generate and review the images.
- [X] T064 [US3] Add `runStayAckJourney` to `test/helpers/stay_journey.dart`:
  1. Check in on `…021`.
  2. `await backend.stay.ownerConfirmsHandover(id)`, then pump.
  3. Expect `l10n.bookingStatusCheckedIn`.
  4. Tap `primary-confirm_checkout` and confirm.
  5. `await backend.stay.ownerConfirmsCheckout(id)`, then pump.
  6. Expect `l10n.bookingStatusCompleted`.

  Call it from the host and device journey files.

**Checkpoint**: US1–US3 pass. "Stay in progress" appears only after the mock owner confirms.

---

## Phase 6: User Story 4 - Cancel with a clear preview and follow the refund (Priority: P1)

**Goal**: The guest sees the server's refund preview before confirming. A changed amount asks
again, and the refund stages reach "Received" only after the final check (AC-030 to AC-032,
AC-042).

**Independent Test**: In mock mode, open `…023` (free), `…021` (deposit lost), and `…024` (no
refund) and check that each sentence and amount matches Appendix B. Cancel `…021` after the
mock tool "تغيير شروط الإلغاء مرة" → the changed rows are highlighted and the guest must confirm
again. Then use "تقديم مرحلة الاسترداد" until the chip reads "تم رد المبلغ".

### Tests for User Story 4

- [X] T065 [P] [US4] Write `test/features/stay/presentation/cancellation_cubit_test.dart` for `CancellationCubit` (T067):
  - (a) `load()` on `…023` emits `CancelLoading`, then `CancelReady(preview, changes: PreviewChange.none)`;
  - (b) `selectReason(CancellationReason.other)` then `setNote('x' * 301)` keeps 300 characters;
  - (c) `submit()` emits `CancelSubmitting`, sends `expectedRefund == preview.refund` (assert `backend.stay.lastExpectedRefund`) and the key from `ActionAttemptStore`, then emits `CancelDone`, and the key is cleared;
  - (d) a second `submit()` while submitting does nothing;
  - (e) on `…021`: `load()` first, **then** `backend.stay.forceTermsChangeOnce('…021')`, then `submit()` → the cubit calls the preview again (`backend.stay.previews == 2`) and emits `CancelReady` with `changes.refund == true` and `error.code == ErrorCode.cancellationTermsChanged`, and the key is cleared;
  - (f) a network error keeps the key, emits `CancelReady(error: network)`, and the retry uses the same key (`backend.stay.lastCancelKey` is equal both times);
  - (g) cancelling `…020` twice gives `CancelNotAllowed` on the second attempt (the mock returns `INVALID_BOOKING_STATE` once cancelled);
  - (h) offline `load()` emits `CancelOffline`.
- [X] T066 [P] [US4] Write `test/features/stay/presentation/cancellation_screen_test.dart`:
  - (a) for `…023` / `…021` / `…024`, the `NoticeCard` shows `l10n.cancelReasonFree(...)` / `l10n.cancelReasonDepositLost(...)` / `l10n.cancelReasonNoRefund` with the Appendix B amounts and date;
  - (b) the `l10n.cancelNonRefundable` row is hidden for `…023` (zero);
  - (c) after a terms change, the refund row is `AmountRow(highlighted: true)` with `previousValue` set;
  - (d) the destructive button opens a dialog with `l10n.cancelDialogBody(<refund>)`, and "رجوع" sends nothing (`backend.stay.cancels == 0`);
  - (e) `l10n.cancelKeep` pops with no call;
  - (f) the reason chips are single-select, and `l10n.cancelReasonOther` shows a text field with `maxLength` 300;
  - (g) offline shows `l10n.stayNeedsConnection`.

### Implementation for User Story 4

- [X] T067 [US4] Create `lib/features/stay/presentation/cancellation/cancellation_cubit.dart` (makes T065 pass):
  - **States:**
    - `CancelLoading`;
    - `CancelReady({required CancellationPreview preview, CancellationPreview? previous, required PreviewChange changes, CancellationReason? reason, String note = '', ApiError? error})`;
    - `CancelSubmitting({required CancelReady from})`;
    - `CancelDone(CancellationResult result)`;
    - `CancelNotAllowed`, `CancelOffline`, `CancelNotAvailable`, `CancelFailed(ApiError)`.
  - **Constructor:** `({required this._stay, required this._attempts, required this._connectivity, required this._logger, required this._bookingId})`.
  - **`load()`:** if offline, emit `CancelOffline`. Otherwise `preview = await _stay.previewCancellation(id)`, log `'cancellation_previewed booking=$id'`, and emit `CancelReady(preview: preview, changes: PreviewChange.none)`. `notFound` → `CancelNotAvailable`; `invalidBookingState` / `actionNotAllowed` → `CancelNotAllowed`; others → `CancelFailed`.
  - **Reason and note:** `selectReason(CancellationReason? r)` and `setNote(String n)` (truncates to `CancellationReason.noteMaxLength`) both emit a copy of the ready state.
  - **`submit()`:**
    1. guard `_busy` and `state is CancelReady`;
    2. `key = await _attempts.keyFor('cancel', id)`;
    3. emit `CancelSubmitting(from: ready)`;
    4. `result = await _stay.cancelBooking(bookingId: id, expectedRefund: ready.preview.refund, reason: ready.reason, reasonNote: ready.reason == CancellationReason.other ? ready.note.trim() : null, idempotencyKey: key)`;
    5. clear the key;
    6. log `'cancellation_confirmed booking=$id'`;
    7. emit `CancelDone(result)`.

    Error handling (by `failure.error.code`):

    | Error | What to do |
    |---|---|
    | `cancellationTermsChanged` | clear the key; `fresh = await _stay.previewCancellation(id)`; log `'cancellation_terms_changed booking=$id'`; emit `CancelReady(preview: fresh, previous: ready.preview, changes: PreviewChange.between(ready.preview, fresh), reason: ready.reason, note: ready.note, error: failure.error)` |
    | `invalidBookingState` / `actionNotAllowed` | clear the key, emit `CancelNotAllowed` |
    | `network` | keep the key, emit `ready` copied with `error: failure.error` |
    | anything else | clear the key, emit `ready` copied with `error` |
- [X] T068 [US4] Create `lib/features/stay/presentation/cancellation/cancellation_texts.dart` and `cancellation_screen.dart` (layout: [contracts/ui-screens.md §7](contracts/ui-screens.md); makes T066 pass):
  - **`cancellationSentence(CancellationPreview p, AppLocalizations l10n)`** in `cancellation_texts.dart`:
    - `free` → `l10n.cancelReasonFree(fmt(p.refund))`;
    - `depositLost` → `p.freeCancellationUntil == null ? l10n.cancelReasonDepositLostNoDate(fmt(p.refund), fmt(p.nonRefundable)) : l10n.cancelReasonDepositLost(fmt(p.refund), fmt(p.nonRefundable), formatCairoDayMonthTime(p.freeCancellationUntil!))`;
    - `noRefund` → `l10n.cancelReasonNoRefund`;
    - `unknown` → `l10n.bookingMsgUnknown`.

    `fmt` is `MoneyFormatter().format`.
  - **`maxLength` for `OnAirTextField`:** in `lib/design_system/components/on_air_text_field.dart`, add optional `this.maxLength` (`int?`) and `this.maxLines = 1` (`int`) parameters, passed through to the inner `TextField` (`maxLength:` / `maxLines:`). Existing callers are unchanged.
  - **Screen:** `CancellationScreen({required String bookingId})` with `AppBar(title: Text(l10n.cancelTitle))`. When ready, a `ListView` holding:
    1. when `error?.code == ErrorCode.cancellationTermsChanged`, `InfoBanner(message: l10n.cancellationTermsChanged, tone: StatusTone.warning)`;
    2. a `Card` → `Padding(all: Dimens.space16)` holding:
       - `AmountRow(label: l10n.cancelRefund, value: fmt(preview.refund), emphasized: true, highlighted: changes.refund, previousValue: changes.refund && previous != null ? fmt(previous!.refund) : null)`;
       - when `preview.nonRefundable.amountMinor > 0`, the same pattern for `l10n.cancelNonRefundable` with `changes.nonRefundable`;
    3. `NoticeCard(icon: AppIcons.infoOutline, message: cancellationSentence(preview, l10n))`;
    4. the section title `l10n.cancelReasonTitle`;
    5. a `Wrap(spacing: Dimens.space8)` of four `ChoiceChip(label: Text(…), selected: reason == r, onSelected: (on) => cubit.selectReason(on ? r : null))`, labelled `cancelReasonChangeOfPlans`, `cancelReasonFoundOther`, `cancelReasonTravelProblem`, and `cancelReasonOther`;
    6. when `reason == other`, `OnAirTextField(hint: l10n.cancelReasonOtherHint, onChanged: cubit.setNote, maxLength: 300, maxLines: 3)`;
    7. when there is any other `error`, the error text (`apiErrorMessage`) in `errorText` colour.
  - **Bottom area:** `bottomNavigationBar: SafeArea(child: Padding(all: Dimens.space12, child: Column(mainAxisSize: min, children: [...])))`, holding:
    1. `OutlinedButton(key: ValueKey('cancel-confirm'), style: OutlinedButton.styleFrom(foregroundColor: context.colors.errorText, side: BorderSide(color: context.colors.errorText), minimumSize: const Size.fromHeight(Dimens.minTouchTarget)), onPressed: state is CancelSubmitting ? null : _confirm, child: state is CancelSubmitting ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.actionCancelBooking))`;
    2. `TextButton(onPressed: () => context.pop(false), child: Text(l10n.cancelKeep))`.

    `_confirm`: `if (await OnAirConfirmDialog.ask(context, title: l10n.cancelDialogTitle, body: l10n.cancelDialogBody(fmt(preview.refund)), confirmLabel: l10n.cancelDialogConfirm, cancelLabel: l10n.dialogBack, destructive: true)) cubit.submit();`.
  - **Listener:**
    - `CancelDone` → `context.pop(true)`;
    - `CancelNotAllowed` → `context.go(AppRoutes.bookingDetails(id))` plus `SnackBar(l10n.stayStepNotAvailable)`.
  - **Other states:** offline → `ErrorView(l10n.stayNeedsConnection)`; failed → `ErrorView` with a reference; not available → `EmptyView`.
  - **Route:** replace the `cancelBookingPattern` placeholder in `app_router.dart` with a `BlocProvider<CancellationCubit>` (+ `load()`).
- [X] T069 [US4] Add a widget test in `test/features/stay/presentation/cancellation_flow_test.dart`. Using the full router (`routerConfig` in `pumpOnAirApp`, a backend with `includeG3Fixtures: true` and `g3()`):
  1. Open `…023`.
  2. Tap `action-request_cancellation`.
  3. Tap `cancel-confirm`, then confirm the dialog.
  4. Expect details to show `l10n.bookingStatusCancelled`, `l10n.refundChipRequested`, and `l10n.bookingMsgCancelledByGuest`.
  5. Call `await backend.stay.advanceRefund(id)` twice (pumping each time). The chip shows `l10n.refundChipInProgress`, **not** done.
  6. After the third call, it shows `l10n.refundChipDone` (AC-042).
- [X] T070 [P] [US4] Write `test/features/stay/goldens/cancellation_golden_test.dart` covering `cancellation_free` (`…023`), `cancellation_deposit_lost` (`…021`), `cancellation_no_refund` (`…024`), and `cancellation_changed` (`…021` after `forceTermsChangeOnce` + submit) in the four standard variants, plus `light_RTL` at widths 320 and 800 for `deposit_lost`. Generate and review the images.
- [X] T071 [US4] Add `runCancellationJourney` to `test/helpers/stay_journey.dart` (the Independent Test above), and call it from the host and device journey files.

**Checkpoint**: US1–US4 pass. The refund shown before confirming always equals the refund
applied, or the guest is asked again.

---

## Phase 7: User Story 5 - Answer a damage claim (Priority: P2)

**Goal**: The guest sees the claim with its evidence (private, memory-only) and the protection
notice, and either agrees or disputes with a written reason. The claim stays visible in details
(AC-036).

**Independent Test**: In mock mode, open `…025`. The "مطالبات الضرر" section shows two cards.
Open the open claim: the protection notice comes first and two thumbnails are shown (as
placeholders, because there is no network). Dispute with 5 characters → error; with 20
characters → "رقم الحالة: SC-1001". The resolved claim shows its outcome and has no buttons.

### Tests for User Story 5

- [X] T072 [P] [US5] Write `test/features/stay/presentation/evidence_url_cache_test.dart` for `EvidenceUrlCache` (T074), using a fake `StayRepository` that counts `fileUrl` calls and returns `expiresAt = now + 5 min`:
  - (a) the first `urlFor(id)` makes one call, and a second call reuses it;
  - (b) with a fake clock moved to `expiresAt - 20 s`, `urlFor` refetches;
  - (c) `invalidate(id)` forces a refetch;
  - (d) `clear()` empties the cache;
  - (e) read the source file `lib/features/stay/presentation/claims/evidence_url_cache.dart` as text and assert it does not contain `JsonFileCache`, `BookingsCache`, `CacheManager`, or `path_provider`.
- [X] T073 [P] [US5] Write `test/features/stay/presentation/damage_claim_cubit_test.dart` (backend `includeG3Fixtures: true`, `g3()`):
  - (a) `load()` for booking `…025`, claim `e0000000-0000-4000-8000-000000000001` emits `ClaimReady` with 2 evidence refs and `canRespond == true`;
  - (b) the same claim loaded with booking `…021` emits `ClaimNotAvailable`;
  - (c) `agree()` emits `ClaimSubmitting`, then `ClaimReady` with `claim.status == DamageClaimStatus.guestAccepted`;
  - (d) `dispute('short')` emits `ClaimReady(noteError: true)` and makes no call (`backend.stay.claimAnswers == 0`);
  - (e) `dispute('a valid long reason text')` emits `ClaimReady` with `claim.supportCaseNumber == 'SC-1001'`;
  - (f) answering an already-answered claim (`e…02`) gives `CLAIM_ALREADY_ANSWERED`, which reloads the claim;
  - (g) a double `agree()` makes one call.

  Also write `test/features/stay/presentation/damage_claim_screen_test.dart`:
  - (a) the first widget in the list is the `InfoBanner` with `l10n.claimProtection`;
  - (b) the chip text is `l10n.claimStatusOpen`;
  - (c) `l10n.claimDispute` opens the form, and submitting 5 characters shows `l10n.claimDisputeTooShort`;
  - (d) `l10n.claimAgree` opens a dialog with `l10n.claimAgreeDialogBody(<amount>)`;
  - (e) claim `e…02` shows `l10n.claimOutcomeNoCharge` and no `l10n.claimAgree` button;
  - (f) there is no attachment button (`find.byIcon(AppIcons.photoStack)` finds nothing);
  - (g) tapping the first thumbnail opens the viewer, whose title is `l10n.claimEvidencePhoto('1', '2')`;
  - (h) the resolver `/damage-claims/e…01` replaces itself with `/bookings/…025/damage-claim/e…01`, and an unknown UUID shows `NotAvailableScreen`.

### Implementation for User Story 5

- [X] T074 [US5] Create `lib/features/stay/presentation/claims/evidence_url_cache.dart` (makes T072 pass):
  ```dart
  final class EvidenceUrlCache {
    EvidenceUrlCache(this._stay, {DateTime Function()? now}) : _now = now ?? (() => DateTime.now().toUtc());
    final StayRepository _stay;
    final DateTime Function() _now;
    final Map<String, FileUrl> _urls = {};
    Future<Uri> urlFor(String attachmentId); // reuse when expiresAt.difference(_now()) >= 30 s, else fetch via _stay.fileUrl and store
    void invalidate(String attachmentId);    // _urls.remove
    void clear();                            // _urls.clear
  }
  ```
- [X] T075 [US5] Create `lib/features/stay/presentation/claims/damage_claim_cubit.dart` (makes the T073 cubit tests pass):
  - **States:** `ClaimLoading`, `ClaimReady({required DamageClaim claim, required bool canRespond, bool disputeOpen = false, bool noteError = false, ApiError? error})`, `ClaimSubmitting({required ClaimReady from})`, `ClaimNotAvailable`, `ClaimOffline`, `ClaimFailed(ApiError)`.
  - **Constructor:** `({required this._stay, required this._bookings, required this._attempts, required this._registry, required this._connectivity, required this._logger, required this._bookingId, required this._claimId})`.
  - **`load()`:**
    1. If offline, emit `ClaimOffline`.
    2. `claim = await _stay.getDamageClaim(_claimId)`. If `claim.bookingId != _bookingId`, emit `ClaimNotAvailable` and return.
    3. `details = await _bookings.getBooking(_bookingId)`.
    4. `canRespond = claim.status == DamageClaimStatus.open && _registry.visible(details.availableActions).contains(BookingActionCode.respondDamageClaim)`.
    5. Emit `ClaimReady`.

    `notFound` → `ClaimNotAvailable`; others → `ClaimFailed`.
  - **`openDispute()`:** emits a copy with `disputeOpen: true`.
  - **`agree()` / `dispute(String note)`:**
    1. guard `_busy` and `ClaimReady`;
    2. for a dispute, `if (!ClaimLimits.validDisputeNote(note)) { emit(ready.copy(noteError: true)); return; }`;
    3. `key = keyFor('claim_answer', _claimId)`;
    4. emit `ClaimSubmitting`;
    5. `await _stay.respondDamageClaim(claimId:, decision:, note: decision == dispute ? note.trim() : null, idempotencyKey: key)`;
    6. clear the key;
    7. log `'claim_answered claim=$_claimId decision=${decision.wire}'`;
    8. `await load()`.

    Error handling:

    | Error | What to do |
    |---|---|
    | `claimAlreadyAnswered` | clear the key, `await load()` |
    | `network` | keep the key, emit the ready copy with `error` |
    | anything else | clear the key, emit the ready copy with `error` |
- [X] T076 [US5] Create `lib/features/stay/presentation/claims/claim_texts.dart` and `damage_claim_screen.dart` (layout: [contracts/ui-screens.md §8](contracts/ui-screens.md)):
  - **`claim_texts.dart`** has three functions:
    - `String claimStatusLabel(DamageClaimStatus s, AppLocalizations l10n)` → the `claimStatus*` keys;
    - `StatusTone claimStatusTone(DamageClaimStatus s)`, following data-model §7: `open` → `warning`, `guestAccepted` / `resolved` → `completed`, `guestDisputed` / `inMediation` → `pending`, `withdrawn` / `unknown` → `cancelled`;
    - `String claimOutcomeText(ClaimResolution r, AppLocalizations l10n)`: `guestPays` → `claimOutcomeGuestPays(fmt(r.amount!))`, `partial` → `claimOutcomePartial(fmt(r.amount!))`, `noCharge` → `claimOutcomeNoCharge`, `withdrawn` → `claimOutcomeWithdrawn`, `unknown` → `bookingMsgUnknown`.
  - **Screen:** `DamageClaimScreen({required String bookingId, required String claimId})`, a `StatefulWidget` that creates `late final _urls = EvidenceUrlCache(context.read<StayRepository>())` and calls `_urls.clear()` in `dispose`. `AppBar(title: Text(l10n.claimTitle))`. When `ClaimReady` (or submitting), a `ListView` holding, in order and separated by `Dimens.space16`:
    1. `InfoBanner(message: l10n.claimProtection, tone: StatusTone.cancelled)`;
    2. a `Card` → `Padding(all: Dimens.space16)` → `Column([StatusChip(label: claimStatusLabel(...), tone: claimStatusTone(...)), SizedBox(height: Dimens.space8), Text(claim.description, style: bodyMedium), SizedBox(height: Dimens.space8), AmountRow(label: l10n.claimAmount, value: fmt(claim.amount), emphasized: true)])`;
    3. when `claim.evidence.isNotEmpty`:
       - the title `l10n.claimEvidence`;
       - `SizedBox(height: 96, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: n, separatorBuilder: → SizedBox(width: Dimens.space8), itemBuilder: (_, i) => _Thumb(...)))`;
       - `_Thumb` is a `StatefulWidget`. It holds a `Future<Uri>` from `_urls.urlFor(ref.attachmentId)` and shows `Semantics(button: true, label: l10n.claimEvidencePhoto('${i + 1}', '$n'), child: InkWell(onTap: open viewer, child: ClipRRect(borderRadius: BorderRadius.circular(Dimens.radiusField), child: FutureBuilder(...))))`;
       - the `FutureBuilder` shows the image: `Image.network(uri.toString(), width: 96, height: 96, fit: BoxFit.cover, cacheWidth: (96 * MediaQuery.devicePixelRatioOf(context)).round(), errorBuilder: (_, _, _) => _ThumbError(onRetry: () { _urls.invalidate(id); setState(() { _future = _urls.urlFor(id); }); }))`;
       - `_ThumbError` is a 96×96 `ColoredBox(color: context.colors['detailCard'])` with a centered `Icon(AppIcons.imageNotSupportedOutlined)` and a `Tooltip(message: l10n.claimPhotoFailed)`;
       - while loading, show `ColoredBox(color: context.colors['detailCard'])`;
    4. when `claim.response != null`, `NoticeCard(icon: AppIcons.checkCircleOutline, message: '${l10n.claimYourAnswer}: ${claimStatusLabel(claim.status, l10n)}')`, and when `claim.supportCaseNumber != null`, `SelectableText(l10n.claimCaseNumber(claim.supportCaseNumber!))`;
    5. when `claim.resolution != null`, `NoticeCard(icon: AppIcons.infoOutline, message: claimOutcomeText(...))`;
    6. when `disputeOpen`, `OnAirTextField(controller: _note, label: l10n.claimDisputeReason, hint: l10n.claimDisputeReasonHint, errorText: noteError ? l10n.claimDisputeTooShort : null, maxLength: ClaimLimits.disputeMax, maxLines: 5)`.
  - **Bottom bar:** only when `canRespond`:
    - if `!disputeOpen`: `BottomActionBar(leading: OutlinedButton(key: ValueKey('claim-dispute'), style: OutlinedButton.styleFrom(foregroundColor: context.colors.errorText, side: BorderSide(color: context.colors.errorText), minimumSize: const Size.fromHeight(Dimens.minTouchTarget)), onPressed: cubit.openDispute, child: Text(l10n.claimDispute)), action: OnAirPrimaryButton(key: ValueKey('claim-agree'), label: l10n.claimAgree, isLoading: submitting, onPressed: _agree))`;
    - if `disputeOpen`: `SafeArea(Padding(all: Dimens.space12, child: OutlinedButton(key: ValueKey('claim-send-dispute'), <same errorText style>, onPressed: submitting ? null : () => cubit.dispute(_note.text), child: Text(l10n.claimDisputeSend))))`.

    `_agree`: `if (await OnAirConfirmDialog.ask(context, title: l10n.claimAgreeDialogTitle, body: l10n.claimAgreeDialogBody(fmt(amount)), confirmLabel: l10n.dialogConfirm, cancelLabel: l10n.dialogBack)) cubit.agree();`.
  - **Other states:** offline → `ErrorView(l10n.stayNeedsConnection)`; not available → `EmptyView(l10n.notAvailable)`; failed → `ErrorView` with a reference.
- [X] T077 [US5] Create `lib/features/stay/presentation/claims/evidence_viewer.dart`:
  - **Widget:** `EvidenceViewer({required List<EvidenceRef> evidence, required int initialIndex, required EvidenceUrlCache cache})`.
  - **How to open:** from `_Thumb`, `Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => EvidenceViewer(...)))`.
  - **Layout:** a `Scaffold` whose `AppBar` has `title: Text(l10n.claimEvidencePhoto('${page + 1}', '$n'))` and `leading: IconButton(icon: const Icon(AppIcons.close), tooltip: MaterialLocalizations.of(context).closeButtonTooltip, onPressed: () => Navigator.pop(context))`.
  - **Body:** `PageView.builder(controller: PageController(initialPage: initialIndex), onPageChanged: setState page, itemBuilder: (_, i) => FutureBuilder<Uri>(future: cache.urlFor(evidence[i].attachmentId), builder: → InteractiveViewer(child: Center(child: Image.network(uri.toString(), fit: BoxFit.contain, errorBuilder: → Icon(AppIcons.imageNotSupportedOutlined))))))`.
  - **Rule:** no download or share action.
- [X] T078 [US5] Routes:
  - (a) In `app_router.dart`, replace the `damageClaimPattern` builder (`NotAvailableScreen`) with a `BlocProvider<DamageClaimCubit>` (+ `load()`) around `DamageClaimScreen(bookingId: id, claimId: state.pathParameters['claimId']!)`.
  - (b) Create `lib/features/stay/presentation/claims/damage_claim_resolver_screen.dart`, with `DamageClaimResolverScreen({required String claimId})`:
    - **Data:** a `StatefulWidget` that, in `initState`, calls `unawaited(_resolve())`. `_resolve` does `final claim = await context.read<StayRepository>().getDamageClaim(widget.claimId)` and then, if mounted, `context.replace(AppRoutes.damageClaim(claim.bookingId, claim.id))`.
    - **On `AppFailure`:** sets `_missing = true`.
    - **`build`:** `_missing ? const NotAvailableScreen() : Scaffold(body: Center(child: CircularProgressIndicator()))`.
  - (c) Replace the `damageClaimResolverPattern` placeholder with `DamageClaimResolverScreen(claimId: state.pathParameters['claimId']!)`.
- [X] T079 [US5] In `booking_details_screen.dart`, right after the refund section, add the claims section when `details.damageClaims.isNotEmpty`:
  ```dart
  KeyedSubtree(key: _claimsKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: Dimens.space16),
    Text(l10n.claimsSectionTitle, style: titleMedium textPrimary),
    const SizedBox(height: Dimens.space8),
    for (final claim in details.damageClaims) Card(child: InkWell(
      onTap: () => context.push(AppRoutes.damageClaim(details.id, claim.id)),
      child: Semantics(button: true, label: '${l10n.claimTitle} ${fmt(claim.amount)} ${claimStatusLabel(claim.status, l10n)}',
        child: Padding(padding: const EdgeInsetsDirectional.all(Dimens.space12), child: Row(children: [
          Expanded(child: Text(fmt(claim.amount), style: titleSmall textPrimary)),
          StatusChip(label: claimStatusLabel(claim.status, l10n), tone: claimStatusTone(claim.status)),
          const SizedBox(width: Dimens.space8),
          Icon(<chevron by direction, as in T054>, size: 16),
        ]))))),
  ]))
  ```
  Add a widget test with `…025`: two cards are shown, and tapping the first opens the claim screen.
- [X] T080 [P] [US5] Write `test/features/stay/goldens/claim_golden_test.dart` covering `damage_claim_open` (thumbnails in the error-placeholder state), `damage_claim_dispute_form` (form open with the short-note error), `damage_claim_resolved` (`e…02`), and `booking_details_claims` (`…025`) in the four standard variants. Generate and review the images.
- [X] T081 [US5] Add `runClaimJourney` to `test/helpers/stay_journey.dart` (the Independent Test above), and call it from the host and device journey files.

**Checkpoint**: US1–US5 pass. Searching `lib/features/stay/presentation/claims/` for
`JsonFileCache`, `BookingsCache`, `CacheManager`, and `CachedNetworkImage` finds nothing.

---

## Phase 8: User Story 6 - Answer a replacement offer (Priority: P2)

**Goal**: A rejected or expired booking with an OnAir offer shows an offer card with the
difference worded in plain language. The guest accepts or declines with a confirmation, and
nothing changes without their answer.

**Independent Test**: In mock mode, open `…026` from a "عندك عرض بديل" notification. The page
scrolls to the offer card, which says "هتدفع … زيادة"; accepting shows "وافقت على العرض". Open
`…027`: the expired offer shows "العرض انتهى" with no buttons.

### Tests for User Story 6

- [ ] T082 [P] [US6] Write `test/features/stay/presentation/replacement_offer_cubit_test.dart` for `ReplacementOfferCubit` (T084):
  - (a) `accept()` on offer `f0000000-0000-4000-8000-000000000001` emits `OfferSubmitting(true)`, then `OfferAnswered(accepted: true)`, using the key `offer_answer`;
  - (b) `decline()` emits `OfferAnswered(accepted: false)`;
  - (c) the expired offer `f…02` gives `OFFER_NOT_AVAILABLE` → `OfferGone`;
  - (d) a double tap makes one call (`backend.stay.offerAnswers == 1`);
  - (e) a network error keeps the key and emits `OfferIdle(error: network)`.
- [ ] T083 [P] [US6] Write `test/features/stay/presentation/offer_card_test.dart`:
  - (a) a pending `guestPays` offer of `Money(50000)` shows `l10n.offerPayMore(fmt(Money(50000)))`; build an offer with `-50000` in the test and expect `l10n.offerRefundDiff(...)`; `0` gives `l10n.offerNoDiff`;
  - (b) `expiresAt` shows `l10n.offerExpires(formatCairoDayMonthTime(expiresAt))`;
  - (c) `l10n.offerAccept` opens a dialog with `l10n.offerAcceptDialogTitle`, and its body is the same difference sentence;
  - (d) the statuses `accepted`, `declined`, `expired`, and `withdrawn` show their status chip and no `l10n.offerAccept` button;
  - (e) opening `/bookings/<…026>?focus=offer` through the router scrolls the card into view: the card's `Rect` from `tester.getRect` overlaps the screen.

### Implementation for User Story 6

- [ ] T084 [US6] Create `lib/features/stay/presentation/offer/replacement_offer_cubit.dart` (makes T082 pass):
  - **States:** `OfferIdle({ApiError? error})`, `OfferSubmitting(bool accept)`, `OfferAnswered({required bool accepted})`, `OfferGone`.
  - **Constructor:** `({required this._stay, required this._attempts, required this._logger, required this._offerId})`.
  - **Methods:** `accept()` and `decline()` call `_answer(bool accept)`:
    1. guard `_busy`;
    2. `key = keyFor('offer_answer', _offerId)`;
    3. emit `OfferSubmitting(accept)`;
    4. `await _stay.respondReplacementOffer(offerId:, accept:, idempotencyKey: key)`;
    5. clear the key;
    6. log `'offer_answered offer=$_offerId accept=$accept'`;
    7. emit `OfferAnswered(accepted: accept)`.

    Errors: `offerNotAvailable` → clear the key, emit `OfferGone`; `network` → keep the key, emit `OfferIdle(error:)`; anything else → clear the key, emit `OfferIdle(error:)`.
- [ ] T085 [US6] Create `lib/features/stay/presentation/offer/offer_card.dart` (layout: [contracts/ui-screens.md §9](contracts/ui-screens.md)):
  - **Widget:** `OfferCard({required ReplacementOffer offer, required VoidCallback onAnswered})`. It wraps itself in `BlocProvider(create: (c) => ReplacementOfferCubit(stay: c.read(), attempts: c.read(), logger: c.read(), offerId: offer.id))`.
  - **Helper:** `String offerDifferenceText(ReplacementOffer o, AppLocalizations l10n)` in the same file: `guestPays` → `offerPayMore(fmt(o.difference))`, `guestRefunded` → `offerRefundDiff(fmt(o.difference))`, `none` → `offerNoDiff`.
  - **Content:** a `Card` → `Padding(all: Dimens.space16)` → `Column(crossAxisAlignment: start)` holding:
    1. `Text(l10n.offerTitle)` in `titleMedium`;
    2. `Dimens.space12`;
    3. a property `Row`: a 64×64 `OnAirNetworkImage(variants: offer.coverImage?.variants ?? const [])` in a `ClipRRect(radiusChip)`, `Dimens.space12`, and an `Expanded` `Column` of the title (`titleSmall`) and the area (`bodySmall` / `textSecondary`);
    4. `Dimens.space12`;
    5. `AmountRow(label: l10n.bookingDatesTitle, value: '${DateOnlyFormatter.dayMonth(offer.stay.checkIn)} – ${DateOnlyFormatter.dayMonth(offer.stay.checkOut)}')`;
    6. `Dimens.space8`;
    7. `InfoBanner(message: offerDifferenceText(offer, l10n), tone: switch (offer.direction) { guestRefunded => StatusTone.info, guestPays => StatusTone.warning, none => StatusTone.cancelled })`;
    8. when `offer.status == OfferStatus.pending`:
       - when `expiresAt != null`, `Text(l10n.offerExpires(formatCairoDayMonthTime(expiresAt)))` in `bodySmall`;
       - `Dimens.space12`;
       - `OnAirPrimaryButton(key: ValueKey('offer-accept'), label: l10n.offerAccept, isLoading: state is OfferSubmitting && state.accept, onPressed: busy ? null : _accept)`;
       - `Dimens.space8`;
       - `OutlinedButton(key: ValueKey('offer-decline'), style: minimumSize Size.fromHeight(Dimens.minTouchTarget), onPressed: busy ? null : _decline, child: Text(l10n.offerDecline))`;
    9. otherwise, `StatusChip(label: switch status { accepted => offerStatusAccepted, declined => offerStatusDeclined, _ => offerStatusExpired }, tone: accepted ? StatusTone.completed : StatusTone.cancelled)`.

    `_accept` asks `OnAirConfirmDialog.ask(title: l10n.offerAcceptDialogTitle, body: offerDifferenceText(...), confirmLabel: l10n.dialogConfirm, cancelLabel: l10n.dialogBack)`. `_decline` asks `(title: l10n.offerDeclineDialogTitle, body: l10n.offerDeclineDialogBody, …)`.
  - **Listener:** `OfferAnswered` → `onAnswered()`. `OfferGone` → `SnackBar(l10n.offerNotAvailable)` and `onAnswered()`.
- [ ] T086 [US6] In `booking_details_screen.dart`, right after the tracker block from T062 (if US3 is not done yet, right after the status `NoticeCard`), add:
  ```dart
  if (details.replacementOffer case final offer?) ...[
    const SizedBox(height: Dimens.space16),
    KeyedSubtree(key: _offerKey, child: OfferCard(offer: offer, onAnswered: () => unawaited(context.read<BookingDetailsCubit>().refresh()))),
  ],
  ```
  Run T083 (e).
- [ ] T087 [P] [US6] Write `test/features/stay/goldens/offer_golden_test.dart` covering details with a pending pay-more offer (`…026`), an expired offer (`…027`), and the accept dialog, in the four standard variants. Generate and review the images.
- [ ] T088 [US6] Add `runOfferJourney` to `test/helpers/stay_journey.dart`:
  1. `await backend.server.notifyGuest('booking.replacement_offered', '…026')`.
  2. Open `/notifications` and tap the new row.
  3. Expect `offer-accept` to be visible.
  4. Tap it and confirm the dialog.
  5. Expect `l10n.offerStatusAccepted`.

  Call it from the host and device journey files.

**Checkpoint**: All six stories pass on the mock.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [ ] T089 [P] Create `lib/features/stay/presentation/mock_stay_tools_sheet.dart` (mock mode only):
  - **Entry point:** in `booking_details_screen.dart`, when `context.read<MockStayServer?>() != null`, add an `IconButton(icon: const Icon(AppIcons.tuneOutlined), tooltip: l10n.mockToolsTitle, onPressed: () => showMockStayTools(context, details.id))` to `AppBar.actions`.
  - **`showMockStayTools`:** opens `showModalBottomSheet` with the same shape as `OnAirConfirmSheet.show`. It contains a `Column` of `ListTile`s, one per tool in Appendix D §8, labelled with the `mock*` keys in Appendix A. Each tile calls the matching `MockStayServer` method with the booking ID, closes the sheet, and then calls `context.read<BookingDetailsCubit>().refresh()`.
  - **Test:** with a `null` provider (remote mode), the icon is not shown.
- [ ] T090 [P] Create `integration_test/stay_staging_test.dart`. Copy `integration_test/booking_outcomes_staging_test.dart`, with every test `skip: !const bool.fromEnvironment('STAY_STAGING')`. Write one `testWidgets` per AC: AC-025, AC-026, AC-027, AC-030, AC-031, AC-032, AC-036, AC-037, and AC-042. Each body is a `// TODO(staging-seed): <seed row from contracts/supabase-stay.md §7>` comment followed by `expect(true, isTrue);`. The file must compile.
- [ ] T091 [P] English and LTR pass: in every screen golden file from T045, T055, T063, T070, T080, and T087, add one more variant `light_LTR_en` (locale `en`, `TextDirection.ltr`, scale 1.0). Generate the images, then check that chevrons mirror, amounts sit at the end, and no Arabic text appears.
- [ ] T092 Accessibility sweep. Create `test/features/stay/presentation/stay_semantics_test.dart` with one `testWidgets` per new screen (remaining, cash phone, cash code, receipt, cancellation, claim, offer card, check-in sheet). Using `final handle = tester.ensureSemantics();`, assert that:
  - every `IconButton` has a non-empty tooltip;
  - every `InkWell` / button is at least 48×48 (`tester.getSize(...)`);
  - the sheet and dialog titles are in a `Semantics(header: true)`.

  Use `expect(tester, meetsGuideline(androidTapTargetGuideline))` and `meetsGuideline(labeledTapTargetGuideline)`. Fix any failure in the screen, not in the test.
- [ ] T093 Create `test/features/stay/logging_rules_test.dart`:
  - it lists every `.dart` file under `lib/features/stay/`, plus `payment_attempt_cubit.dart` and `unfinished_payment_cubit.dart`;
  - it fails if any line containing `logger.` or `_logger.` also contains one of these words (case-insensitive): `phone`, `e164`, `email`, `code`, `note`, `url`, `name`, `receipt`.

  Fix any hit by logging IDs only (research R14).
- [ ] T094 Run `tool/check_hardcoded_styles.sh`, `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`, and `flutter test --tags golden`. Fix every failure.
- [ ] T095 Walk through the 16 validation scenarios in [quickstart.md](quickstart.md) on an Android emulator in mock mode, in Arabic and English, light and dark, and at the largest font size. Write the result in `specs/004-guest-stay-cancellation/checklists/manual-validation.md` as a table with columns Scenario | AR light | AR dark | EN | 1.3× | Notes.
- [ ] T096 Update `docs/OnAir Guest App Plan.md` §17 G3:
  - tick the six items;
  - under them, add a status note in the same style as the G1 and G2 notes: "**حالة G3 (<date>):** القصص الست مكتملة كود وتشتغل في وضع mock … وضع remote مستني الفروقات S1–S8 في `contracts/supabase-stay.md` وبيانات الـ Seed (§7)."

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: needs Phase 1, and blocks every story.
- **US1 (Phase 3)**: needs Phase 2. It is the MVP.
- **US2 (Phase 4)**: needs Phase 2. The US1 remaining screen links to it, but it can be built and tested on its own from `…028` or `/bookings/<id>/cash-confirm`.
- **US3 (Phase 5)**: needs Phase 2.
- **US4 (Phase 6)**: needs Phase 2. T069 expects the T061 messages, so do T061 first or accept that T069 waits for it.
- **US5 (Phase 7)**: needs Phase 2 and the T068 `maxLength` / `maxLines` parameters of `OnAirTextField`. If US4 is not done, do that bullet of T068 first.
- **US6 (Phase 8)**: needs Phase 2.
- **Polish (Phase 9)**: after the stories you ship.

### Within each story

- Tests first; they must fail before implementation.
- Order: cubit → screen → route wiring → details-screen section → goldens → journey.

### Same-file warnings (do not run these in parallel)

- `lib/features/bookings/presentation/booking_details_screen.dart`: T030, T044, T054, T062, T079, T086, T089.
- `lib/app/router/app_router.dart`: T023, T030, T043, T053, T068, T078.
- `lib/features/bookings/data/mock_booking_server.dart`: T014, T017, T038.
- `lib/design_system/components/on_air_text_field.dart`: T068 only.
- `lib/design_system/components/on_air_confirm_sheet.dart`: T026, T060.
- `test/helpers/stay_journey.dart`, `test/features/journey/stay_journey_test.dart`, `integration_test/stay_journey_mock_test.dart`: T046, T056, T064, T071, T081, T088 (append only).
- `lib/l10n/*.arb`: T003 only. If a key is missing, add it to Appendix A first, then to both files.

---

## Parallel Example: Phase 2

```text
Together (different files): T005, T006, T007, T008, T009, T010
Then together: T016, T018, T021, T022, T026, T027, T028
Then in order: T011 → T012 → T013 → T014 → T015 → T017 → T019 → T020 → T023 → T024 → T025 → T029 → T030 → T031
```

## Parallel Example: User Story 1

```text
Together: T032, T033, T034, T035, T036
Then: T037 → T038 → T039 → T040 → T041 → T042 → T043 → T044
Then together: T045, T046
```

## Parallel Example: Two implementers after Phase 2

```text
Implementer A: US1 (T032–T046) then US2 (T047–T056)
Implementer B: US3 (T057–T064) then US4 (T065–T071)
Coordinate edits to booking_details_screen.dart and app_router.dart (see Same-file warnings).
```

---

## Implementation Strategy

### MVP first (User Story 1)

1. Phase 1 → Phase 2 (all checkpoints green, existing goldens unchanged).
2. Phase 3 (US1). Stop and validate with quickstart scenarios 1–3.
3. Demo: a deposit-only booking can be fully paid in the app.

### Incremental delivery

1. US1 → US2: the remaining amount can be paid online or in cash.
2. US3: stays can start and end.
3. US4: guests can cancel with a clear preview.
4. US5 → US6: claims and offers.
5. Polish, then merge `feature/004-guest-stay-cancellation` into `develop` with `git merge --no-ff`.

---

## Notes

- Never edit generated files in `lib/core/api/generated/` or `lib/l10n/generated/` by hand.
- Do not add packages. Everything needed is already in `pubspec.yaml` (research R12).
- Tests use the fixed clock `DateTime.utc(2026, 11, 1, 10)` from `FakeBookingBackend`.
- Commit after each task or small group, with a message naming the task IDs, for example
  `T037-T040: remaining payment attempt`.

---

## Appendix A — Localization keys

Add each key to `lib/l10n/app_ar.arb` (Arabic column) and `lib/l10n/app_en.arb` (English
column). For keys with `{placeholders}`, add the `"@key"` metadata block to `app_ar.arb` with
every placeholder typed `String`. Tone: plain Egyptian Arabic, as in the existing booking keys.

### Errors and general

| Key | Arabic | English |
|---|---|---|
| `stayCollectorNotAuthorized` *(existing — new value)* | الشخص ده مش مفوّض يستلم فلوس للشقة دي. متسلّمش كاش وكلّم OnAir. | This person isn't authorized to collect payments for this apartment. Don't hand over cash; contact OnAir. |
| `stayCashNotAllowed` | الدفع الكاش مش متاح للشقة دي. | Cash payment isn't available for this apartment. |
| `stayCashAmountChanged` | المبلغ المتبقي اتغير. راجع المبلغ الجديد. | The remaining amount changed. Check the new amount. |
| `stayRemainingNotPaid` | لازم تسدد المبلغ المتبقي قبل استلام الشقة. | Pay the remaining amount before receiving the apartment. |
| `cancellationTermsChanged` | مبلغ الاسترداد اتغير. راجع التفاصيل الجديدة. | The refund amount changed. Review the new details. |
| `claimAlreadyAnswered` | المطالبة دي اتردّ عليها قبل كده. | This claim was already answered. |
| `offerNotAvailable` | العرض ده مبقاش متاح. | This offer is no longer available. |
| `stayNeedsConnection` | الخطوة دي محتاجة اتصال بالإنترنت. | This step needs an internet connection. |
| `stayStepNotAvailable` | الخطوة دي مش متاحة دلوقتي. | This step isn't available right now. |
| `stayActionDone` | تمام، اتسجّل. | Done, it's saved. |
| `dialogConfirm` | تأكيد | Confirm |
| `dialogBack` | رجوع | Back |

If any key above already exists in `app_ar.arb` (check with search first), keep it and skip it.

### Actions and the card line

| Key | Arabic | English |
|---|---|---|
| `actionPayRemaining` | ادفع المبلغ المتبقي | Pay the remaining amount |
| `actionConfirmCash` | تأكيد دفع كاش | Confirm a cash payment |
| `actionCancelBooking` | إلغاء الحجز | Cancel booking |
| `actionConfirmCheckin` | استلمت الشقة | I received the apartment |
| `actionConfirmCheckout` | غادرت الشقة | I left the apartment |
| `actionRespondClaim` | الرد على المطالبة | Respond to the claim |
| `bookingNeedsAction` | مطلوب منك: {action} | Needs your action: {action} |

### Status messages (additions to Guest Plan §7.2)

| Key | Arabic | English |
|---|---|---|
| `bookingMsgWaitingHandover` | أكّدت استلامك. مستنيين المالك يأكّد تسليم الشقة. | You confirmed. Waiting for the owner to confirm the handover. |
| `bookingMsgHostHandedOver` | المالك أكّد تسليم الشقة. أكّد إنك استلمتها. | The owner confirmed the handover. Confirm you received the apartment. |
| `bookingMsgWaitingCheckout` | أكّدت مغادرتك. مستنيين المالك يأكّد استلام الشقة. | You confirmed leaving. Waiting for the owner to confirm receiving the apartment. |
| `bookingMsgCancelledByGuest` | لغيت الحجز. تفاصيل الاسترداد تحت. | You cancelled this booking. Refund details are below. |
| `bookingMsgCancelledByPlatform` | OnAir لغت الحجز. تفاصيل الاسترداد تحت. | OnAir cancelled this booking. Refund details are below. |
| `bookingMsgReopened` | حجزك اتفتح تاني. كمّل سداد المتبقي قبل الاستلام. | Your booking was reopened. Pay the remaining amount before check-in. |

### Stay tracker and sheets

| Key | Arabic | English |
|---|---|---|
| `ackTitleCheckin` | تسليم الشقة | Apartment handover |
| `ackTitleCheckout` | مغادرة الشقة | Leaving the apartment |
| `ackYou` | أنت | You |
| `ackOwner` | المالك | Owner |
| `ackConfirmedAt` | أكّد {time} | Confirmed {time} |
| `ackWaiting` | مستني التأكيد | Waiting |
| `ackKeyLeftSafe` | المفتاح اتساب في المكان المتفق عليه | Key left in the agreed place |
| `checkinSheetTitle` | استلمت الشقة فعلًا؟ | Did you actually receive the apartment? |
| `checkinSheetBody` | أكّد بس لو استلمت الشقة والمفاتيح. | Confirm only if you received the apartment and the keys. |
| `checkinSheetConfirm` | أيوه، استلمتها | Yes, I received it |
| `checkoutSheetTitle` | غادرت الشقة؟ | Did you leave the apartment? |
| `checkoutSheetBody` | أكّد بعد ما تسيب الشقة وتسلّم المفاتيح. | Confirm after you leave the apartment and hand over the keys. |
| `checkoutSheetConfirm` | أيوه، غادرت | Yes, I left |
| `sheetNotYet` | لسه | Not yet |
| `checkinProblem` | عندي مشكلة في الاستلام | I have a problem with the handover |

### Remaining payment

| Key | Arabic | English |
|---|---|---|
| `remainingTitle` | سداد المتبقي | Pay the remaining amount |
| `remainingNote` | لازم تسدد المتبقي قبل ما تستلم الشقة. | The remaining amount must be paid before you receive the apartment. |
| `remainingDueLabel` | آخر ميعاد للسداد | Due by |
| `remainingChooseMethod` | هتدفع إزاي؟ | How will you pay? |
| `remainingOptionOnline` | ادفع أونلاين | Pay online |
| `remainingOptionCash` | دفعت أو هدفع كاش | I paid / will pay in cash |
| `remainingPayButton` | ادفع {amount} | Pay {amount} |
| `remainingCashButton` | كمّل تأكيد الكاش | Continue to cash confirmation |
| `remainingPaidTitle` | تم سداد المتبقي | Remaining amount paid |
| `remainingPaidBody` | حجزك مدفوع بالكامل دلوقتي. | Your booking is now fully paid. |
| `remainingFailedBody` | الدفع ما كملش ومفيش أي مبلغ اتخصم. تقدر تحاول تاني. | The payment wasn't completed and nothing was charged. You can try again. |

### Cash confirmation and receipt

| Key | Arabic | English |
|---|---|---|
| `cashTitle` | تأكيد دفع كاش | Confirm a cash payment |
| `cashAmountLabel` | المبلغ | Amount |
| `cashAmountLocked` | المبلغ ثابت ومش ممكن يتغير | Amount, not editable |
| `cashPhoneLabel` | رقم موبايل اللي استلم الفلوس | Mobile number of the person who received the cash |
| `cashPhoneHint` | 01xxxxxxxxx | 01xxxxxxxxx |
| `cashPhoneInvalid` | اكتب رقم موبايل مصري صحيح. | Enter a valid Egyptian mobile number. |
| `cashWarning` | متسلّمش فلوس غير لشخص مفوّض من OnAir. | Only hand cash to a person authorized by OnAir. |
| `cashSendCode` | ابعت الكود على بريدي | Send the code to my email |
| `cashCodeSent` | بعتنا كود على {email} | We sent a code to {email} |
| `cashCollectorLabel` | المستلم | Received by |
| `cashStatement` | أؤكد إني سلّمت {amount} كاش لـ {name} | I confirm I handed {amount} in cash to {name} |
| `cashResend` | ابعت الكود تاني | Resend code |
| `cashResendIn` | ابعت تاني بعد {time} | Resend in {time} |
| `cashConfirmButton` | أكّد الدفع | Confirm payment |
| `cashContactSupport` | كلّم الدعم | Contact support |
| `receiptTitle` | تم تأكيد الدفع الكاش | Cash payment confirmed |
| `receiptNumber` | رقم الإيصال | Receipt number |
| `receiptDate` | التاريخ | Date |
| `receiptBack` | رجوع للحجز | Back to booking |
| `receiptShow` | عرض الإيصال | Show receipt |
| `receiptCopied` | اتنسخ رقم الإيصال | Receipt number copied |

### Cancellation

| Key | Arabic | English |
|---|---|---|
| `cancelTitle` | إلغاء الحجز | Cancel booking |
| `cancelRefund` | هيترجعلك | Refunded to you |
| `cancelNonRefundable` | مش هيترجع | Not refundable |
| `cancelReasonFree` | الإلغاء مجاني. هيترجعلك المبلغ كله ({amount}). | Free cancellation. You'll get the full amount back ({amount}). |
| `cancelReasonDepositLost` | هيترجعلك {refund}. العربون {deposit} مش هيترجع لأن ميعاد الإلغاء المجاني خلص يوم {date}. | {refund} will be refunded. The {deposit} deposit isn't refundable because free cancellation ended on {date}. |
| `cancelReasonDepositLostNoDate` | هيترجعلك {refund}. العربون {deposit} مش هيترجع لأن ميعاد الإلغاء المجاني خلص. | {refund} will be refunded. The {deposit} deposit isn't refundable because free cancellation has ended. |
| `cancelReasonNoRefund` | مفيش استرداد، لأن الحجز مدفوع بالكامل وعدّى أكتر من 24 ساعة على ميعاد الاستلام. | No refund, because the booking is fully paid and more than 24 hours have passed since the scheduled check-in. |
| `cancelReasonTitle` | سبب الإلغاء (اختياري) | Reason (optional) |
| `cancelReasonChangeOfPlans` | خططي اتغيرت | My plans changed |
| `cancelReasonFoundOther` | لقيت مكان تاني | I found another place |
| `cancelReasonTravelProblem` | مشكلة في السفر | Travel problem |
| `cancelReasonOther` | سبب تاني | Other |
| `cancelReasonOtherHint` | اكتب السبب | Write the reason |
| `cancelKeep` | خليني محتفظ بالحجز | Keep my booking |
| `cancelDialogTitle` | متأكد إنك عايز تلغي؟ | Are you sure you want to cancel? |
| `cancelDialogBody` | هيترجعلك {amount}. | {amount} will be refunded. |
| `cancelDialogConfirm` | أيوه، ألغي | Yes, cancel |

### Damage claims

| Key | Arabic | English |
|---|---|---|
| `claimTitle` | مطالبة ضرر | Damage claim |
| `claimsSectionTitle` | مطالبات الضرر | Damage claims |
| `claimProtection` | مفيش أي مبلغ هيتخصم من غير موافقتك أو قرار من OnAir. | No amount will be deducted without your agreement or a decision from OnAir. |
| `claimAmount` | المبلغ المطلوب | Amount claimed |
| `claimEvidence` | الصور | Photos |
| `claimEvidencePhoto` | صورة {index} من {count} | Photo {index} of {count} |
| `claimPhotoFailed` | الصورة ما اتحملتش. اضغط للمحاولة تاني. | The photo didn't load. Tap to retry. |
| `claimAgree` | موافق | I agree |
| `claimDispute` | معترض | I dispute |
| `claimAgreeDialogTitle` | توافق على المطالبة؟ | Agree to the claim? |
| `claimAgreeDialogBody` | انت موافق على مبلغ {amount}. | You agree to {amount}. |
| `claimDisputeReason` | سبب الاعتراض | Reason for the dispute |
| `claimDisputeReasonHint` | اكتب اللي حصل بالتفصيل | Describe what happened |
| `claimDisputeTooShort` | اكتب 10 حروف على الأقل. | Write at least 10 characters. |
| `claimDisputeSend` | ابعت الاعتراض | Send dispute |
| `claimCaseNumber` | رقم الحالة: {number} | Case number: {number} |
| `claimYourAnswer` | ردك | Your answer |
| `claimStatusOpen` | مستنية ردك | Waiting for you |
| `claimStatusAccepted` | وافقت | You agreed |
| `claimStatusDisputed` | اعترضت | You disputed |
| `claimStatusMediation` | عند OnAir للمراجعة | Under review by OnAir |
| `claimStatusResolved` | اتقفلت | Resolved |
| `claimStatusWithdrawn` | اتسحبت | Withdrawn |
| `claimStatusUnknown` | فيه تحديث | Updated |
| `claimOutcomeGuestPays` | القرار: تدفع {amount}. | Decision: you pay {amount}. |
| `claimOutcomePartial` | القرار: تدفع جزء من المبلغ ({amount}). | Decision: you pay part of the amount ({amount}). |
| `claimOutcomeNoCharge` | القرار: مفيش أي مبلغ عليك. | Decision: you don't pay anything. |
| `claimOutcomeWithdrawn` | المالك سحب المطالبة. | The owner withdrew the claim. |

### Replacement offer

| Key | Arabic | English |
|---|---|---|
| `offerTitle` | عرض بديل من OnAir | Alternative offer from OnAir |
| `offerPayMore` | هتدفع {amount} زيادة. | You will pay {amount} more. |
| `offerRefundDiff` | هيترجعلك {amount}. | {amount} will be refunded to you. |
| `offerNoDiff` | مفيش فرق في السعر. | No price difference. |
| `offerExpires` | رد قبل {time} | Answer before {time} |
| `offerAccept` | موافق على العرض | I accept |
| `offerDecline` | لا، عايز استرداد فلوسي | No, I want my refund |
| `offerAcceptDialogTitle` | توافق على العرض البديل؟ | Accept the alternative offer? |
| `offerDeclineDialogTitle` | ترفض العرض البديل؟ | Decline the alternative offer? |
| `offerDeclineDialogBody` | الاسترداد هيكمل زي ما هو. | Your refund will continue as before. |
| `offerStatusAccepted` | وافقت على العرض | You accepted the offer |
| `offerStatusDeclined` | رفضت العرض | You declined the offer |
| `offerStatusExpired` | العرض انتهى | The offer expired |

### Mock tools (mock mode only)

| Key | Arabic | English |
|---|---|---|
| `mockToolsTitle` | أدوات المحاكاة | Mock tools |
| `mockOwnerHandover` | المالك أكّد التسليم | Owner confirms handover |
| `mockOwnerCheckout` | المالك أكّد الاستلام | Owner confirms checkout |
| `mockOwnerCheckoutKey` | المالك أكّد الاستلام (المفتاح في مكان آمن) | Owner confirms checkout (key left safe) |
| `mockCollectorCash` | المحصّل سجّل كاش | Collector records cash |
| `mockOpenClaim` | فتح مطالبة | Open a claim |
| `mockAdvanceRefund` | تقديم مرحلة الاسترداد | Advance the refund stage |
| `mockChangeTerms` | تغيير شروط الإلغاء مرة | Change cancellation terms once |

---

## Appendix B — Mock fixtures

All dates are chosen around the test clock `2026-11-01T10:00:00Z`. Every booking repeats the
fields G2 requires (copy the shape of `lib/features/bookings/data/fixtures/bookings.json`
entries). The `mock_*` keys are read only by `MockStayServer` and are ignored by
`BookingDetails.fromJson`.

### B.1 `lib/features/bookings/data/fixtures/bookings_g3.json`

Write a JSON **array** of the nine objects below.
- **Shared values** (fields marked `…common…`), the same for every object:
  - `"currency": "EGP"`, `"owner_response_deadline": null`, `"payment_state": "succeeded"`;
  - `"terms_snapshot": {"policy_summary": {"deposit_type": "percent", "deposit_percent_bp": 2500, "deposit_amount_minor": null, "free_cancellation_hours": 72}}`;
  - `"access_instructions": "المفتاح مع حارس العمارة."`;
  - `"events": [{"event_type": "booking.confirmed", "to_status": "confirmed", "created_at": "2026-10-20T12:00:00Z", "note": null}]`;
  - `"created_at": "2026-10-20T08:00:00Z"`.
- **Property block** (`"property"`), the same in every object except `id` and `title`:
  - `{"id": "<P>", "title": "<T>", "cover_image": {"variants": [{"width": 320, "url": "https://cdn.mock.onair.test/310-320.jpg"}, {"width": 720, "url": "https://cdn.mock.onair.test/310-720.jpg"}], "blurhash": null}, "area_name": "رأس البر", "city_name": "دمياط", "address_text": "شارع النيل، رأس البر", "check_in_time": "14:00", "check_out_time": "12:00"}`.
- **Payment lines:** a line written `kashier(<id>, <purpose>, <amount>)` means `{"id": "<id>", "purpose": "<purpose>", "method": "kashier", "status": "succeeded", "amount_minor": <amount>, "paid_at": "2026-10-20T09:00:00Z"}`.

| ID (`b0000000-0000-4000-8000-0000000000NN`) | code | status | P / T | check_in → check_out, nights, guests | nightly / total / pay_now / paid / remaining (minor) | remaining_due_at | payments | refund | available_actions | G3 fields |
|---|---|---|---|---|---|---|---|---|---|---|
| `…020` | `OA-G3020` | `confirmed` | `00000000-0000-4000-8000-00000000001f` / `شقة 3 غرف للتجربة` | 2026-11-25 → 2026-11-28, 3, 2 | 150000 / 450000 / 112500 / 112500 / 337500 | `2026-11-24T22:00:00Z` | `[kashier(c0000000-0000-4000-8000-000000000020, initial, 112500)]` | `null` | `["pay_remaining","confirm_cash_payment","request_cancellation","contact_support"]` | `"mock_cash_allowed": true`, `"mock_cancellation_preview": {"refund_minor": 0, "non_refundable_minor": 112500, "policy_case": "deposit_lost", "free_cancellation_until": "2026-11-22T10:00:00Z"}` |
| `…021` | `OA-G3021` | `confirmed` | same P / `شقة على البحر` | 2026-11-01 → 2026-11-04, 3, 2 | 120000 / 360000 / 360000 / 360000 / 0 | `null` | `[kashier(c0000000-0000-4000-8000-000000000021, initial, 360000)]` | `null` | `["confirm_checkin","request_cancellation","contact_support"]` | `"acknowledgements": {"guest_checkin_at": null, "host_checkin_at": null, "guest_checkout_at": null, "host_checkout_at": null, "key_left_safe": false}`, `"mock_cancellation_preview": {"refund_minor": 270000, "non_refundable_minor": 90000, "policy_case": "deposit_lost", "free_cancellation_until": "2026-10-29T10:00:00Z"}` |
| `…022` | `OA-G3022` | `checked_in` | same P / `شقة الحديقة` | 2026-10-30 → 2026-11-03, 4, 3 | 75000 / 300000 / 75000 / 300000 / 0 | `null` | `[kashier(c0000000-0000-4000-8000-000000000221, initial, 75000), {"id": "c0000000-0000-4000-8000-000000000222", "purpose": "remaining", "method": "cash", "status": "succeeded", "amount_minor": 225000, "paid_at": "2026-10-30T13:00:00Z", "receipt": {"receipt_no": "R-2026-000123", "collector_display_name": "أحمد م.", "confirmed_at": "2026-10-30T13:00:00Z"}}]` | `null` | `["confirm_checkout","contact_support"]` | `"acknowledgements": {"guest_checkin_at": "2026-10-30T14:10:00Z", "host_checkin_at": "2026-10-30T14:05:00Z", "guest_checkout_at": null, "host_checkout_at": null, "key_left_safe": false}` |
| `…023` | `OA-G3023` | `confirmed` | same P / `شاليه الشاطئ` | 2026-12-20 → 2026-12-23, 3, 4 | 150000 / 450000 / 450000 / 450000 / 0 | `null` | `[kashier(c0000000-0000-4000-8000-000000000023, initial, 450000)]` | `null` | `["request_cancellation","contact_support"]` | `"mock_cancellation_preview": {"refund_minor": 450000, "non_refundable_minor": 0, "policy_case": "free", "free_cancellation_until": "2026-12-17T10:00:00Z"}` |
| `…024` | `OA-G3024` | `confirmed` | same P / `شقة المرسى` | 2026-10-30 → 2026-11-02, 3, 2 | 133333 / 400000 / 400000 / 400000 / 0 | `null` | `[kashier(c0000000-0000-4000-8000-000000000024, initial, 400000)]` | `null` | `["request_cancellation","contact_support"]` | `"mock_cancellation_preview": {"refund_minor": 0, "non_refundable_minor": 400000, "policy_case": "no_refund", "free_cancellation_until": null}` |
| `…025` | `OA-G3025` | `completed` | same P / `شقة بلطيم` | 2026-10-20 → 2026-10-23, 3, 2 | 100000 / 300000 / 300000 / 300000 / 0 | `null` | `[kashier(c0000000-0000-4000-8000-000000000025, initial, 300000)]` | `null` | `["respond_damage_claim","contact_support"]` | `"acknowledgements": {"guest_checkin_at": "2026-10-20T14:00:00Z", "host_checkin_at": "2026-10-20T14:00:00Z", "guest_checkout_at": "2026-10-23T11:00:00Z", "host_checkout_at": "2026-10-23T11:30:00Z", "key_left_safe": false}`, `"damage_claims": [{"id": "e0000000-0000-4000-8000-000000000001", "amount_minor": 50000, "status": "open", "created_at": "2026-10-24T09:00:00Z"}, {"id": "e0000000-0000-4000-8000-000000000002", "amount_minor": 30000, "status": "resolved", "created_at": "2026-10-23T15:00:00Z"}]` |
| `…026` | `OA-G3026` | `rejected` | same P / `شقة مطروح` | 2026-11-15 → 2026-11-18, 3, 2 | 150000 / 450000 / 180000 / 180000 / 270000 | `null` | `[kashier(c0000000-0000-4000-8000-000000000026, initial, 180000)]` | `{"id": "d0000000-0000-4000-8000-000000000026", "amount_minor": 180000, "status": "requested", "updated_at": "2026-10-31T10:00:00Z"}` | `["contact_support"]` | `"replacement_offer": {"id": "f0000000-0000-4000-8000-000000000001", "status": "pending", "offered_property": {"id": "00000000-0000-4000-8000-00000000002f", "title": "شقة بديلة على البحر", "area_name": "رأس البر", "cover_image": null}, "check_in": "2026-11-15", "check_out": "2026-11-18", "price_difference_minor": 50000, "expires_at": "2026-11-02T10:00:00Z"}` |
| `…027` | `OA-G3027` | `expired` | same P / `شقة جمصة` | 2026-11-10 → 2026-11-12, 2, 2 | 100000 / 200000 / 50000 / 50000 / 150000 | `null` | `[kashier(c0000000-0000-4000-8000-000000000027, initial, 50000)]` | `{"id": "d0000000-0000-4000-8000-000000000027", "amount_minor": 50000, "status": "approved", "updated_at": "2026-10-30T10:00:00Z"}` | `["contact_support"]` | `"replacement_offer": {"id": "f0000000-0000-4000-8000-000000000002", "status": "expired", "offered_property": {"id": "00000000-0000-4000-8000-00000000003f", "title": "شقة بديلة في جمصة", "area_name": "جمصة", "cover_image": null}, "check_in": "2026-11-10", "check_out": "2026-11-12", "price_difference_minor": -20000, "expires_at": "2026-10-31T10:00:00Z"}` |
| `…028` | `OA-G3028` | `confirmed` | same P / `شقة الكورنيش` | 2026-11-08 → 2026-11-11, 3, 2 | 150000 / 450000 / 112500 / 112500 / 337500 | `2026-11-07T22:00:00Z` | `[kashier(c0000000-0000-4000-8000-000000000028, initial, 112500)]` | `null` | `["confirm_cash_payment","contact_support"]` | `"mock_cash_allowed": true`, `"pending_cash": {"payment_id": "c0000000-0000-4000-8000-000000000281", "challenge_id": "a0000000-0000-4000-8000-000000000281", "collector_display_name": "أحمد م.", "amount_minor": 337500, "masked_email": "g***@mock.onair.test", "code_expires_at": "2026-11-01T10:15:00Z", "retry_after_seconds": 0, "origin": "collector"}` |

For `…026` and `…027`, set `"payment_state": "succeeded"` and keep `access_instructions`
(the server hides it for non-confirmed statuses).

### B.2 `lib/features/stay/data/fixtures/claims.json`

```json
[
  {
    "id": "e0000000-0000-4000-8000-000000000001",
    "booking_id": "b0000000-0000-4000-8000-000000000025",
    "description": "كسر في باب البلكونة وبقعة على الكنبة.",
    "amount_minor": 50000,
    "status": "open",
    "created_at": "2026-10-24T09:00:00Z",
    "evidence": [
      {"attachment_id": "a1000000-0000-4000-8000-000000000001", "kind": "image", "width": 1600, "height": 1200},
      {"attachment_id": "a1000000-0000-4000-8000-000000000002", "kind": "image", "width": 1200, "height": 1600}
    ],
    "guest_response": null,
    "support_case_number": null,
    "resolution": null
  },
  {
    "id": "e0000000-0000-4000-8000-000000000002",
    "booking_id": "b0000000-0000-4000-8000-000000000025",
    "description": "كوباية مكسورة.",
    "amount_minor": 30000,
    "status": "resolved",
    "created_at": "2026-10-23T15:00:00Z",
    "evidence": [],
    "guest_response": {"decision": "dispute", "note": "الكوباية كانت مكسورة من الأول.", "responded_at": "2026-10-23T16:00:00Z"},
    "support_case_number": "SC-1000",
    "resolution": {"outcome_code": "no_charge", "amount_minor": null, "decided_at": "2026-10-25T10:00:00Z"}
  }
]
```

---

## Appendix C — Stay domain types (copy exactly)

Use `package:flutter/foundation.dart` `@immutable`. Add `==` / `hashCode` with `Object.hash`
or `Object.hashAll` for every class (omitted below for space; they are required). JSON keys are
in the comments.

```dart
// lib/features/stay/domain/cancellation_preview.dart
enum PolicyCase {
  free, depositLost, noRefund, unknown;
  static PolicyCase fromWire(String? v) => switch (v) {
    'free' => free, 'deposit_lost' => depositLost, 'no_refund' => noRefund, _ => unknown };
}

@immutable
final class CancellationPreview {
  const CancellationPreview({required this.refund, required this.nonRefundable,
    required this.policyCase, required this.freeCancellationUntil,
    required this.previewToken, required this.validUntil});
  // {"refund_minor":270000,"non_refundable_minor":90000,"policy_case":"deposit_lost",
  //  "free_cancellation_until":"2026-10-29T10:00:00Z","preview_token":"t1","valid_until":"2026-11-01T10:10:00Z"}
  factory CancellationPreview.fromJson(Map<String, dynamic> json) => CancellationPreview(
    refund: Money(json['refund_minor'] as int),
    nonRefundable: Money(json['non_refundable_minor'] as int),
    policyCase: PolicyCase.fromWire(json['policy_case'] as String?),
    freeCancellationUntil: json['free_cancellation_until'] == null ? null
        : DateTime.parse(json['free_cancellation_until'] as String),
    previewToken: json['preview_token'] as String? ?? '',
    validUntil: json['valid_until'] == null ? null : DateTime.parse(json['valid_until'] as String),
  );
  final Money refund;
  final Money nonRefundable;
  final PolicyCase policyCase;
  final DateTime? freeCancellationUntil;
  final String previewToken;
  final DateTime? validUntil;
}

/// Which preview fields changed between two server answers. Highlights only.
@immutable
final class PreviewChange {
  const PreviewChange({this.refund = false, this.nonRefundable = false, this.policyCase = false});
  static const none = PreviewChange();
  factory PreviewChange.between(CancellationPreview a, CancellationPreview b) => PreviewChange(
    refund: a.refund != b.refund,
    nonRefundable: a.nonRefundable != b.nonRefundable,
    policyCase: a.policyCase != b.policyCase,
  );
  final bool refund;
  final bool nonRefundable;
  final bool policyCase;
  bool get any => refund || nonRefundable || policyCase;
}

enum CancellationReason {
  changeOfPlans, foundOtherPlace, travelProblem, other;
  static const noteMaxLength = 300;
  String get wire => switch (this) {
    changeOfPlans => 'change_of_plans', foundOtherPlace => 'found_other_place',
    travelProblem => 'travel_problem', other => 'other' };
}
```

```dart
// lib/features/stay/domain/damage_claim.dart
@immutable
final class EvidenceRef {
  const EvidenceRef({required this.attachmentId, required this.kind, this.width, this.height});
  // {"attachment_id":"…","kind":"image","width":1600,"height":1200}
  factory EvidenceRef.fromJson(Map<String, dynamic> json) => EvidenceRef(
    attachmentId: json['attachment_id'] as String, kind: json['kind'] as String? ?? 'image',
    width: json['width'] as int?, height: json['height'] as int?);
  final String attachmentId; final String kind; final int? width; final int? height;
}

enum ClaimDecision { accept, dispute; String get wire => name; }

@immutable
final class ClaimResponse {
  const ClaimResponse({required this.decision, required this.note, required this.respondedAt});
  // {"decision":"dispute","note":"…","responded_at":"…"}
  factory ClaimResponse.fromJson(Map<String, dynamic> json) => ClaimResponse(
    decision: json['decision'] == 'dispute' ? ClaimDecision.dispute : ClaimDecision.accept,
    note: json['note'] as String?, respondedAt: DateTime.parse(json['responded_at'] as String));
  final ClaimDecision decision; final String? note; final DateTime respondedAt;
}

enum ClaimOutcome {
  guestPays, partial, noCharge, withdrawn, unknown;
  static ClaimOutcome fromWire(String? v) => switch (v) {
    'guest_pays' => guestPays, 'partial' => partial, 'no_charge' => noCharge,
    'withdrawn' => withdrawn, _ => unknown };
}

@immutable
final class ClaimResolution {
  const ClaimResolution({required this.outcome, required this.amount, required this.decidedAt});
  // {"outcome_code":"no_charge","amount_minor":null,"decided_at":"…"}
  factory ClaimResolution.fromJson(Map<String, dynamic> json) => ClaimResolution(
    outcome: ClaimOutcome.fromWire(json['outcome_code'] as String?),
    amount: json['amount_minor'] == null ? null : Money(json['amount_minor'] as int),
    decidedAt: DateTime.parse(json['decided_at'] as String));
  final ClaimOutcome outcome; final Money? amount; final DateTime decidedAt;
}

@immutable
final class DamageClaim {
  const DamageClaim({required this.id, required this.bookingId, required this.description,
    required this.amount, required this.status, required this.createdAt, required this.evidence,
    required this.response, required this.supportCaseNumber, required this.resolution});
  // Shape: Appendix B.2 objects.
  factory DamageClaim.fromJson(Map<String, dynamic> json) => DamageClaim(
    id: json['id'] as String, bookingId: json['booking_id'] as String,
    description: json['description'] as String, amount: Money(json['amount_minor'] as int),
    status: DamageClaimStatus.fromWire(json['status'] as String?),
    createdAt: DateTime.parse(json['created_at'] as String),
    evidence: [for (final e in json['evidence'] as List? ?? const [])
      EvidenceRef.fromJson(Map<String, dynamic>.from(e as Map))],
    response: json['guest_response'] == null ? null
        : ClaimResponse.fromJson(Map<String, dynamic>.from(json['guest_response'] as Map)),
    supportCaseNumber: json['support_case_number'] as String?,
    resolution: json['resolution'] == null ? null
        : ClaimResolution.fromJson(Map<String, dynamic>.from(json['resolution'] as Map)));
  final String id; final String bookingId; final String description; final Money amount;
  final DamageClaimStatus status; final DateTime createdAt; final List<EvidenceRef> evidence;
  final ClaimResponse? response; final String? supportCaseNumber; final ClaimResolution? resolution;
}

abstract final class ClaimLimits {
  static const disputeMin = 10;
  static const disputeMax = 1000;
  static bool validDisputeNote(String note) {
    final trimmed = note.trim();
    return trimmed.length >= disputeMin && trimmed.length <= disputeMax;
  }
}
```

`DamageClaimStatus` is the enum from `booking_stay_parts.dart` (T013); import it.

```dart
// lib/features/stay/domain/stay_results.dart
@immutable
final class CancellationResult {
  const CancellationResult({required this.status, required this.refund});
  // {"status":"cancelled","refund":{"id":"…","amount_minor":450000,"status":"requested"}|null}
  factory CancellationResult.fromJson(Map<String, dynamic> json) => CancellationResult(
    status: json['status'] as String,
    refund: json['refund'] == null ? null
        : RefundInfo.fromJson(Map<String, dynamic>.from(json['refund'] as Map)));
  final String status; final RefundInfo? refund;
}

@immutable
final class ClaimAnswerResult {
  const ClaimAnswerResult({required this.status, required this.supportCaseNumber});
  // {"status":"guest_disputed","support_case_number":"SC-1001"}
  factory ClaimAnswerResult.fromJson(Map<String, dynamic> json) => ClaimAnswerResult(
    status: DamageClaimStatus.fromWire(json['status'] as String?),
    supportCaseNumber: json['support_case_number'] as String?);
  final DamageClaimStatus status; final String? supportCaseNumber;
}

@immutable
final class OfferAnswerResult {
  const OfferAnswerResult({required this.status, required this.newBookingId});
  // {"status":"accepted","new_booking_id":null}
  factory OfferAnswerResult.fromJson(Map<String, dynamic> json) => OfferAnswerResult(
    status: OfferStatus.fromWire(json['status'] as String?),
    newBookingId: json['new_booking_id'] as String?);
  final OfferStatus status; final String? newBookingId;
}

@immutable
final class FileUrl {
  const FileUrl({required this.url, required this.expiresAt});
  final Uri url; final DateTime expiresAt;
}
```

`RefundInfo.fromJson` reads `updated_at` as optional. If it requires it, pass
`{...json, 'updated_at': json['updated_at']}` unchanged; it already handles null (see
`booking_parts.dart`).

```dart
// lib/features/stay/domain/stay_repository.dart
/// Every G3 command the guest can send (contracts/supabase-stay.md §1).
/// Every method throws AppFailure on error. No method computes an amount.
abstract interface class StayRepository {
  Future<CancellationPreview> previewCancellation(String bookingId);

  /// [expectedRefund] is the refund the guest saw in the preview; the server
  /// rejects with CANCELLATION_TERMS_CHANGED when it no longer matches.
  Future<CancellationResult> cancelBooking({
    required String bookingId,
    required Money expectedRefund,
    required CancellationReason? reason,
    required String? reasonNote,
    required String idempotencyKey,
  });

  /// Returns the booking status after the call (wire value).
  Future<String> confirmCheckIn(String bookingId);
  Future<String> confirmCheckOut(String bookingId);

  /// [expectedAmount] is the server's remaining amount the guest saw; the
  /// server rejects with CASH_AMOUNT_CHANGED when it no longer matches.
  Future<CashRequest> startCashConfirmation({
    required String bookingId,
    required String collectorPhoneE164,
    required Money expectedAmount,
    required String idempotencyKey,
  });

  Future<void> sendCashCode(String challengeId);

  Future<CashReceipt> confirmCashPayment({
    required String paymentId,
    required String challengeId,
    required String code,
  });

  Future<DamageClaim> getDamageClaim(String claimId);

  /// In G3 no attachments are sent (Clarification 2026-11-05).
  Future<ClaimAnswerResult> respondDamageClaim({
    required String claimId,
    required ClaimDecision decision,
    required String? note,
    required String idempotencyKey,
  });

  /// A short-lived private URL; never cache it on disk.
  Future<FileUrl> fileUrl(String attachmentId);

  Future<OfferAnswerResult> respondReplacementOffer({
    required String offerId,
    required bool accept,
    required String idempotencyKey,
  });
}
```

`confirmCashPayment` in the Supabase class parses the response `{"receipt": {…}}` with
`CashReceipt.fromJson(json['receipt'])`.

---

## Appendix D — Mock server behaviour (`MockStayServer` and the remaining payment)

Rules for every method:
- **Delay:** run inside a `_delayed` helper copied from `MockBookingServer` (honours `latency`).
- **Booking maps:** read with `final all = await _bookings.bookings;`, and a missing ID →
  `throw AppFailure(ErrorMapper.fromCode('NOT_FOUND'))`.
- **Mutations:** change the booking **map in place**. The next `getBooking` sees the change.
- **Notifications:** emit them with `await _bookings.notifyGuest(type, bookingId)`, which also
  refreshes open details through the signal.
- **Test switches:**
  - `bool failNextWithNetwork = false`: when true, the next call of any method first sets it
    false and throws `AppFailure(ErrorMapper.noResponse())`.
  - `bool rateLimitNextSend = false`: when true, the next `sendCashCode` sets it false and
    throws `AppFailure(ApiError(code: ErrorCode.rateLimited, messageKey: 'authRateLimited',
    retryAfter: Duration(seconds: 30)))`.
- **Public counters** (for tests): `int previews, cancels, checkIns, checkOuts, codesSent,
  cashConfirms, claimAnswers, offerAnswers;` and `Money? lastExpectedRefund,
  lastExpectedAmount; String? lastCancelKey, lastCashStartKey;`.

### D.1 Remaining payment (in `MockBookingServer`, T038)

- **`startRemainingPayment({bookingId, attemptKey})`:**
  1. `remainingStarts++`.
  2. The booking must exist (`NOT_FOUND`), have status `confirmed` (`INVALID_BOOKING_STATE`), and `remaining_minor > 0` (`INVALID_BOOKING_STATE`).
  3. If `_sessionForKey[attemptKey]` exists, return it.
  4. If any `payments` line has `purpose == 'remaining'` and `status == 'pending'`, throw `CONFLICT`.
  5. Otherwise append a line `{"id": _randomId('r'), "purpose": "remaining", "method": "kashier", "status": "pending", "amount_minor": <remaining_minor>, "paid_at": null}` and set `json['pending_remaining_payment_id'] = <that id>`.
  6. Create a `PaymentSessionInfo(bookingId:, paymentId: <line id>, paymentUrl: Uri.parse('https://pay.mock.onair.test/remaining/$bookingId'), paymentUrlExpiresAt: _now() + 30 min)`, store it in `_sessionForKey[attemptKey]` and `_sessionForBooking[bookingId]`, and return it.
- **The remaining branch at the top of `completePayment(bookingId, result)`:** find the line with `purpose == 'remaining' && status == 'pending'`. If found:
  - `success`:
    - line `status = 'succeeded'`, `paid_at = now`;
    - `paid_minor = total_minor`, `remaining_minor = 0`, `remaining_due_at = null`, `pending_remaining_payment_id = null`;
    - `available_actions` = the old list with `pay_remaining` and `confirm_cash_payment` removed, plus `confirm_checkin` inserted at index 0 **only if** `check_in <= today` (Cairo).

      For `…020`, `check_in` is in the future, so `confirm_checkin` is not added.
    - `appendEvent(json, 'payment.remaining_paid', 'confirmed')`;
    - `notifyGuest('payment.remaining_paid', bookingId)`.
  - `failure`:
    - line `status = 'failed'`, `pending_remaining_payment_id = null`;
    - `notifyGuest('payment.failed', bookingId)`.
  - `conflict` or `silent`: leave the line `pending` (the verification screen times out).

  Then `return;`.

### D.2 Cancellation

- **`previewCancellation(id)`:**
  1. `previews++`.
  2. The status must be `confirmed`, else `INVALID_BOOKING_STATE`.
  3. Take `json['mock_cancellation_preview']`. If it is missing, use `{"refund_minor": paid_minor, "non_refundable_minor": 0, "policy_case": "free", "free_cancellation_until": null}`.
  4. Return `CancellationPreview.fromJson({...thatMap, 'preview_token': 'mock-$previews', 'valid_until': (now + 10 min).toIso8601String()})`.
- **`forceTermsChangeOnce(id)`:**
  1. Set a private flag `_termsChange.add(id)`.
  2. Change the fixture's `mock_cancellation_preview.refund_minor` to `refund_minor - 10000`, and `non_refundable_minor` to `non_refundable_minor + 10000`.

  For `…021`: 270000 → 260000 and 90000 → 100000.
- **`cancelBooking(...)`:**
  1. `cancels++`; `lastExpectedRefund = expectedRefund`; `lastCancelKey = idempotencyKey`.
  2. If `_cancelResults[idempotencyKey]` exists, return it.
  3. If `_termsChange.remove(id)` was true, throw `CANCELLATION_TERMS_CHANGED`.
  4. The status must be `confirmed`, else `INVALID_BOOKING_STATE`.
  5. If `expectedRefund.amountMinor != preview.refund_minor`, throw `CANCELLATION_TERMS_CHANGED`.
  6. Set `status = 'cancelled'`, `available_actions = ['contact_support']`, and `cancellation = {"cancelled_at": now, "by_scope": "guest", "reason_code": reason?.wire}`.
  7. If `refund_minor > 0`, set `refund = {"id": _randomId('d'), "amount_minor": refund_minor, "status": "requested", "updated_at": now}`.
  8. `appendEvent(json, 'booking.cancelled_by_guest', 'cancelled')` and `notifyGuest('booking.cancelled_by_guest', id)`.
  9. Store and return `CancellationResult(status: 'cancelled', refund: …)`.
- **`advanceRefund(id)`:**
  1. The refund `status` moves `requested → approved → executed → verified` (one step per call), with `updated_at = now`.
  2. Emit `refund.requested` / `refund.executed` / `refund.verified` (use `refund.executed` for the `approved` step too).
  3. When it is already `verified`, do nothing.

### D.3 Check-in / check-out

- **`confirmCheckIn(id)`:**
  1. `checkIns++`.
  2. The status must be `confirmed`, else `INVALID_BOOKING_STATE`.
  3. If `paid_minor < total_minor`, throw `REMAINING_NOT_PAID` **without** changing anything.
  4. Ensure `json['acknowledgements']` exists (create the all-null map) and set `guest_checkin_at = now` if it is null.
  5. Remove `confirm_checkin` and `request_cancellation` from `available_actions`.
  6. If `host_checkin_at != null`, call `_advance(json)` (below).
  7. Return `json['status']`.
- **`ownerConfirmsHandover(id)`:** set `host_checkin_at = now` if it is null, call `_advance(json)`, and if the status is still `confirmed`, `notifyGuest('stay.host_handover_confirmed', id)`.
- **`confirmCheckOut(id)`:** `checkOuts++`, the status must be `checked_in`, set `guest_checkout_at = now`, remove `confirm_checkout`, call `_advance(json)`, and return the status.
- **`ownerConfirmsCheckout(id, {bool keyLeftSafe = false})`:** set `host_checkout_at = now`, set `key_left_safe = keyLeftSafe`, and call `_advance(json)`.
- **`_advance(json)`:**
  - if the status is `confirmed` and both check-in times are set → `status = 'checked_in'`, `available_actions = ['confirm_checkout','contact_support']`, `appendEvent(json, 'stay.checked_in', 'checked_in')`, `notifyGuest('stay.checked_in', id)`;
  - if the status is `checked_in` and both check-out times are set → `status = 'completed'`, `available_actions = ['contact_support']`, `appendEvent(json, 'stay.completed', 'completed')`, `notifyGuest('stay.completed', id)`.

### D.4 Cash

Mock constants:
- the authorized phone is `+201000000001`;
- the collector name is `أحمد م.`;
- the masked email is `g***@mock.onair.test`;
- the correct code is `123456`.

- **`changeAmountOnce(id)`:** set `_amountChange.add(id)` and `remaining_minor = remaining_minor - 12500`. The next start uses the new amount.
- **`startCashConfirmation(...)`:**
  1. `lastExpectedAmount = expectedAmount`; `lastCashStartKey = idempotencyKey`.
  2. If `_cashStarts[idempotencyKey]` exists, return it.
  3. The status must be `confirmed`, else `INVALID_BOOKING_STATE`.
  4. If `json['mock_cash_allowed'] != true`, throw `CASH_NOT_ALLOWED`.
  5. If `collectorPhoneE164 != '+201000000001'`, throw `COLLECTOR_NOT_AUTHORIZED`.
  6. If `expectedAmount.amountMinor != remaining_minor`, throw `CASH_AMOUNT_CHANGED`.
  7. Create `pending_cash = {"payment_id": _randomId('c'), "challenge_id": _randomId('a'), "collector_display_name": "أحمد م.", "amount_minor": remaining_minor, "masked_email": "g***@mock.onair.test", "code_expires_at": now + 15 min, "retry_after_seconds": 0, "origin": "guest"}`.
  8. Store it in the booking map and in `_cashStarts`, and return `CashRequest.fromJson(...)`.
- **`sendCashCode(challengeId)`:** apply the `rateLimitNextSend` rule, then `codesSent++`.
- **`confirmCashPayment(...)`:**
  1. `cashConfirms++`.
  2. Find the booking whose `pending_cash.payment_id == paymentId`, else `NOT_FOUND`.
  3. If `code != '123456'`, throw `OTP_INVALID`.
  4. Append a payment line `{"id": paymentId, "purpose": "remaining", "method": "cash", "status": "succeeded", "amount_minor": <pending amount>, "paid_at": now, "receipt": {"receipt_no": "R-2026-${100000 + cashConfirms}", "collector_display_name": "أحمد م.", "confirmed_at": now}}`.
  5. Set `paid_minor = total_minor`, `remaining_minor = 0`, `remaining_due_at = null`, and `pending_cash = null`.
  6. Remove `pay_remaining` and `confirm_cash_payment` from `available_actions`.
  7. `notifyGuest('cash.payment_confirmed', paymentId, entityType: 'payment', params: {'booking_id': id})`.
  8. Return `CashReceipt.fromJson(<receipt map>)`.
- **`collectorRecordsCash(id)`:** set `pending_cash` exactly as in `startCashConfirmation` but with `"origin": "collector"`, add `confirm_cash_payment` to `available_actions` if it is missing, and `notifyGuest('cash.confirmation_requested', id)`.

### D.5 Claims and files

- **`getDamageClaim(claimId)`:** a missing claim → `NOT_FOUND`. Return `DamageClaim.fromJson(claim)`.
- **`respondDamageClaim(...)`:**
  1. `claimAnswers++`.
  2. If `_claimResults[key]` exists, return it.
  3. If the claim `status != 'open'`, throw `CLAIM_ALREADY_ANSWERED`.
  4. A dispute with an invalid note (`ClaimLimits`) → `VALIDATION_FAILED`.
  5. `accept` → `status = 'guest_accepted'`. `dispute` → `status = 'guest_disputed'`, `support_case_number = 'SC-1001'`.
  6. Set `guest_response = {decision, note, responded_at: now}`.
  7. Update the matching entry in the booking's `damage_claims` list, and remove `respond_damage_claim` from `available_actions` when no claim is `open`.
  8. Return `ClaimAnswerResult(...)`.
- **`openClaim(bookingId)`:**
  1. Add a new claim `{"id": _randomId('e'), "booking_id": bookingId, "description": "مطالبة تجريبية.", "amount_minor": 25000, "status": "open", "created_at": now, "evidence": [], "guest_response": null, "support_case_number": null, "resolution": null}`.
  2. Add its summary to the booking's `damage_claims` and `respond_damage_claim` to `available_actions`.
  3. `notifyGuest('damage.claim_opened', claimId, entityType: 'damage_claim')`.
- **`fileUrl(id)`:** return `FileUrl(url: Uri.parse('https://files.mock.onair.test/$id.jpg'), expiresAt: now + 5 min)`. In tests the image fails to load, so the placeholder shows; that is expected.

### D.6 Offers

- **`respondReplacementOffer(...)`:**
  1. `offerAnswers++`.
  2. If `_offerResults[key]` exists, return it.
  3. Find the booking whose `replacement_offer.id == offerId`, else `NOT_FOUND`.
  4. If the offer `status != 'pending'`, throw `OFFER_NOT_AVAILABLE`.
  5. Set `status = accept ? 'accepted' : 'declined'`.
  6. Return `OfferAnswerResult(status:, newBookingId: null)`.

### D.7 Ids

Copy `_randomId(prefix)` from `MockBookingServer` (it must produce valid UUID v4 strings).

### D.8 Owner-side helpers (public, for tests and the T089 mock tools)

| Method | Mock tools label key |
|---|---|
| `Future<void> ownerConfirmsHandover(String bookingId)` | `mockOwnerHandover` |
| `Future<void> ownerConfirmsCheckout(String bookingId, {bool keyLeftSafe = false})` | `mockOwnerCheckout` / `mockOwnerCheckoutKey` |
| `Future<void> collectorRecordsCash(String bookingId)` | `mockCollectorCash` |
| `Future<void> openClaim(String bookingId)` | `mockOpenClaim` |
| `Future<void> advanceRefund(String bookingId)` | `mockAdvanceRefund` |
| `void forceTermsChangeOnce(String bookingId)` | `mockChangeTerms` |
| `void changeAmountOnce(String bookingId)` | (tests only) |
