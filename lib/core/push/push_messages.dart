import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// One decoded FCM data payload (contracts/app-routes-g2.md §5): only
/// `type` and `target_id` are read; everything else is ignored.
@immutable
final class PushMessage {
  const PushMessage({required this.type, required this.targetId});

  final String type;
  final String targetId;

  /// Null when either required field is missing or not a string.
  static PushMessage? fromData(Map<String, dynamic> data) {
    final type = data['type'];
    final targetId = data['target_id'];
    if (type is! String || targetId is! String) return null;
    return PushMessage(type: type, targetId: targetId);
  }

  @override
  bool operator ==(Object other) =>
      other is PushMessage && other.type == type && other.targetId == targetId;

  @override
  int get hashCode => Object.hash(type, targetId);
}

/// The push streams the app reacts to: banners while foregrounded, taps
/// that open the app, and the cold-start message.
abstract interface class PushMessageSource {
  Stream<PushMessage> get foreground;
  Stream<PushMessage> get opened;
  Future<PushMessage?> initial();
}

/// Real FCM source (remote backend mode).
final class FirebasePushMessageSource implements PushMessageSource {
  static PushMessage? _decode(RemoteMessage message) =>
      PushMessage.fromData(message.data);

  @override
  Stream<PushMessage> get foreground => FirebaseMessaging.onMessage
      .map(_decode)
      .where((message) => message != null)
      .cast<PushMessage>();

  @override
  Stream<PushMessage> get opened => FirebaseMessaging.onMessageOpenedApp
      .map(_decode)
      .where((message) => message != null)
      .cast<PushMessage>();

  @override
  Future<PushMessage?> initial() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message == null ? null : PushMessage.fromData(message.data);
  }
}

/// Mock/test source: no pushes ever arrive.
final class NoopPushMessageSource implements PushMessageSource {
  const NoopPushMessageSource();

  @override
  Stream<PushMessage> get foreground => const Stream.empty();

  @override
  Stream<PushMessage> get opened => const Stream.empty();

  @override
  Future<PushMessage?> initial() async => null;
}
