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

/// Controllable source used by the in-process mock backend and journeys.
final class MockPushMessageSource implements PushMessageSource {
  final StreamController<PushMessage> _foreground =
      StreamController<PushMessage>.broadcast();
  final StreamController<PushMessage> _opened =
      StreamController<PushMessage>.broadcast();

  @override
  Stream<PushMessage> get foreground => _foreground.stream;

  @override
  Stream<PushMessage> get opened => _opened.stream;

  @override
  Future<PushMessage?> initial() async => null;

  void emitForeground(PushMessage message) => _foreground.add(message);
  void emitOpened(PushMessage message) => _opened.add(message);

  Future<void> dispose() async {
    await _foreground.close();
    await _opened.close();
  }
}
