import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/social_sign_in_button.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Future<AppLocalizations> _pump(WidgetTester tester, Widget child) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      theme: OnAirTheme.light,
      darkTheme: OnAirTheme.dark,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Center(child: child),
          );
        },
      ),
    ),
  );
  await tester.pump();
  return l10n;
}

void main() {
  testWidgets('renders the official mark and carries the semantics label', (
    tester,
  ) async {
    final l10n = await _pump(
      tester,
      SocialSignInButton(
        provider: SocialProvider.google,
        onPressed: () {},
      ),
    );

    expect(find.byKey(const ValueKey('social-google-button')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/social/google_g.png',
      ),
      findsOneWidget,
    );
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('social-google-button')),
    );
    expect(semantics.label, l10n.authContinueWithGoogle);
  });

  testWidgets('the apple mark follows the theme brightness', (tester) async {
    final l10n = await _pump(
      tester,
      Theme(
        data: OnAirTheme.dark,
        child: SocialSignInButton(
          provider: SocialProvider.apple,
          onPressed: () {},
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            (widget.image as AssetImage).assetName ==
                'assets/images/social/apple_logo_white.png',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('social-apple-button')))
          .label,
      l10n.authContinueWithApple,
    );
  });

  testWidgets('is at least a 48dp touch target (56dp circle)', (tester) async {
    await _pump(
      tester,
      SocialSignInButton(
        provider: SocialProvider.google,
        onPressed: () {},
      ),
    );

    final size = tester.getSize(
      find.byKey(const ValueKey('social-google-button')),
    );
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('busy replaces the logo with a loader and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      SocialSignInButton(
        provider: SocialProvider.google,
        onPressed: () => taps += 1,
        busy: true,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.byKey(const ValueKey('social-google-button')));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('a disabled button has no tap handler', (tester) async {
    await _pump(
      tester,
      const SocialSignInButton(
        provider: SocialProvider.google,
        onPressed: null,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    final ink = tester.widget<InkWell>(
      find.byKey(const ValueKey('social-google-button')),
    );
    expect(ink.onTap, isNull);
  });
}
