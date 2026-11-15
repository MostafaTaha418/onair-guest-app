import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/push/firebase_push_token_source.dart';

final class _Gateway implements FirebaseMessagingGateway {
  _Gateway({required this.allowed, this.token});

  final bool allowed;
  final String? token;
  final StreamController<String> refreshes =
      StreamController<String>.broadcast();
  int tokenReads = 0;

  @override
  Future<bool> canReadTokenWithoutPrompt() async => allowed;

  @override
  Future<String?> getToken() async {
    tokenReads += 1;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh => refreshes.stream;

  Future<void> close() => refreshes.close();
}

void main() {
  test('does not read a token when doing so could prompt', () async {
    final gateway = _Gateway(allowed: false, token: 'token');
    final source = FirebasePushTokenSource(gateway);

    expect(await source.currentToken(), isNull);
    expect(gateway.tokenReads, 0);

    await gateway.close();
  });

  test('returns the Firebase token after authorization', () async {
    final gateway = _Gateway(allowed: true, token: 'token');
    final source = FirebasePushTokenSource(gateway);

    expect(await source.currentToken(), 'token');
    expect(gateway.tokenReads, 1);

    await gateway.close();
  });

  test('forwards Firebase token refreshes', () async {
    final gateway = _Gateway(allowed: true);
    final source = FirebasePushTokenSource(gateway);
    final refreshed = expectLater(source.tokenRefreshes, emits('refreshed'));

    gateway.refreshes.add('refreshed');

    await refreshed;
    await gateway.close();
  });
}
