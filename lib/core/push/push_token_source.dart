abstract interface class PushTokenSource {
  Future<String?> currentToken();

  Stream<String> get tokenRefreshes;
}

final class NoopPushTokenSource implements PushTokenSource {
  const NoopPushTokenSource();

  @override
  Future<String?> currentToken() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();
}
