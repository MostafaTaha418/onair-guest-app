import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:on_air/core/errors/api_error.dart';

/// Detects a server-revoked refresh session on resume and within 60 seconds
/// while the signed-in app remains in the foreground.
final class SessionHeartbeat with WidgetsBindingObserver {
  SessionHeartbeat({
    required this.heartbeat,
    required this.isSignedIn,
    required this.onSessionEnded,
    this.interval = const Duration(seconds: 60),
  });

  final Future<void> Function() heartbeat;
  final bool Function() isSignedIn;
  final void Function() onSessionEnded;
  final Duration interval;

  Timer? _timer;
  bool _started = false;
  bool _resumed = true;
  bool _checking = false;
  bool _ended = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _schedule();
    unawaited(checkNow());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_resumed) {
      _schedule();
      unawaited(checkNow());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (!_resumed) return;
    _timer = Timer.periodic(interval, (_) => unawaited(checkNow()));
  }

  Future<void> checkNow() async {
    if (!_started || !_resumed || _checking || _ended || !isSignedIn()) return;
    _checking = true;
    try {
      await heartbeat();
    } on AppFailure catch (failure) {
      if (failure.error.code == ErrorCode.sessionRevoked ||
          failure.error.code == ErrorCode.unauthenticated) {
        _ended = true;
        _timer?.cancel();
        onSessionEnded();
      }
    } finally {
      _checking = false;
    }
  }

  void dispose() {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
