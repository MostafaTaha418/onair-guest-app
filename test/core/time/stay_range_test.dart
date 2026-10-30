import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';

void main() {
  final today = DateOnly(2026, 11, 1);

  group('StayRange.tryCreate', () {
    test('returns null when checkOut is not after checkIn', () {
      expect(
        StayRange.tryCreate(
          DateOnly(2026, 11, 5),
          DateOnly(2026, 11, 5),
          today,
        ),
        isNull,
      );
      expect(
        StayRange.tryCreate(
          DateOnly(2026, 11, 6),
          DateOnly(2026, 11, 5),
          today,
        ),
        isNull,
      );
    });

    test('returns null when checkIn is before today', () {
      expect(
        StayRange.tryCreate(
          DateOnly(2026, 10, 31),
          DateOnly(2026, 11, 3),
          today,
        ),
        isNull,
      );
    });

    test('accepts a stay starting today', () {
      final stay = StayRange.tryCreate(
        DateOnly(2026, 11, 1),
        DateOnly(2026, 11, 4),
        today,
      );
      expect(stay, isNotNull);
    });

    test('returns null for null inputs without throwing', () {
      expect(StayRange.tryCreate(null, DateOnly(2026, 11, 4), today), isNull);
      expect(StayRange.tryCreate(DateOnly(2026, 11, 1), null, today), isNull);
      expect(StayRange.tryCreate(null, null, today), isNull);
    });
  });

  test('nights equals the whole-day difference', () {
    final stay = StayRange(
      DateOnly(2026, 11, 1),
      DateOnly(2026, 11, 4),
    );
    expect(stay.nights, 3);
  });

  test('nightsIterable yields each night up to the day before checkOut', () {
    final stay = StayRange(
      DateOnly(2026, 11, 28),
      DateOnly(2026, 12, 2),
    );
    expect(stay.nightsIterable().toList(), [
      DateOnly(2026, 11, 28),
      DateOnly(2026, 11, 29),
      DateOnly(2026, 11, 30),
      DateOnly(2026, 12, 1),
    ]);
  });

  group('isSelectable', () {
    test('is false when any night is unavailable', () {
      final stay = StayRange(
        DateOnly(2026, 11, 1),
        DateOnly(2026, 11, 4),
      );
      final unavailable = {DateOnly(2026, 11, 2)};
      expect(stay.isSelectable(unavailable), isFalse);
    });

    test('is true when only the checkOut day is unavailable', () {
      // The departure day may be the next guest's arrival night.
      final stay = StayRange(
        DateOnly(2026, 11, 1),
        DateOnly(2026, 11, 4),
      );
      final unavailable = {DateOnly(2026, 11, 4)};
      expect(stay.isSelectable(unavailable), isTrue);
    });

    test('is true when nothing is unavailable', () {
      final stay = StayRange(
        DateOnly(2026, 11, 1),
        DateOnly(2026, 11, 4),
      );
      expect(stay.isSelectable(const {}), isTrue);
    });
  });

  test('value equality', () {
    final a = StayRange(DateOnly(2026, 11, 1), DateOnly(2026, 11, 4));
    final b = StayRange(DateOnly(2026, 11, 1), DateOnly(2026, 11, 4));
    final c = StayRange(DateOnly(2026, 11, 1), DateOnly(2026, 11, 5));
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });
}
