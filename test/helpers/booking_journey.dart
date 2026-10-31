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
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_booking_backend.dart';

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

  // 1. Boot, sign in, open the first apartment.
  await bootApp(tester, backend);
  final apartmentTitle = await openFirstApartmentAndSignIn(
    tester,
    l10n,
    firstSignIn: true,
  );

  // 2. Pick three nights and pay with the mock «Succeed».
  await pickThreeNights(tester, l10n);
  await tester.tap(find.byKey(const ValueKey('dates-continue')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('summary-pay')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('mock-pay-success')), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('mock-pay-success')));
  // The mock server applies the outcome, then signals after 2 s.
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text(l10n.paymentSuccessTitle), findsOneWidget);

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
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('summary-pay')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('mock-pay-failure')));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text(l10n.paymentFailedTitle), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('return-try-again')));
  await tester.pumpAndSettle();
  expect(find.byType(DatesScreen), findsOneWidget);
  expect(find.text(l10n.bookingNightsCount('3')), findsOneWidget);

  // 4. «Never answer»: the shortened backoff runs out and the timeout view
  // sends the guest to My Bookings, where the booking is under Current.
  await tester.tap(find.byKey(const ValueKey('dates-continue')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('summary-pay')));
  await tester.pumpAndSettle();
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
  await bootApp(tester, backend);
  await openFirstApartmentAndSignIn(tester, l10n, firstSignIn: false);
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(AppRoutes.home);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text(l10n.unfinishedPaymentBanner), findsOneWidget);
}

Future<void> bootApp(WidgetTester tester, FakeBookingBackend backend) async {
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
  final auth = MockAuthRepository();
  addTearDown(auth.dispose);

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

String _firstCardTitle(WidgetTester tester) => tester
    .widget<Text>(
      find
          .descendant(
            of: find.byType(PropertyCard).first,
            matching: find.byType(Text),
          )
          .first,
    )
    .data!;

/// Search → first result → «Book now», and — when the guest is signed out —
/// the mock sign-in (the first sign-in also completes the fresh profile).
/// Returns the apartment's title.
Future<String> openFirstApartmentAndSignIn(
  WidgetTester tester,
  AppLocalizations l10n, {
  required bool firstSignIn,
}) async {
  await tester.tap(find.byKey(const ValueKey('nav-search')));
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
  await tester.pumpAndSettle();
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
    expect(find.byKey(const ValueKey('phone-field')), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('phone-field')),
        matching: find.byType(TextField),
      ),
      '01012345678',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-code-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      MockBackend.verificationCode,
    );
    await tester.pump();
    await tester.pumpAndSettle();
    // A fresh mock account is incomplete: finish the profile first.
    await tester.enterText(find.byType(TextField), 'زائر تجريبي');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('terms-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('complete-profile-button')));
    await tester.pumpAndSettle();
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
