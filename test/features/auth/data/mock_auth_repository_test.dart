import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

/// T067/T069 — the mock auth contract after US6: the email code never
/// completes an account («أكّد رقمك» does), and the seeded legacy account is
/// the same object for social and email sign-in.
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
      MockBackend.termsVersion,
    );
    return repository.verifyEmailCode(
      'guest@example.com',
      MockBackend.verificationCode,
    );
  }

  test(
    'the email code leaves the account incomplete; the WhatsApp step activates',
    () async {
      final account = await signUpAndVerify();

      expect(account.emailVerified, isTrue);
      expect(account.status, AccountStatus.incomplete);
      expect(account.phone, isNull);
      expect(account.phoneVerified, isFalse);
      expect(account.isComplete, isFalse);

      // «أكّد رقمك» success path (US4): confirms the number and activates.
      repository.activatePhone(
        userId: account.id,
        phoneE164: '+201012345678',
      );
      final active = repository.account!;
      expect(active.status, AccountStatus.active);
      expect(active.isComplete, isTrue);
      expect(active.phone, '+201012345678');
      expect(active.phoneVerified, isTrue);
    },
  );

  test('unconfirmed email sign-in asks for the code, then succeeds', () async {
    await repository.signUpEmail(
      'Guest',
      'Guest@Example.com',
      'password1',
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
    expect(account.status, AccountStatus.incomplete);
  });

  test('refreshAccount re-reads the current account', () async {
    final account = await signUpAndVerify();
    final refreshed = await repository.refreshAccount();
    expect(refreshed!.id, account.id);
    expect(refreshed.status, AccountStatus.incomplete);
  });

  test('terms version must match and sign-out clears the session', () async {
    await expectLater(
      repository.signUpEmail(
        'Guest',
        'guest@example.com',
        'password1',
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

  test('the seeded legacy account signs in by email, complete', () async {
    final account = await repository.signInEmail(
      'legacy@onair.test',
      MockAuthRepository.legacyPassword,
    );

    expect(account.id, 'mock-guest-legacy');
    expect(account.status, AccountStatus.active);
    expect(account.isComplete, isTrue);
    expect(account.phone, '+201012340000');
    expect(account.phoneVerified, isTrue);
    expect(account.email, 'legacy@onair.test');
    expect(account.emailVerified, isTrue);
  });

  test(
    'the legacyUser social scenario returns the same seeded account',
    () async {
      repository.scenario = MockSocialScenario.legacyUser;
      final social = await repository.signInWithGoogle();

      expect(social.account.id, 'mock-guest-legacy');
      expect(social.account.status, AccountStatus.active);
      expect(social.account.phone, '+201012340000');

      // The email sign-in path returns the same account object (US7's
      // one-account rule in mock form).
      final email = await repository.signInEmail(
        'legacy@onair.test',
        MockAuthRepository.legacyPassword,
      );
      expect(email.id, social.account.id);
    },
  );
}
