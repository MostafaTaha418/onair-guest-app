@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/support/data/faq_cache.dart';
import 'package:on_air/features/support/domain/faq_item.dart';
import 'package:on_air/features/support/presentation/faq/faq_cubit.dart';
import 'package:on_air/features/support/presentation/faq/faq_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_support_repository.dart';

void main() {
  final items = [
    const FaqItem(
      id: 'faq-1',
      question: 'إزاي أحجز شقة؟',
      answer:
          'اختار الشقة، حدد المواعيد وعدد الأفراد، وادفع العربون من وسيلة'
          ' الدفع اللي تفضلها. الحجز يتأكد فورًا بعد الدفع.',
      sortOrder: 1,
    ),
    const FaqItem(
      id: 'faq-2',
      question: 'إيه طرق الدفع المتاحة؟',
      answer:
          'فيزا أو ماستركارد عبر كاشير، أو دفع كاش لموظف OnAir حسب بيان'
          ' سياسة الشقة.',
      sortOrder: 2,
    ),
    const FaqItem(
      id: 'faq-3',
      question: 'الاسترداد بيرجع في وقت قد إيه؟',
      answer:
          'الاسترداد بيتنفذ على نفس وسيلة الدفع خلال 5-7 أيام عمل بعد'
          ' اعتماد الطلب.',
      sortOrder: 3,
    ),
  ];

  final states = <(String, FaqReady)>[
    ('list', FaqReady(items: items)),
    ('no_results', const FaqReady(items: [], query: 'كلام مالوش لزمة')),
    ('stale', FaqReady(items: items, stale: true)),
  ];

  for (final (stateName, state) in states) {
    for (final (themeName, themeMode) in [
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ]) {
      for (final (localeName, locale) in [
        ('ar_rtl', const Locale('ar')),
        ('en_ltr', const Locale('en')),
      ]) {
        for (final (scaleName, textScale) in [
          ('1_0', 1.0),
          ('1_3', 1.3),
        ]) {
          for (final width in [320.0, 800.0]) {
            final widthName = width.toInt();
            final variant =
                '${themeName}_${localeName}_${scaleName}_$widthName';
            unawaited(
              goldenTest(
                'faq — $stateName $variant',
                fileName: 'faq_${stateName}_$variant',
                constraints: BoxConstraints(
                  maxWidth: width + 40,
                  maxHeight: 920,
                ),
                pumpBeforeTest: (tester) async {
                  await tester.pump();
                  await tester.pump(const Duration(milliseconds: 300));
                },
                builder: () => GoldenTestScenario(
                  name: '$stateName/$variant',
                  child: _surface(
                    state,
                    themeMode: themeMode,
                    locale: locale,
                    textScale: textScale,
                    width: width,
                  ),
                ),
              ),
            );
          }
        }
      }
    }
  }
}

Widget _surface(
  FaqReady state, {
  required ThemeMode themeMode,
  required Locale locale,
  required double textScale,
  required double width,
}) {
  final cubit = FaqCubit.seeded(
    repository: FakeSupportRepository(),
    // The seeded cubit never touches the cache; the file stays untouched.
    cache: FaqCache(
      JsonFileCache(
        directory: Directory.systemTemp,
        fileName: 'faq_golden_inert.json',
        schema: 1,
      ),
    ),
    state: state,
  );
  return SizedBox(
    width: width,
    height: 844,
    child: RepositoryProvider<AppConfigSource>.value(
      value: const MockAppConfigSource(),
      child: BlocProvider<FaqCubit>.value(
        value: cubit,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OnAirTheme.light,
          darkTheme: OnAirTheme.dark,
          themeMode: themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const FaqScreen(),
        ),
      ),
    ),
  );
}
