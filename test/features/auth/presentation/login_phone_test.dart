import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeAppConfigRepository config;

  setUp(() {
    auth = FakeAuthRepository();
    config = FakeAppConfigRepository(
      const AppConfig(
        minSupportedBuildAndroid: 1,
        minSupportedBuildIos: 1,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    );
  });

  testWidgets('invalid phone keeps send disabled and shows Arabic hint', (
    tester,
  ) async {
    await tester.pumpOnAirApp(
      const LoginScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.enterText(find.byKey(const ValueKey('phone-field')), '123');
    await tester.pump();

    expect(
      find.text(
        AppLocalizations.of(
          tester.element(find.byType(LoginScreen)),
        ).authPhoneInvalid,
      ),
      findsOneWidget,
    );
    final button = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const ValueKey('send-code-button')),
        matching: find.byType(TextButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('send is disabled while the request is in flight', (
    tester,
  ) async {
    final barrier = Completer<void>();
    auth.requestPhoneBarrier = barrier.future;
    await tester.pumpOnAirApp(
      const LoginScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.enterText(
      find.byKey(const ValueKey('phone-field')),
      '01012345678',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-code-button')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    barrier.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('unsupported country offers the email action', (tester) async {
    auth.requestPhoneError = const AuthRequestRejected(
      'PHONE_COUNTRY_NOT_SUPPORTED',
    );
    await tester.pumpOnAirApp(
      const LoginScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.enterText(
      find.byKey(const ValueKey('phone-field')),
      '01012345678',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-code-button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('use-email-action')), findsOneWidget);
    expect(find.textContaining('المصرية'), findsOneWidget);
  });

  testWidgets('success copy is uniform for every phone number', (tester) async {
    for (final phone in ['01012345678', '01112345678']) {
      await tester.pumpOnAirApp(
        const LoginScreen(),
        authRepository: auth,
        appConfigRepository: config,
      );
      await tester.enterText(find.byKey(const ValueKey('phone-field')), phone);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send-code-button')));
      await tester.pumpAndSettle();
      expect(auth.lastRequestedPhone, phone);
      expect(find.text('بعتنا لك كود التأكيد.'), findsOneWidget);
      expect(find.textContaining('حساب موجود'), findsNothing);
    }
  });

  testWidgets('no connection shows a message instead of "code sent"', (
    tester,
  ) async {
    auth.requestPhoneError = const AuthNetworkFailure();
    await tester.pumpOnAirApp(
      const LoginScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.enterText(
      find.byKey(const ValueKey('phone-field')),
      '01012345678',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-code-button')));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(LoginScreen)));
    expect(find.text(l10n.errorNoConnection), findsOneWidget);
    expect(find.text(l10n.authCodeSent), findsNothing);
  });
}
