import 'package:flutter/foundation.dart';

@immutable
final class DateOnly implements Comparable<DateOnly> {
  DateOnly(this.year, this.month, this.day) {
    final candidate = DateTime.utc(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      throw FormatException('Invalid date-only value: $year-$month-$day');
    }
  }

  factory DateOnly.fromDateTime(DateTime value) =>
      DateOnly(value.year, value.month, value.day);

  factory DateOnly.parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw FormatException('Invalid date-only value: $value');
    }
    final parts = value.split('-').map(int.parse).toList();
    return DateOnly(parts[0], parts[1], parts[2]);
  }

  /// Null on bad input, for query-parameter parsing.
  static DateOnly? tryParse(String? value) {
    if (value == null) return null;
    try {
      return DateOnly.parse(value);
    } on FormatException {
      return null;
    }
  }

  final int year;
  final int month;
  final int day;

  /// A date [days] later, computed on the UTC calendar so it never drifts.
  DateOnly addDays(int days) {
    final shifted = DateTime.utc(year, month, day).add(Duration(days: days));
    return DateOnly(shifted.year, shifted.month, shifted.day);
  }

  /// Whole-day difference to [other]; negative when [other] is earlier.
  int daysUntil(DateOnly other) => DateTime.utc(
    other.year,
    other.month,
    other.day,
  ).difference(DateTime.utc(year, month, day)).inDays;

  bool isBefore(DateOnly other) => compareTo(other) < 0;

  bool isAfter(DateOnly other) => compareTo(other) > 0;

  @override
  int compareTo(DateOnly other) {
    final byYear = year.compareTo(other.year);
    if (byYear != 0) return byYear;
    final byMonth = month.compareTo(other.month);
    if (byMonth != 0) return byMonth;
    return day.compareTo(other.day);
  }

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is DateOnly &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
