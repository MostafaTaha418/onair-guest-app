import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';

void main() {
  setUpAll(() async {
    CairoTime.initialize();
    await initializeDateFormatting('ar');
  });

  group('DateOnly helpers', () {
    test('addDays crosses a month boundary', () {
      expect(DateOnly(2026, 2, 28).addDays(1), DateOnly(2026, 3, 1));
    });

    test('addDays(-1) crosses months and years', () {
      expect(DateOnly(2026, 1, 1).addDays(-1), DateOnly(2025, 12, 31));
      expect(DateOnly(2026, 3, 1).addDays(-1), DateOnly(2026, 2, 28));
    });

    test('addDays keeps UTC arithmetic exact across DST-like jumps', () {
      expect(DateOnly(2026, 10, 27).addDays(2), DateOnly(2026, 10, 29));
    });

    test('daysUntil returns the whole-day difference', () {
      expect(
        DateOnly(2026, 11, 20).daysUntil(DateOnly(2026, 11, 23)),
        3,
      );
      expect(
        DateOnly(2026, 11, 23).daysUntil(DateOnly(2026, 11, 20)),
        -3,
      );
      expect(
        DateOnly(2026, 11, 20).daysUntil(DateOnly(2026, 11, 20)),
        0,
      );
    });

    test('isBefore, isAfter, and compareTo order dates', () {
      final early = DateOnly(2026, 1, 5);
      final late = DateOnly(2026, 1, 6);
      expect(early.isBefore(late), isTrue);
      expect(late.isAfter(early), isTrue);
      expect(early.isBefore(early), isFalse);
      expect(early.isAfter(early), isFalse);
      expect(early.compareTo(late), isNegative);
      expect(late.compareTo(early), isPositive);
      expect(early.compareTo(early), 0);
    });

    test('fromDateTime keeps only year, month, and day', () {
      final value = DateOnly.fromDateTime(
        DateTime(2026, 11, 20, 23, 59, 59, 999, 999),
      );
      expect(value, DateOnly(2026, 11, 20));
    });

    test('fromDateTime accepts a UTC instant', () {
      expect(
        DateOnly.fromDateTime(DateTime.utc(2026, 11, 20, 10, 30)),
        DateOnly(2026, 11, 20),
      );
    });
  });

  group('CairoTime.today', () {
    test('a late UTC evening is already tomorrow in Cairo', () {
      // Cairo is UTC+2 in winter and UTC+3 in summer; 22:30 UTC is past
      // midnight in Cairo under either offset.
      expect(
        CairoTime.today(now: DateTime.utc(2026, 10, 27, 22, 30)),
        DateOnly(2026, 10, 28),
      );
    });

    test('midday UTC is the same calendar day in Cairo', () {
      expect(
        CairoTime.today(now: DateTime.utc(2026, 10, 27, 12)),
        DateOnly(2026, 10, 27),
      );
    });
  });

  group('DateOnlyFormatter', () {
    test('dayMonth uses Western digits and the Arabic month name', () {
      final text = DateOnlyFormatter.dayMonth(DateOnly(2026, 11, 20));
      expect(text, contains('20'));
      expect(text, isNot(contains('٢٠')));
      expect(text, contains('نوفمبر'));
    });

    test('monthYear uses the Arabic month name and the year', () {
      final text = DateOnlyFormatter.monthYear(DateOnly(2026, 11, 1));
      expect(text, contains('نوفمبر'));
      expect(text, contains('2026'));
    });

    test('month names come from the ar locale symbols', () {
      // Guards against a formatter that silently falls back to English.
      expect(
        DateFormat.MMMM('ar').format(DateTime.utc(2026, 11)),
        'نوفمبر',
      );
    });
  });
}
