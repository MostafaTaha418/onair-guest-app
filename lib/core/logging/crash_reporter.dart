abstract interface class CrashReporter {
  void record(Object error, StackTrace stackTrace);
}

final class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  void record(Object error, StackTrace stackTrace) {}
}
