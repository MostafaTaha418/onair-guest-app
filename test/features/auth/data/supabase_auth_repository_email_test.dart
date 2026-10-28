import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/features/auth/data/profile_repository.dart';
import 'package:on_air/features/auth/data/supabase_auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class _GoTrueClient extends Mock implements GoTrueClient {}

final class _AuthClient extends Mock implements PhoneAuthClient {}

final class _Profiles extends Mock implements ProfileSource {}

final class _AuthResponse extends Mock implements AuthResponse {}

final class _UserResponse extends Mock implements UserResponse {}

final class _ResendResponse extends Mock implements ResendResponse {}

final class _User extends Mock implements User {}

void _stubUser(_User user) {
  when(() => user.id).thenReturn('email-guest');
  when(() => user.phone).thenReturn(null);
  when(() => user.email).thenReturn('guest@example.com');
  when(() => user.phoneConfirmedAt).thenReturn(null);
  when(() => user.emailConfirmedAt).thenReturn('2026-10-27T10:00:00Z');
}

void main() {
  setUpAll(() {
    registerFallbackValue(UserAttributes(password: 'fallback-password1'));
  });

  test(
    'Supabase adapter uses the required email auth APIs and OTP types',
    () async {
      final client = _GoTrueClient();
      final authResponse = _AuthResponse();
      final userResponse = _UserResponse();
      final resendResponse = _ResendResponse();
      final user = _User();
      _stubUser(user);
      when(() => authResponse.user).thenReturn(user);
      when(() => userResponse.user).thenReturn(user);
      when(
        () => client.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => authResponse);
      when(
        () => client.resend(
          email: any(named: 'email'),
          type: OtpType.signup,
        ),
      ).thenAnswer((_) async => resendResponse);
      when(
        () => client.verifyOTP(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: OtpType.signup,
        ),
      ).thenAnswer((_) async => authResponse);
      when(
        () => client.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => authResponse);
      when(
        () => client.resetPasswordForEmail(any()),
      ).thenAnswer((_) async {});
      when(
        () => client.verifyOTP(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: OtpType.recovery,
        ),
      ).thenAnswer((_) async => authResponse);
      when(
        () => client.updateUser(any()),
      ).thenAnswer((_) async => userResponse);
      final adapter = SupabasePhoneAuthClient(client);

      await adapter.signUpWithEmail(
        'Guest Name',
        'guest@example.com',
        'password1',
      );
      await adapter.resendSignupEmail('guest@example.com');
      await adapter.verifySignupEmailOtp('guest@example.com', '123456');
      await adapter.signInWithEmailPassword('guest@example.com', 'password1');
      await adapter.requestPasswordRecovery('guest@example.com');
      await adapter.verifyRecoveryEmailOtp('guest@example.com', '654321');
      await adapter.updatePassword('new-password1');

      verify(
        () => client.signUp(
          email: 'guest@example.com',
          password: 'password1',
          data: {'full_name': 'Guest Name'},
        ),
      ).called(1);
      verify(
        () => client.verifyOTP(
          email: 'guest@example.com',
          token: '123456',
          type: OtpType.signup,
        ),
      ).called(1);
      verify(
        () => client.resetPasswordForEmail('guest@example.com'),
      ).called(1);
      verify(
        () => client.verifyOTP(
          email: 'guest@example.com',
          token: '654321',
          type: OtpType.recovery,
        ),
      ).called(1);
      final captured = verify(() => client.updateUser(captureAny())).captured;
      expect((captured.single as UserAttributes).password, 'new-password1');
    },
  );

  group('SupabaseAuthRepository email behavior', () {
    late _AuthClient auth;
    late SupabaseAuthRepository repository;
    final now = DateTime.utc(2026, 10, 27, 10);

    setUp(() {
      auth = _AuthClient();
      final profiles = _Profiles();
      when(() => auth.userChanges).thenAnswer((_) => const Stream.empty());
      when(() => profiles.loadOwnProfile(any())).thenAnswer(
        (_) async => const ProfileRecord(),
      );
      repository = SupabaseAuthRepository(auth, profiles, clock: () => now);
    });

    test('wrong credentials map to the uniform domain error', () async {
      when(
        () => auth.signInWithEmailPassword(any(), any()),
      ).thenThrow(const AuthException('Invalid login credentials'));

      await expectLater(
        repository.signInEmail('Guest@Example.com ', 'bad-password1'),
        throwsA(
          isA<AuthRequestRejected>().having(
            (error) => error.code,
            'code',
            'INVALID_CREDENTIALS',
          ),
        ),
      );
    });

    test('unknown recovery email returns the same success challenge', () async {
      when(
        () => auth.requestPasswordRecovery(any()),
      ).thenThrow(const AuthException('User not found'));

      final challenge = await repository.requestRecovery(
        'Missing@Example.com ',
      );

      expect(challenge.channel, VerificationChannel.emailRecovery);
      expect(challenge.target, 'missing@example.com');
      expect(challenge.resendAt, now);
    });

    test(
      'unconfirmed email resends the signup code instead of failing',
      () async {
        when(() => auth.signInWithEmailPassword(any(), any())).thenThrow(
          const AuthException(
            'Email not confirmed',
            statusCode: '400',
            code: 'email_not_confirmed',
          ),
        );
        when(() => auth.resendSignupEmail(any())).thenAnswer((_) async {});

        await expectLater(
          repository.signInEmail('Guest@Example.com ', 'password1'),
          throwsA(
            isA<AuthVerificationRequired>()
                .having(
                  (e) => e.challenge.channel,
                  'channel',
                  VerificationChannel.emailSignup,
                )
                .having(
                  (e) => e.challenge.target,
                  'target',
                  'guest@example.com',
                ),
          ),
        );
        verify(() => auth.resendSignupEmail('guest@example.com')).called(1);
      },
    );

    test(
      'no connection is reported as a network failure, not bad input',
      () async {
        when(
          () => auth.signInWithEmailPassword(any(), any()),
        ).thenThrow(AuthRetryableFetchException());
        when(
          () => auth.requestPasswordRecovery(any()),
        ).thenThrow(AuthRetryableFetchException());

        await expectLater(
          repository.signInEmail('guest@example.com', 'password1'),
          throwsA(isA<AuthNetworkFailure>()),
        );
        await expectLater(
          repository.requestRecovery('guest@example.com'),
          throwsA(isA<AuthNetworkFailure>()),
        );
      },
    );
  });
}
