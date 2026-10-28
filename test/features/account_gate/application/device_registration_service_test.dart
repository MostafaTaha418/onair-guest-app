import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/push/push_token_source.dart';
import 'package:on_air/features/account_gate/application/device_registration_service.dart';
import 'package:on_air/features/account_gate/data/device_repository.dart';

final class _PushTokens implements PushTokenSource {
  _PushTokens(this.token);

  final String? token;
  final refreshes = StreamController<String>.broadcast();

  @override
  Future<String?> currentToken() async => token;

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;
}

final class _Devices implements DeviceTokenRepository {
  final registrations = <String>[];

  @override
  Future<void> registerDeviceToken({
    required String token,
    required DevicePlatform platform,
    required String locale,
  }) async {
    registrations.add('$token:${platform.name}:$locale');
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {}
}

void main() {
  test('registers after sign-in and again when the token refreshes', () async {
    final tokens = _PushTokens('initial');
    final devices = _Devices();
    final service = DeviceRegistrationService(
      devices: devices,
      pushTokens: tokens,
      platform: DevicePlatform.android,
      locale: () => 'ar',
    )..start();

    await service.registerAfterSignIn();
    tokens.refreshes.add('refreshed');
    await Future<void>.delayed(Duration.zero);

    expect(devices.registrations, [
      'initial:android:ar',
      'refreshed:android:ar',
    ]);

    await service.close();
    await tokens.refreshes.close();
  });

  test('does not register a missing token', () async {
    final tokens = _PushTokens(null);
    final devices = _Devices();
    final service = DeviceRegistrationService(
      devices: devices,
      pushTokens: tokens,
      platform: DevicePlatform.ios,
      locale: () => 'en',
    );

    await service.registerAfterSignIn();

    expect(devices.registrations, isEmpty);
    await tokens.refreshes.close();
  });
}
