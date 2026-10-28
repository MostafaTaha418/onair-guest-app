import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/features/auth/data/profile_repository.dart';
import 'package:on_air/features/auth/data/supabase_auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class _AuthClient extends Mock implements PhoneAuthClient {}

final class _Profiles extends Mock implements ProfileSource {}

final class _GoTrueClient extends Mock implements GoTrueClient {}

final class _AuthResponse extends Mock implements AuthResponse {}

final class _User extends Mock implements User {}

void main() {
  test('Supabase adapter uses account creation and the SMS OTP type', () async {
    final client = _GoTrueClient();
    final response = _AuthResponse();
    final user = _User();
    when(
      () => client.signInWithOtp(
        phone: any(named: 'phone'),
        shouldCreateUser: any(named: 'shouldCreateUser'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => client.verifyOTP(
        phone: any(named: 'phone'),
        token: any(named: 'token'),
        type: OtpType.sms,
      ),
    ).thenAnswer((_) async => response);
    when(() => response.user).thenReturn(user);
    when(() => user.id).thenReturn('guest');
    when(() => user.phone).thenReturn('+201012345678');
    when(() => user.email).thenReturn(null);
    when(() => user.phoneConfirmedAt).thenReturn('2026-10-27T10:00:00Z');
    when(() => user.emailConfirmedAt).thenReturn(null);
    final adapter = SupabasePhoneAuthClient(client);

    await adapter.requestOtp('+201012345678');
    await adapter.verifySmsOtp('+201012345678', '123456');

    verify(
      () => client.signInWithOtp(
        phone: '+201012345678',
        shouldCreateUser: true,
      ),
    ).called(1);
    verify(
      () => client.verifyOTP(
        phone: '+201012345678',
        token: '123456',
        type: OtpType.sms,
      ),
    ).called(1);
  });

  late _AuthClient auth;
  late _Profiles profiles;
  late SupabaseAuthRepository repository;
  final now = DateTime.utc(2026, 10, 27, 10);

  setUp(() {
    auth = _AuthClient();
    profiles = _Profiles();
    when(() => auth.userChanges).thenAnswer((_) => const Stream.empty());
    when(() => profiles.loadOwnProfile(any())).thenAnswer(
      (_) async => const ProfileRecord(),
    );
    repository = SupabaseAuthRepository(auth, profiles, clock: () => now);
  });

  test('requests an OTP with normalized phone and account creation', () async {
    when(() => auth.requestOtp(any())).thenAnswer((_) async {});

    final challenge = await repository.requestPhoneCode('010 1234 5678');

    expect(challenge.target, '+201012345678');
    expect(challenge.resendAt, now);
    verify(() => auth.requestOtp('+201012345678')).called(1);
  });

  test('verifies the exact SMS OTP and returns the account', () async {
    when(() => auth.verifySmsOtp(any(), any())).thenAnswer(
      (_) async => const PhoneAuthUser(
        id: 'guest',
        phone: '+201012345678',
        phoneVerified: true,
      ),
    );

    final account = await repository.verifyPhoneCode(
      '+201012345678',
      '123456',
    );

    expect(account.phoneVerified, isTrue);
    verify(
      () => auth.verifySmsOtp('+201012345678', '123456'),
    ).called(1);
  });

  test('maps invalid and expired OTP errors', () async {
    when(() => auth.verifySmsOtp(any(), any())).thenThrow(
      const AuthException('Token is invalid', code: 'otp_invalid'),
    );
    await expectLater(
      repository.verifyPhoneCode('+201012345678', '000000'),
      throwsA(
        isA<AuthCodeRejected>().having((e) => e.code, 'code', 'OTP_INVALID'),
      ),
    );

    when(() => auth.verifySmsOtp(any(), any())).thenThrow(
      const AuthException('Token has expired', code: 'otp_expired'),
    );
    await expectLater(
      repository.verifyPhoneCode('+201012345678', '000000'),
      throwsA(
        isA<AuthCodeRejected>().having((e) => e.code, 'code', 'OTP_EXPIRED'),
      ),
    );
  });

  test('maps server rate limit including retry seconds', () async {
    when(() => auth.requestOtp(any())).thenThrow(
      const AuthException(
        'Please retry after 42 seconds',
        statusCode: '429',
        code: 'over_sms_send_rate_limit',
      ),
    );

    await expectLater(
      repository.requestPhoneCode('+201012345678'),
      throwsA(
        isA<AuthRateLimited>().having(
          (e) => e.until,
          'until',
          now.add(const Duration(seconds: 42)),
        ),
      ),
    );
  });

  test('rejects unsupported countries with the domain code', () async {
    await expectLater(
      repository.requestPhoneCode('+971501234567'),
      throwsA(
        isA<AuthRequestRejected>().having(
          (e) => e.code,
          'code',
          'PHONE_COUNTRY_NOT_SUPPORTED',
        ),
      ),
    );
  });
}
