import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:on_air/core/api/generated/export.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/deletion.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// The Supabase-backed [AccountRepository] (contracts U5 + Node
/// `/v1/otp/send`, task T069).
final class SupabaseAccountRepository implements AccountRepository {
  SupabaseAccountRepository({
    required Future<dynamic> Function(String fn, Map<String, dynamic> params)
    rpc,
    required FallbackClient node,
  }) : this._(rpc, node);

  SupabaseAccountRepository._(this._rpc, this._node);

  final Future<dynamic> Function(String fn, Map<String, dynamic> params) _rpc;

  /// The generated Node client, the same one the cash code uses
  /// (`sendCashCode`, G3).
  final FallbackClient _node;

  @override
  Future<DeletionRequest> requestDeletion() => _guard(() async {
    final response = await _rpc('common_request_account_deletion', {});
    return DeletionRequest.fromJson(_asMap(response));
  });

  @override
  Future<SendWindow> sendDeletionCode(String challengeId) async {
    OtpSent sent;
    try {
      sent = await _node.sendOtpCode(
        xRequestId: const Uuid().v4(),
        body: V1OtpSendRequestBody(challengeId: challengeId),
      );
    } on DioException catch (error) {
      final inner = error.error;
      throw AppFailure(inner is ApiError ? inner : ErrorMapper.noResponse());
    }
    return SendWindow(
      serverTime: sent.serverTime,
      receivedAt: DateTime.now().toUtc(),
      nextSendAt: sent.nextSendAt,
      blockedUntil: sent.blockedUntil,
    );
  }

  @override
  Future<void> confirmDeletion(String challengeId, String code) => _guard(
    () async {
      await _rpc('common_confirm_account_deletion', {
        'p_challenge_id': challengeId,
        'p_code': code,
      });
    },
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      final code = [error.message, ?error.code].firstWhere(
        ErrorMapper.hasCode,
        orElse: () => 'INTERNAL',
      );
      if (code == 'ACCOUNT_HAS_ACTIVE_BOOKINGS') {
        final rawDetails = error.details;
        final details = DeletionBlockedException.parseDetailsJson(
          rawDetails is String
              ? rawDetails
              : rawDetails == null
              ? null
              : jsonEncode(rawDetails),
        );
        throw DeletionBlockedException(DeletionBlocker.fromDetails(details));
      }
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

  static Map<String, dynamic> _asMap(Object? value) =>
      Map<String, dynamic>.from(value! as Map);
}
