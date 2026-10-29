import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/mock_listings_repository.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The SC-007 visitor-resume journey (T095), shared by the host widget test
/// and the `integration_test/discovery_journey_test.dart` device run: mock
/// mode end to end, from search to the booking entry and back.
Future<void> runVisitorBookingJourney(WidgetTester tester) async {
  CairoTime.initialize();
  SharedPreferences.setMockInitialValues({});
  final l10n = lookupAppLocalizations(const Locale('ar'));
  // Sync IO: async dart:io futures never complete under the fake async
  // zone of a host widget test.
  final directory = Directory.systemTemp.createTempSync('on_air_journey');
  if (TestWidgetsFlutterBinding.instance
      is AutomatedTestWidgetsFlutterBinding) {
    // The host window is 800x600; a taller surface keeps the whole date
    // sheet on screen. Device runs keep their real window.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  addTearDown(() => directory.deleteSync(recursive: true));
  final cache = JsonFileCache(
    directory: directory,
    fileName: 'discovery_cache.json',
    schema: 1,
  );
  // On the host, rootBundle never completes under the fake async zone —
  // read the fixture files directly (the same reason T027 added `loader`).
  final listings =
      TestWidgetsFlutterBinding.instance is AutomatedTestWidgetsFlutterBinding
      ? MockListingsRepository(
          loader: (path) async => File(path).readAsStringSync(),
        )
      : MockListingsRepository();
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
        RepositoryProvider<HomeFeedCache>.value(
          value: HomeFeedCache(cache),
        ),
        RepositoryProvider<LastSearchStore>.value(value: LastSearchStore()),
      ],
      child: const OnAirApp(),
    ),
  );
  await tester.pumpAndSettle();

  // 1–2. Open Search, pick 2 guests.
  await tester.tap(find.byKey(const ValueKey('nav-search')));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip(l10n.guestsIncrease));
  await tester.pumpAndSettle();

  // 3. Choose dates three nights from today.
  final today = CairoTime.today();
  final checkIn = today.addDays(3);
  final checkOut = today.addDays(6);
  await tester.tap(find.text(l10n.searchDatesHint));
  await tester.pumpAndSettle();
  var displayedMonth = DateOnly(today.year, today.month, 1);
  while (displayedMonth.year != checkIn.year ||
      displayedMonth.month != checkIn.month) {
    await tester.tap(find.byTooltip(l10n.calendarNextMonth));
    await tester.pumpAndSettle();
    final shifted = displayedMonth.addDays(32);
    displayedMonth = DateOnly(shifted.year, shifted.month, 1);
  }
  await tester.tap(find.text('${checkIn.day}'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('${checkOut.day}'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.calendarConfirm));
  await tester.pumpAndSettle();

  // 4. Search.
  await tester.tap(find.text(l10n.searchAction));
  await tester.pumpAndSettle();

  // 5. Open the first result and remember its title.
  await tester.pumpAndSettle();
  final firstCard = find.byType(PropertyCard).first;
  final apartmentTitle = tester
      .widget<Text>(
        find.descendant(of: firstCard, matching: find.byType(Text)).first,
      )
      .data!;
  await tester.tap(firstCard);
  await tester.pumpAndSettle();
  expect(find.text(apartmentTitle), findsOneWidget);

  // 6–7. «احجز الآن» as a visitor → mock sign-in (code 123456) →
  // complete the profile → the resume forwards to the booking entry.
  await tester.tap(find.text(l10n.bookNow));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('phone-field')), findsOneWidget);
  // The phone tab hosts the only TextField on the login screen. The pump
  // rebuilds the submit button, which was disabled with the empty field.
  await tester.enterText(find.byType(TextField), '01012345678');
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('send-code-button')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), MockBackend.verificationCode);
  await tester.pump();
  await tester.pumpAndSettle();
  // A fresh mock account is incomplete: finish the profile first.
  await tester.enterText(find.byType(TextField), 'زائر تجريبي');
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('terms-checkbox')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('complete-profile-button')));
  await tester.pumpAndSettle();
  // 8. The booking placeholder carries the same dates and guests.
  expect(find.text(l10n.bookingEntryComingSoon), findsOneWidget);
  expect(
    find.textContaining(DateOnlyFormatter.dayMonth(checkIn)),
    findsOneWidget,
  );
  expect(
    find.textContaining(DateOnlyFormatter.dayMonth(checkOut)),
    findsOneWidget,
  );
  expect(
    find.textContaining('${l10n.searchGuestsLabel}: 2'),
    findsOneWidget,
  );
  expect(find.text(l10n.bookingEntryTermsCarried), findsOneWidget);

  // 9. Back to the apartment, sign out, and repeat as a visitor:
  // cancelling sign-in returns to the same apartment (FR-029).
  await tester.tap(find.byType(BackButton).first);
  await tester.pumpAndSettle();
  expect(find.text(apartmentTitle), findsOneWidget);

  // The sign-in navigation replaced the stack, so the shell tabs are gone;
  // reach the account screen through the router to sign out.
  GoRouter.of(tester.element(find.text(apartmentTitle))).go('/account');
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('sign-out-button')));
  await tester.pumpAndSettle();
  // A members-only route ends the session straight into sign-in;
  // cancelling lands on home (resolveAuthCancelDestination).
  final closeButton = find.byKey(const ValueKey('close-login-button'));
  if (tester.any(closeButton)) {
    await tester.tap(closeButton);
    await tester.pumpAndSettle();
  }

  // The Search branch form kept the criteria (guests 2 + dates), so the
  // same first result comes back.
  await tester.tap(find.byKey(const ValueKey('nav-search')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.searchAction));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(PropertyCard).first);
  await tester.pumpAndSettle();
  expect(find.text(apartmentTitle), findsOneWidget);

  await tester.tap(find.text(l10n.bookNow));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('phone-field')), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('close-login-button')));
  await tester.pumpAndSettle();
  expect(find.text(apartmentTitle), findsOneWidget);
}
