// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'fallback/fallback_client.dart';

/// OnAir integrations-service — Guest App routes `v0.2.0-draft`.
///
/// The Node.js `integrations-service` routes the Guest App calls (Backend Master Plan §12.6).
/// The single source of names is `docs/OnAir Backend Master Plan.md` (28 Oct 2026).
///
/// Changed on 28 Oct 2026:.
/// - There is no SMS. Every code goes to the account's email through `POST /v1/otp/send`.
/// - Push tokens moved to the RPCs `common_register_device` / `common_unregister_device`.
///   The old `/v1/devices` routes are removed.
///
/// Rules:.
/// - Every request carries `Authorization: Bearer <Supabase access token>` and.
///   `x-request-id` (UUID v4).
/// - Every error response uses the ErrorResponse shape.
/// - Amounts, prices, statuses, and permissions are never sent by the app. Amounts in.
///   responses are integer minor units (`bigint`) plus `currency`.
/// - Reads and other commands go straight to Supabase RPC (`guest_*`, `common_*`). See.
///   supabase-backend.md and supabase-discovery.md.
///
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  }) : _dio = dio,
       _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.2.0-draft';

  FallbackClient? _fallback;

  FallbackClient get fallback =>
      _fallback ??= FallbackClient(_dio, baseUrl: _baseUrl);
}
