import 'package:intl/intl.dart';
import 'package:on_air/core/time/cairo_time.dart';

String _monthName(DateTime cairo) =>
    DateFormat.MMMM('ar').format(DateTime.utc(cairo.year, cairo.month));

String _clock(DateTime cairo) =>
    '${cairo.hour.toString().padLeft(2, '0')}:'
    '${cairo.minute.toString().padLeft(2, '0')}';

/// «20 نوفمبر – 14:00» — a UTC server instant on a Cairo wall clock, with
/// the same Arabic month names the stay-date formatter uses and Western
/// digits.
String formatCairoDayMonthTime(DateTime utc) {
  final cairo = CairoTime.inCairo(utc);
  return '${cairo.day} ${_monthName(cairo)} – ${_clock(cairo)}';
}

/// «14:00»
String formatCairoTime(DateTime utc) => _clock(CairoTime.inCairo(utc));
