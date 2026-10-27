import 'package:on_air/features/account_gate/data/device_repository.dart';

/// In-memory device registration for `BACKEND_MODE=mock`.
final class MockDeviceTokenRepository implements DeviceTokenRepository {
  final Set<String> registeredTokens = {};

  @override
  Future<void> registerDeviceToken({
    required String token,
    required DevicePlatform platform,
    required String locale,
  }) async => registeredTokens.add(token);

  @override
  Future<void> unregisterDeviceToken(String token) async =>
      registeredTokens.remove(token);
}
