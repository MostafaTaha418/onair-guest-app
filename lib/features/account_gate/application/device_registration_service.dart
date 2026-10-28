import 'dart:async';

import 'package:on_air/core/push/push_token_source.dart';
import 'package:on_air/features/account_gate/data/device_repository.dart';

final class DeviceRegistrationService {
  DeviceRegistrationService({
    required this.devices,
    required this.pushTokens,
    required this.platform,
    required this.locale,
  });

  final DeviceTokenRepository devices;
  final PushTokenSource pushTokens;
  final DevicePlatform platform;
  final String Function() locale;
  StreamSubscription<String>? _refreshSubscription;

  void start() {
    _refreshSubscription ??= pushTokens.tokenRefreshes.listen(
      (token) => unawaited(_registerBestEffort(token)),
      onError: (Object _, StackTrace _) {},
    );
  }

  Future<void> registerAfterSignIn() async {
    final token = await pushTokens.currentToken();
    if (token != null && token.isNotEmpty) await _register(token);
  }

  Future<void> _register(String token) => devices.registerDeviceToken(
    token: token,
    platform: platform,
    locale: locale(),
  );

  Future<void> _registerBestEffort(String token) async {
    try {
      await _register(token);
    } on Object {
      // Token registration is retried on the next sign-in or token refresh.
    }
  }

  Future<void> close() async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
  }
}
