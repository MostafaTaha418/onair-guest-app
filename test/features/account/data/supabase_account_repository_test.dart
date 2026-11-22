import 'package:flutter_test/flutter_test.dart';
// Hide the generated ErrorCode: the core one (api_error.dart) is canonical.
import 'package:on_air/core/api/generated/export.dart' hide ErrorCode;
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/account/data/supabase_account_repository.dart';
import 'package:on_air/features/account/domain/notification_preference.dart';

// The generated ErrorCode clashes with the core one (S005 gotcha).
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

class _RpcMock {
  final calls = <(String, Map<String, dynamic>)>[];
  Exception? nextError;
  dynamic response = <String, dynamic>{};

  Future<dynamic> call(String fn, Map<String, dynamic> params) async {
    calls.add((fn, params));
    if (nextError case final error?) {
      nextError = null;
      throw error;
    }
    return response;
  }
}

class _NodeMock extends Fake implements FallbackClient {
  final otpCalls = <String>[];
  V1AccountPasswordRequestBody? passwordBody;

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

  @override
  Future<void> changePassword({
    required String xRequestId,
    required V1AccountPasswordRequestBody body,
  }) async {
    passwordBody = body;
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

  test('session methods use the U6 RPC names and parameters', () async {
    rpc.response = [
      {
        'id': 'current',
        'device_label': 'Pixel',
        'platform': 'android',
        'created_at': '2026-11-01T00:00:00Z',
        'last_active_at': '2026-11-17T00:00:00Z',
        'is_current': true,
      },
    ];
    expect((await repository.listSessions()).single.id, 'current');
    rpc.response = <String, dynamic>{};
    await repository.endSession('session-2');
    await repository.endOtherSessions();
    await repository.heartbeat();
    expect(rpc.calls.map((call) => call.$1), [
      'common_list_my_sessions',
      'common_end_session',
      'common_end_other_sessions',
      'common_heartbeat',
    ]);
    expect(rpc.calls[1].$2, {'p_session_id': 'session-2'});
  });

  test('changePassword calls the generated Node operation', () async {
    await repository.changePassword(current: 'Passw0rd!', next: 'Nextpass1');
    expect(node.passwordBody?.currentPassword, 'Passw0rd!');
    expect(node.passwordBody?.newPassword, 'Nextpass1');
  });

  test('notification preferences use the exact U9 RPC contract', () async {
    rpc.response = [
      {
        'category': 'support',
        'is_mandatory': false,
        'channels': [
          {'channel': 'push', 'enabled': true},
          {'channel': 'email', 'enabled': false},
        ],
      },
    ];
    final result = await repository.getPreferences();
    expect(result.single.enabled(NotificationChannel.email), isFalse);
    await repository.setPreference(
      'support',
      NotificationChannel.push,
      false,
    );
    expect(rpc.calls[0].$1, 'common_get_notification_preferences');
    expect(rpc.calls[0].$2, {'p_audience': 'guest'});
    expect(rpc.calls[1].$1, 'common_set_notification_preferences');
    expect(rpc.calls[1].$2, {
      'p_items': [
        {'category': 'support', 'channel': 'push', 'enabled': false},
      ],
    });
  });
}
