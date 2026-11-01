import 'dart:async';

import 'package:on_air/core/push/push_messages.dart';

/// Test double with controllable streams (T085): two broadcast controllers
/// and a settable cold-start message.
final class ControllablePushMessageSource implements PushMessageSource {
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  /// Returned by [initial]; set before the app pumps.
  PushMessage? initialMessage;

  void emitForeground(PushMessage message) => _foreground.add(message);

  void emitOpened(PushMessage message) => _opened.add(message);

  @override
  Stream<PushMessage> get foreground => _foreground.stream;

  @override
  Stream<PushMessage> get opened => _opened.stream;

  @override
  Future<PushMessage?> initial() async => initialMessage;

  Future<void> dispose() async {
    await _foreground.close();
    await _opened.close();
  }
}
