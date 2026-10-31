import 'package:on_air/core/time/date_only.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

abstract final class CairoTime {
  static tz.Location? _location;

  static void initialize() {
    timezone_data.initializeTimeZones();
    _location = tz.getLocation('Africa/Cairo');
  }

  static tz.TZDateTime fromUtcIso(String value) {
    final location = _location;
    if (location == null) {
      throw StateError('CairoTime.initialize must be called first');
    }
    final utc = DateTime.parse(value);
    if (!utc.isUtc) {
      throw const FormatException('Timestamp must carry a UTC offset');
    }
    return tz.TZDateTime.from(utc, location);
  }

  /// The calendar day in Africa/Cairo for [now] (default: the current time).
  static DateOnly today({DateTime? now}) {
    final location = _location;
    if (location == null) {
      throw StateError('CairoTime.initialize must be called first');
    }
    final cairo = tz.TZDateTime.from(now ?? DateTime.now(), location);
    return DateOnly(cairo.year, cairo.month, cairo.day);
  }

  /// The instant [utc] as seen on a Cairo wall clock.
  static DateTime inCairo(DateTime utc) {
    final location = _location;
    if (location == null) {
      throw StateError('CairoTime.initialize must be called first');
    }
    final parsed = utc.isUtc ? utc : utc.toUtc();
    return tz.TZDateTime.from(parsed, location);
  }
}
