import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/phone_verification/data/mock_phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';

/// Review extra: the mock verify honours A8's code lifecycle — the 10-minute
/// expiry, the five wrong attempts, and an older generation's code after a
/// resend. `MockBackend.clock` drives the time.
void main() {
  var now = DateTime.utc(2026, 11, 14, 10);

  Future<AppFailure> failureOf(Future<Object> Function() action) async {
    try {
      await action();
    } on AppFailure catch (failure) {
      return failure;
    }
    fail('the call was expected to fail');
  }

  Future<(MockPhoneVerificationRepository, String)> repo() async {
    final auth = MockAuthRepository(clock: () => now)
      ..scenario = MockSocialScenario.newUser;
    await auth.signInWithGoogle();
    final repository = MockPhoneVerificationRepository(auth: auth)
      ..clock = () => now;
    final challengeId = await repository.start(
      PhoneVerificationDraft(
        phone: EgyptPhone.parse('01012345678'),
        locale: 'ar',
      ),
      PhoneVerificationPurpose.register,
    );
    return (repository, challengeId);
  }

  tearDown(() => MockBackend.clock = DateTime.now);

  setUp(() => MockBackend.clock = () => now);

  test('a code older than the 10-minute ttl answers OTP_EXPIRED', () async {
    final (repository, challengeId) = await repo();
    await repository.send(challengeId);
    now = now.add(MockBackend.otpTtl);

    final failure = await failureOf(
      () => repository.verify(challengeId, MockBackend.verificationCode),
    );
    expect(failure.error.code, ErrorCode.otpExpired);
  });

  test('the fifth wrong attempt answers OTP_ATTEMPTS_EXCEEDED', () async {
    final (repository, challengeId) = await repo();
    await repository.send(challengeId);

    for (var attempt = 1; attempt < 5; attempt++) {
      final failure = await failureOf(
        () => repository.verify(challengeId, '000000'),
      );
      expect(
        failure.error.code,
        ErrorCode.otpInvalid,
        reason: 'attempt $attempt',
      );
    }
    final fifth = await failureOf(
      () => repository.verify(challengeId, '000000'),
    );
    expect(fifth.error.code, ErrorCode.otpAttemptsExceeded);

    // The code is burned: even the right one is refused now.
    final afterExceeded = await failureOf(
      () => repository.verify(challengeId, MockBackend.verificationCode),
    );
    expect(afterExceeded.error.code, ErrorCode.otpAttemptsExceeded);
  });

  test(
    'an older generation code after a resend answers OTP_SUPERSEDED',
    () async {
      final (repository, challengeId) = await repo();
      await repository.send(challengeId); // generation 1: 123456
      now = now.add(const Duration(seconds: 31)); // the ladder waits out
      await repository.send(challengeId); // generation 2: 654321

      final stale = await failureOf(
        () => repository.verify(challengeId, MockBackend.verificationCode),
      );
      expect(stale.error.code, ErrorCode.otpSuperseded);

      // The fresh generation's code verifies and activates the account.
      final account = await repository.verify(
        challengeId,
        MockBackend.resendVerificationCode,
      );
      expect(account.phone, '+201012345678');
      expect(account.phoneVerified, isTrue);
    },
  );

  test('a resend resets the wrong-attempt counter', () async {
    final (repository, challengeId) = await repo();
    await repository.send(challengeId);
    for (var attempt = 0; attempt < 4; attempt++) {
      await failureOf(() => repository.verify(challengeId, '000000'));
    }
    now = now.add(const Duration(seconds: 31)); // the ladder waits out
    await repository.send(challengeId); // fresh code, fresh attempts

    for (var attempt = 0; attempt < 4; attempt++) {
      await failureOf(() => repository.verify(challengeId, '000000'));
    }
    final fifth = await failureOf(
      () => repository.verify(challengeId, '000000'),
    );
    expect(fifth.error.code, ErrorCode.otpAttemptsExceeded);
  });
}
