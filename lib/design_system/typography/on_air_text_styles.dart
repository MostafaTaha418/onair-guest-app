import 'package:flutter/material.dart';

final class OnAirTextStyles extends ThemeExtension<OnAirTextStyles> {
  const OnAirTextStyles({required this.authTitleSize});

  final double authTitleSize;
  static const standard = OnAirTextStyles(authTitleSize: 36);
  static const narrow = OnAirTextStyles(authTitleSize: 32);

  TextStyle _style(
    double size,
    FontWeight weight, {
    double? spacing,
    double? height,
  }) => TextStyle(
    fontFamily: 'Cairo',
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing,
    height: height,
  );
  TextStyle get authTitle =>
      _style(authTitleSize, FontWeight.w800, spacing: -0.5, height: 1.1);
  TextStyle get authDescription => _style(14, FontWeight.w400, height: 1.5);
  TextStyle get input => _style(15, FontWeight.w500);
  TextStyle get placeholder => _style(15, FontWeight.w400);
  TextStyle get forgotLink => _style(11, FontWeight.w700, spacing: 0.5);
  TextStyle get passwordHint => _style(12, FontWeight.w400, height: 1.4);
  TextStyle get authButton => _style(15, FontWeight.w600);
  TextStyle get homeWelcome => _style(15, FontWeight.w700, height: 1.15);
  TextStyle get homeUserName => _style(18, FontWeight.w500, height: 1.15);
  TextStyle get sectionTitle => _style(18, FontWeight.w800);
  TextStyle get areaCardTitle => _style(17, FontWeight.w800);
  TextStyle get areaBadge => _style(11, FontWeight.w700);
  TextStyle get propertyTitle => _style(15, FontWeight.w800);
  TextStyle get price => _style(14, FontWeight.w800);
  TextStyle get seeAll => _style(14, FontWeight.w700);
  TextStyle get homeSearch => _style(16, FontWeight.w400);
  TextStyle get navLabel => _style(10, FontWeight.w700);
  TextStyle get splashTitle => _style(48, FontWeight.w800, spacing: 1.2);

  @override
  OnAirTextStyles copyWith({double? authTitleSize}) =>
      OnAirTextStyles(authTitleSize: authTitleSize ?? this.authTitleSize);

  @override
  OnAirTextStyles lerp(ThemeExtension<OnAirTextStyles>? other, double t) =>
      other is OnAirTextStyles
      ? OnAirTextStyles(
          authTitleSize:
              authTitleSize + (other.authTitleSize - authTitleSize) * t,
        )
      : this;
}

TextTheme onAirTextTheme(Color color) => TextTheme(
  displayLarge: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    color: color,
  ),
  displayMedium: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 45,
    fontWeight: FontWeight.w400,
    color: color,
  ),
  displaySmall: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 36,
    fontWeight: FontWeight.w400,
    color: color,
  ),
  headlineLarge: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 32,
    fontWeight: FontWeight.w400,
    color: color,
  ),
  headlineMedium: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 28,
    fontWeight: FontWeight.w400,
    color: color,
  ),
  headlineSmall: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: color,
  ),
  titleLarge: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: color,
  ),
  titleMedium: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: color,
  ),
  titleSmall: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: color,
  ),
  bodyLarge: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: color,
  ),
  bodyMedium: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: color,
  ),
  bodySmall: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: color,
  ),
  labelLarge: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: color,
  ),
  labelMedium: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: color,
  ),
  labelSmall: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: color,
  ),
);
