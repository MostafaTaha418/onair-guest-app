import 'package:flutter/foundation.dart';
import 'package:on_air/core/time/date_only.dart';

/// A stay `[checkIn, checkOut)` — the nights `checkIn … checkOut−1`.
///
/// [nights] is for display and validation only; totals always come from the
/// server (Constitution II).
@immutable
final class StayRange {
  StayRange(this.checkIn, this.checkOut) {
    if (!checkOut.isAfter(checkIn)) {
      throw ArgumentError.value(
        checkOut,
        'checkOut',
        'must be after checkIn ($checkIn)',
      );
    }
  }

  final DateOnly checkIn;
  final DateOnly checkOut;

  /// Number of nights; at least 1.
  int get nights => checkIn.daysUntil(checkOut);

  Iterable<DateOnly> nightsIterable() sync* {
    var night = checkIn;
    while (night.isBefore(checkOut)) {
      yield night;
      night = night.addDays(1);
    }
  }

  /// True when no night of the stay is unavailable. The departure day itself
  /// may be unavailable: it is the next guest's arrival night.
  bool isSelectable(Set<DateOnly> unavailableNights) =>
      nightsIterable().every((night) => !unavailableNights.contains(night));

  /// Null-safe construction for link and query parsing; never throws.
  static StayRange? tryCreate(
    DateOnly? checkIn,
    DateOnly? checkOut,
    DateOnly today,
  ) {
    if (checkIn == null || checkOut == null) return null;
    if (checkIn.isBefore(today)) return null;
    if (!checkOut.isAfter(checkIn)) return null;
    return StayRange(checkIn, checkOut);
  }

  @override
  bool operator ==(Object other) =>
      other is StayRange &&
      other.checkIn == checkIn &&
      other.checkOut == checkOut;

  @override
  int get hashCode => Object.hash(checkIn, checkOut);

  @override
  String toString() => 'StayRange($checkIn, $checkOut)';
}
