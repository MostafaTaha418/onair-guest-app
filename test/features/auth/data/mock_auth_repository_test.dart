import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

void main() {
  late MockAuthRepository repository;
  final now = DateTime.utc(2026, 10, 28, 10);

  setUp(() => repository = MockAuthRepository(clock: () => now));
  tearDown(() => repository.dispose());

  Future<GuestAccount> signUpAndVerify() async {
    await repository.signUpEmail(
      'Guest',
      'guest@example.com',
      'password1',
      '01012345678',
      MockBackend.termsVersion,
    );
    return repository.verifyEmailCode(
      'guest@example.com',
      MockBackend.verificationCode,
    );
  }

  test(
    'the legacy registration shape (name + phone + terms) activates the account',
    () async {
      final account = await signUpAndVerify();

      expect(account.emailVerified, isTrue);
      expect(account.status, AccountStatus.active);
      expect(account.isComplete, isTrue);
      expect(account.phone, '+201012345678');
      expect(account.phoneVerified, isTrue);
    },
  );

  test('unconfirmed email sign-in asks for the code, then succeeds', () async {
    await repository.signUpEmail(
      'Guest',
      'Guest@Example.com',
      'password1',
      '01012345678',
      MockBackend.termsVersion,
    );
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

  test('refreshAccount re-reads the current account', () async {
    final account = await signUpAndVerify();
    final refreshed = await repository.refreshAccount();
    expect(refreshed!.id, account.id);
    expect(refreshed.status, AccountStatus.active);
  });

  test('terms version must match and sign-out clears the session', () async {
    await expectLater(
      repository.signUpEmail(
        'Guest',
        'guest@example.com',
        'password1',
        '01012345678',
        'old-terms',
      ),
      throwsA(isA<ProfileTermsChanged>()),
    );
    await signUpAndVerify();
    final events = <Object?>[];
    final subscription = repository.authStateChanges.listen(events.add);
    await repository.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(await repository.restoreSession(), isNull);
    expect(await repository.refreshAccount(), isNull);
    expect(events.last, isNull);
    await subscription.cancel();
  });
}
