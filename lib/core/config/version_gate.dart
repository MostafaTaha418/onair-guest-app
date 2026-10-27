import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:on_air/core/config/app_config_repository.dart';

typedef InstalledBuildSource = Future<int?> Function();

/// Server-driven version gate: the installed build is compared against the
/// minimum supported build for the current platform from `app_config`.
///
/// The server is the authority (Constitution II): a config fetch that fails
/// keeps the current gate state, so the app opens normally when the check
/// cannot reach the server and an already-blocked session stays blocked.
/// The installed build number is resolved once and memoized; the config is
/// refetched on every check (app start and every resume).
final class VersionGate extends ChangeNotifier {
  VersionGate({
    required AppConfigSource configSource,
    required InstalledBuildSource installedBuildSource,
    required TargetPlatform Function() platformResolver,
    bool observeLifecycle = true,
  }) : _source = configSource,
       _buildSource = installedBuildSource,
       _currentPlatform = platformResolver {
    if (observeLifecycle) {
      _lifecycleListener = AppLifecycleListener(onResume: check);
    }
  }

  final AppConfigSource _source;
  final InstalledBuildSource _buildSource;
  final TargetPlatform Function() _currentPlatform;
  AppLifecycleListener? _lifecycleListener;
  Future<int?>? _installedBuild;
  bool _updateRequired = false;

  bool get updateRequired => _updateRequired;

  Future<void> check() async {
    final int? minSupportedBuild;
    try {
      final config = await _source.load(refresh: true);
      minSupportedBuild = switch (_currentPlatform()) {
        TargetPlatform.android => config.minSupportedBuildAndroid,
        TargetPlatform.iOS => config.minSupportedBuildIos,
        // Other platforms are not release targets; the gate does not apply.
        _ => null,
      };
    } on Object {
      return;
    }
    if (minSupportedBuild == null) {
      _setUpdateRequired(false);
      return;
    }
    try {
      final build = _installedBuild ??= _buildSource();
      final installedBuild = await build;
      _setUpdateRequired(
        installedBuild != null && installedBuild < minSupportedBuild,
      );
    } on Object {
      return;
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  void _setUpdateRequired(bool value) {
    if (_updateRequired == value) return;
    _updateRequired = value;
    notifyListeners();
  }
}
