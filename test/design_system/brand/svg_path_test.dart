import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/brand/svg_path.dart';

void main() {
  test('absolute and relative lines close into the expected box', () {
    final path = parseSvgPath('M10 20H30v40h-20Z');
    expect(path.getBounds(), const Rect.fromLTRB(10, 20, 30, 60));
    expect(path.contains(const Offset(20, 40)), isTrue);
  });

  test('the brand mark arch spans its 50x65 box', () {
    final path = parseSvgPath(
      'M25 86V46a25 25 0 0 1 50 0v40H63V46a13 13 0 0 0-26 0v40Z',
    );
    final bounds = path.getBounds();
    expect(bounds.left, closeTo(25, 0.01));
    expect(bounds.top, closeTo(21, 0.01));
    expect(bounds.right, closeTo(75, 0.01));
    expect(bounds.bottom, closeTo(86, 0.01));
    // Filled leg, hollow doorway.
    expect(path.contains(const Offset(30, 70)), isTrue);
    expect(path.contains(const Offset(50, 70)), isFalse);
  });

  test('quadratic curves and implicit lines after a move', () {
    final path = parseSvgPath('M0 0 10 0Q10 10 0 10Z');
    expect(path.getBounds().right, closeTo(10, 0.01));
    expect(path.getBounds().bottom, closeTo(10, 0.01));
  });

  test('rejects malformed data', () {
    expect(() => parseSvgPath('10 10'), throwsFormatException);
    expect(() => parseSvgPath('M10'), throwsFormatException);
    expect(() => parseSvgPath('M0 0Z 5 5'), throwsFormatException);
  });
}
