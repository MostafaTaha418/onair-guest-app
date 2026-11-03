import 'package:intl/intl.dart';
import 'package:on_air/core/time/date_only.dart';

/// Formats stay dates for display with Arabic month names and Western
/// digits (G0 decision on numerals).
abstract final class DateOnlyFormatter {
  static String _monthName(DateOnly date, String locale) =>
      DateFormat.MMMM(locale).format(DateTime.utc(date.year, date.month));

  /// «20 نوفمبر»
  static String dayMonth(DateOnly date, {String locale = 'ar'}) =>
      '${date.day} ${_monthName(date, locale)}';

  /// «نوفمبر 2026»
  static String monthYear(DateOnly date, {String locale = 'ar'}) =>
      '${_monthName(date, locale)} ${date.year}';
}
