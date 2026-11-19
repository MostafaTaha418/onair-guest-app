import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class CaseLiveSource {
  Stream<void> get changes;
  Stream<bool> get connected;
  Future<void> open(String caseId);
  Future<void> close();
}

final class SupabaseCaseLiveChannel implements CaseLiveSource {
  SupabaseCaseLiveChannel(this._client);

  final SupabaseClient _client;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final StreamController<bool> _connected = StreamController<bool>.broadcast();
  RealtimeChannel? _channel;
  String? _caseId;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Stream<bool> get connected => _connected.stream;

  @override
  Future<void> open(String caseId) async {
    if (_caseId == caseId && _channel != null) return;
    await close();
    _caseId = caseId;
    _channel = _client
        .channel('support-case-$caseId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'case_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'case_id',
            value: caseId,
          ),
          callback: (_) => _changes.add(null),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'support_cases',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: caseId,
          ),
          callback: (_) => _changes.add(null),
        )
        .subscribe((status, _) {
          _connected.add(status == RealtimeSubscribeStatus.subscribed);
        });
  }

  @override
  Future<void> close() async {
    final channel = _channel;
    if (channel != null) {
      await _client.removeChannel(channel);
      _channel = null;
    }
    _caseId = null;
    _connected.add(false);
  }
}

final class ControllableCaseLiveSource implements CaseLiveSource {
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final StreamController<bool> _connected = StreamController<bool>.broadcast();

  String? openedCaseId;
  int opens = 0;
  int closes = 0;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Stream<bool> get connected => _connected.stream;

  @override
  Future<void> open(String caseId) async {
    openedCaseId = caseId;
    opens++;
  }

  void emitChange() {
    if (openedCaseId != null) _changes.add(null);
  }

  void setConnected({required bool value}) {
    if (openedCaseId != null) _connected.add(value);
  }

  @override
  Future<void> close() async {
    openedCaseId = null;
    closes++;
    _connected.add(false);
  }
}
