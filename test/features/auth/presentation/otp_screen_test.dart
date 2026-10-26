import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/platform/secure_screen.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/otp_screen.dart';

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
  final now = DateTime.utc(2026, 10, 27, 10);
  late FakeAuthRepository auth;
  late FakeAppConfigRepository config;
  late AuthCubit cubit;

  setUp(() async {
    auth = FakeAuthRepository()
      ..account = GuestAccount(
        id: 'guest',
        phone: '+201012345678',
        phoneVerified: true,
      )
      ..challenge = CodeChallenge(
        channel: VerificationChannel.sms,
        target: '+201012345678',
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
    cubit = AuthCubit(auth, currentTermsVersion: 'v1', clock: () => now);
    await cubit.requestPhoneCode('+201012345678');
  });

  Future<void> pump(WidgetTester tester) => tester.pumpOnAirApp(
    OtpScreen(
      codeReader: _NoSms(),
      secureScreen: _NoSecure(),
      clock: () => now,
    ),
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

  testWidgets('wrong code is announced under the field', (tester) async {
    auth.verifyPhoneError = const AuthCodeRejected('OTP_INVALID');
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

  testWidgets('rate limit disables entry and change phone clears state', (
    tester,
  ) async {
    auth.rateLimit = AuthRateLimited(now.add(const Duration(seconds: 45)));
    await cubit.requestPhoneCode('+201012345678');
    await pump(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(find.textContaining('45'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('change-phone-button')));
    await tester.pump();
    expect(cubit.state, isA<SignedOut>());
  });
}
