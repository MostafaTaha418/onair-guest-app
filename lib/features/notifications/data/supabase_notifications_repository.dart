import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/notifications/domain/app_notification.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads notification rows through `common_list_notifications`,
/// `common_unread_count`, and `common_mark_notifications_read` (G0). Nothing
/// but this class talks to Supabase for notifications (Constitution VII).
final class SupabaseNotificationsRepository implements NotificationsRepository {
  SupabaseNotificationsRepository({
    required Future<dynamic> Function(String fn, Map<String, dynamic> params)
    rpc,
  }) : this._(rpc);

  SupabaseNotificationsRepository._(this._rpc);

  final Future<dynamic> Function(String fn, Map<String, dynamic> params) _rpc;

  @override
  Future<List<AppNotification>> list({DateTime? before, int limit = 30}) =>
      _guard(() async {
        final rows = await _rpc('common_list_notifications', {
          'p_cursor': ?before?.toUtc().toIso8601String(),
          'p_limit': limit,
        });
        return [
          for (final row in _asList(rows))
            AppNotification.fromJson(_asMap(row)),
        ];
      });

  @override
  Future<int> unreadCount() => _guard(() async {
    final response = await _rpc('common_unread_count', {});
    return (response as num).toInt();
  });

  @override
  Future<void> markRead(List<String>? ids) => _guard(() async {
    await _rpc('common_mark_notifications_read', {'p_ids': ids});
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

  static Map<String, dynamic> _asMap(Object? value) =>
      Map<String, dynamic>.from(value! as Map);

  static List<Object?> _asList(Object? value) =>
      List<Object?>.from(value! as List);
}
