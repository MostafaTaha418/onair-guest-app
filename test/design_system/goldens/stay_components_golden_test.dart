import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/acknowledgement_tracker.dart';
import 'package:on_air/design_system/components/on_air_confirm_dialog.dart';
import 'package:on_air/design_system/components/on_air_confirm_sheet.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Widget _scenario(
  ThemeMode mode,
  TextDirection direction,
  double scale,
) => SizedBox(
  width: 360,
  height: 1500,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: direction == TextDirection.rtl
        ? const Locale('ar')
        : const Locale('en'),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              OnAirConfirmSheet(
                title: 'تأكيد استلام الشقة',
                body: 'أكد فقط بعد استلام المفتاح والدخول إلى الشقة.',
                confirmLabel: 'تأكيد الاستلام',
                cancelLabel: 'رجوع',
                onConfirm: () {},
              ),
              const OnAirConfirmDialog(
                title: 'تأكيد الإجراء',
                body: 'هل تريد المتابعة؟',
                confirmLabel: 'تأكيد',
                cancelLabel: 'إلغاء',
              ),
              const OnAirConfirmDialog(
                title: 'إلغاء الحجز',
                body: 'لا يمكن التراجع عن هذا الإجراء.',
                confirmLabel: 'إلغاء الحجز',
                cancelLabel: 'رجوع',
                destructive: true,
              ),
              const AcknowledgementTracker(
                title: 'تأكيد الاستلام',
                steps: [
                  AckStep(
                    label: 'تأكيدك',
                    statusText: 'تم التأكيد',
                    done: true,
                  ),
                  AckStep(
                    label: 'تأكيد المالك',
                    statusText: 'بانتظار التأكيد',
                    done: false,
                  ),
                ],
              ),
              const AcknowledgementTracker(
                title: 'تأكيد الاستلام',
                steps: [
                  AckStep(
                    label: 'تأكيدك',
                    statusText: 'بانتظار التأكيد',
                    done: false,
                  ),
                  AckStep(
                    label: 'تأكيد المالك',
                    statusText: 'تم التأكيد',
                    done: true,
                  ),
                ],
              ),
              const AcknowledgementTracker(
                title: 'تأكيد المغادرة',
                steps: [
                  AckStep(
                    label: 'تأكيدك',
                    statusText: 'تم التأكيد',
                    done: true,
                  ),
                  AckStep(
                    label: 'تأكيد المالك',
                    statusText: 'تم التأكيد',
                    done: true,
                  ),
                ],
                note: 'تم ترك المفتاح في مكان آمن.',
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  unawaited(
    goldenTest(
      'stay confirmation components',
      fileName: 'stay_components',
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 6400),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          for (final mode in [ThemeMode.light, ThemeMode.dark])
            for (final direction in [TextDirection.rtl, TextDirection.ltr])
              for (final scale in [1.0, 1.3])
                GoldenTestScenario(
                  name:
                      '${mode.name} ${direction.name} ${scale == 1 ? '1x' : '1.3x'}',
                  child: _scenario(mode, direction, scale),
                ),
        ],
      ),
    ),
  );
}
