import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/core/api/generated/export.dart' hide ErrorCode;
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/phone_verification/data/supabase_phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';

final class _Rpc extends Mock {
  Future<dynamic> call(String fn, Map<String, dynamic> params);
}

final class _Node extends Mock implements FallbackClient {}

void main() {
  late _Rpc rpc;
  late _Node node;
  late SupabasePhoneVerificationRepository repository;

  const challengeJson = {'challenge_id': 'challenge-1'};

  setUpAll(() {
    registerFallbackValue(
      const V1OtpSendRequestBody(challengeId: 'fallback-challenge'),
    );
  });

  setUp(() {
    rpc = _Rpc();
    when(() => rpc(any(), any())).thenAnswer((_) async => challengeJson);
    node = _Node();
    repository = SupabasePhoneVerificationRepository(
      rpc: rpc.call,
      node: node,
    );
  });

  test(
    'start(register) calls common_start_phone_verification per A5',
    () async {
      final draft = PhoneVerificationDraft(
        phone: EgyptPhone.parse('01012345678'),
        fullName: 'Mona Adel',
        acceptedTermsVersion: 'v1',
        locale: 'ar',
      );

      final challengeId = await repository.start(
        draft,
        PhoneVerificationPurpose.register,
      );

      expect(challengeId, 'challenge-1');
      final captured =
          verify(
                () => rpc('common_start_phone_verification', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured, {
        'p_phone': '+201012345678',
        'p_full_name': 'Mona Adel',
        'p_accepted_terms_version': 'v1',
        'p_locale': 'ar',
      });
    },
  );

  test(
    'a register draft without name/terms sends nulls (A5 defaults)',
    () async {
      final draft = PhoneVerificationDraft(
        phone: EgyptPhone.parse('01012345678'),
        locale: 'ar',
      );

      await repository.start(draft, PhoneVerificationPurpose.register);

      final captured =
          verify(
                () => rpc('common_start_phone_verification', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['p_full_name'], isNull);
      expect(captured['p_accepted_terms_version'], isNull);
    },
  );

  test(
    'start(change) calls common_request_phone_change with the number only',
    () async {
      final draft = PhoneVerificationDraft(
        phone: EgyptPhone.parse('01098765432'),
        locale: 'ar',
      );

      await repository.start(draft, PhoneVerificationPurpose.change);

      verifyNever(() => rpc('common_start_phone_verification', any()));
      final captured =
          verify(
                () => rpc('common_request_phone_change', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured, {'p_new_phone': '+201098765432'});
    },
  );

  test(
    'send calls the generated sendOtpCode and maps the A8 payload',
    () async {
      final now = DateTime.utc(2026, 11, 14, 10);
      final next = now.add(const Duration(seconds: 30));
      when(
        () => node.sendOtpCode(
          xRequestId: any(named: 'xRequestId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => OtpSent(
          channel: OtpSentChannel.whatsapp,
          maskedTarget: '+20 10•• ••• 678',
          expiresAt: now.add(const Duration(minutes: 10)),
          serverTime: now,
          nextSendAt: next,
        ),
      );

      final challenge = await repository.send('challenge-1');

      expect(challenge.challengeId, 'challenge-1');
      expect(challenge.maskedPhone, '+20 10•• ••• 678');
      expect(challenge.expiresAt, now.add(const Duration(minutes: 10)));
      expect(challenge.window.serverTime, now);
      expect(challenge.window.nextSendAt, next);
      expect(challenge.window.blockedUntil, isNull);
      final captured =
          verify(
                () => node.sendOtpCode(
                  xRequestId: any(named: 'xRequestId'),
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as V1OtpSendRequestBody;
      expect(captured.challengeId, 'challenge-1');
    },
  );

  test('status calls common_get_otp_status and maps A7', () async {
    final now = DateTime.utc(2026, 11, 14, 10);
    when(() => rpc('common_get_otp_status', any())).thenAnswer(
      (_) async => {
        'delivery_status': 'failed',
        'failure_reason': 'not_on_whatsapp',
        'expires_at': now.add(const Duration(minutes: 10)).toIso8601String(),
        'next_send_at': nextSendIso(now),
        'blocked_until': null,
        'server_time': now.toIso8601String(),
      },
    );

    final (status, failure, window) = await repository.status('challenge-1');

    expect(status, DeliveryStatus.failed);
    expect(failure, DeliveryFailure.notOnWhatsApp);
    expect(window.serverTime, now);
    expect(window.nextSendAt, DateTime.parse(nextSendIso(now)).toUtc());
    verify(
      () => rpc('common_get_otp_status', {
        'p_challenge_id': 'challenge-1',
      }),
    ).called(1);
  });

  test(
    'verify calls common_verify_otp and maps the returned profile',
    () async {
      final acceptedAt = DateTime.utc(2026, 11, 14);
      when(() => rpc('common_verify_otp', any())).thenAnswer(
        (_) async => {
          'guest_id': 'guest-1',
          'profile_status': 'active',
          'auth_providers': ['google'],
          'has_password': false,
          'email': 'guest@example.com',
          'email_verified': true,
          'full_name': 'Mona Adel',
          'phone_e164': '+201012345678',
          'phone_verified': true,
          'accepted_terms_version': 'v1',
          'accepted_terms_at': acceptedAt.toIso8601String(),
        },
      );

      final account = await repository.verify('challenge-1', '123456');

      expect(account.id, 'guest-1');
      expect(account.status, AccountStatus.active);
      expect(account.isComplete, isTrue);
      expect(account.phone, '+201012345678');
      expect(account.phoneVerified, isTrue);
      expect(account.authProviders, {AuthProvider.google});
      expect(account.hasPassword, isFalse);
      verify(
        () => rpc('common_verify_otp', {
          'p_challenge_id': 'challenge-1',
          'p_code': '123456',
        }),
      ).called(1);
    },
  );

  test(
    'a Node 429 OTP_SEND_BLOCKED carries the blocked_until details',
    () async {
      final now = DateTime.utc(2026, 11, 14, 10);
      final blockedUntil = now.add(const Duration(days: 7));
      when(
        () => node.sendOtpCode(
          xRequestId: any(named: 'xRequestId'),
          body: any(named: 'body'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/otp/send'),
          error: ErrorMapper.fromCode(
            'OTP_SEND_BLOCKED',
            details: {
              'blocked_until': blockedUntil.toIso8601String(),
              'server_time': now.toIso8601String(),
            },
          ),
        ),
      );

      late final Object failure;
      try {
        await repository.send('challenge-1');
        fail('expected the blocked send to fail');
      } on Object catch (error) {
        failure = error;
      }

      expect(failure, isA<AppFailure>());
      final apiError = (failure as AppFailure).error;
      expect(apiError.code, ErrorCode.otpSendBlocked);
      expect(
        apiError.details?['blocked_until'],
        blockedUntil.toIso8601String(),
      );
    },
  );
}

String nextSendIso(DateTime now) =>
    now.add(const Duration(seconds: 30)).toIso8601String();
