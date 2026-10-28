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
