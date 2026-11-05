import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:on_air/core/api/generated/export.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/stay/domain/cancellation_preview.dart';
import 'package:on_air/features/stay/domain/damage_claim.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/domain/stay_results.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final class SupabaseStayRepository implements StayRepository {
  SupabaseStayRepository({
    required Future<dynamic> Function(String fn, Map<String, dynamic> params)
    rpc,
    required FallbackClient node,
  }) : this._(rpc, node);

  SupabaseStayRepository._(this._rpc, this._node);

  final Future<dynamic> Function(String fn, Map<String, dynamic> params) _rpc;
  final FallbackClient _node;

  @override
  Future<CancellationPreview> previewCancellation(String bookingId) =>
      _guard(() async {
        final response = await _rpc('guest_preview_cancellation', {
          'p_booking_id': bookingId,
        });
        return CancellationPreview.fromJson(
          Map<String, dynamic>.from(response! as Map),
        );
      });

  @override
  Future<CancellationResult> cancelBooking({
    required String bookingId,
    required Money expectedRefund,
    required CancellationReason? reason,
    required String? reasonNote,
    required String idempotencyKey,
  }) => _guard(() async {
    final response = await _rpc('guest_cancel_booking', {
      'p_booking_id': bookingId,
      'p_expected_refund_minor': expectedRefund.amountMinor,
      'p_reason': reason?.wire,
      'p_reason_note': reasonNote,
      'p_idempotency_key': idempotencyKey,
    });
    return CancellationResult.fromJson(
      Map<String, dynamic>.from(response! as Map),
    );
  });

  @override
  Future<String> confirmCheckIn(String bookingId) => _guard(() async {
    final response = await _rpc('guest_confirm_checkin', {
      'p_booking_id': bookingId,
    });
    return response! as String;
  });

  @override
  Future<String> confirmCheckOut(String bookingId) => _guard(() async {
    final response = await _rpc('guest_confirm_checkout', {
      'p_booking_id': bookingId,
    });
    return response! as String;
  });

  @override
  Future<CashRequest> startCashConfirmation({
    required String bookingId,
    required String collectorPhoneE164,
    required Money expectedAmount,
    required String idempotencyKey,
  }) => _guard(() async {
    final response = await _rpc('guest_start_cash_confirmation', {
      'p_booking_id': bookingId,
      'p_collector_phone': collectorPhoneE164,
      'p_expected_amount_minor': expectedAmount.amountMinor,
      'p_idempotency_key': idempotencyKey,
    });
    return CashRequest.fromJson(
      Map<String, dynamic>.from(response! as Map),
    );
  });

  @override
  Future<void> sendCashCode(String challengeId) async {
    try {
      await _node.sendOtpCode(
        xRequestId: const Uuid().v4(),
        body: V1OtpSendRequestBody(challengeId: challengeId),
      );
    } on DioException catch (error) {
      final inner = error.error;
      throw AppFailure(inner is ApiError ? inner : ErrorMapper.noResponse());
    }
  }

  @override
  Future<CashReceipt> confirmCashPayment({
    required String paymentId,
    required String challengeId,
    required String code,
  }) => _guard(() async {
    final response = await _rpc('guest_confirm_cash_payment', {
      'p_payment_id': paymentId,
      'p_challenge_id': challengeId,
      'p_code': code,
    });
    final json = Map<String, dynamic>.from(response! as Map);
    return CashReceipt.fromJson(
      Map<String, dynamic>.from(json['receipt'] as Map),
    );
  });

  @override
  Future<DamageClaim> getDamageClaim(String claimId) => _guard(() async {
    final response = await _rpc('guest_get_damage_claim', {
      'p_claim_id': claimId,
    });
    return DamageClaim.fromJson(
      Map<String, dynamic>.from(response! as Map),
    );
  });

  @override
  Future<ClaimAnswerResult> respondDamageClaim({
    required String claimId,
    required ClaimDecision decision,
    required String? note,
    required String idempotencyKey,
  }) => _guard(() async {
    final response = await _rpc('guest_respond_damage_claim', {
      'p_claim_id': claimId,
      'p_decision': decision.wire,
      'p_note': note,
      'p_attachment_ids': <String>[],
      'p_idempotency_key': idempotencyKey,
    });
    return ClaimAnswerResult.fromJson(
      Map<String, dynamic>.from(response! as Map),
    );
  });

  @override
  Future<FileUrl> fileUrl(String attachmentId) async {
    try {
      final response = await _node.getFileUrl(
        xRequestId: const Uuid().v4(),
        attachmentId: attachmentId,
      );
      return FileUrl(
        url: Uri.parse(response.url),
        expiresAt: response.expiresAt,
      );
    } on DioException catch (error) {
      final inner = error.error;
      throw AppFailure(inner is ApiError ? inner : ErrorMapper.noResponse());
    }
  }

  @override
  Future<OfferAnswerResult> respondReplacementOffer({
    required String offerId,
    required bool accept,
    required String idempotencyKey,
  }) => _guard(() async {
    final response = await _rpc('guest_respond_replacement_offer', {
      'p_offer_id': offerId,
      'p_accept': accept,
      'p_idempotency_key': idempotencyKey,
    });
    return OfferAnswerResult.fromJson(
      Map<String, dynamic>.from(response! as Map),
    );
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
