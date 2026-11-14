import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:on_air/core/push/push_token_source.dart';

abstract interface class FirebaseMessagingGateway {
  Future<bool> canReadTokenWithoutPrompt();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;
}

final class PluginFirebaseMessagingGateway implements FirebaseMessagingGateway {
  PluginFirebaseMessagingGateway([FirebaseMessaging? messaging])
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<bool> canReadTokenWithoutPrompt() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      return !kIsWeb;
    }
    final settings = await _messaging.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently ||
      AuthorizationStatus.notDetermined => false,
    };
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}

final class FirebasePushTokenSource implements PushTokenSource {
  FirebasePushTokenSource([FirebaseMessagingGateway? gateway])
    : _gateway = gateway ?? PluginFirebaseMessagingGateway();

  final FirebaseMessagingGateway _gateway;

  @override
  Future<String?> currentToken() async {
    if (!await _gateway.canReadTokenWithoutPrompt()) return null;
    final token = await _gateway.getToken();
    return token == null || token.isEmpty ? null : token;
  }

  @override
  Stream<String> get tokenRefreshes => _gateway.onTokenRefresh;
}
