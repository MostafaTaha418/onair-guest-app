import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/push/firebase_push_token_source.dart';

final class _Gateway implements FirebaseMessagingGateway {
  _Gateway({required this.allowed, this.token});

  final bool allowed;
  final String? token;
  final StreamController<String> registrations =
      StreamController<String>.broadcast();
  int registrationRequests = 0;

  @override
  Future<bool> canReadTokenWithoutPrompt() async => allowed;

  @override
  Stream<String> get onRegistered => registrations.stream;

  @override
  Future<void> register() async {
    registrationRequests += 1;
    final value = token;
    if (value != null) registrations.add(value);
  }

  Future<void> close() => registrations.close();
}

void main() {
  test('does not read a token when doing so could prompt', () async {
    final gateway = _Gateway(allowed: false, token: 'token');
    final source = FirebasePushTokenSource(gateway);

    expect(await source.currentToken(), isNull);
    expect(gateway.registrationRequests, 0);

    await gateway.close();
  });

  test('returns the Firebase token after authorization', () async {
    final gateway = _Gateway(allowed: true, token: 'token');
    final source = FirebasePushTokenSource(gateway);

    expect(await source.currentToken(), 'token');
    expect(gateway.registrationRequests, 1);

    await gateway.close();
  });

  test('forwards Firebase token refreshes', () async {
    final gateway = _Gateway(allowed: true);
    final source = FirebasePushTokenSource(gateway);
    final refreshed = expectLater(source.tokenRefreshes, emits('refreshed'));

    gateway.registrations.add('refreshed');

    await refreshed;
    await gateway.close();
  });
}
