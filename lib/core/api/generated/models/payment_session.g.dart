// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentSession _$PaymentSessionFromJson(Map<String, dynamic> json) =>
    _PaymentSession(
      bookingId: json['booking_id'] as String,
      paymentId: json['payment_id'] as String,
      paymentUrl: json['payment_url'] as String,
      paymentUrlExpiresAt: DateTime.parse(
        json['payment_url_expires_at'] as String,
      ),
      amountMinor: (json['amount_minor'] as num).toInt(),
      currency: PaymentSessionCurrency.fromJson(json['currency'] as String),
    );

Map<String, dynamic> _$PaymentSessionToJson(_PaymentSession instance) =>
    <String, dynamic>{
      'booking_id': instance.bookingId,
      'payment_id': instance.paymentId,
      'payment_url': instance.paymentUrl,
      'payment_url_expires_at': instance.paymentUrlExpiresAt.toIso8601String(),
      'amount_minor': instance.amountMinor,
      'currency': _$PaymentSessionCurrencyEnumMap[instance.currency]!,
    };

const _$PaymentSessionCurrencyEnumMap = {
  PaymentSessionCurrency.egp: 'EGP',
  PaymentSessionCurrency.$unknown: r'$unknown',
};
