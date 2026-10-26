import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';

void main() {
  test('date-only parses and serializes without a timezone', () {
    expect(DateOnly.parse('2026-10-26').toString(), '2026-10-26');
    expect(() => DateOnly.parse('2026-02-30'), throwsFormatException);
  });

  test('UTC timestamps use Cairo daylight-saving rules', () {
    CairoTime.initialize();
    expect(CairoTime.fromUtcIso('2026-01-15T12:00:00Z').hour, 14);
    expect(CairoTime.fromUtcIso('2026-07-15T12:00:00Z').hour, 15);
  });
}
