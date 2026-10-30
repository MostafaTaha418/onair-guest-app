// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'v1_guest_bookings_start_payment_request_body.freezed.dart';
part 'v1_guest_bookings_start_payment_request_body.g.dart';

@Freezed()
abstract class V1GuestBookingsStartPaymentRequestBody
    with _$V1GuestBookingsStartPaymentRequestBody {
  const factory V1GuestBookingsStartPaymentRequestBody({
    @JsonKey(name: 'quote_id') required String quoteId,
    @JsonKey(name: 'terms_hash') required String termsHash,
    @JsonKey(name: 'idempotency_key') required String idempotencyKey,
  }) = _V1GuestBookingsStartPaymentRequestBody;

  factory V1GuestBookingsStartPaymentRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$V1GuestBookingsStartPaymentRequestBodyFromJson(json);
}
