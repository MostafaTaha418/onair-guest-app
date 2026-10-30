// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_guest_bookings_start_payment_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_V1GuestBookingsStartPaymentRequestBody
_$V1GuestBookingsStartPaymentRequestBodyFromJson(Map<String, dynamic> json) =>
    _V1GuestBookingsStartPaymentRequestBody(
      quoteId: json['quote_id'] as String,
      termsHash: json['terms_hash'] as String,
      idempotencyKey: json['idempotency_key'] as String,
    );

Map<String, dynamic> _$V1GuestBookingsStartPaymentRequestBodyToJson(
  _V1GuestBookingsStartPaymentRequestBody instance,
) => <String, dynamic>{
  'quote_id': instance.quoteId,
  'terms_hash': instance.termsHash,
  'idempotency_key': instance.idempotencyKey,
};
