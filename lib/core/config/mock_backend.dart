import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/device/device_identity.dart';

/// Fixed values shared by the in-memory (mock) repositories
/// (`BACKEND_MODE=mock`, Guest Plan §2.6). Never used in production.
abstract final class MockBackend {
  /// Every email code is accepted only if it equals this value.
  static const verificationCode = '123456';

  static const termsVersion = 'mock-terms-v1';

  /// Resend countdown the mock "server" returns after sending a code.
  static const resendInterval = Duration(seconds: 30);

  static const appConfig = AppConfig(
    minSupportedBuildAndroid: 1,
    minSupportedBuildIos: 1,
    supportPhone: '+201000000000',
    currentTermsVersion: termsVersion,
  );
}

/// Public app configuration without a backend.
final class MockAppConfigSource implements AppConfigSource {
  const MockAppConfigSource();

  @override
  Future<AppConfig> load({bool refresh = false}) async => MockBackend.appConfig;

  @override
  void clearCache() {}
}

/// Mock device id for the OTP send-limit keys (S005 US5); the value is
/// stable per app session and never leaves the process.
final class MemoryDeviceIdentity implements DeviceIdentity {
  const MemoryDeviceIdentity([this.value = 'mock-device']);

  final String value;

  @override
  Future<String> id() async => value;
}
