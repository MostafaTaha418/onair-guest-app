import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/components/range_calendar.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('ar'));

Future<void> pumpCalendar(
  WidgetTester tester, {
  required DateOnly today,
  required DateOnly initialMonth,
  required void Function(DateOnly day) onDayTap,
  DateOnly? selectedCheckIn,
  DateOnly? selectedCheckOut,
  Set<DateOnly> unavailableNights = const {},
  void Function(DateOnly firstDayOfMonth)? onMonthShown,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: OnAirTheme.light,
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: 360,
            child: RangeCalendar(
              today: today,
              initialMonth: initialMonth,
              selectedCheckIn: selectedCheckIn,
              selectedCheckOut: selectedCheckOut,
              unavailableNights: unavailableNights,
              onDayTap: onDayTap,
              onMonthShown: onMonthShown,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  testWidgets('Saturday is the first column of the grid', (tester) async {
    await pumpCalendar(
      tester,
      today: DateOnly(2026, 11, 10),
      initialMonth: DateOnly(2026, 11, 1),
      onDayTap: (_) {},
    );
    // November 2026: the 7th is a Saturday, the 6th a Friday. In RTL the
    // first column sits at the right, so Saturday's x is the larger one.
    final saturday = tester.getRect(find.text('7'));
    final friday = tester.getRect(find.text('6'));
    expect(saturday.left, greaterThan(friday.left));

    // The weekday header starts with السبت.
    expect(find.text('السبت'), findsOneWidget);
  });

  testWidgets('a past day does not call onDayTap', (tester) async {
    final tapped = <DateOnly>[];
    await pumpCalendar(
      tester,
      today: DateOnly(2026, 11, 10),
      initialMonth: DateOnly(2026, 11, 1),
      onDayTap: tapped.add,
    );
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(tapped, isEmpty);

    await tester.tap(find.text('12'));
    await tester.pump();
    expect(tapped, [DateOnly(2026, 11, 12)]);
  });

  testWidgets('changing month calls onMonthShown', (tester) async {
    final shown = <DateOnly>[];
    await pumpCalendar(
      tester,
      today: DateOnly(2026, 11, 10),
      initialMonth: DateOnly(2026, 11, 1),
      onDayTap: (_) {},
      onMonthShown: shown.add,
    );
    expect(shown, [DateOnly(2026, 11, 1)]);

    await tester.tap(find.byTooltip(l10n.calendarNextMonth));
    await tester.pump();
    expect(shown.last, DateOnly(2026, 12, 1));
    expect(find.textContaining('ديسمبر'), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.calendarPrevMonth));
    await tester.pump();
    expect(shown.last, DateOnly(2026, 11, 1));
  });

  testWidgets('the previous button is disabled on the current month', (
    tester,
  ) async {
    await pumpCalendar(
      tester,
      today: DateOnly(2026, 11, 10),
      initialMonth: DateOnly(2026, 11, 1),
      onDayTap: (_) {},
    );
    final button = tester.widget<IconButton>(
      find
          .ancestor(
            of: find.byTooltip(l10n.calendarPrevMonth),
            matching: find.byType(IconButton),
          )
          .first,
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('unavailable days carry the unavailable semantics', (
    tester,
  ) async {
    await pumpCalendar(
      tester,
      today: DateOnly(2026, 11, 10),
      initialMonth: DateOnly(2026, 11, 1),
      unavailableNights: {DateOnly(2026, 11, 20)},
      onDayTap: (_) {},
    );
    expect(find.text('20'), findsOneWidget);
    final semantics = tester.getSemantics(find.text('20'));
    expect(
      semantics.label,
      l10n.calendarUnavailableDay('20 نوفمبر'),
    );
  });

  testWidgets('a selected range is highlighted', (tester) async {
    await pumpCalendar(
      tester,
      today: DateOnly(2026, 11, 10),
      initialMonth: DateOnly(2026, 11, 1),
      selectedCheckIn: DateOnly(2026, 11, 20),
      selectedCheckOut: DateOnly(2026, 11, 23),
      onDayTap: (_) {},
    );
    // Endpoints are selected; middle days are in range but not "selected".
    Tristate selectedAt(String day) =>
        tester.getSemantics(find.text(day)).flagsCollection.isSelected;
    expect(selectedAt('20'), Tristate.isTrue);
    expect(selectedAt('23'), Tristate.isTrue);
    expect(selectedAt('21'), isNot(Tristate.isTrue));
  });
}
