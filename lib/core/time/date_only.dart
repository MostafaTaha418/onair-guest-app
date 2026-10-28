import 'package:flutter/foundation.dart';

@immutable
final class DateOnly {
  DateOnly(this.year, this.month, this.day) {
    final candidate = DateTime.utc(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      throw FormatException('Invalid date-only value: $year-$month-$day');
    }
  }

  factory DateOnly.parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw FormatException('Invalid date-only value: $value');
    }
    final parts = value.split('-').map(int.parse).toList();
    return DateOnly(parts[0], parts[1], parts[2]);
  }

  final int year;
  final int month;
  final int day;

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
