import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/typography/on_air_text_styles.dart';

void main() {
  test('discovery text styles use the specified size and weight', () {
    const styles = OnAirTextStyles.standard;

    expect(styles.areaCardTitle.fontSize, 17);
    expect(styles.areaCardTitle.fontWeight, FontWeight.w800);
    expect(styles.areaBadge.fontSize, 11);
    expect(styles.areaBadge.fontWeight, FontWeight.w700);
    expect(styles.propertyTitle.fontSize, 15);
    expect(styles.propertyTitle.fontWeight, FontWeight.w800);
    expect(styles.price.fontSize, 14);
    expect(styles.price.fontWeight, FontWeight.w800);
  });
}
