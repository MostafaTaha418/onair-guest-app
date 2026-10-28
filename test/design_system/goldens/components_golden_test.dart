import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/components/section_header.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Widget _sample(
  ThemeMode mode,
  TextDirection direction,
  double scale,
) => SizedBox(
  width: 320,
  height: 550,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    themeMode: mode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Directionality(textDirection: direction, child: child!),
    ),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            OnAirPrimaryButton(
              label: 'متابعة',
              onPressed: () {},
              gradient: true,
            ),
            const SizedBox(height: 12),
            const OnAirTextField(hint: 'رقم الموبايل', errorText: 'راجع الرقم'),
            const SizedBox(height: 12),
            OnAirOtpField(onCompleted: (_) {}),
            const SizedBox(height: 12),
            SectionHeader(title: 'أقسام', onSeeAll: () {}),
            const SizedBox(height: 8),
            const EmptyView(icon: Icons.favorite_border, message: 'مفيش عناصر'),
          ],
        ),
      ),
    ),
  ),
);

Widget _states(ThemeMode mode, TextDirection direction, double scale) =>
    SizedBox(
      width: 320,
      height: 720,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OnAirTheme.light,
        darkTheme: OnAirTheme.dark,
        themeMode: mode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(textDirection: direction, child: child!),
        ),
        home: Scaffold(
          body: Column(
            children: [
              const LoadingView(),
              SizedBox(
                height: 180,
                child: ErrorView(
                  message: 'حصلت مشكلة',
                  referenceNumber: 'REQ-123',
                  onRetry: () {},
                ),
              ),
              const OfflineBanner(),
            ],
          ),
        ),
      ),
    );

void main() {
  unawaited(
    goldenTest(
      'shared components in light, dark, RTL, and large text',
      fileName: 'shared_components',
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 1200),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'light RTL',
            child: _sample(ThemeMode.light, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'dark RTL',
            child: _sample(ThemeMode.dark, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'light LTR',
            child: _sample(ThemeMode.light, TextDirection.ltr, 1),
          ),
          GoldenTestScenario(
            name: 'light RTL 1.3x',
            child: _sample(ThemeMode.light, TextDirection.rtl, 1.3),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'loading, error, and offline states in each display mode',
      fileName: 'state_views',
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 1500),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'light RTL',
            child: _states(ThemeMode.light, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'dark RTL',
            child: _states(ThemeMode.dark, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'light LTR',
            child: _states(ThemeMode.light, TextDirection.ltr, 1),
          ),
          GoldenTestScenario(
            name: 'light RTL 1.3x',
            child: _states(ThemeMode.light, TextDirection.rtl, 1.3),
          ),
        ],
      ),
    ),
  );
}
