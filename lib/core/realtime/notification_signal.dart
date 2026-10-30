import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One live notification row for the signed-in guest (data-model §10).
/// Consumers match on [entityId] and read [typeKey] for context only.
@immutable
final class NotificationSignal {
  const NotificationSignal({
    required this.id,
    required this.typeKey,
    required this.entityType,
    required this.entityId,
  });

  /// Null when the record is not a guest notification row; missing fields
  /// default per the contract.
  static NotificationSignal? fromRecord(Map<String, dynamic> record) {
    final typeKey = record['type_key'];
    final entityId = record['entity_id'];
    if (typeKey is! String || entityId is! String) return null;
    return NotificationSignal(
      id: record['id'] is String ? record['id'] as String : '',
      typeKey: typeKey,
      entityType: record['entity_type'] is String
          ? record['entity_type'] as String
          : '',
      entityId: entityId,
    );
  }

  final String id;
  final String typeKey;
  final String entityType;
  final String entityId;

  @override
  bool operator ==(Object other) =>
      other is NotificationSignal &&
      other.id == id &&
      other.typeKey == typeKey &&
      other.entityType == entityType &&
      other.entityId == entityId;

  @override
  int get hashCode => Object.hash(id, typeKey, entityType, entityId);
}

/// The single live channel for the signed-in guest (Guest Plan §12.3):
/// features subscribe through this, never to Supabase on their own.
abstract interface class NotificationSignalSource {
  Stream<NotificationSignal> get signals;

  Future<void> start(String userId);

  Future<void> stop();
}

/// The real implementation: one Realtime channel on `public.notifications`
/// filtered by the guest's own rows (RLS + change filter, research R9).
final class SupabaseNotificationSignalSource
    implements NotificationSignalSource {
  SupabaseNotificationSignalSource(this._client);

  final SupabaseClient _client;
  final StreamController<NotificationSignal> _controller =
      StreamController<NotificationSignal>.broadcast();
  RealtimeChannel? _channel;
  String? _userId;

  @override
  Stream<NotificationSignal> get signals => _controller.stream;

  @override
  Future<void> start(String userId) async {
    if (_userId == userId && _channel != null) return;
    await stop();
    _userId = userId;
    _channel =
        _client
            .channel('guest-notifications-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (payload) {
                final signal = NotificationSignal.fromRecord(payload.newRecord);
                if (signal != null) _controller.add(signal);
              },
            )
          ..subscribe();
  }

  @override
  Future<void> stop() async {
    final channel = _channel;
    if (channel != null) {
      await _client.removeChannel(channel);
      _channel = null;
    }
    _userId = null;
  }
}

/// Test and mock-mode source: emissions are delivered only while started.
final class ControllableNotificationSignalSource
    implements NotificationSignalSource {
  final StreamController<NotificationSignal> _controller =
      StreamController<NotificationSignal>.broadcast();

  String? _userId;

  @override
  Stream<NotificationSignal> get signals => _controller.stream;

  @override
  Future<void> start(String userId) async {
    _userId = userId;
  }

  @override
  Future<void> stop() async {
    _userId = null;
  }

  /// Ignored unless the source was started and not stopped.
  void emit(NotificationSignal signal) {
    if (_userId == null) return;
    _controller.add(signal);
  }
}
