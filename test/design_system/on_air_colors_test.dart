import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/tokens/on_air_colors.dart';

void main() {
  test('settings icon tones match the light and dark design tokens', () {
    expect(OnAirColors.light.settingsIconBlueBg, const Color(0xFFD6EBF7));
    expect(OnAirColors.light.settingsIconBlueFg, const Color(0xFF006399));
    expect(OnAirColors.light.settingsIconTealBg, const Color(0xFFD1F0EA));
    expect(OnAirColors.light.settingsIconTealFg, const Color(0xFF00796B));
    expect(OnAirColors.light.settingsIconOrangeBg, const Color(0xFFFFE8CC));
    expect(OnAirColors.light.settingsIconOrangeFg, const Color(0xFFE65100));
    expect(OnAirColors.light.settingsIconNeutralBg, const Color(0xFFE8E8E8));
    expect(OnAirColors.light.settingsIconNeutralFg, const Color(0xFF6B7280));
    expect(OnAirColors.light.settingsIconDangerBg, const Color(0xFFFDECEA));
    expect(OnAirColors.light.settingsIconDangerFg, const Color(0xFFC62828));

    expect(OnAirColors.dark.settingsIconBlueBg, const Color(0xFF1E3A5F));
    expect(OnAirColors.dark.settingsIconBlueFg, const Color(0xFF81D4FA));
    expect(OnAirColors.dark.settingsIconTealBg, const Color(0xFF1A3D38));
    expect(OnAirColors.dark.settingsIconTealFg, const Color(0xFF80CBC4));
    expect(OnAirColors.dark.settingsIconOrangeBg, const Color(0xFF3D2E1B));
    expect(OnAirColors.dark.settingsIconOrangeFg, const Color(0xFFFFB74D));
    expect(OnAirColors.dark.settingsIconNeutralBg, const Color(0xFF2A3340));
    expect(OnAirColors.dark.settingsIconNeutralFg, const Color(0xFFB0BEC5));
    expect(OnAirColors.dark.settingsIconDangerBg, const Color(0xFF3D1B1F));
    expect(OnAirColors.dark.settingsIconDangerFg, const Color(0xFFEF9A9A));
  });

  test('copyWith and lerp preserve settings icon tones', () {
    final copied = OnAirColors.light.copyWith();
    expect(copied.settingsIconBlueBg, OnAirColors.light.settingsIconBlueBg);
    expect(
      copied.settingsIconDangerFg,
      OnAirColors.light.settingsIconDangerFg,
    );

    final midpoint = OnAirColors.light.lerp(OnAirColors.dark, 0.5);
    expect(
      midpoint.settingsIconBlueBg,
      Color.lerp(
        OnAirColors.light.settingsIconBlueBg,
        OnAirColors.dark.settingsIconBlueBg,
        0.5,
      ),
    );
    expect(
      midpoint.settingsIconDangerFg,
      Color.lerp(
        OnAirColors.light.settingsIconDangerFg,
        OnAirColors.dark.settingsIconDangerFg,
        0.5,
      ),
    );
  });
}
