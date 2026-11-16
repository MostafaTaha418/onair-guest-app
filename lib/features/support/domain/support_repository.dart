import 'package:on_air/features/support/domain/support_case.dart';

final class NewCaseDraft {
  const NewCaseDraft({
    required this.draftId,
    required this.type,
    required this.body,
    this.bookingId,
    this.propertyId,
    this.attachmentIds = const [],
  });

  final String draftId;
  final CaseType type;
  final String body;
  final String? bookingId;
  final String? propertyId;
  final List<String> attachmentIds;
}

final class ReplyDraft {
  const ReplyDraft({
    required this.draftId,
    required this.body,
    this.attachmentIds = const [],
  });

  final String draftId;
  final String body;
  final List<String> attachmentIds;
}

final class CreatedCase {
  const CreatedCase({required this.caseId, required this.code});
  final String caseId;
  final String code;
}

final class ReplyResult {
  const ReplyResult({required this.messageId, required this.caseStatus});
  final String messageId;
  final CaseStatus caseStatus;
}

abstract interface class SupportRepository {
  Future<CasePage> listCases({String? cursor});
  Future<CaseDetails> getCase(String id, {String? beforeCursor});
  Future<CreatedCase> createCase(NewCaseDraft draft);
  Future<ReplyResult> reply(String caseId, ReplyDraft draft);
  Future<List<Map<String, dynamic>>> listFaq();
  Stream<void> caseChanges(String caseId);
  Stream<bool> get liveConnected;
  Future<void> closeCaseChanges();
}
