import 'dart:async';

import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/domain/support_repository.dart';

final class FakeSupportRepository implements SupportRepository {
  final List<CasePage> pages = [];
  final List<CaseDetails> detailPages = [];
  Exception? nextError;
  Exception? nextReplyError;
  Exception? nextCreateError;
  ReplyResult replyResult = const ReplyResult(
    messageId: 'm-server',
    caseStatus: CaseStatus.inProgress,
  );
  CreatedCase createResult = const CreatedCase(
    caseId: 'c-new',
    code: 'SC-2001',
  );
  final StreamController<void> changes = StreamController<void>.broadcast();
  final StreamController<bool> connected = StreamController<bool>.broadcast();
  final List<String?> listCursors = [];
  final List<String?> beforeCursors = [];
  final List<ReplyDraft> replies = [];
  final List<NewCaseDraft> creations = [];
  List<Map<String, dynamic>> faqRows = [];
  Exception? nextFaqError;
  int getCalls = 0;
  int closeLiveCalls = 0;
  String? liveCaseId;

  @override
  Future<CasePage> listCases({String? cursor}) async {
    listCursors.add(cursor);
    if (nextError case final error?) {
      nextError = null;
      throw error;
    }
    return pages.removeAt(0);
  }

  @override
  Future<CaseDetails> getCase(String id, {String? beforeCursor}) async {
    getCalls++;
    beforeCursors.add(beforeCursor);
    if (nextError case final error?) {
      nextError = null;
      throw error;
    }
    return detailPages.isEmpty ? sampleDetails() : detailPages.removeAt(0);
  }

  @override
  Future<ReplyResult> reply(String caseId, ReplyDraft draft) async {
    replies.add(draft);
    if (nextReplyError case final error?) {
      nextReplyError = null;
      throw error;
    }
    return replyResult;
  }

  @override
  Stream<void> caseChanges(String caseId) {
    liveCaseId = caseId;
    return changes.stream;
  }

  @override
  Stream<bool> get liveConnected => connected.stream;

  @override
  Future<void> closeCaseChanges() async {
    closeLiveCalls++;
    liveCaseId = null;
  }

  @override
  Future<CreatedCase> createCase(NewCaseDraft draft) async {
    creations.add(draft);
    if (nextCreateError case final error?) {
      nextCreateError = null;
      throw error;
    }
    return createResult;
  }

  bool anyUnread = false;

  @override
  Future<bool> anyUnreadStaffReply() async => anyUnread;

  @override
  Future<List<Map<String, dynamic>>> listFaq() async {
    if (nextFaqError case final error?) {
      nextFaqError = null;
      throw error;
    }
    return faqRows;
  }
}

SupportCase sampleSupportCase({
  String id = 'c0000000-0000-4000-8000-000000000001',
  String code = 'SC-1042',
  CaseStatus status = CaseStatus.waitingUser,
  DateTime? activity,
}) => SupportCase(
  id: id,
  code: code,
  type: CaseType.booking,
  status: status,
  bookingId: 'b0000000-0000-4000-8000-000000000021',
  bookingCode: 'OA-2042',
  createdAt: DateTime.utc(2026, 11, 15),
  lastActivityAt: activity ?? DateTime.utc(2026, 11, 16),
  hasUnreadStaffReply: true,
);

CaseDetails sampleDetails({CaseStatus status = CaseStatus.waitingUser}) =>
    CaseDetails(
      supportCase: sampleSupportCase(status: status),
      messages: [
        CaseMessage(
          id: 'm1',
          author: MessageAuthor.onAir,
          body: 'إزاي نقدر نساعدك؟',
          createdAt: DateTime.utc(2026, 11, 16, 10),
          attachments: const [],
        ),
      ],
      nextOlderCursor: null,
    );
