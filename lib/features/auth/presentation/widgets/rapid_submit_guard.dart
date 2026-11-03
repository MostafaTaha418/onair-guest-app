/// Suppresses accidental repeated taps even if the first request finishes fast.
final class RapidSubmitGuard {
  RapidSubmitGuard({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  DateTime? _lastSubmission;

  void reset() => _lastSubmission = null;

  bool tryEnter() {
    final now = _clock();
    if (_lastSubmission case final last?) {
      if (now.difference(last) < const Duration(milliseconds: 700)) {
        return false;
      }
    }
    _lastSubmission = now;
    return true;
  }
}
