import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/version_gate.dart';

import '../../helpers/fake_app_config_repository.dart';

const _config = AppConfig(
  minSupportedBuildAndroid: 20,
  minSupportedBuildIos: 15,
  supportPhone: '+201000000000',
  currentTermsVersion: 'v1',
);

final class _ThrowingConfigRepository implements AppConfigSource {
  @override
  Future<AppConfig> load({bool refresh = false}) async {
    throw Exception('config unavailable');
  }

  @override
  void clearCache() {}
}

VersionGate _gate({
  AppConfigSource? configSource,
  Future<int?> Function()? installedBuild,
  TargetPlatform platform = TargetPlatform.android,
}) {
  final gate = VersionGate(
    configSource: configSource ?? FakeAppConfigRepository(_config),
    installedBuildSource: installedBuild ?? (() async => 1),
    platformResolver: () => platform,
    observeLifecycle: false,
  );
  addTearDown(gate.dispose);
  return gate;
}

void main() {
  test('a build below the platform minimum activates the gate', () async {
    final gate = _gate(installedBuild: () async => 19);
    await gate.check();
    expect(gate.updateRequired, isTrue);
  });

  test('a build at the minimum is not blocked', () async {
    final gate = _gate(installedBuild: () async => 20);
    await gate.check();
    expect(gate.updateRequired, isFalse);
  });

  test('each platform compares against its own minimum', () async {
    // Build 17 is below the Android minimum (20) but above the iOS one (15).
    final android = _gate(installedBuild: () async => 17);
    final ios = _gate(
      installedBuild: () async => 17,
      platform: TargetPlatform.iOS,
    );
    await android.check();
    await ios.check();
    expect(android.updateRequired, isTrue);
    expect(ios.updateRequired, isFalse);
  });

  test('platforms outside the release targets are never blocked', () async {
    final gate = _gate(
      installedBuild: () async => 1,
      platform: TargetPlatform.macOS,
    );
    await gate.check();
    expect(gate.updateRequired, isFalse);
  });

  test('an unknown installed build never blocks', () async {
    final gate = _gate(installedBuild: () async => null);
    await gate.check();
    expect(gate.updateRequired, isFalse);
  });

  test('a failed config fetch never activates the gate', () async {
    final gate = _gate(configSource: _ThrowingConfigRepository());
    await gate.check();
    expect(gate.updateRequired, isFalse);
  });

  test('an active gate survives a failed resume check', () async {
    var shouldThrow = false;
    final gate = _gate(
      installedBuild: () async => 19,
      configSource: _FailingAfterFirstConfigRepository(() => shouldThrow),
    );
    await gate.check();
    expect(gate.updateRequired, isTrue);
    shouldThrow = true;
    await gate.check();
    expect(
      gate.updateRequired,
      isTrue,
      reason: 'a failed re-check must not lift the gate',
    );
  });

  test('the gate refreshes the config on every check', () async {
    final repository = FakeAppConfigRepository(_config);
    final gate = _gate(
      configSource: repository,
      installedBuild: () async => 20,
    );
    await gate.check();
    await gate.check();
    expect(repository.loadCount, 2);
  });

  test('listeners are notified only when the gate state flips', () async {
    final gate = _gate(installedBuild: () async => 19);
    var notifications = 0;
    gate.addListener(() => notifications++);
    await gate.check();
    await gate.check();
    expect(gate.updateRequired, isTrue);
    expect(notifications, 1);
  });
}

final class _FailingAfterFirstConfigRepository implements AppConfigSource {
  _FailingAfterFirstConfigRepository(this.shouldThrow);
  final bool Function() shouldThrow;
  var _calls = 0;

  @override
  Future<AppConfig> load({bool refresh = false}) async {
    _calls++;
    if (_calls > 1 && shouldThrow()) {
      throw Exception('config unavailable');
    }
    return _config;
  }

  @override
  void clearCache() {}
}
