import 'package:flutter_test/flutter_test.dart';
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
}
