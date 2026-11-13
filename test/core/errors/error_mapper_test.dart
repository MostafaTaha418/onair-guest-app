import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/auth/profile_gate.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';

void main() {
  test('maps the documented codes to localization keys', () {
    expect(ErrorMapper.fromCode('OTP_INVALID').messageKey, 'authOtpInvalid');
    expect(ErrorMapper.fromCode('RATE_LIMITED').messageKey, 'authRateLimited');
    expect(
      ErrorMapper.fromCode('PHONE_NOT_VERIFIED').messageKey,
      'bookingPhoneNotVerified',
    );
  });

  test('NOT_FOUND maps to the not-available code and message', () {
    final error = ErrorMapper.fromCode('NOT_FOUND', requestId: 'request-1');
    expect(error.code, ErrorCode.notFound);
    expect(error.messageKey, 'propertyNotAvailable');
    expect(error.requestId, 'request-1');
  });

  test('unknown code preserves the request reference', () {
    final error = ErrorMapper.fromCode('UNKNOWN', requestId: 'request-1');
    expect(error.code.name, 'internal');
    expect(error.messageKey, 'errorUnexpected');
    expect(error.requestId, 'request-1');
  });

  test('network and retry time come from transport metadata', () {
    expect(ErrorMapper.noResponse().messageKey, 'errorNoConnection');
    expect(
      ErrorMapper.fromCode(
        'RATE_LIMITED',
        details: {'retry_after_seconds': 12},
      ).retryAfter,
      const Duration(seconds: 12),
    );
    expect(
      ErrorMapper.fromCode('RATE_LIMITED', retryAfterHeader: '9').retryAfter,
      const Duration(seconds: 9),
    );
  });

  group('S005 codes', () {
    test('each new code maps to its ErrorCode and message key', () {
      final expected = <String, (ErrorCode, String)>{
        'PROFILE_ALREADY_COMPLETE': (
          ErrorCode.profileAlreadyComplete,
          'authProfileIncomplete',
        ),
        'OTP_SEND_BLOCKED': (ErrorCode.otpSendBlocked, 'otpBlockedUntil'),
        'PHONE_NOT_ON_WHATSAPP': (
          ErrorCode.phoneNotOnWhatsApp,
          'whatsappNotOnWhatsApp',
        ),
        'APP_ATTESTATION_FAILED': (
          ErrorCode.appAttestationFailed,
          'otpAttestationFailed',
        ),
        'OTP_TEMPORARILY_UNAVAILABLE': (
          ErrorCode.otpTemporarilyUnavailable,
          'otpTemporarilyUnavailable',
        ),
        'OTP_SUPERSEDED': (ErrorCode.otpSuperseded, 'whatsappUseLatestCode'),
        'OTP_ATTEMPTS_EXCEEDED': (
          ErrorCode.otpAttemptsExceeded,
          'otpAttemptsExceeded',
        ),
      };
      for (final MapEntry(key: code, value: mapping) in expected.entries) {
        final error = ErrorMapper.fromCode(code);
        expect(error.code, mapping.$1, reason: code);
        expect(error.messageKey, mapping.$2, reason: code);
      }
    });

    test('the server payload is kept on ApiError.details', () {
      final error = ErrorMapper.fromCode(
        'OTP_SEND_BLOCKED',
        details: {
          'blocked_until': '2026-11-20T10:00:00Z',
          'server_time': '2026-11-13T10:00:00Z',
        },
      );
      expect(error.details, {
        'blocked_until': '2026-11-20T10:00:00Z',
        'server_time': '2026-11-13T10:00:00Z',
      });
      final detailed = ErrorMapper.fromCode('OTP_INVALID', details: {'x': 1});
      expect(detailed.details, {'x': 1});
    });

    test('gate codes notify ProfileGate exactly once; others never', () async {
      final events = <void>[];
      final subscription = ProfileGate.events.listen(events.add);
      addTearDown(subscription.cancel);

      ErrorMapper.fromCode('PROFILE_INCOMPLETE');
      ErrorMapper.fromCode('PHONE_NOT_VERIFIED');
      ErrorMapper.fromCode('OTP_INVALID');
      ErrorMapper.fromCode('RATE_LIMITED');
      ErrorMapper.fromCode('OTP_SEND_BLOCKED');
      await pumpEventQueue();

      expect(events, hasLength(2));
    });
  });
}
