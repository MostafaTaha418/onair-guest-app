import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/support/data/case_live_channel.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseSupportRepository implements SupportRepository {
  SupabaseSupportRepository({
    required this.rpc,
    required this.live,
  });

  final Future<dynamic> Function(String fn, Map<String, dynamic> params) rpc;
  final CaseLiveSource live;

  @override
  Future<CasePage> listCases({String? cursor}) => _guard(() async {
    final response = await rpc('common_list_my_support_cases', {
      'p_cursor': cursor,
      'p_limit': 20,
    });
    return CasePage.fromJson(_asMap(response));
  });

  @override
  Future<CaseDetails> getCase(String id, {String? beforeCursor}) =>
      _guard(() async {
        final response = await rpc('common_get_support_case', {
          'p_case_id': id,
          'p_before_cursor': beforeCursor,
        });
        return CaseDetails.fromJson(_asMap(response));
      });

  @override
  Future<CreatedCase> createCase(NewCaseDraft draft) => _guard(() async {
    final response = _asMap(
      await rpc('common_create_support_case', {
        'p_type': draft.type.raw,
        'p_body': draft.body,
        'p_draft_id': draft.draftId,
        'p_booking_id': draft.bookingId,
        'p_property_id': draft.propertyId,
        'p_attachment_ids': draft.attachmentIds,
      }),
    );
    return CreatedCase(
      caseId: response['case_id'] as String,
      code: response['code'] as String,
    );
  });

  @override
  Future<ReplyResult> reply(String caseId, ReplyDraft draft) =>
      _guard(() async {
        final response = _asMap(
          await rpc('common_reply_support_case', {
            'p_case_id': caseId,
            'p_body': draft.body,
            'p_draft_id': draft.draftId,
            'p_attachment_ids': draft.attachmentIds,
          }),
        );
        return ReplyResult(
          messageId: response['message_id'] as String,
          caseStatus: CaseStatus.fromWire(response['case_status'] as String),
        );
      });

  @override
  Future<List<Map<String, dynamic>>> listFaq() => _guard(() async {
    final response = await rpc('common_list_faq', {'p_audience': 'guest'});
    return [for (final row in response! as List) _asMap(row)];
  });

  @override
  Stream<void> caseChanges(String caseId) {
    unawaited(live.open(caseId));
    return live.changes;
  }

  @override
  Stream<bool> get liveConnected => live.connected;

  @override
  Future<void> closeCaseChanges() => live.close();

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
}
