import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/platform/secure_screen.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/otp_screen.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

final class _NoSecure implements SecureScreenControl {
  @override
  Future<void> setSecure({required bool enabled}) async {}
}

void main() {
  final now = DateTime.utc(2026, 10, 27, 10);
  late FakeAuthRepository auth;
  late FakeAppConfigRepository config;
  late AuthCubit cubit;

  setUp(() async {
    auth = FakeAuthRepository()
      ..account = GuestAccount(
        id: 'guest',
        status: AccountStatus.active,
        phone: '+201012345678',
        phoneVerified: true,
        email: 'guest@example.com',
        emailVerified: true,
        fullName: 'Guest',
        acceptedTermsVersion: 'v1',
      )
      ..challenge = CodeChallenge(
        channel: VerificationChannel.emailSignup,
        target: 'guest@example.com',
        resendAt: now.add(const Duration(seconds: 30)),
      );
    config = FakeAppConfigRepository(
      const AppConfig(
        minSupportedBuildAndroid: 1,
        minSupportedBuildIos: 1,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    );
    cubit = AuthCubit(auth, clock: () => now);
    await cubit.requestEmailVerification('guest@example.com');
  });

  Future<void> pump(WidgetTester tester) => tester.pumpOnAirApp(
    OtpScreen(secureScreen: _NoSecure(), clock: () => now),
    authRepository: auth,
    appConfigRepository: config,
    authCubit: cubit,
  );

  testWidgets('paste fills six boxes and submits', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(cubit.state, isA<SignedIn>());
  });

  testWidgets('confirm explains empty and incomplete code under the field', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('verify-code-button')));
    await tester.pump();
    expect(find.text('اكتب كود التأكيد.'), findsOneWidget);
    expect(cubit.state, isA<CodeSent>());
    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();
    expect(find.text('اكتب الكود كاملًا من 6 أرقام.'), findsOneWidget);
    expect(cubit.state, isA<CodeSent>());
  });

  testWidgets('wrong code is announced under the field', (tester) async {
    auth.verifyEmailError = const AuthCodeRejected('OTP_INVALID');
    await pump(tester);
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    expect(find.byKey(const ValueKey('otp-error')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('otp-error')))
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
  });

  testWidgets('countdown uses challenge resend deadline', (tester) async {
    await pump(tester);
    expect(find.textContaining('30'), findsOneWidget);
  });

  testWidgets('resend ignores a rapid second tap', (tester) async {
    auth.challenge = CodeChallenge(
      channel: VerificationChannel.emailSignup,
      target: 'guest@example.com',
      resendAt: now,
    );
    await cubit.requestEmailVerification('guest@example.com');
    final baseline = auth.requestEmailVerificationCalls;
    final barrier = Completer<void>();
    auth.requestEmailVerificationBarrier = barrier.future;
    await pump(tester);

    final resend = find.byKey(const ValueKey('resend-button'));
    await tester.tap(resend);
    await tester.tap(resend);
    await tester.pump();

    expect(auth.requestEmailVerificationCalls, baseline + 1);
    barrier.complete();
    await tester.pump();
  });

  testWidgets('rate limit disables entry and change email clears state', (
    tester,
  ) async {
    auth.rateLimit = AuthRateLimited(now.add(const Duration(seconds: 45)));
    await cubit.requestEmailVerification('guest@example.com');
    await pump(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(find.textContaining('45'), findsWidgets);

    final changeEmail = find.byKey(const ValueKey('change-email-button'));
    await tester.scrollUntilVisible(
      changeEmail,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(changeEmail);
    await tester.pump();
    expect(cubit.state, isA<SignedOut>());
  });
}
