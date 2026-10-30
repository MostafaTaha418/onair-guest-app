import 'dart:async';

/// Time left to a server deadline (research R15). The deadline itself is
/// never extended or recomputed: when it passes the stream emits
/// [Duration.zero] once and closes, and the owning screen refetches.
final class Countdown {
  Countdown({required this._deadlineUtc, DateTime Function()? now})
    : _now = now ?? _defaultNow;

  static DateTime _defaultNow() => DateTime.now().toUtc();

  final DateTime _deadlineUtc;
  final DateTime Function() _now;
  Timer? _timer;
  StreamController<Duration>? _controller;
  bool _pastDeadline = false;

  /// Emits the remaining time immediately, then every 60 s while ≥ 1 h is
  /// left and every 1 s below it. Closes after zero.
  Stream<Duration> get remaining {
    final controller = _controller ??=
        // Synchronous delivery: a listener opened right now must see the
        // first value without waiting for a microtask.
        StreamController<Duration>.broadcast(
          sync: true,
          onListen: _emitAndSchedule,
          onCancel: _stopTimer,
        );
    if (controller.hasListener && !controller.isClosed) {
      // A listener that arrived after the first still gets the current
      // value at once; the tick schedule stays untouched.
      _emit(_left());
    }
    return controller.stream;
  }

  Duration _left() {
    final left = _deadlineUtc.difference(_now());
    return left.isNegative ? Duration.zero : left;
  }

  void _emitAndSchedule() {
    if (_pastDeadline) return;
    _emit(_left());
    if (_pastDeadline) return;
    _scheduleNext();
  }

  void _emit(Duration value) {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    if (value == Duration.zero) {
      _pastDeadline = true;
      _stopTimer();
      controller.add(Duration.zero);
      unawaited(controller.close());
      return;
    }
    controller.add(value);
  }

  void _scheduleNext() {
    _stopTimer();
    final period = _left() >= const Duration(hours: 1)
        ? const Duration(seconds: 60)
        : const Duration(seconds: 1);
    _timer = Timer(period, () {
      if (_pastDeadline) return;
      final value = _left();
      if (value == Duration.zero) {
        _emit(Duration.zero);
        return;
      }
      _emit(value);
      _scheduleNext();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void cancel() {
    _stopTimer();
    final controller = _controller;
    if (controller != null && !controller.isClosed) {
      unawaited(controller.close());
    }
    _controller = null;
  }

  /// `H:MM` above one hour (`23:05`, `1:00`), `M:SS` below (`59:09`, `0:07`),
  /// Western digits (G0 numerals decision).
  static String format(Duration d) {
    final totalSeconds = d.inSeconds;
    if (totalSeconds >= 3600) {
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    }
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
