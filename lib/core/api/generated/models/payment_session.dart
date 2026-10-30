// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'payment_session_currency.dart';

part 'payment_session.freezed.dart';
part 'payment_session.g.dart';

@Freezed()
abstract class PaymentSession with _$PaymentSession {
  const factory PaymentSession({
    @JsonKey(name: 'booking_id') required String bookingId,
    @JsonKey(name: 'payment_id') required String paymentId,
    @JsonKey(name: 'payment_url') required String paymentUrl,
    @JsonKey(name: 'payment_url_expires_at')
    required DateTime paymentUrlExpiresAt,

    /// Display only; computed on the server
    @JsonKey(name: 'amount_minor') required int amountMinor,
    required PaymentSessionCurrency currency,
  }) = _PaymentSession;

  factory PaymentSession.fromJson(Map<String, Object?> json) =>
      _$PaymentSessionFromJson(json);
}
