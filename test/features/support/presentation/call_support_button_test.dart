import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/support/presentation/widgets/call_support_button.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class _FakeConfig implements AppConfigSource {
  _FakeConfig(this.config);
  final AppConfig config;
  @override
  Future<AppConfig> load({bool refresh = false}) async => config;
  @override
  void clearCache() {}
}

AppConfig configWith({
  String phone = '+201000000000',
  String? hoursAr = 'يوميًا 9ص–9م',
}) => AppConfig(
  minSupportedBuildAndroid: 1,
  minSupportedBuildIos: 1,
  supportPhone: phone,
  currentTermsVersion: 'v1',
  supportContact: SupportContact(
    phone: phone.isEmpty ? null : phone,
    hoursAr: hoursAr,
    hoursEn: 'Daily 9am-9pm',
  ),
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  Future<void> pump(
    WidgetTester tester, {
    required AppConfig config,
    required Future<bool> Function(Uri uri) canLaunch,
    required Future<bool> Function(Uri uri) launch,
  }) async {
    await tester.pumpWidget(
      RepositoryProvider<AppConfigSource>.value(
        value: _FakeConfig(config),
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OnAirTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CallSupportButton(canLaunch: canLaunch, launch: launch),
            ),
          ),
        ),
      ),
    );
    // The button reads the config asynchronously; give it a frame.
    await tester.pump();
  }

  testWidgets('hidden when the support phone is not published', (tester) async {
    await pump(
      tester,
      config: configWith(phone: ''),
      canLaunch: (_) async => true,
      launch: (_) async => true,
    );
    expect(find.text(l10n.supportCall), findsNothing);
  });

  testWidgets('shows the hours line when published', (tester) async {
    await pump(
      tester,
      config: configWith(),
      canLaunch: (_) async => true,
      launch: (_) async => true,
    );
    expect(find.text(l10n.supportCall), findsOneWidget);
    expect(find.text(l10n.supportCallHours('يوميًا 9ص–9م')), findsOneWidget);
    // The card-level Semantics carries the button label and merges the
    // visible rows under it.
    final semantics = tester.getSemantics(find.text(l10n.supportCall));
    expect(semantics.label, contains(l10n.supportCall));
    expect(semantics.label, contains(l10n.supportCallHours('يوميًا 9ص–9م')));
  });

  testWidgets('a tap launches tel: with the E.164 number', (tester) async {
    final launched = <Uri>[];
    await pump(
      tester,
      config: configWith(),
      canLaunch: (_) async => true,
      launch: (uri) async {
        launched.add(uri);
        return true;
      },
    );
    await tester.tap(find.text(l10n.supportCall));
    await tester.pump();
    expect(launched, [Uri.parse('tel:+201000000000')]);
  });

  testWidgets('without a dialer the sheet offers the number and a copy', (
    tester,
  ) async {
    final launched = <Uri>[];
    var copied = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    await pump(
      tester,
      config: configWith(),
      canLaunch: (_) async => false,
      launch: (uri) async {
        launched.add(uri);
        return true;
      },
    );
    await tester.tap(find.text(l10n.supportCall));
    await tester.pumpAndSettle();
    expect(launched, isEmpty);
    expect(find.text('+201000000000'), findsOneWidget);
    await tester.tap(find.text(l10n.supportCallCopied));
    await tester.pumpAndSettle();
    expect(copied, '+201000000000');
    expect(find.text(l10n.supportCallCopied), findsOneWidget);
  });

  testWidgets('a launch failure falls back to the sheet', (tester) async {
    await pump(
      tester,
      config: configWith(),
      canLaunch: (_) async => true,
      launch: (_) async => throw const FormatException('no dialer'),
    );
    await tester.tap(find.text(l10n.supportCall));
    await tester.pumpAndSettle();
    expect(find.text('+201000000000'), findsOneWidget);
  });
}
