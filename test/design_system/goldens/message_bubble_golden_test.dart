import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/components/message_bubble.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Widget _scenario(ThemeMode mode, Locale locale, double scale) => SizedBox(
  width: 360,
  height: 480,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    themeMode: mode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MessageBubble(
            author: MessageAuthor.onAir,
            body: locale.languageCode == 'ar'
                ? 'أهلًا، راجعنا التفاصيل وهنرد عليك هنا.'
                : 'We reviewed the details and will reply here.',
            time: DateTime.utc(2026, 11, 16, 9, 30),
          ),
          MessageBubble(
            author: MessageAuthor.guest,
            body: locale.languageCode == 'ar'
                ? 'تمام، دي صورة الإيصال.'
                : 'Okay, here is the receipt photo.',
            time: DateTime.utc(2026, 11, 16, 9, 32),
            attachments: const [
              SizedBox(
                width: 72,
                height: 56,
                child: ColoredBox(color: Colors.black12),
              ),
            ],
            sendState: MessageSendState.sending,
          ),
          MessageBubble(
            author: MessageAuthor.guest,
            body: locale.languageCode == 'ar'
                ? 'الرسالة منفعتش تتبعت.'
                : 'The message failed to send.',
            time: DateTime.utc(2026, 11, 16, 9, 34),
            sendState: MessageSendState.failed,
            onRetry: () {},
          ),
        ],
      ),
    ),
  ),
);

Future<void> _pump(WidgetTester tester) => tester.pump();

void main() {
  CairoTime.initialize();
  unawaited(
    goldenTest(
      'support message bubbles',
      fileName: 'message_bubbles',
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 5000),
      pumpBeforeTest: _pump,
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          for (final mode in [ThemeMode.light, ThemeMode.dark])
            for (final locale in [const Locale('ar'), const Locale('en')])
              for (final scale in [1.0, 1.3])
                GoldenTestScenario(
                  name: '${mode.name} ${locale.languageCode} ${scale}x',
                  child: _scenario(mode, locale, scale),
                ),
        ],
      ),
    ),
  );
}
