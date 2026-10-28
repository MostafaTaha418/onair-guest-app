import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';

void main() {
  late MockAuthRepository repository;
  final now = DateTime.utc(2026, 10, 28, 10);

  setUp(() => repository = MockAuthRepository(clock: () => now));
  tearDown(() => repository.dispose());

  test(
    'phone sign-in follows the Egypt-only contract and fixed code',
    () async {
      await expectLater(
        repository.requestPhoneCode('+966501234567'),
        throwsA(
          isA<AuthRequestRejected>().having(
            (e) => e.code,
            'code',
            'PHONE_COUNTRY_NOT_SUPPORTED',
          ),
        ),
      );
      final challenge = await repository.requestPhoneCode('01012345678');
      expect(challenge.target, '+201012345678');
      expect(challenge.resendAt, now.add(MockBackend.resendInterval));
      await expectLater(
        repository.verifyPhoneCode(challenge.target, '000000'),
        throwsA(isA<AuthCodeRejected>()),
      );
      final account = await repository.verifyPhoneCode(
        challenge.target,
        MockBackend.verificationCode,
      );
      expect(account.phoneVerified, isTrue);
      expect(account.isComplete(MockBackend.termsVersion), isFalse);

      final completed = await repository.completeProfile(
        ' Guest Name ',
        MockBackend.termsVersion,
      );
      expect(completed.fullName, 'Guest Name');
      expect(completed.isComplete(MockBackend.termsVersion), isTrue);
    },
  );

  test('unconfirmed email sign-in asks for the code, then succeeds', () async {
    await repository.signUpEmail('Guest', 'Guest@Example.com', 'password1');
    await expectLater(
      repository.signInEmail('guest@example.com', 'wrong-password1'),
      throwsA(isA<AuthRequestRejected>()),
    );
    await expectLater(
      repository.signInEmail('guest@example.com', 'password1'),
      throwsA(
        isA<AuthVerificationRequired>().having(
          (e) => e.challenge.channel,
          'channel',
          VerificationChannel.emailSignup,
        ),
      ),
    );
    await repository.verifyEmailCode(
      'guest@example.com',
      MockBackend.verificationCode,
    );
    final account = await repository.signInEmail(
      'guest@example.com',
      'password1',
    );
    expect(account.emailVerified, isTrue);
  });

  test('terms version must match and sign-out clears the session', () async {
    final challenge = await repository.requestPhoneCode('01012345678');
    await repository.verifyPhoneCode(
      challenge.target,
      MockBackend.verificationCode,
    );
    await expectLater(
      repository.completeProfile('Guest Name', 'old-terms'),
      throwsA(isA<ProfileTermsChanged>()),
    );
    final events = <Object?>[];
    final subscription = repository.authStateChanges.listen(events.add);
    await repository.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(await repository.restoreSession(), isNull);
    expect(events.last, isNull);
    await subscription.cancel();
  });
}
