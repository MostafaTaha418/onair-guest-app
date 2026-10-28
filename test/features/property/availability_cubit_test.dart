import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/property/presentation/availability_cubit.dart';

import '../../helpers/fake_listings_repository.dart';

int _monthKey(int year, int month) => year * 12 + month;

void main() {
  late FakeListingsRepository listings;
  final confirmed = <StayRange>[];

  setUp(() {
    listings = FakeListingsRepository();
    confirmed.clear();
  });

  AvailabilityCubit buildCubit() => AvailabilityCubit(
    repo: listings,
    propertyId: 'p1',
    today: () => DateOnly(2026, 11, 1),
    onStayConfirmed: confirmed.add,
  );

  test('showMonth loads a 3-month window once', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);

    await cubit.showMonth(DateOnly(2026, 11, 1));

    final windowCalls = listings.calls
        .where((call) => call.startsWith('unavailableNights'))
        .toList();
    expect(windowCalls, hasLength(1));
    expect(windowCalls.single, contains('2026-11-01'));
    expect(windowCalls.single, contains('2027-02-01'));

    await cubit.showMonth(DateOnly(2026, 11, 1));
    expect(
      listings.calls.where((call) => call.startsWith('unavailableNights')),
      hasLength(1),
      reason: 'already-loaded months are never fetched again',
    );
  });

  test('a shifted month fetches only the months not loaded yet', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);

    await cubit.showMonth(DateOnly(2026, 11, 1));
    await cubit.showMonth(DateOnly(2026, 12, 1));

    final windowCalls = listings.calls
        .where((call) => call.startsWith('unavailableNights'))
        .toList();
    expect(windowCalls, hasLength(2));
    expect(windowCalls.last, contains('2027-02-01'));
    expect(windowCalls.last, contains('2027-03-01'));
  });

  test('month keys are marked loading while the window runs', () async {
    final completer = Completer<Set<DateOnly>>();
    listings.unavailableNightsResponses.add(completer.future);
    final cubit = buildCubit();
    addTearDown(cubit.close);

    final pending = cubit.showMonth(DateOnly(2026, 11, 1));
    expect(cubit.state.loading, {
      _monthKey(2026, 11),
      _monthKey(2026, 12),
      _monthKey(2027, 1),
    });

    completer.complete({});
    await pending;
    expect(cubit.state.loading, isEmpty);
  });

  test('a valid range is emitted and confirmed', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await cubit.showMonth(DateOnly(2026, 11, 1));

    cubit
      ..onDayTap(DateOnly(2026, 11, 10))
      ..onDayTap(DateOnly(2026, 11, 12));

    expect(
      cubit.state.selection,
      CalendarRange(
        StayRange(
          DateOnly(2026, 11, 10),
          DateOnly(2026, 11, 12),
        ),
      ),
    );

    cubit.confirm();
    expect(confirmed, hasLength(1));
    expect(
      confirmed.single,
      StayRange(DateOnly(2026, 11, 10), DateOnly(2026, 11, 12)),
    );
  });

  test(
    'a range crossing an unavailable night is rejected and restarts',
    () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      listings.unavailableNightsResponses.add({
        DateOnly(2026, 11, 15),
      });
      await cubit.showMonth(DateOnly(2026, 11, 1));

      cubit
        ..onDayTap(DateOnly(2026, 11, 10))
        ..onDayTap(DateOnly(2026, 11, 20));

      expect(cubit.state.rangeRejected, isTrue);
      expect(
        cubit.state.selection,
        CalendarArrivalPicked(DateOnly(2026, 11, 20)),
      );

      // The next tap from the restarted arrival is free to form a range.
      cubit.onDayTap(DateOnly(2026, 11, 25));
      expect(cubit.state.rangeRejected, isFalse);
    },
  );

  test('a tap on or before the arrival restarts the selection', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await cubit.showMonth(DateOnly(2026, 11, 1));

    cubit.onDayTap(DateOnly(2026, 11, 10));
    expect(
      cubit.state.selection,
      CalendarArrivalPicked(DateOnly(2026, 11, 10)),
    );

    cubit.onDayTap(DateOnly(2026, 11, 8));
    expect(cubit.state.selection, CalendarArrivalPicked(DateOnly(2026, 11, 8)));

    cubit.onDayTap(DateOnly(2026, 11, 12));
    expect(
      cubit.state.selection,
      CalendarRange(StayRange(DateOnly(2026, 11, 8), DateOnly(2026, 11, 12))),
    );
  });

  test(
    'a failed window keeps the months greyed and retryMonth refetches',
    () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      listings.unavailableNightsResponses.add(
        AppFailure(ErrorMapper.noResponse()),
      );

      await cubit.showMonth(DateOnly(2026, 11, 1));

      expect(cubit.state.failed, {
        _monthKey(2026, 11),
        _monthKey(2026, 12),
        _monthKey(2027, 1),
      });
      expect(cubit.state.windows, isEmpty);

      listings.unavailableNightsResponses.add(const <DateOnly>{});
      await cubit.retryMonth(DateOnly(2026, 11, 1));

      expect(cubit.state.failed, isEmpty);
      expect(cubit.state.windows, isNotEmpty);
    },
  );
}
