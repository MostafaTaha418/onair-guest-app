import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/platform/secure_screen.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/forgot_password_screen.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';
import 'package:on_air/features/auth/presentation/new_password_screen.dart';
import 'package:on_air/features/auth/presentation/otp_screen.dart';
import 'package:on_air/features/auth/presentation/register_screen.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

final class _NoSms implements SmsCodeReader {
  @override
  Future<void> cancel() async {}
  @override
  Future<String?> readCode() async => null;
}

final class _NoSecure implements SecureScreenControl {
  @override
  Future<void> setSecure({required bool enabled}) async {}
}

void main() {
  late FakeAuthRepository auth;
  late FakeAppConfigRepository config;

  setUp(() {
    auth = FakeAuthRepository()
      ..account = GuestAccount(
        id: 'email-guest',
        email: 'guest@example.com',
        emailVerified: true,
        fullName: 'Guest',
        acceptedTermsVersion: 'v1',
        acceptedTermsAt: DateTime.utc(2026),
      );
    config = FakeAppConfigRepository(
      const AppConfig(
        minSupportedBuildAndroid: 1,
        minSupportedBuildIos: 1,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    );
  });

  testWidgets('email tab signs in with email and password', (tester) async {
    await tester.pumpOnAirApp(
      const LoginScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.tap(find.text('البريد الإلكتروني'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'guest@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'password1',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('email-submit-button')));
    await tester.pump();

    expect(auth.lastEmail, 'guest@example.com');
    expect(auth.lastPassword, 'password1');
  });

  testWidgets('email registration has no phone field', (tester) async {
    await tester.pumpOnAirApp(
      const RegisterScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.tap(find.text('البريد الإلكتروني'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('email-name-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('password-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('phone-field')), findsNothing);
  });

  testWidgets('forgot password shows the same success for any email', (
    tester,
  ) async {
    for (final email in ['known@example.com', 'missing@example.com']) {
      await tester.pumpOnAirApp(
        const ForgotPasswordScreen(),
        authRepository: auth,
        appConfigRepository: config,
      );
      await tester.enterText(
        find.byKey(const ValueKey('recovery-email-field')),
        email,
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('recovery-submit-button')));
      await tester.pump();

      expect(
        find.text('لو البريد مسجّل، هتوصلك رسالة الاستعادة.'),
        findsOneWidget,
      );
    }
  });

  testWidgets('new password enforces the password rule', (tester) async {
    auth.challenge = CodeChallenge(
      channel: VerificationChannel.emailRecovery,
      target: 'guest@example.com',
      resendAt: DateTime.utc(2026),
    );
    final cubit = AuthCubit(auth, currentTermsVersion: 'v1');
    await cubit.requestRecovery('guest@example.com');
    await cubit.verifyRecovery('123456');
    await tester.pumpOnAirApp(
      const NewPasswordScreen(),
      authRepository: auth,
      appConfigRepository: config,
      authCubit: cubit,
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password-field')),
      'letters-only',
    );
    await tester.pump();

    final button = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const ValueKey('new-password-submit-button')),
        matching: find.byType(TextButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.textContaining('حرف ورقم'), findsWidgets);
  });

  testWidgets('email code screen offers change email', (tester) async {
    final now = DateTime.utc(2026, 10, 27);
    auth.challenge = CodeChallenge(
      channel: VerificationChannel.emailSignup,
      target: 'guest@example.com',
      resendAt: now,
    );
    final cubit = AuthCubit(auth, currentTermsVersion: 'v1', clock: () => now);
    await cubit.requestEmailSignup(
      'Guest',
      'guest@example.com',
      'password1',
    );
    await tester.pumpOnAirApp(
      OtpScreen(
        codeReader: _NoSms(),
        secureScreen: _NoSecure(),
        clock: () => now,
      ),
      authRepository: auth,
      appConfigRepository: config,
      authCubit: cubit,
    );

    expect(find.byKey(const ValueKey('change-email-button')), findsOneWidget);
    expect(find.text('تغيير البريد الإلكتروني'), findsOneWidget);
  });
}
