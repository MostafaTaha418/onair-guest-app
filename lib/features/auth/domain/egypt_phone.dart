import 'package:flutter/foundation.dart';

@immutable
final class EgyptPhone {
  const EgyptPhone._(this.e164);

  factory EgyptPhone.parse(String value) {
    final phone = tryParse(value);
    if (phone == null) {
      throw FormatException('Invalid Egyptian mobile number', value);
    }
    return phone;
  }

  static EgyptPhone? tryParse(String value) {
    var normalized = value.replaceAll(RegExp(r'[\s()-]'), '');
    if (normalized.startsWith('01')) {
      normalized = '+20${normalized.substring(1)}';
    } else if (normalized.startsWith('20')) {
      normalized = '+$normalized';
    }
    return RegExp(r'^\+201[0125]\d{8}$').hasMatch(normalized)
        ? EgyptPhone._(normalized)
        : null;
  }

  final String e164;

  @override
  bool operator ==(Object other) => other is EgyptPhone && other.e164 == e164;

  @override
  int get hashCode => e164.hashCode;

  @override
  String toString() => e164;
}

/// `+201012345678` → `+20 10•• ••• 678` — the server's `masked_target`
/// style (node-otp.md A8): the operator prefix opens the display, the last
/// 3 digits stay readable, and everything in between is bullets. Numbers
/// too short to mask come back unchanged.
String maskPhone(String e164) {
  final digits = e164.replaceAll(RegExp(r'\D'), '');
  final rest = digits.startsWith('20') ? digits.substring(2) : digits;
  if (rest.length < 6) return e164;
  return '+20 ${rest.substring(0, 2)}•• '
      '••• ${rest.substring(rest.length - 3)}';
}
