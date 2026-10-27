import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:on_air/core/push/push_token_source.dart';

abstract interface class FirebaseMessagingGateway {
  Future<bool> canReadTokenWithoutPrompt();

  Future<void> register();

  Stream<String> get onRegistered;
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
  Future<void> register() => _messaging.register();

  @override
  Stream<String> get onRegistered => _messaging.onRegistered;
}

final class FirebasePushTokenSource implements PushTokenSource {
  FirebasePushTokenSource([FirebaseMessagingGateway? gateway])
    : _gateway = gateway ?? PluginFirebaseMessagingGateway();

  final FirebaseMessagingGateway _gateway;

  @override
  Future<String?> currentToken() async {
    if (!await _gateway.canReadTokenWithoutPrompt()) return null;
    final registration = _gateway.onRegistered.first.timeout(
      const Duration(seconds: 10),
      onTimeout: () => '',
    );
    await _gateway.register();
    final token = await registration;
    return token.isEmpty ? null : token;
  }

  @override
  Stream<String> get tokenRefreshes => _gateway.onRegistered;
}
