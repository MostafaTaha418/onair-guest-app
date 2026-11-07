import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/design_system/components/range_calendar.dart';
import 'package:on_air/features/booking/presentation/dates_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import 'mock_app.dart';
import 'pump_until_found.dart';
import 'register_mock_guest.dart';

/// The SC-007 visitor-resume journey (T095), shared by the host widget test
/// and the `integration_test/discovery_journey_test.dart` device run: mock
/// mode end to end, from search to the booking entry and back.
Future<void> runVisitorBookingJourney(WidgetTester tester) async {
  final l10n = lookupAppLocalizations(const Locale('ar'));
  if (TestWidgetsFlutterBinding.instance
      is AutomatedTestWidgetsFlutterBinding) {
    // The host window is 800x600; a taller surface keeps the whole date
    // sheet on screen. Device runs keep their real window.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await bootMockApp(tester);

  // 1–2. Open Search, pick 2 guests.
  await tester.tap(find.byKey(const ValueKey('home-search-box')));
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
  // Scope the day numbers to the calendar: a single-digit day otherwise
  // collides with the guests stepper's «2» and similar labels on screen.
  Finder calendarDay(int day) => find.descendant(
    of: find.byType(RangeCalendar),
    matching: find.text('$day'),
  );
  await tester.tap(calendarDay(checkIn.day));
  await tester.pumpAndSettle();
  await tester.tap(calendarDay(checkOut.day));
  await tester.pumpAndSettle();
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.calendarConfirm));
  await tester.pumpAndSettle();

  // 4. Search.
  await tester.tap(find.text(l10n.searchAction));
  await tester.pumpAndSettle();

  // 5. Open the first result and remember its title.
  await pumpUntilFound(tester, find.byType(PropertyCard));
  final firstCard = find.byType(PropertyCard).first;
  final apartmentTitle = tester.widget<PropertyCard>(firstCard).title;
  await tester.tap(firstCard);
  await pumpUntilFound(tester, find.text(l10n.bookNow));
  expect(find.text(apartmentTitle), findsOneWidget);

  // 6–7. «احجز الآن» as a visitor → email registration → booking entry.
  await tester.tap(find.text(l10n.bookNow));
  await tester.pumpAndSettle();
  await registerMockGuest(tester, l10n);
  await pumpUntilFound(tester, find.byType(DatesScreen));
  // 8. The date step starts empty even though the search carried a stay:
  // the guest re-picks the same range on the availability container.
  expect(find.text(l10n.bookingNightsCount('3')), findsNothing);
  displayedMonth = DateOnly(today.year, today.month, 1);
  while (displayedMonth.year != checkIn.year ||
      displayedMonth.month != checkIn.month) {
    await tester.tap(find.byTooltip(l10n.calendarNextMonth));
    await tester.pumpAndSettle();
    final shifted = displayedMonth.addDays(32);
    displayedMonth = DateOnly(shifted.year, shifted.month, 1);
  }
  await tester.tap(calendarDay(checkIn.day));
  await tester.pumpAndSettle();
  await tester.tap(calendarDay(checkOut.day));
  await tester.pumpAndSettle();
  await tester.pumpAndSettle();
  expect(find.byType(DatesScreen), findsOneWidget);
  expect(find.text(l10n.bookingNightsCount('3')), findsOneWidget);

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
  await tester.tap(find.byKey(const ValueKey('home-search-box')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.searchAction));
  await pumpUntilFound(tester, find.byType(PropertyCard));
  await tester.tap(find.byType(PropertyCard).first);
  await pumpUntilFound(tester, find.text(l10n.bookNow));
  expect(find.text(apartmentTitle), findsOneWidget);

  await tester.ensureVisible(find.text(l10n.bookNow));
  await tester.tap(find.text(l10n.bookNow));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('close-login-button')));
  await tester.pumpAndSettle();
  expect(find.text(apartmentTitle), findsOneWidget);
}
