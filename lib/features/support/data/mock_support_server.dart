import 'dart:async';

import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:uuid/uuid.dart';

final class MockSupportServer implements SupportRepository {
  MockSupportServer({
    this.latency = const Duration(milliseconds: 250),
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc()) {
    _seed();
  }

  static const waitingCaseId = 'c0000000-0000-4000-8000-000000000001';
  static const resolvedCaseId = 'c0000000-0000-4000-8000-000000000002';
  static const closedCaseId = 'c0000000-0000-4000-8000-000000000003';
  static const systemCaseId = 'c0000000-0000-4000-8000-000000000004';
  static const foreignCaseId = 'c0000000-0000-4000-8000-000000000099';
  static const linkedBookingId = 'b0000000-0000-4000-8000-000000000021';

  final Duration latency;
  final DateTime Function() _now;
  final Map<String, _MockCaseRecord> _cases = {};
  final Map<String, ReplyResult> _replyResults = {};
  final StreamController<String> _changes =
      StreamController<String>.broadcast();
  final StreamController<bool> _connected = StreamController<bool>.broadcast();
  String? _openedCaseId;
  int replyCalls = 0;
  int getCalls = 0;
  String? get openedCaseId => _openedCaseId;

  void _seed() {
    _cases[waitingCaseId] = _record(
      id: waitingCaseId,
      code: 'SC-1042',
      type: 'booking',
      status: 'waiting_user',
      day: 16,
      unread: true,
      bookingId: linkedBookingId,
      bookingCode: 'OA-2042',
      messages: [
        _message('m-w-1', 'guest', 'محتاج مساعدة في معاد الدخول', 9),
        _message('m-w-2', 'onair', 'ممكن تبعت وقت وصولك؟', 10),
        _message('internal-w', 'internal', 'INTERNAL', 11),
      ],
    );
    _cases[resolvedCaseId] = _record(
      id: resolvedCaseId,
      code: 'SC-1038',
      type: 'refund',
      status: 'resolved',
      day: 15,
      messages: [
        _message('m-r-1', 'guest', 'الاسترداد اتأخر', 8),
        _message('m-r-2', 'onair', 'تم حل المشكلة', 9),
      ],
    );
    _cases[closedCaseId] = _record(
      id: closedCaseId,
      code: 'SC-1020',
      type: 'other',
      status: 'closed',
      day: 14,
      bookingId: linkedBookingId,
      bookingCode: 'OA-2042',
      messages: [_message('m-c-1', 'onair', 'الحالة مقفولة', 8)],
    );
    _cases[systemCaseId] = _record(
      id: systemCaseId,
      code: 'SC-1019',
      type: 'damage_dispute',
      status: 'in_progress',
      day: 13,
      messages: [_message('m-s-1', 'onair', 'بنراجع الاعتراض', 8)],
    );
  }

  void seedCase({required int index}) {
    final id =
        'c${index.toString().padLeft(7, '0')}-0000-4000-8000-000000000010';
    _cases[id] = _record(
      id: id,
      code: 'SC-${1100 + index}',
      type: 'other',
      status: index.isEven ? 'open' : 'resolved',
      day: (index % 20) + 1,
      messages: [_message('m-$index', 'guest', 'رسالة $index', 8)],
    );
  }

  _MockCaseRecord _record({
    required String id,
    required String code,
    required String type,
    required String status,
    required int day,
    required List<Map<String, dynamic>> messages,
    bool unread = false,
    String? bookingId,
    String? bookingCode,
  }) {
    final created = DateTime.utc(2026, 11, day, 8);
    return _MockCaseRecord(
      data: {
        'id': id,
        'code': code,
        'type': type,
        'status': status,
        'booking_id': bookingId,
        'booking_code': bookingCode,
        'property_id': null,
        'property_title': null,
        'created_at': created.toIso8601String(),
        'last_activity_at': created
            .add(const Duration(hours: 3))
            .toIso8601String(),
        'has_unread_staff_reply': unread,
      },
      messages: messages,
    );
  }

  Map<String, dynamic> _message(
    String id,
    String author,
    String body,
    int hour,
  ) => {
    'id': id,
    'author': author,
    'body': body,
    'created_at': DateTime.utc(2026, 11, 16, hour).toIso8601String(),
    'attachments': <Object>[],
  };

  Future<T> _delayed<T>(T Function() action) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return action();
  }

  Never _fail(String code) => throw AppFailure(ErrorMapper.fromCode(code));

  @override
  Future<CasePage> listCases({String? cursor}) => _delayed(() {
    final items =
        _cases.values
            .map((record) => SupportCase.fromJson(record.data))
            .toList()
          ..sort(SupportCase.compareForList);
    final offset = int.tryParse(cursor ?? '') ?? 0;
    final end = (offset + 20).clamp(0, items.length);
    return CasePage(
      items: items.sublist(offset, end),
      nextCursor: end < items.length ? '$end' : null,
    );
  });

  @override
  Future<CaseDetails> getCase(String id, {String? beforeCursor}) =>
      _delayed(() {
        getCalls++;
        final record = _cases[id];
        if (record == null || id == foreignCaseId) _fail('NOT_FOUND');
        record.data['has_unread_staff_reply'] = false;
        final visible = record.messages
            .where((message) => message['author'] != 'internal')
            .toList();
        return CaseDetails.fromJson({
          'case': record.data,
          'messages': visible,
          'next_older_cursor': null,
        });
      });

  @override
  Future<ReplyResult> reply(String caseId, ReplyDraft draft) => _delayed(() {
    replyCalls++;
    final record = _cases[caseId];
    if (record == null) _fail('NOT_FOUND');
    final previous = _replyResults[draft.draftId];
    if (previous != null) return previous;
    final body = draft.body.trim();
    if (body.isEmpty || body.length > 4000) _fail('VALIDATION_FAILED');
    final current = CaseStatus.fromWire(record.data['status'] as String);
    if (!current.isReplyable) _fail('CASE_CLOSED');
    final nextStatus = current == CaseStatus.resolved
        ? CaseStatus.open
        : current == CaseStatus.waitingUser
        ? CaseStatus.inProgress
        : current;
    final now = _now();
    final messageId = const Uuid().v4();
    record.messages.add({
      'id': messageId,
      'author': 'guest',
      'body': body,
      'created_at': now.toIso8601String(),
      'attachments': [
        for (final id in draft.attachmentIds)
          {'id': id, 'kind': 'image', 'size_bytes': 1024},
      ],
    });
    record.data
      ..['status'] = nextStatus.raw
      ..['last_activity_at'] = now.toIso8601String();
    final result = ReplyResult(
      messageId: messageId,
      caseStatus: nextStatus,
    );
    _replyResults[draft.draftId] = result;
    _changes.add(caseId);
    Timer(const Duration(seconds: 3), () => _staffReply(caseId));
    return result;
  });

  void _staffReply(String caseId) {
    final record = _cases[caseId];
    if (record == null || record.data['status'] == 'closed') return;
    final now = _now().add(const Duration(seconds: 3));
    record.messages.add({
      'id': const Uuid().v4(),
      'author': 'onair',
      'body': 'وصلنا ردك، وفريق OnAir بيتابع معاك.',
      'created_at': now.toIso8601String(),
      'attachments': <Object>[],
    });
    record.data
      ..['last_activity_at'] = now.toIso8601String()
      ..['has_unread_staff_reply'] = true;
    _changes.add(caseId);
  }

  void setStatus(String caseId, CaseStatus status) {
    final record = _cases[caseId];
    if (record == null) return;
    record.data['status'] = status.raw;
    _changes.add(caseId);
  }

  void sendStaffReply(String caseId) => _staffReply(caseId);

  @override
  Future<CreatedCase> createCase(NewCaseDraft draft) async =>
      _fail('ACTION_NOT_ALLOWED');

  @override
  Future<List<Map<String, dynamic>>> listFaq() async => const [];

  @override
  Stream<void> caseChanges(String caseId) {
    _openedCaseId = caseId;
    scheduleMicrotask(() => _connected.add(true));
    return _changes.stream.where((changed) => changed == caseId).map((_) {});
  }

  @override
  Stream<bool> get liveConnected => _connected.stream;

  @override
  Future<void> closeCaseChanges() async {
    _openedCaseId = null;
    _connected.add(false);
  }
}

final class _MockCaseRecord {
  _MockCaseRecord({required this.data, required this.messages});
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> messages;
}
