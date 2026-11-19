import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

final class UserAgentDevice {
  const UserAgentDevice({
    required this.platform,
    required this.osVersion,
    required this.model,
  });

  final String platform;
  final String osVersion;
  final String model;
}

final class UserAgentBuilder {
  const UserAgentBuilder({
    required this.loadVersion,
    required this.loadDevice,
  });

  factory UserAgentBuilder.fromPlatform({
    TargetPlatform? platform,
    DeviceInfoPlugin? deviceInfo,
  }) {
    final target = platform ?? defaultTargetPlatform;
    final plugin = deviceInfo ?? DeviceInfoPlugin();
    return UserAgentBuilder(
      loadVersion: () async => (await PackageInfo.fromPlatform()).version,
      loadDevice: () async => switch (target) {
        TargetPlatform.android => () async {
          final info = await plugin.androidInfo;
          return UserAgentDevice(
            platform: 'android',
            osVersion: info.version.release,
            model: info.model,
          );
        }(),
        TargetPlatform.iOS => () async {
          final info = await plugin.iosInfo;
          return UserAgentDevice(
            platform: 'ios',
            osVersion: info.systemVersion,
            model: info.model,
          );
        }(),
        _ => Future.value(
          UserAgentDevice(
            platform: target.name,
            osVersion: 'unknown',
            model: 'unknown',
          ),
        ),
      },
    );
  }

  final Future<String> Function() loadVersion;
  final Future<UserAgentDevice> Function() loadDevice;

  Future<String> build() async {
    final version = await loadVersion();
    final device = await loadDevice();
    return 'OnAirGuest/$version (${device.platform} ${device.osVersion}; ${device.model})';
  }
}
