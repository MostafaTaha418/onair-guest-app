import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/features/auth/presentation/forgot_password_screen.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';
import 'package:on_air/features/auth/presentation/new_password_screen.dart';
import 'package:on_air/features/auth/presentation/register_screen.dart';

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

  testWidgets('email sign in shows required errors then invalid email', (
    tester,
  ) async {
    await tester.pumpOnAirApp(
      const LoginScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.tap(find.byKey(const ValueKey('email-submit-button')));
    await tester.pump();
    expect(find.text('الحقل ده مطلوب.'), findsNWidgets(2));
    expect(auth.lastEmail, isNull);

    await tester.enterText(find.byKey(const ValueKey('email-field')), 'bad');
    await tester.pump();
    expect(find.text('اكتب بريد إلكتروني صحيح.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'guest@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('password-field')), 'abc');
    await tester.pump();
    expect(find.text('الحقل ده مطلوب.'), findsNothing);
    expect(find.text('اكتب بريد إلكتروني صحيح.'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('email-submit-button')));
    await tester.pump();
    expect(auth.lastPassword, 'abc');
  });

  testWidgets('email registration marks all empty fields and terms', (
    tester,
  ) async {
    // A tall surface keeps every field built (the social row lengthens the
    // form), so all four required errors are on screen after the tap.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpOnAirApp(
      const RegisterScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    final button = find.byKey(const ValueKey('email-submit-button'));
    await tester.scrollUntilVisible(
      button,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('الحقل ده مطلوب.'), findsNWidgets(4));
    expect(find.text('لازم توافق على الشروط للمتابعة.'), findsOneWidget);
    expect(auth.signUpEmailCalls, 0);
  });

  testWidgets('recovery shows required then malformed email errors', (
    tester,
  ) async {
    await tester.pumpOnAirApp(
      const ForgotPasswordScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.tap(find.byKey(const ValueKey('recovery-submit-button')));
    await tester.pump();
    expect(find.text('الحقل ده مطلوب.'), findsOneWidget);
    expect(auth.requestRecoveryCalls, 0);
    await tester.enterText(
      find.byKey(const ValueKey('recovery-email-field')),
      'bad',
    );
    await tester.pump();
    expect(find.text('اكتب بريد إلكتروني صحيح.'), findsOneWidget);
  });

  testWidgets('new password shows required then password rule', (tester) async {
    await tester.pumpOnAirApp(
      const NewPasswordScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.tap(find.byKey(const ValueKey('new-password-submit-button')));
    await tester.pump();
    expect(find.text('الحقل ده مطلوب.'), findsOneWidget);
    expect(auth.setNewPasswordCalls, 0);
    await tester.enterText(
      find.byKey(const ValueKey('new-password-field')),
      'letters-only',
    );
    await tester.pump();
    expect(find.text('8 أحرف على الأقل، بينهم حرف ورقم'), findsWidgets);
  });
}
