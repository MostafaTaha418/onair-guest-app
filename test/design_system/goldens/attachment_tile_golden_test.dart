import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/attachment_tile.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Widget _scenario(ThemeMode mode, Locale locale, double scale) => SizedBox(
  width: 360,
  height: 260,
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AttachmentTile(
              kind: AttachmentTileKind.image,
              name: 'photo.jpg',
              sizeLabel: '1.2 MB',
              state: AttachmentTileState.preparing,
              onRemove: () {},
            ),
            AttachmentTile(
              kind: AttachmentTileKind.image,
              name: 'receipt.jpg',
              sizeLabel: '850 KB',
              state: AttachmentTileState.uploading,
              progress: .62,
              onRemove: () {},
            ),
            AttachmentTile(
              kind: AttachmentTileKind.pdf,
              name: 'invoice.pdf',
              sizeLabel: '2.4 MB',
              state: AttachmentTileState.failed,
              onRetry: () {},
              onRemove: () {},
            ),
            AttachmentTile(
              kind: AttachmentTileKind.pdf,
              name: 'booking.pdf',
              sizeLabel: '420 KB',
              onRemove: () {},
            ),
          ],
        ),
      ),
    ),
  ),
);

Future<void> _pump(WidgetTester tester) => tester.pump();

void main() {
  unawaited(
    goldenTest(
      'attachment tiles cover upload states',
      fileName: 'attachment_tiles',
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 3000),
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
