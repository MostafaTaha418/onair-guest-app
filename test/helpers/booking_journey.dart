import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/design_system/components/range_calendar.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/booking/presentation/dates_screen.dart';
import 'package:on_air/features/booking/presentation/payment_verification_cubit.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/mock_listings_repository.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/notifications/presentation/push_permission_coordinator.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_booking_backend.dart';
import 'pump_until_found.dart';
import 'register_mock_guest.dart';

/// The T101 payment journey in mock mode (US1 + US6): pay → success, pay →
/// fail → «Try again», pay → the server never answers → timeout → My
/// Bookings, then a restart rebuilds the app on the same secure store and
/// the unfinished-payment banner comes back.
///
/// Runs on the host in `test/features/journey/booking_journey_test.dart` and
/// on a device through `integration_test/booking_journey_mock_test.dart`.
Future<void> runPaymentJourney(WidgetTester tester) async {
  final l10n = lookupAppLocalizations(const Locale('ar'));
  if (TestWidgetsFlutterBinding.instance
      is AutomatedTestWidgetsFlutterBinding) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  CairoTime.initialize();
  SharedPreferences.setMockInitialValues({});

  // One backend across the whole scenario — the «restart» reuses the same
  // stores, which is exactly what survives a real process kill.
  final backend = FakeBookingBackend();
  addTearDown(backend.dispose);
  final auth = MockAuthRepository();
  addTearDown(auth.dispose);

  // 1. Boot, sign in, open the first apartment.
  await bootApp(tester, backend, auth);
  final apartmentTitle = await openFirstApartmentAndSignIn(
    tester,
    l10n,
    firstSignIn: true,
  );

  // 2. Pick three nights and pay with the mock «Succeed».
  await pickThreeNights(tester, l10n);
  await tester.tap(find.byKey(const ValueKey('dates-continue')));
  await _pumpUntilVisible(
    tester,
    find.byKey(const ValueKey('summary-pay')),
  );
  await tester.tap(find.byKey(const ValueKey('summary-pay')));
  await _pumpUntilVisible(
    tester,
    find.byKey(const ValueKey('mock-pay-success')),
  );
  await tester.tap(find.byKey(const ValueKey('mock-pay-success')));
  // The mock server applies the outcome, then signals after 2 s.
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text(l10n.paymentSuccessTitle), findsOneWidget);
  // The success page may still be sliding in; a tap during the transition
  // is absorbed (IgnorePointer) and misses the button on slower runners.
  await tester.pump(const Duration(seconds: 1));

  // 3. A second journey: pay with «Fail», then «Try again» returns to the
  // dates step carrying the same stay.
  await tester.tap(find.byKey(const ValueKey('return-view-booking')));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(AppRoutes.home);
  await tester.pumpAndSettle();
  await openFirstApartmentAndSignIn(tester, l10n, firstSignIn: false);
  await pickThreeNights(tester, l10n);
  await tester.tap(find.byKey(const ValueKey('dates-continue')));
  await _pumpUntilVisible(
    tester,
    find.byKey(const ValueKey('summary-pay')),
  );
  await tester.tap(find.byKey(const ValueKey('summary-pay')));
  await _pumpUntilVisible(
    tester,
    find.byKey(const ValueKey('mock-pay-failure')),
  );
  await tester.tap(find.byKey(const ValueKey('mock-pay-failure')));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text(l10n.paymentFailedTitle), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('return-try-again')));
  await _pumpUntilVisible(tester, find.byType(DatesScreen));
  // On device, restoring the stay into the dates screen lands after the
  // first frames of the route.
  for (
    var attempt = 0;
    attempt < 40 && !tester.any(find.text(l10n.bookingNightsCount('3')));
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(find.text(l10n.bookingNightsCount('3')), findsOneWidget);

  // 4. «Never answer»: the shortened backoff runs out and the timeout view
  // sends the guest to My Bookings, where the booking is under Current.
  await tester.tap(find.byKey(const ValueKey('dates-continue')));
  await _pumpUntilVisible(
    tester,
    find.byKey(const ValueKey('summary-pay')),
  );
  await tester.tap(find.byKey(const ValueKey('summary-pay')));
  await _pumpUntilVisible(
    tester,
    find.byKey(const ValueKey('mock-pay-silent')),
  );
  await tester.tap(find.byKey(const ValueKey('mock-pay-silent')));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  expect(find.text(l10n.paymentTimeoutTitle), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('return-go-bookings')));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  // Both earlier bookings for the apartment sit under Current (awaiting
  // owner + verifying), so at least one card carries the title.
  expect(find.text(apartmentTitle), findsWidgets);

  // 5. Restart on the same stores: after signing in again the
  // unfinished-payment banner waits on Home.
  await bootApp(tester, backend, auth);
  await openFirstApartmentAndSignIn(tester, l10n, firstSignIn: false);
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(AppRoutes.home);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text(l10n.unfinishedPaymentBanner), findsOneWidget);
}

/// Waits for a specific screen state without requiring the whole app to have
/// no scheduled frames. Real device plugins (such as the SMS consent reader)
/// can keep scheduling frames after navigation has completed.
Future<void> _pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40 && !tester.any(finder); attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsOneWidget);
}

Future<void> bootApp(
  WidgetTester tester,
  FakeBookingBackend backend,
  MockAuthRepository auth,
) async {
  // A process restart must dispose the old router; replacing providers under
  // the same OnAirApp widget would preserve its current tab and auth state.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  final listings =
      TestWidgetsFlutterBinding.instance is AutomatedTestWidgetsFlutterBinding
      ? MockListingsRepository(
          loader: (path) async => File(path).readAsStringSync(),
        )
      : MockListingsRepository();
  final directory = Directory.systemTemp.createTempSync('on_air_journey');
  addTearDown(() => directory.deleteSync(recursive: true));
  final cache = JsonFileCache(
    directory: directory,
    fileName: 'discovery_cache.json',
    schema: 1,
  );
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppConfigSource>.value(
          value: const MockAppConfigSource(),
        ),
        RepositoryProvider<AuthRepository>.value(value: auth),
        RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
        RepositoryProvider<ListingsRepository>.value(value: listings),
        RepositoryProvider<JsonFileCache>.value(value: cache),
        RepositoryProvider<ReferenceDataCache>.value(
          value: ReferenceDataCache(listings, cache),
        ),
        RepositoryProvider<HomeFeedCache>.value(value: HomeFeedCache(cache)),
        RepositoryProvider<LastSearchStore>.value(value: LastSearchStore()),
        RepositoryProvider<NotificationSignalSource>.value(
          value: backend.signals,
        ),
        RepositoryProvider<NotificationPermission>.value(
          value: FakeNotificationPermission(),
        ),
        // The notifications tab needs the push coordinator even when the
        // journey never answers a permission ask.
        RepositoryProvider<PushPermissionCoordinator>.value(
          value: PushPermissionCoordinator(
            permission: FakeNotificationPermission(),
            devices: null,
          ),
        ),
        // Test-only: the «never answers» journey reaches the timeout fast.
        RepositoryProvider<PaymentVerificationBackoff>.value(
          value: const PaymentVerificationBackoff([
            Duration(milliseconds: 200),
            Duration(milliseconds: 200),
          ]),
        ),
        ...backend.appProviders(),
      ],
      child: const OnAirApp(),
    ),
  );
  await tester.pumpAndSettle();
}

String _firstCardTitle(WidgetTester tester) =>
    tester.widget<PropertyCard>(find.byType(PropertyCard).first).title;

/// Search → first result → «Book now», and — when the guest is signed out —
/// the mock sign-in (the first sign-in also completes the fresh profile).
/// Returns the apartment's title.
Future<String> openFirstApartmentAndSignIn(
  WidgetTester tester,
  AppLocalizations l10n, {
  required bool firstSignIn,
}) async {
  await tester.tap(find.byKey(const ValueKey('home-search-box')));
  await tester.pumpAndSettle();
  // Search needs criteria: pick the three nights on the search date sheet
  // the first time; the search branch keeps its criteria afterwards, so a
  // repeat visit goes straight to the results.
  if (tester.any(find.text(l10n.searchDatesHint))) {
    await tester.tap(find.text(l10n.searchDatesHint));
    await tester.pumpAndSettle();
    await pickThreeNights(tester, l10n);
    await tester.tap(find.text(l10n.calendarConfirm));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(l10n.searchAction));
  await tester.pumpAndSettle();
  // A cold restart recreates the file-backed listings repository. On slower
  // iOS runners, loading and decoding the fixtures can outlive the usual
  // ten-second device wait even though the search is still progressing.
  await pumpUntilFound(
    tester,
    find.byType(PropertyCard),
    maxAttempts: 120,
  );
  final apartmentTitle = _firstCardTitle(tester);
  await tester.tap(find.byType(PropertyCard).first);
  await tester.pumpAndSettle();
  // On device, loading fixture assets can finish after the navigation frame.
  for (
    var attempt = 0;
    attempt < 40 && !tester.any(find.text(l10n.bookNow));
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(find.text(l10n.bookNow), findsOneWidget);
  await tester.tap(find.text(l10n.bookNow));
  await tester.pumpAndSettle();
  if (firstSignIn) {
    await registerMockGuest(tester, l10n);
  }
  // On device, the dates route push waits on the real secure-storage write
  // that completes the sign-in, which outlasts pumpAndSettle.
  for (
    var attempt = 0;
    attempt < 40 && !tester.any(find.byType(DatesScreen));
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(find.byType(DatesScreen), findsOneWidget);
  return apartmentTitle;
}

/// Three nights from today on the dates screen calendar.
Future<void> pickThreeNights(WidgetTester tester, AppLocalizations l10n) async {
  // The dates route can render its loading skeleton while device assets load.
  for (
    var attempt = 0;
    attempt < 40 && !tester.any(find.byType(RangeCalendar));
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(find.byType(RangeCalendar), findsOneWidget);
  final today = CairoTime.today();
  final checkIn = today.addDays(3);
  final checkOut = today.addDays(6);
  var displayedMonth = DateOnly(today.year, today.month, 1);
  while (displayedMonth.year != checkIn.year ||
      displayedMonth.month != checkIn.month) {
    await tester.tap(find.byTooltip(l10n.calendarNextMonth));
    await tester.pumpAndSettle();
    final shifted = displayedMonth.addDays(32);
    displayedMonth = DateOnly(shifted.year, shifted.month, 1);
  }
  Finder calendarDay(int day) => find.descendant(
    of: find.byType(RangeCalendar),
    matching: find.text('$day'),
  );
  await tester.tap(calendarDay(checkIn.day));
  await tester.pumpAndSettle();
  await tester.tap(calendarDay(checkOut.day));
  await tester.pumpAndSettle();
  await tester.pumpAndSettle();
}
