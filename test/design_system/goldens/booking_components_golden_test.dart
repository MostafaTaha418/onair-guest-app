import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/booking_timeline.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/refund_stage_tracker.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Widget _chips(ThemeMode mode, TextDirection direction, double scale) => _wrap(
  mode,
  direction,
  scale,
  Column(
    children: [
      for (final tone in StatusTone.values)
        Padding(
          padding: const EdgeInsets.all(4),
          child: StatusChip(label: _toneLabel(tone), tone: tone),
        ),
    ],
  ),
);

String _toneLabel(StatusTone tone) => switch (tone) {
  StatusTone.warning => 'بانتظار إتمام الدفع',
  StatusTone.info => 'جارٍ التحقق من الدفع',
  StatusTone.pending => 'بانتظار تأكيد المالك',
  StatusTone.success => 'حجز مؤكد',
  StatusTone.badge => 'إقامة جارية',
  StatusTone.completed => 'إقامة مكتملة',
  StatusTone.rejected => 'رفض المالك',
  StatusTone.cancelled => 'ملغي',
};

Widget _rows(ThemeMode mode, TextDirection direction, double scale) => _wrap(
  mode,
  direction,
  scale,
  const Column(
    children: [
      AmountRow(label: 'الإجمالي', value: 'EGP 4,500.00'),
      AmountRow(label: 'المطلوب دفعه دلوقتي', value: 'EGP 1,125.00'),
      AmountRow(
        label: 'المتبقي',
        value: 'EGP 3,400.00',
        previousValue: 'EGP 3,375.00',
        highlighted: true,
      ),
      AmountRow(
        label: 'الإجمالي',
        value: 'EGP 4,500.00',
        emphasized: true,
      ),
    ],
  ),
);

Widget _banners(ThemeMode mode, TextDirection direction, double scale) => _wrap(
  mode,
  direction,
  scale,
  Column(
    children: [
      const InfoBanner(
        message: 'هيتبعت طلبك للمالك بعد الدفع.',
        tone: StatusTone.info,
      ),
      const SizedBox(height: 8),
      InfoBanner(
        message: 'السعر اتحدّث. راجع المبالغ الجديدة قبل الدفع.',
        tone: StatusTone.warning,
        actionLabel: 'أكّد',
        onAction: () {},
      ),
      const SizedBox(height: 8),
      const NoticeCard(
        icon: Icons.support_agent,
        message: 'فيه مشكلة في الاسترداد. فريق OnAir بيتابعها.',
      ),
    ],
  ),
);

Widget _timeline(ThemeMode mode, TextDirection direction, double scale) =>
    _wrap(
      mode,
      direction,
      scale,
      const BookingTimeline(
        entries: [
          TimelineEntry(title: 'بانتظار إتمام الدفع', time: '28 أكتوبر 10:55'),
          TimelineEntry(title: 'بانتظار تأكيد المالك', time: '28 أكتوبر 12:00'),
          TimelineEntry(title: 'حجز مؤكد', time: '28 أكتوبر 14:00'),
        ],
      ),
    );

Widget _stages(ThemeMode mode, TextDirection direction, double scale) => _wrap(
  mode,
  direction,
  scale,
  const Column(
    children: [
      RefundStageTracker(
        stageLabels: ['طُلب', 'اعتُمد', 'قيد التنفيذ', 'تم التحقق'],
        currentIndex: 2,
      ),
      SizedBox(height: 16),
      RefundStageTracker(
        stageLabels: ['طُلب', 'اعتُمد', 'قيد التنفيذ', 'تم التحقق'],
        currentIndex: 1,
        failed: true,
      ),
    ],
  ),
);

Widget _timelineAndStages(
  ThemeMode mode,
  TextDirection direction,
  double scale,
) => _wrap(
  mode,
  direction,
  scale,
  Column(
    children: [
      _timeline(mode, direction, scale),
      const SizedBox(height: 12),
      _stages(mode, direction, scale),
    ],
  ),
  height: 980,
);

Widget _wrap(
  ThemeMode mode,
  TextDirection direction,
  double scale,
  Widget child, {
  double height = 420,
}) => SizedBox(
  width: 320,
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

void main() {
  unawaited(
    goldenTest(
      'booking status chips in every tone',
      fileName: 'booking_status_chips',
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 1400),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'light RTL',
            child: _chips(ThemeMode.light, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'dark RTL',
            child: _chips(ThemeMode.dark, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'light RTL 1.3x',
            child: _chips(ThemeMode.light, TextDirection.rtl, 1.3),
          ),
          GoldenTestScenario(
            name: 'dark RTL 1.3x',
            child: _chips(ThemeMode.dark, TextDirection.rtl, 1.3),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'amount rows with the re-price states',
      fileName: 'booking_amount_rows',
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 1200),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'light RTL',
            child: _rows(ThemeMode.light, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'dark RTL',
            child: _rows(ThemeMode.dark, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'light RTL 1.3x',
            child: _rows(ThemeMode.light, TextDirection.rtl, 1.3),
          ),
          GoldenTestScenario(
            name: 'dark RTL 1.3x',
            child: _rows(ThemeMode.dark, TextDirection.rtl, 1.3),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'info banner and notice card',
      fileName: 'booking_banners',
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 1200),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'light RTL',
            child: _banners(ThemeMode.light, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'dark RTL',
            child: _banners(ThemeMode.dark, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'light RTL 1.3x',
            child: _banners(ThemeMode.light, TextDirection.rtl, 1.3),
          ),
          GoldenTestScenario(
            name: 'dark RTL 1.3x',
            child: _banners(ThemeMode.dark, TextDirection.rtl, 1.3),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'timeline and refund stage tracker',
      fileName: 'booking_timeline_stages',
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 1200),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'light RTL',
            child: _timelineAndStages(ThemeMode.light, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'dark RTL',
            child: _timelineAndStages(ThemeMode.dark, TextDirection.rtl, 1),
          ),
          GoldenTestScenario(
            name: 'light RTL 1.3x',
            child: _timelineAndStages(ThemeMode.light, TextDirection.rtl, 1.3),
          ),
          GoldenTestScenario(
            name: 'dark RTL 1.3x',
            child: _timelineAndStages(ThemeMode.dark, TextDirection.rtl, 1.3),
          ),
        ],
      ),
    ),
  );
}
