import 'package:flutter/material.dart';
import 'package:on_air/design_system/tokens/on_air_colors.dart';
import 'package:on_air/design_system/typography/on_air_text_styles.dart';

abstract final class OnAirTheme {
  static ThemeData light = _build(OnAirColors.light, Brightness.light);
  static ThemeData dark = _build(OnAirColors.dark, Brightness.dark);

  static ThemeData _build(OnAirColors colors, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          surface: colors.surface,
          onSurface: colors.textPrimary,
          error: brightness == Brightness.dark
              ? colors['rejectedText']
              : colors['destructive'],
          onError: colors.onPrimary,
          outline: brightness == Brightness.dark
              ? colors['borderDetail']
              : colors['borderNeutral'],
          outlineVariant: brightness == Brightness.dark
              ? colors['borderDetail']
              : colors['divider'],
          onSurfaceVariant: colors.textSecondary,
          secondary: colors['textAccent'],
          secondaryContainer: colors['badgeNavActive'],
        );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: scheme,
      textTheme: onAirTextTheme(colors.textPrimary),
      extensions: [colors, OnAirTextStyles.standard],
    );
  }
}

extension OnAirThemeContext on BuildContext {
  OnAirColors get colors => Theme.of(this).extension<OnAirColors>()!;
  OnAirTextStyles get textStyles => MediaQuery.sizeOf(this).width < 360
      ? OnAirTextStyles.narrow
      : Theme.of(this).extension<OnAirTextStyles>()!;
}
