import 'package:flutter_test/flutter_test.dart';
// Hide the generated ErrorCode: the core one (api_error.dart) is canonical.
import 'package:on_air/core/api/generated/export.dart' hide ErrorCode;
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/account/data/supabase_account_repository.dart';

// The generated ErrorCode clashes with the core one (S005 gotcha).
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

class _RpcMock {
  final calls = <(String, Map<String, dynamic>)>[];
  Exception? nextError;

  Future<dynamic> call(String fn, Map<String, dynamic> params) async {
    calls.add((fn, params));
    if (nextError case final error?) {
      nextError = null;
      throw error;
    }
    return <String, dynamic>{};
  }
}

class _NodeMock extends Fake implements FallbackClient {
  final otpCalls = <String>[];

  @override
  Future<OtpSent> sendOtpCode({
    required String xRequestId,
    required V1OtpSendRequestBody body,
    String? xDeviceId,
    String? xFirebaseAppCheck,
  }) async {
    otpCalls.add(body.challengeId);
    return OtpSent(
      channel: OtpSentChannel.email,
      maskedTarget: 'g***@e***.com',
      expiresAt: DateTime.utc(2026, 11, 17, 13),
      serverTime: DateTime.utc(2026, 11, 17, 12),
      nextSendAt: DateTime.utc(2026, 11, 17, 12, 1),
    );
  }
}

/// T072's repository half: exact function and parameter names from the
/// Reference table (`common_update_profile(p_full_name, p_locale)`), a
/// null parameter being omitted, and errors through `ErrorMapper`.
void main() {
  late _RpcMock rpc;
  late _NodeMock node;
  late SupabaseAccountRepository repository;

  setUp(() {
    rpc = _RpcMock();
    node = _NodeMock();
    repository = SupabaseAccountRepository(
      rpc: rpc.call,
      node: node,
    );
  });

  test('updateProfile sends both RPC parameters when supplied', () async {
    await repository.updateProfile(fullName: 'زائر', locale: 'en');
    final (fn, params) = rpc.calls.single;
    expect(fn, 'common_update_profile');
    expect(params, {
      'p_full_name': 'زائر',
      'p_locale': 'en',
    });
  });

  test('a null parameter is omitted from the update', () async {
    await repository.updateProfile(locale: 'ar');
    expect(rpc.calls.single.$2, {
      'p_locale': 'ar',
    });
  });

  test('VALIDATION_FAILED goes through ErrorMapper', () async {
    rpc.nextError = const PostgrestException(message: 'VALIDATION_FAILED');
    await expectLater(
      repository.updateProfile(fullName: 'ا'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.error.code,
          'code',
          ErrorCode.validationFailed,
        ),
      ),
    );
  });
}
