import 'package:flutter/foundation.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';

/// The Kashier session the Node route opened (contract §3).
@immutable
final class PaymentSessionInfo {
  const PaymentSessionInfo({
    required this.bookingId,
    required this.paymentId,
    required this.paymentUrl,
    required this.paymentUrlExpiresAt,
  });

  final String bookingId;
  final String paymentId;
  final Uri paymentUrl;
  final DateTime paymentUrlExpiresAt;

  @override
  bool operator ==(Object other) =>
      other is PaymentSessionInfo &&
      other.bookingId == bookingId &&
      other.paymentId == paymentId &&
      other.paymentUrl == paymentUrl &&
      other.paymentUrlExpiresAt == paymentUrlExpiresAt;

  @override
  int get hashCode =>
      Object.hash(bookingId, paymentId, paymentUrl, paymentUrlExpiresAt);
}

/// What `common_get_my_context()` says about verification (research R8).
@immutable
final class VerificationStatus {
  const VerificationStatus({
    required this.emailConfirmed,
    required this.phoneConfirmed,
    required this.email,
    required this.phone,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) =>
      VerificationStatus(
        emailConfirmed: json['email_confirmed'] as bool? ?? false,
        phoneConfirmed: json['phone_confirmed'] as bool? ?? false,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
      );

  final bool emailConfirmed;
  final bool phoneConfirmed;
  final String? email;
  final String? phone;

  bool get isComplete => emailConfirmed && phoneConfirmed;

  @override
  bool operator ==(Object other) =>
      other is VerificationStatus &&
      other.emailConfirmed == emailConfirmed &&
      other.phoneConfirmed == phoneConfirmed &&
      other.email == email &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(emailConfirmed, phoneConfirmed, email, phone);
}

/// The phone-change challenge created by `common_request_phone_change`.
@immutable
final class PhoneChallenge {
  const PhoneChallenge({required this.challengeId, this.retryAfter});

  final String challengeId;
  final Duration? retryAfter;

  @override
  bool operator ==(Object other) =>
      other is PhoneChallenge &&
      other.challengeId == challengeId &&
      other.retryAfter == retryAfter;

  @override
  int get hashCode => Object.hash(challengeId, retryAfter);
}

/// The booking flow's data layer: quote, payment start, and the
/// verify-before-booking challenges. Every method throws `AppFailure` on
/// error.
abstract interface class BookingFlowRepository {
  Future<VerificationStatus> verificationStatus();

  Future<BookingQuote> quote({
    required String propertyId,
    required StayRange stay,
    required int guests,
    required String termsHash,
  });

  /// Sends only `quoteId`, `termsHash`, and the attempt key — never an
  /// amount (Constitution III, AC-016).
  Future<PaymentSessionInfo> startPayment({
    required String quoteId,
    required String termsHash,
    required String attemptKey,
  });

  Future<PhoneChallenge> requestPhoneChange({
    required String phoneE164,
    required bool hasWhatsapp,
    String? whatsappE164,
  });

  Future<void> sendCode(String challengeId);

  Future<void> verifyCode({required String challengeId, required String code});
}
