import 'package:flutter/foundation.dart';

@immutable
final class GuestAccount {
  GuestAccount({
    required this.id,
    this.phone,
    this.phoneVerified = false,
    this.email,
    this.emailVerified = false,
    String? fullName,
    this.acceptedTermsVersion,
    this.acceptedTermsAt,
  }) : fullName = fullName?.trim() {
    if (phone == null && email == null) {
      throw ArgumentError('A phone or email is required');
    }
    if (phone != null && !RegExp(r'^\+201[0125]\d{8}$').hasMatch(phone!)) {
      throw ArgumentError.value(phone, 'phone');
    }
    if (this.fullName != null &&
        (this.fullName!.length < 2 || this.fullName!.length > 80)) {
      throw ArgumentError.value(fullName, 'fullName');
    }
  }

  final String id;
  final String? phone;
  final bool phoneVerified;
  final String? email;
  final bool emailVerified;
  final String? fullName;
  final String? acceptedTermsVersion;
  final DateTime? acceptedTermsAt;

  bool isComplete(String currentTermsVersion) =>
      fullName != null && acceptedTermsVersion == currentTermsVersion;
}
