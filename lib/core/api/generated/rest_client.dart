// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'fallback/fallback_client.dart';

/// OnAir Node Commands — Guest App G0 (DRAFT) `v0.1.0-draft`.
///
/// Draft contract written by the Guest App developer for the backend owner (Guest Plan §2.3).
/// Only the Node commands G0 needs. Supabase Auth and RLS reads are described in.
/// supabase-backend.md. Amounts, statuses, and permissions are never sent by the app.
///
/// Every request carries `Authorization: Bearer <Supabase access token>` (except where noted).
/// and `x-request-id` (UUID v4). Every error response uses the ErrorResponse shape.
///
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  }) : _dio = dio,
       _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.1.0-draft';

  FallbackClient? _fallback;

  FallbackClient get fallback =>
      _fallback ??= FallbackClient(_dio, baseUrl: _baseUrl);
}
