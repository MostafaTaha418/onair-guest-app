@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/design_system/components/range_calendar.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Widget _theme(
  ThemeMode mode,
  TextDirection direction,
  double scale,
  double width,
  double height,
  Widget child,
) => SizedBox(
  width: width,
  height: height,
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
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

Widget _cards(ThemeMode mode, TextDirection direction, double scale) => _theme(
  mode,
  direction,
  scale,
  400,
  1000,
  SingleChildScrollView(
    child: Column(
      children: [
        PropertyCard(
          title: 'شقة 3 غرف بإطلالة',
          subtitle: 'التجمع الخامس • القاهرة الجديدة',
          imageVariants: const [],
          priceText: 'EGP 1,500.00',
          stayTotalText: 'إجمالي 3 ليالي: EGP 4,500.00',
          ratingText: '4.6',
          ratingSemantics: 'التقييم 4.6 من 5، 12 تقييم',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        PropertyCard(
          title: 'استوديو جديد مفروش بالكامل',
          subtitle: 'الرحاب • القاهرة الجديدة',
          imageVariants: const [],
          priceText: 'EGP 900.00',
          onTap: () {},
        ),
      ],
    ),
  ),
);

Widget _skeleton(ThemeMode mode, TextDirection direction, double scale) =>
    _theme(
      mode,
      direction,
      scale,
      400,
      620,
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Column(
          children: [
            PropertyCardSkeleton(),
            SizedBox(height: 16),
            SkeletonBox(width: double.infinity, height: 60),
          ],
        ),
      ),
    );

Widget _calendar(ThemeMode mode, TextDirection direction, double scale) =>
    _theme(
      mode,
      direction,
      scale,
      400,
      560,
      RangeCalendar(
        today: DateOnly(2026, 11, 10),
        initialMonth: DateOnly(2026, 11, 1),
        selectedCheckIn: DateOnly(2026, 11, 20),
        selectedCheckOut: DateOnly(2026, 11, 23),
        unavailableNights: {
          DateOnly(2026, 11, 14),
          DateOnly(2026, 11, 15),
          DateOnly(2026, 11, 16),
        },
        onDayTap: (_) {},
      ),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  final modes = [
    ('light RTL', ThemeMode.light, TextDirection.rtl, 1.0),
    ('dark RTL', ThemeMode.dark, TextDirection.rtl, 1.0),
    ('light LTR', ThemeMode.light, TextDirection.ltr, 1.0),
    ('light RTL 1.3x', ThemeMode.light, TextDirection.rtl, 1.3),
  ];

  for (final (name, mode, direction, scale) in modes) {
    unawaited(
      goldenTest(
        'property cards — $name',
        fileName: 'discovery_property_cards_${name.replaceAll(' ', '_')}',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1100),
        builder: () => GoldenTestScenario(
          name: name,
          child: _cards(mode, direction, scale),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'skeletons — $name',
        fileName: 'discovery_skeletons_${name.replaceAll(' ', '_')}',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 700),
        builder: () => GoldenTestScenario(
          name: name,
          child: _skeleton(mode, direction, scale),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'range calendar — $name',
        fileName: 'discovery_range_calendar_${name.replaceAll(' ', '_')}',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
        builder: () => GoldenTestScenario(
          name: name,
          child: _calendar(mode, direction, scale),
        ),
      ),
    );
  }
}
