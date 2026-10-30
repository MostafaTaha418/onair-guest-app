// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_v1_files_attachment_id_url_response.dart';
import '../models/otp_sent.dart';
import '../models/payment_session.dart';
import '../models/post_v1_uploads_sign_response.dart';
import '../models/v1_guest_bookings_booking_id_remaining_payment_request_body.dart';
import '../models/v1_guest_bookings_start_payment_request_body.dart';
import '../models/v1_otp_send_request_body.dart';
import '../models/v1_uploads_sign_request_body.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  /// Generate and email a 6-digit code for an existing challenge.
  ///
  /// The challenge is created first by an RPC that returns `challenge_id`:.
  /// `common_request_phone_change`, `common_request_account_deletion`,.
  /// `guest_start_cash_confirmation` (or the collector's `partner_record_cash_collection`).
  /// The caller must be the challenge's requester or its recipient. The code goes to the.
  /// **recipient's account email** through Resend, and only its hash is stored. Calling.
  /// again before `retry_after_seconds` returns 429.
  @POST('/v1/otp/send')
  Future<OtpSent> sendOtpCode({
    @Header('x-request-id') required String xRequestId,
    @Body() required V1OtpSendRequestBody body,
  });

  /// Create the booking from a quote and open a Kashier payment session.
  ///
  /// Calls `guest_start_booking` with the guest's own session, then creates the Kashier.
  /// session with the server-side amount. The same `idempotency_key` always returns the same.
  /// booking and session. Returning from the payment page is **not** a confirmation; the app.
  /// waits for the status notification (Realtime on `notifications`) and polls.
  /// `guest_get_booking`.
  @POST('/v1/guest/bookings/start-payment')
  Future<PaymentSession> startBookingPayment({
    @Header('x-request-id') required String xRequestId,
    @Body() required V1GuestBookingsStartPaymentRequestBody body,
  });

  /// Open a Kashier session for the remaining amount after a deposit
  @POST('/v1/guest/bookings/{bookingId}/remaining-payment')
  Future<PaymentSession> startRemainingPayment({
    @Header('x-request-id') required String xRequestId,
    @Path('bookingId') required String bookingId,
    @Body() required V1GuestBookingsBookingIdRemainingPaymentRequestBody body,
  });

  /// Get a short-lived signed PUT URL for a private attachment.
  ///
  /// Checks permission with `common_authorize_upload` (guest: own support case, own case.
  /// message, damage claim on own booking). Limits on type and size come from.
  /// `platform_settings.upload_limits`. Images should have EXIF removed by the app first.
  @POST('/v1/uploads/sign')
  Future<PostV1UploadsSignResponse> signUpload({
    @Header('x-request-id') required String xRequestId,
    @Body() required V1UploadsSignRequestBody body,
  });

  /// Get a short-lived signed GET URL for a private attachment the caller may read
  @GET('/v1/files/{attachmentId}/url')
  Future<GetV1FilesAttachmentIdUrlResponse> getFileUrl({
    @Header('x-request-id') required String xRequestId,
    @Path('attachmentId') required String attachmentId,
  });
}
