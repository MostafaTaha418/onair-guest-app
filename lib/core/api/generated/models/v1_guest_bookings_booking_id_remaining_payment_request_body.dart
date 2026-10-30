// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'v1_guest_bookings_booking_id_remaining_payment_request_body.freezed.dart';
part 'v1_guest_bookings_booking_id_remaining_payment_request_body.g.dart';

@Freezed()
abstract class V1GuestBookingsBookingIdRemainingPaymentRequestBody
    with _$V1GuestBookingsBookingIdRemainingPaymentRequestBody {
  const factory V1GuestBookingsBookingIdRemainingPaymentRequestBody({
    @JsonKey(name: 'idempotency_key') required String idempotencyKey,
  }) = _V1GuestBookingsBookingIdRemainingPaymentRequestBody;

  factory V1GuestBookingsBookingIdRemainingPaymentRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$V1GuestBookingsBookingIdRemainingPaymentRequestBodyFromJson(json);
}
