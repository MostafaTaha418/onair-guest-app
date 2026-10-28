import 'package:flutter/services.dart';

abstract interface class SecureScreenControl {
  Future<void> setSecure({required bool enabled});
}

final class SecureScreen implements SecureScreenControl {
  const SecureScreen();

  static const _channel = MethodChannel('on_air/secure_screen');

  @override
  Future<void> setSecure({required bool enabled}) async {
    try {
      await _channel.invokeMethod<void>('setSecure', {'enabled': enabled});
    } on MissingPluginException {
      // Widget/unit tests do not install the native channel.
    }
  }
}
