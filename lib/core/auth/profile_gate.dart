import 'dart:async';

/// Server said the account is incomplete or the phone is unverified; AuthCubit
/// refreshes the account so the router can redirect (research R9).
abstract final class ProfileGate {
  static final _controller = StreamController<void>.broadcast();

  static Stream<void> get events => _controller.stream;

  static void notify() => _controller.add(null);
}
