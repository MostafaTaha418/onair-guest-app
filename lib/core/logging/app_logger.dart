import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

final class AppLogger {
  AppLogger({bool? release, void Function(String)? sink})
    : _release = release ?? kReleaseMode,
      _sink = sink ?? debugPrint;

  final bool _release;
  final void Function(String) _sink;

  static final _phone = RegExp(r'(?<!\d)(?:\+20|0)1[0125]\d{8}(?!\d)');
  static final _email = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );
  static final _jwt = RegExp(
    r'\b[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b',
  );

  String redact(String value) => value
      .replaceAll(_phone, '[phone]')
      .replaceAll(_email, '[email]')
      .replaceAll(_jwt, '[token]');

  void log(LogLevel level, String message) {
    if (_release && (level == LogLevel.debug || level == LogLevel.info)) return;
    _sink('${level.name}: ${redact(message)}');
  }

  void debug(String message) => log(LogLevel.debug, message);
  void info(String message) => log(LogLevel.info, message);
  void warning(String message) => log(LogLevel.warning, message);
  void error(String message) => log(LogLevel.error, message);
}
