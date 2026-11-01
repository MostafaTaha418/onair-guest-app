# G2 review fixes — task prompt

You are fixing review findings in the OnAir **Guest** Flutter app, feature G2 (booking and
payment). Repository: `D:\flutter\on_air`, branch `feature/003-guest-booking-payment`.

Read these first, in this order:

1. `AGENTS.md` — this repo is the guest app only. **No migrations, SQL, or server code here.**
2. `specs/003-guest-booking-payment/tasks.md` — section "Implementer Guide" (hard rules, code
   style, commands). Every rule there applies to your changes.
3. `specs/003-guest-booking-payment/spec.md` — the requirement IDs (FR-xxx) quoted below.

## Rules (short version of the Implementer Guide)

- No `Color(0x…)`, `Colors.*`, `fontSize:`, `fontWeight:` outside `lib/design_system/`.
- Every visible string comes from `AppLocalizations` (`lib/l10n/app_ar.arb` + `app_en.arb`,
  then `flutter gen-l10n`). If you need a new key, add it to both files.
- RTL-safe layout only (`EdgeInsetsDirectional`, `AlignmentDirectional`).
- Never compute money. Never change a booking status in the app; only the server decides.
- Cubits: check `if (isClosed) return;` after every `await`; cancel timers and subscriptions in
  `close()`.
- Widgets never call repositories or storage directly.
- Do not change behaviour that is not named in a fix. Do not rename public APIs unless the fix
  says so. Keep the existing tests passing; update a test only when the fix changes the behaviour
  it checks, and say which test you changed and why.

## How to work

- Do the fixes **one at a time, in the order below**.
- For each fix: write or update the test first, see it fail, implement, then run:
  1. `dart format .`
  2. `flutter analyze` (must show zero issues)
  3. the tests named in the fix
- Make one commit per fix with a message like `fix(g2): <short description>`. Do not push.
- At the end run the full gates: `dart format --set-exit-if-changed .`, `flutter analyze`,
  `flutter test`, `flutter test --tags golden`, `bash tool/check_hardcoded_styles.sh`.
- If a fix needs a decision that this prompt does not give, stop and report it instead of
  guessing.

---

## Fix 0 — `flutter test` hangs (investigate first)

**Problem**: a full `flutter test --exclude-tags golden` run on Windows stopped making progress
after about 22 seconds, right after
`test/app/router/discovery_links_test.dart: (tearDownAll)`, and never finished (over an hour).

**Do**:
- Run the suites folder by folder with `flutter test <folder> -r expanded` (for example
  `test/app`, `test/core`, `test/features/booking`, `test/features/bookings`,
  `test/features/notifications`, …) to find the test file that hangs.
- Find the cause (typical causes: a `Timer`/`Stream` never cancelled, a `Completer` never
  completed, a real `Future.delayed` inside `fakeAsync`, an `AppLifecycleListener` or
  subscription not disposed, a `pumpAndSettle` that never settles because of a repeating
  countdown or progress indicator).
- Fix the root cause in the test or in the code. Do not just add `skip:` or raise timeouts.

**Done when**: `flutter test` runs to the end and reports a result.

---

## Fix 1 — The app keeps jumping to the payment-verification screen on every resume (High)

**Files**: `lib/features/booking/presentation/payment_attempt_cubit.dart`,
`lib/features/booking/presentation/payment_return_screen.dart`, `lib/app/app.dart`
(`_onResume`, `_onAuthStateChanged`, `_initialize`),
`lib/features/bookings/presentation/unfinished_payment_cubit.dart`.

**Problem**:
- `_onResume` in `app.dart` sends the guest to `/payment/return` whenever
  `PaymentAttemptCubit.state is AttemptOpened`.
- The state stays `AttemptOpened` after the verification screen times out (`VerifyTimeout`),
  after a failed payment, and when the guest leaves the success screen without tapping
  "View booking" (only that button calls `finish()`).
- `UnfinishedPaymentCubit._reconcileAttempt` can clear the stored attempt, but the in-memory
  `PaymentAttemptCubit` state is not updated, so it stays `AttemptOpened`.
- `restore()` emits `AttemptOpened` even for a stored attempt with `bookingId == null` (the app
  was killed before the start-payment response).
- Result: every time the app comes back to the foreground (after a phone call, sharing,
  checking email…) the guest is pulled to the verification screen again, even for a booking the
  server already decided.

**Required behaviour** (spec US6 scenario 2, FR-012, FR-017):
- Add a new state `final class AttemptReturned extends PaymentAttemptState` with a
  `PaymentAttempt attempt` field. It means: the guest already reached the verification screen
  for this attempt.
- Add `void markReturned()` to `PaymentAttemptCubit`: when the state is `AttemptOpened`, emit
  `AttemptReturned(attempt)`; otherwise do nothing. The stored record is **not** cleared.
- `PaymentReturnScreen`: call `markReturned()` once when the verification starts (for example
  in `BlocProvider.create`, after `start()`).
- In the `PaymentVerificationCubit` listener of `PaymentReturnScreen`: when the state becomes
  `VerifyResolved` with outcome `success` or `conflict`, call `attemptCubit.finish()` right away
  (the "View booking" and "Find other dates" buttons then only navigate; keeping a second
  `finish()` call there is harmless). For `failed` and `VerifyTimeout` keep the stored record
  (the "Try again" button and the unfinished-payment banner still need it).
- `_Failed` in `payment_return_screen.dart` reads `termsHash` from the attempt state: also read
  it from `AttemptReturned`.
- `_onResume` keeps redirecting **only** for `AttemptOpened` (the guest left the payment page and
  has not seen the verification screen yet). It must not redirect for `AttemptReturned`.
- `restore()`: emit `AttemptReturned(attempt)` (not `AttemptOpened`) for a stored attempt that
  has a `bookingId`; emit nothing for a stored attempt without `bookingId` (the next `pay()` with
  the same quote already reuses its key). A cold start is handled by the unfinished-payment
  banner, not by a redirect.
- Add `Future<void> syncWithStore()` to `PaymentAttemptCubit`: when the store is empty and the
  state is `AttemptOpened` or `AttemptReturned`, emit `AttemptIdle`. In `app.dart`, call it after
  every `_unfinishedPaymentCubit.refresh()` finishes (on sign-in and in `_onResume`). Make sure
  this cannot loop: the existing listener refreshes the banner when the state becomes
  `AttemptIdle`; `syncWithStore` must not emit when the state is already `AttemptIdle`.
- Every `switch` over `PaymentAttemptState` must handle the new state (the analyzer will show
  them). In `summary_screen.dart` the "come back / check status" banner stays tied to
  `AttemptOpened` only.

**Tests**:
- `test/features/booking/presentation/payment_attempt_cubit_test.dart`: `markReturned()` from
  `AttemptOpened` → `AttemptReturned` with the store unchanged; `restore()` with a `bookingId` →
  `AttemptReturned`; `restore()` without `bookingId` → stays `AttemptIdle`; `syncWithStore()`
  after the store is cleared → `AttemptIdle`, and with a non-empty store → no change.
- `test/features/booking/presentation/payment_return_screen_test.dart`: success and conflict
  outcomes clear the store without tapping any button; failed and timeout keep it.
- Add a widget test (in an existing app-level test file, or a new
  `test/app/payment_resume_test.dart`) that pumps `OnAirApp` and simulates resume with
  `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused)` then `.resumed`:
  with `AttemptOpened` it navigates to `/payment/return`; with `AttemptReturned` it does not.

---

## Fix 2 — The deadline countdown is silent for screen readers (High, accessibility)

**Files**: `lib/features/booking/presentation/payment_return_screen.dart`
(`_DeadlineCountdownState.build`), `lib/features/bookings/presentation/widgets/booking_card.dart`.

**Problem**:
- In `_DeadlineCountdownState.build`, `ExcludeSemantics` wraps the `Semantics(label: …)` too, so
  the static label is removed as well and TalkBack/VoiceOver read nothing.
- In `BookingCard`, the ticking `CountdownText` sits inside the card's merged semantics, so
  under one hour the card's announcement changes every second.

**Required behaviour** (FR-038, Constitution VI: the countdown is announced once, not every tick):
- `payment_return_screen.dart`: the order must be
  `Semantics(label: <static deadline text>, child: ExcludeSemantics(child: CountdownText(...)))`.
  The static text should give the deadline in Cairo time, using `formatCairoDayMonthTime` from
  `lib/core/time/` together with an existing l10n key that fits (look for the
  `bookingMsgAwaitingOwner` / `ownerDeadline…` keys in `app_ar.arb`; add a new key only if none
  fits).
- `booking_card.dart`: wrap the `CountdownText` in `ExcludeSemantics`, and add the static
  deadline text (same format as above) to the card's `Semantics` label when the booking is
  awaiting the owner.
- Fix the claim in `docs/qa/g2-accessibility.md` §1, first row, so it describes the real code.

**Tests**: a widget test for each widget using `tester.getSemantics(...)` /
`find.bySemanticsLabel(...)`: the deadline label is found, and it does not change after
`tester.pump(const Duration(seconds: 2))` with less than one hour left.

---

## Fix 3 — Nothing refreshes when the owner's countdown reaches zero (High, FR-029)

**Spec**: FR-029 and the edge case "The countdown reaches zero while the screen is open: the
booking refreshes from the server instead of changing its status locally". No task in
`tasks.md` covered this.

**Files**: `lib/core/time/countdown.dart` (read only, do not change its contract),
`lib/features/bookings/presentation/widgets/booking_card.dart`,
`lib/features/bookings/presentation/bookings_screen.dart`,
`lib/features/bookings/presentation/booking_details_cubit.dart`.

**Required behaviour**:
- `BookingCard` gets an optional `VoidCallback? onDeadlineReached`. When the card's `Countdown`
  stream emits `Duration.zero` (or closes), call it once.
- `BookingsScreen` passes `onDeadlineReached: () => context.read<BookingsCubit>().refresh()`.
  Several cards reaching zero at the same moment must cause at most one request (use the
  cubit's existing in-flight / sequence handling, or debounce in the screen).
- `BookingDetailsCubit`: after a fresh `DetailsReady` whose status is `awaitingOwner` and whose
  `ownerResponseDeadline` is not null, start a single `Timer` that fires at the deadline plus
  5 seconds (use an injectable clock `DateTime Function() now`, default
  `() => DateTime.now().toUtc()`) and calls `refresh()`. Cancel and replace it on every load,
  cancel it in `close()`. If the deadline is already in the past, do not loop: refresh at most
  once per load.
- The app never changes the status itself; it only asks the server again.

**Tests**: `booking_details_cubit_test.dart` with `fakeAsync`: a booking awaiting the owner with
a deadline 10 s ahead → after 15 s exactly one extra `getBooking` call; after `close()` no call.
A widget test for `BookingCard` that `onDeadlineReached` is called once when the deadline
passes.

---

## Fix 4 — Choosing "Later" on the push sheet leaves no way to turn notifications on (High, FR-030)

**Files**: `lib/features/notifications/presentation/push_permission_coordinator.dart`,
`lib/features/notifications/presentation/notifications_screen.dart`.

**Problem**: the sheet sets the `push_permission_asked` flag for both "Enable" and "Later". The
"Notifications are off" notice in the center shows only when the system status is `denied`.
After "Later" the system status stays `notDetermined`, so the notice never shows. On iOS
the device settings have no notification switch before the app asks once, so the guest has no
way to turn notifications on.

**Required behaviour** (FR-030: "If the guest declines (in the app or at system level) … the
notification center MUST show a persistent 'Notifications are off' notice …"):
- Add to `PushPermissionCoordinator`:
  - `Future<bool> shouldShowOffNotice()` → true when the status is `denied`, or when the status
    is `notDetermined` **and** the asked flag is set.
  - `Future<void> enableFromNotice()` → when the status is `notDetermined`, call
    `_permission.request()` and, if granted, `_devices?.registerAfterSignIn()`; otherwise
    (`denied`) call `_permission.openSettings()`.
- `NotificationsScreen`: build the notice from `shouldShowOffNotice()` instead of
  `status() == denied`; the notice button calls `enableFromNotice()` and then re-checks; keep the
  existing re-check on app resume. The notice hides once permission is granted.
- The sheet itself must still never show a second time.

**Tests**: extend `push_permission_coordinator_test.dart` (both new methods, all three
statuses, flag set and unset) and `notifications_screen_test.dart` (notice visible after
"Later", tapping it calls `request()`; with `denied` it calls `openSettings()`; hidden when
`granted`).

---

## Fix 5 — Home "upcoming booking" card in mock mode (Medium, FR-026)

**Problem**: FR-026 says the Home upcoming-booking card shows the guest's nearest upcoming
confirmed booking from real booking data. No task covered it. In remote mode the card comes
from the server's home feed (`upcoming_booking`). In mock mode it comes from
`lib/features/listings/data/fixtures/home_feed.json`, where `upcoming_booking.item` is `null`,
so the mock never shows the confirmed booking that exists in the bookings fixtures.

**Required behaviour**:
- Mock mode only; do not touch the remote path.
- In `lib/bootstrap.dart` `_mockBackend`, wrap the listings mock in a small decorator (new file
  `lib/features/bookings/data/mock_home_feed_with_bookings.dart`) that implements
  `ListingsRepository`, delegates every method to the wrapped repository, and overrides
  `homeFeed()` to fill `upcomingBooking` from `MockBookingServer`: the first booking of
  `listBookings(BookingTab.current)` whose status is `confirmed` or `checked_in` (the server
  order is already nearest first), mapped to `UpcomingBookingCard` (`bookingId`,
  `propertyTitle`, `checkIn`, `checkOut`, `status` wire string). None → `FeedSectionReady(null)`.
  Note that `MockBookingServer` needs the listings repository, so construct the server with the
  raw listings mock and give the decorator to everyone else.
- Tapping the card already opens `/bookings/<id>`; check it still does.

**Tests**: a unit test for the decorator (confirmed fixture → card with that id; no confirmed
booking → null) and update the Home goldens only if they change, saying so.

---

## Fix 6 — Booking details: a failed refresh hides the saved copy; stale data after "not found" (Medium)

**File**: `lib/features/bookings/presentation/booking_details_cubit.dart`,
`lib/features/bookings/data/bookings_cache.dart`.

**Required behaviour** (FR-024, FR-025, FR-024a):
- When a cached `DetailsReady(fromCache: true)` is already shown and the fetch fails with an
  error other than `notFound`, keep showing the cached state (do not emit `DetailsFailed`).
  Emit `DetailsFailed` only when nothing was shown from the cache.
- On `notFound`: add `Future<void> removeDetails(String id)` to `BookingsCache`, call it, also
  call `_arrival.remove(bookingId)`, then emit `DetailsNotAvailable`.

**Tests**: in `booking_details_cubit_test.dart`: cache + network error → stays `DetailsReady`
from cache; cache + not found → `DetailsNotAvailable`, `readDetails(id)` is null and the
arrival instructions are gone. Add a `BookingsCache.removeDetails` case to
`test/core/storage/secure_stores_test.dart`.

---

## Fix 7 — Verification polling: signals reset the backoff and can be lost (Medium, FR-013 / SC-005)

**File**: `lib/features/booking/presentation/payment_verification_cubit.dart`.

**Problem**:
- A fetch triggered by a notification signal calls `_scheduleNextPoll()`, which cancels and
  restarts the poll timer at the same backoff step, so every signal pushes the timeout further
  away.
- A signal that arrives while a fetch is running is dropped (`_fetching` guard). The running
  fetch may have read the old status, so the result then waits up to 30 s for the next poll.

**Required behaviour**:
- Only poll-triggered fetches (and the first fetch from `start()`) schedule the next poll. A
  signal-triggered fetch that still finds `waiting` leaves the current poll timer as it is.
- If a signal arrives during a fetch, remember it (`_refetchRequested = true`) and run one more
  fetch right after the current one finishes.
- The total waiting time stays the backoff sum (about two minutes).

**Tests** in `payment_verification_cubit_test.dart` (`fakeAsync`): signals at 1 s and 3 s do not
move the timeout (still at 120 s); a signal during an in-flight fetch leads to one extra fetch
right after it.

---

## Fix 8 — Old quote and "amounts changed" survive a change of dates or guests (Medium)

**File**: `lib/features/booking/presentation/booking_flow_cubit.dart`.

**Problem**: `tasks.md` T048 says `setStay` and `setGuests` clear the quote, but `copyWith`
cannot set `quote` to null, so the old quote stays and its expiry timer keeps running. When it
fires, `refreshQuote()` compares a quote for the old dates with one for the new dates and sets
`pendingChange` by mistake. `requestQuote()` also does not clear `pendingChange`.

**Required behaviour**:
- Change `copyWith`'s `quote` parameter to the `Object? quote = _unset` sentinel pattern (like
  `error`).
- `setStay` and `setGuests`: clear `quote`, `pendingChange`, and `error`, and cancel
  `_expiryTimer`.
- `requestQuote()` success: set the new quote and clear `pendingChange`.

**Tests** in `booking_flow_cubit_test.dart` and `booking_flow_interruptions_test.dart`:
after `setStay(other)` the quote is null and no refresh fires at the old expiry; after a new
`requestQuote()` `pendingChange` is null.

---

## Fix 9 — Summary: "apartment no longer available" and rate limit at payment start (Low)

**File**: `lib/features/booking/presentation/summary_screen.dart` (`_PayBar`).

**Required behaviour**:
- `AttemptFailed` with `ErrorCode.propertyNotAvailable` (spec edge case, AC-003): instead of a
  SnackBar, replace the summary body with
  `EmptyView(icon: Icons.home_outlined, message: l10n.propertyNotAvailable, action: OnAirPrimaryButton(label: l10n.bookingsFindApartment, onPressed: () => context.go(AppRoutes.search)))`
  (check that these keys and the `EmptyView` `action` parameter exist; reuse what
  `bookings_screen.dart` already does for its empty tabs).
- `AttemptFailed` with `ErrorCode.rateLimited` and a non-null `retryAfter`: keep the SnackBar,
  and keep the pay button disabled until `retryAfter` has passed (turn `_PayBar` into a
  `StatefulWidget` with a `Timer`, cancelled in `dispose`).

**Tests** in `summary_interruptions_test.dart`: both cases.

---

## Not part of this prompt (do not do these)

- **Backend contract deltas D0–D4** (`contracts/supabase-booking.md` §4): they live in
  `D:\flutter\onair-backend` and are done by the backend owner. Do not touch the backend.
- **"One email code" for email + phone** (FR-002 says one 6-digit code; `tasks.md` T059 built two
  separate steps). This is a product decision; leave the current flow as it is.
- Instruction purge from the list refresh (only the details refresh removes arrival
  instructions today). Leave as is unless asked.

## Final report

When done, reply with: the list of fixes with their commit hashes, the tests added or changed,
the output of each final gate, and anything you could not finish and why.
