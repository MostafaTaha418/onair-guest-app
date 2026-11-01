import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:on_air/core/api/generated/export.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Talks to `guest_quote_booking`, `common_get_my_context`, the phone-change
/// RPCs, and the Node `start-payment` / `otp/send` routes
/// (contracts/supabase-booking.md §1). Nothing but this class knows where the
/// flow's data comes from (Constitution VII).
final class SupabaseBookingFlowRepository implements BookingFlowRepository {
  SupabaseBookingFlowRepository({
    required Future<dynamic> Function(String fn, Map<String, dynamic> params)
    rpc,
    required FallbackClient node,
  }) : this._(rpc, node);

  SupabaseBookingFlowRepository._(this._rpc, this._node);

  final Future<dynamic> Function(String fn, Map<String, dynamic> params) _rpc;
  final FallbackClient _node;

  @override
  Future<VerificationStatus> verificationStatus() => _guard(() async {
    final response = await _rpc('common_get_my_context', {});
    return VerificationStatus.fromJson(
      Map<String, dynamic>.from(response! as Map),
    );
  });

  @override
  Future<BookingQuote> quote({
    required String propertyId,
    required StayRange stay,
    required int guests,
    required String termsHash,
  }) => _guard(() async {
    final response = await _rpc('guest_quote_booking', {
      'p_property_id': propertyId,
      'p_check_in': stay.checkIn.toString(),
      'p_check_out': stay.checkOut.toString(),
      'p_guests': guests,
      'p_terms_hash': termsHash,
    });
    return BookingQuote.fromJson(
      Map<String, dynamic>.from(response! as Map),
    );
  });

  @override
  Future<PaymentSessionInfo> startPayment({
    required String quoteId,
    required String termsHash,
    required String attemptKey,
  }) async {
    try {
      // Only the quote, the terms, and the attempt key travel — never an
      // amount (Constitution III, AC-016).
      final session = await _node.startBookingPayment(
        xRequestId: const Uuid().v4(),
        body: V1GuestBookingsStartPaymentRequestBody(
          quoteId: quoteId,
          termsHash: termsHash,
          idempotencyKey: attemptKey,
        ),
      );
      return PaymentSessionInfo(
        bookingId: session.bookingId,
        paymentId: session.paymentId,
        paymentUrl: Uri.parse(session.paymentUrl),
        paymentUrlExpiresAt: session.paymentUrlExpiresAt,
      );
    } on DioException catch (error) {
      final inner = error.error;
      throw AppFailure(
        inner is ApiError ? inner : ErrorMapper.noResponse(),
      );
    }
  }

  @override
  Future<PhoneChallenge> requestPhoneChange({
    required String phoneE164,
    required bool hasWhatsapp,
    String? whatsappE164,
  }) => _guard(() async {
    final response = await _rpc('common_request_phone_change', {
      'p_new_phone': phoneE164,
      'p_has_whatsapp': hasWhatsapp,
      'p_whatsapp_e164': ?whatsappE164,
    });
    final json = Map<String, dynamic>.from(response! as Map);
    return PhoneChallenge(challengeId: json['challenge_id'] as String);
  });

  @override
  Future<void> sendCode(String challengeId) async {
    try {
      await _node.sendOtpCode(
        xRequestId: const Uuid().v4(),
        body: V1OtpSendRequestBody(challengeId: challengeId),
      );
    } on DioException catch (error) {
      final inner = error.error;
      // A 429 keeps its `retryAfter` through the shared ApiError.
      throw AppFailure(
        inner is ApiError ? inner : ErrorMapper.noResponse(),
      );
    }
  }

  @override
  Future<void> verifyCode({
    required String challengeId,
    required String code,
  }) => _guard(() async {
    await _rpc('common_verify_otp', {
      'p_challenge_id': challengeId,
      'p_code': code,
    });
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      final code = [error.message, ?error.code].firstWhere(
        ErrorMapper.hasCode,
        orElse: () => 'INTERNAL',
      );
      throw AppFailure(ErrorMapper.fromCode(code));
    } on SocketException {
      throw AppFailure(ErrorMapper.noResponse());
    } on TimeoutException {
      throw AppFailure(ErrorMapper.noResponse());
    } on http.ClientException {
      throw AppFailure(ErrorMapper.noResponse());
    } on AppFailure {
      rethrow;
    } on Object {
      throw AppFailure(ErrorMapper.fromCode('INTERNAL'));
    }
  }
}
