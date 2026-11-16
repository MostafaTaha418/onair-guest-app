import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/support/data/case_live_channel.dart';
import 'package:on_air/features/support/data/supabase_support_repository.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

void main() {
  const caseId = 'c0000000-0000-4000-8000-000000000001';
  final caseJson = <String, dynamic>{
    'id': caseId,
    'code': 'SC-1',
    'type': 'booking',
    'status': 'open',
    'booking_id': null,
    'booking_code': null,
    'property_id': null,
    'property_title': null,
    'created_at': '2026-11-16T10:00:00Z',
    'last_activity_at': '2026-11-16T11:00:00Z',
    'has_unread_staff_reply': false,
  };

  test('uses the exact U1 RPC names and parameter names', () async {
    final calls = <(String, Map<String, dynamic>)>[];
    final live = ControllableCaseLiveSource();
    final repository = SupabaseSupportRepository(
      rpc: (fn, params) async {
        calls.add((fn, params));
        return switch (fn) {
          'common_list_my_support_cases' => {
            'items': [caseJson],
            'next_cursor': 'next',
          },
          'common_get_support_case' => {
            'case': caseJson,
            'messages': <Object>[],
            'next_older_cursor': null,
          },
          'common_create_support_case' => {
            'case_id': caseId,
            'code': 'SC-1',
          },
          'common_reply_support_case' => {
            'message_id': 'm1',
            'case_status': 'in_progress',
          },
          _ => <Object>[],
        };
      },
      live: live,
    );

    final page = await repository.listCases(cursor: 'cursor');
    final details = await repository.getCase(caseId, beforeCursor: 'older');
    final created = await repository.createCase(
      const NewCaseDraft(
        draftId: 'd1',
        type: CaseType.booking,
        body: 'وصف صالح للحالة',
        bookingId: 'b1',
        attachmentIds: ['a1'],
      ),
    );
    final reply = await repository.reply(
      caseId,
      const ReplyDraft(
        draftId: 'd2',
        body: 'رد',
        attachmentIds: ['a2'],
      ),
    );

    expect(page.items.single.code, 'SC-1');
    expect(details.supportCase.id, caseId);
    expect(created.caseId, caseId);
    expect(reply.caseStatus, CaseStatus.inProgress);
    expect(calls[0].$1, 'common_list_my_support_cases');
    expect(calls[0].$2, {'p_cursor': 'cursor', 'p_limit': 20});
    expect(calls[1].$1, 'common_get_support_case');
    expect(calls[1].$2, {
      'p_case_id': caseId,
      'p_before_cursor': 'older',
    });
    expect(
      calls[2].$2.keys,
      containsAll([
        'p_type',
        'p_body',
        'p_draft_id',
        'p_booking_id',
        'p_property_id',
        'p_attachment_ids',
      ]),
    );
    expect(
      calls[3].$2.keys,
      containsAll(['p_case_id', 'p_body', 'p_draft_id', 'p_attachment_ids']),
    );
  });

  test('maps Postgrest errors through ErrorMapper', () async {
    final repository = SupabaseSupportRepository(
      rpc: (_, _) async => throw const PostgrestException(
        message: 'CASE_CLOSED',
        code: 'P0001',
      ),
      live: ControllableCaseLiveSource(),
    );
    await expectLater(
      repository.reply(
        caseId,
        const ReplyDraft(draftId: 'd', body: 'رد'),
      ),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.error.code,
          'code',
          ErrorCode.caseClosed,
        ),
      ),
    );
  });
}
