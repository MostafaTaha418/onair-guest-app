import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:on_air/core/api/generated/export.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/network/otp_send_interceptor.dart'
    show OtpSendInterceptor;
import 'package:on_air/features/auth/data/profile_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// The real «أكّد رقمك» backend: the phone RPCs over Supabase plus the Node
/// `POST /v1/otp/send` (contracts/supabase-auth.md A5–A7, node-otp.md A8).
/// The send's device-id/App-Check headers are attached by the
/// [OtpSendInterceptor] — never passed explicitly here.
final class SupabasePhoneVerificationRepository
    implements PhoneVerificationRepository {
  SupabasePhoneVerificationRepository({
    required this._rpc,
    required this._node,
  });

  final Future<dynamic> Function(String fn, Map<String, dynamic> params) _rpc;
  final FallbackClient _node;

  @override
  Future<String> start(
    PhoneVerificationDraft draft,
    PhoneVerificationPurpose purpose,
  ) => _guard(() async {
    // A5/A6: the terms and name go only when the account misses them; the
    // change flow carries the new number alone.
    final response = switch (purpose) {
      PhoneVerificationPurpose.register => await _rpc(
        'common_start_phone_verification',
        {
          'p_phone': draft.phone.e164,
          'p_full_name': draft.fullName,
          'p_accepted_terms_version': draft.acceptedTermsVersion,
          'p_locale': draft.locale,
        },
      ),
      PhoneVerificationPurpose.change => await _rpc(
        'common_request_phone_change',
        {'p_new_phone': draft.phone.e164},
      ),
    };
    final json = Map<String, dynamic>.from(response! as Map);
    return json['challenge_id'] as String;
  });

  @override
  Future<WhatsAppChallenge> send(String challengeId) async {
    try {
      final sent = await _node.sendOtpCode(
        xRequestId: const Uuid().v4(),
        body: V1OtpSendRequestBody(challengeId: challengeId),
      );
      return WhatsAppChallenge(
        challengeId: challengeId,
        maskedPhone: sent.maskedTarget,
        expiresAt: sent.expiresAt,
        window: SendWindow(
          serverTime: sent.serverTime,
          nextSendAt: sent.nextSendAt,
          blockedUntil: sent.blockedUntil,
        ),
      );
    } on DioException catch (error) {
      final inner = error.error;
      // 429 keeps its retryAfter through the shared ApiError; the S005
      // payloads (next_send_at / blocked_until) ride on ApiError.details.
      throw AppFailure(inner is ApiError ? inner : ErrorMapper.noResponse());
    }
  }

  @override
  Future<(DeliveryStatus, DeliveryFailure?, SendWindow)> status(
    String challengeId,
  ) => _guard(() async {
    final response = await _rpc('common_get_otp_status', {
      'p_challenge_id': challengeId,
    });
    final json = Map<String, dynamic>.from(response! as Map);
    return (
      _deliveryStatus(json['delivery_status'] as String?),
      _deliveryFailure(json['failure_reason'] as String?),
      SendWindow(
        serverTime: _requiredTime(json['server_time'], 'server_time'),
        nextSendAt: _time(json['next_send_at']),
        blockedUntil: _time(json['blocked_until']),
      ),
    );
  });

  @override
  Future<GuestAccount> verify(String challengeId, String code) => _guard(
    () async {
      final response = await _rpc('common_verify_otp', {
        'p_challenge_id': challengeId,
        'p_code': code,
      });
      final json = Map<String, dynamic>.from(response! as Map);
      // A5 step 6 returns the profile in the A4 context shape.
      final record = ProfileRecord.fromJson(json);
      final id = (json['guest_id'] ?? json['id'] ?? json['user_id']) as String?;
      if (id == null) {
        throw AppFailure(ErrorMapper.fromCode('INTERNAL'));
      }
      return GuestAccount(
        id: id,
        status: record.status,
        phone: record.phone,
        phoneVerified: record.phoneVerified,
        email: record.email,
        emailVerified: record.emailVerified,
        fullName: record.fullName,
        authProviders: record.authProviders,
        hasPassword: record.hasPassword,
        acceptedTermsVersion: record.acceptedTermsVersion,
        acceptedTermsAt: record.acceptedTermsAt,
      );
    },
  );

  static DeliveryStatus _deliveryStatus(String? value) => switch (value) {
    'pending' => DeliveryStatus.pending,
    'sent' => DeliveryStatus.sent,
    'delivered' => DeliveryStatus.delivered,
    'read' => DeliveryStatus.read,
    'failed' => DeliveryStatus.failed,
    _ => DeliveryStatus.unknown,
  };

  static DeliveryFailure? _deliveryFailure(String? value) => switch (value) {
    'not_on_whatsapp' => DeliveryFailure.notOnWhatsApp,
    'other' => DeliveryFailure.other,
    _ => null,
  };

  static DateTime? _time(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toUtc();

  static DateTime _requiredTime(Object? value, String field) {
    if (value == null) {
      throw AppFailure(ErrorMapper.fromCode('INTERNAL'));
    }
    return DateTime.parse(value as String).toUtc();
  }

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
