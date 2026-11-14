import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/platform/secure_screen.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
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
        status: AccountStatus.active,
        phone: '+201012345678',
        phoneVerified: true,
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

  testWidgets('sign-in opens on email fields', (tester) async {
    await tester.pumpOnAirApp(
      const LoginScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'guest@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'password1',
    );
    await tester.pump();
    final button = find.byKey(const ValueKey('email-submit-button'));
    await tester.scrollUntilVisible(
      button,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(button);
    await tester.pump();

    expect(auth.lastEmail, 'guest@example.com');
    expect(auth.lastPassword, 'password1');
  });

  testWidgets('sign-in shows no phone field and no segmented control', (
    tester,
  ) async {
    await tester.pumpOnAirApp(
      const LoginScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );

    expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('phone-field')), findsNothing);
    expect(find.byType(SegmentedButton<bool>), findsNothing);
  });

  testWidgets('email registration has no phone field (T067)', (tester) async {
    await tester.pumpOnAirApp(
      const RegisterScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );

    expect(find.byKey(const ValueKey('email-name-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
    // S005 US6: «أكّد رقمك» owns the number after the email code.
    expect(find.byKey(const ValueKey('email-phone-field')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('password-field')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('password-field')), findsOneWidget);
  });

  testWidgets('email registration sends the current terms only', (
    tester,
  ) async {
    await tester.pumpOnAirApp(
      const RegisterScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.enterText(
      find.byKey(const ValueKey('email-name-field')),
      'Guest Name',
    );
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'guest@example.com',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('password-field')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'password1',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('email-terms-checkbox')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('email-terms-checkbox')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('email-terms-checkbox')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('email-submit-button')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('email-submit-button')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('email-submit-button')));
    await tester.pump();

    expect(auth.lastTermsVersion, 'v1');
    expect(auth.lastName, 'Guest Name');
    expect(auth.lastLocale, 'ar');
  });

  testWidgets('email registration sends the app language (en)', (
    tester,
  ) async {
    await tester.pumpOnAirApp(
      const RegisterScreen(),
      authRepository: auth,
      appConfigRepository: config,
      locale: const Locale('en'),
    );
    await tester.enterText(
      find.byKey(const ValueKey('email-name-field')),
      'Guest Name',
    );
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'guest@example.com',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('password-field')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'password1',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('email-terms-checkbox')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('email-terms-checkbox')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('email-terms-checkbox')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('email-submit-button')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('email-submit-button')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('email-submit-button')));
    await tester.pump();

    expect(auth.lastLocale, 'en');
  });

  testWidgets('email registration ignores a rapid second submit', (
    tester,
  ) async {
    final barrier = Completer<void>();
    auth.signUpEmailBarrier = barrier.future;
    await tester.pumpOnAirApp(
      const RegisterScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.enterText(
      find.byKey(const ValueKey('email-name-field')),
      'Guest Name',
    );
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'guest@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'password1',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('email-terms-checkbox')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('email-terms-checkbox')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('email-terms-checkbox')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('email-submit-button')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('email-submit-button')),
    );
    await tester.pump();
    final button = find.byKey(const ValueKey('email-submit-button'));
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();

    expect(auth.signUpEmailCalls, 1);
    barrier.complete();
    await tester.pump();
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

  testWidgets('recovery ignores a rapid second submit', (tester) async {
    final barrier = Completer<void>();
    auth.requestRecoveryBarrier = barrier.future;
    await tester.pumpOnAirApp(
      const ForgotPasswordScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.enterText(
      find.byKey(const ValueKey('recovery-email-field')),
      'guest@example.com',
    );
    await tester.pump();
    final button = find.byKey(const ValueKey('recovery-submit-button'));
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();

    expect(auth.requestRecoveryCalls, 1);
    barrier.complete();
    await tester.pump();
  });

  testWidgets('new password enforces the password rule', (tester) async {
    auth.challenge = CodeChallenge(
      channel: VerificationChannel.emailRecovery,
      target: 'guest@example.com',
      resendAt: DateTime.utc(2026),
    );
    final cubit = AuthCubit(auth);
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

    await tester.tap(find.byKey(const ValueKey('new-password-submit-button')));
    await tester.pump();
    expect(auth.setNewPasswordCalls, 0);
    expect(find.textContaining('حرف ورقم'), findsWidgets);
  });

  testWidgets('new password ignores a rapid second submit', (tester) async {
    auth.challenge = CodeChallenge(
      channel: VerificationChannel.emailRecovery,
      target: 'guest@example.com',
      resendAt: DateTime.utc(2026),
    );
    final cubit = AuthCubit(auth);
    await cubit.requestRecovery('guest@example.com');
    await cubit.verifyRecovery('123456');
    final barrier = Completer<void>();
    auth.setNewPasswordBarrier = barrier.future;
    await tester.pumpOnAirApp(
      const NewPasswordScreen(),
      authRepository: auth,
      appConfigRepository: config,
      authCubit: cubit,
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password-field')),
      'password1',
    );
    await tester.pump();
    final button = find.byKey(const ValueKey('new-password-submit-button'));
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();

    expect(auth.setNewPasswordCalls, 1);
    barrier.complete();
    await tester.pump();
  });

  testWidgets('email code screen offers change email', (tester) async {
    final now = DateTime.utc(2026, 10, 27);
    auth.challenge = CodeChallenge(
      channel: VerificationChannel.emailSignup,
      target: 'guest@example.com',
      resendAt: now,
    );
    final cubit = AuthCubit(auth, clock: () => now);
    await cubit.requestEmailSignup(
      'Guest',
      'guest@example.com',
      'password1',
      'v1',
    );
    await tester.pumpOnAirApp(
      OtpScreen(secureScreen: _NoSecure(), clock: () => now),
      authRepository: auth,
      appConfigRepository: config,
      authCubit: cubit,
    );

    expect(find.byKey(const ValueKey('change-email-button')), findsOneWidget);
    expect(find.text('تغيير البريد الإلكتروني'), findsOneWidget);
  });
}
