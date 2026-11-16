import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/support/data/mock_support_server.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/domain/support_repository.dart';

void main() {
  late MockSupportServer server;

  setUp(() {
    server = MockSupportServer(
      latency: Duration.zero,
      now: () => DateTime.utc(2026, 11, 16, 12),
    );
  });

  test('seeds three lifecycle cases and one system case', () async {
    final page = await server.listCases();
    expect(page.items, hasLength(4));
    expect(
      page.items.map((item) => item.status),
      containsAll([
        CaseStatus.waitingUser,
        CaseStatus.resolved,
        CaseStatus.closed,
      ]),
    );
    expect(
      page.items.map((item) => item.type),
      contains(CaseType.damageDispute),
    );
  });

  test('list paginates twenty at a time with an opaque cursor', () async {
    for (var index = 0; index < 22; index++) {
      server.seedCase(index: index + 10);
    }
    final first = await server.listCases();
    final second = await server.listCases(cursor: first.nextCursor);
    expect(first.items, hasLength(20));
    expect(first.nextCursor, isNotNull);
    expect(second.items.length, greaterThanOrEqualTo(6));
  });

  test('foreign and unknown ids are both neutral NOT_FOUND', () async {
    for (final id in [MockSupportServer.foreignCaseId, 'missing']) {
      await expectLater(
        server.getCase(id),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.notFound,
          ),
        ),
      );
    }
  });

  test('internal seed notes are never returned', () async {
    final details = await server.getCase(MockSupportServer.waitingCaseId);
    expect(
      details.messages.map((message) => message.body),
      isNot(contains('INTERNAL')),
    );
    expect(
      details.messages.map((message) => message.author).toSet(),
      isNot(contains('internal')),
    );
  });

  test('draft idempotency creates one message', () async {
    const draft = ReplyDraft(draftId: 'draft-1', body: 'متابعة');
    final first = await server.reply(MockSupportServer.waitingCaseId, draft);
    final second = await server.reply(MockSupportServer.waitingCaseId, draft);
    expect(second.messageId, first.messageId);
    final details = await server.getCase(MockSupportServer.waitingCaseId);
    expect(
      details.messages.where((message) => message.body == 'متابعة'),
      hasLength(1),
    );
  });

  test(
    'reply transitions resolved and waiting cases, but closed refuses',
    () async {
      final resolved = await server.reply(
        MockSupportServer.resolvedCaseId,
        const ReplyDraft(draftId: 'draft-resolved', body: 'لسه محتاج مساعدة'),
      );
      final waiting = await server.reply(
        MockSupportServer.waitingCaseId,
        const ReplyDraft(draftId: 'draft-waiting', body: 'ده ردي'),
      );
      expect(resolved.caseStatus, CaseStatus.open);
      expect(waiting.caseStatus, CaseStatus.inProgress);
      await expectLater(
        server.reply(
          MockSupportServer.closedCaseId,
          const ReplyDraft(draftId: 'draft-closed', body: 'رد'),
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.caseClosed,
          ),
        ),
      );
    },
  );

  test('reply body must be trimmed and within 1-4000', () async {
    for (final body in ['', ' ', List.filled(4001, 'x').join()]) {
      await expectLater(
        server.reply(
          MockSupportServer.waitingCaseId,
          ReplyDraft(draftId: 'draft-${body.length}', body: body),
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.validationFailed,
          ),
        ),
      );
    }
  });

  test('auto reply arrives after three seconds and signals a change', () {
    fakeAsync((async) {
      var changes = 0;
      final subscription = server
          .caseChanges(MockSupportServer.waitingCaseId)
          .listen((_) => changes++);
      unawaited(
        server.reply(
          MockSupportServer.waitingCaseId,
          const ReplyDraft(draftId: 'draft-auto', body: 'رد للموظف'),
        ),
      );
      async.flushMicrotasks();
      final afterGuest = changes;
      async.elapse(const Duration(seconds: 2));
      expect(changes, afterGuest);
      async.elapse(const Duration(seconds: 1));
      expect(changes, afterGuest + 1);
      unawaited(subscription.cancel());
    });
  });

  group('createCase', () {
    NewCaseDraft draft({
      String draftId = 'new-draft',
      CaseType type = CaseType.booking,
      String body = 'المكيف مش شغال من يوم الوصول',
      String? bookingId,
      String? propertyId,
      List<String> attachmentIds = const [],
    }) => NewCaseDraft(
      draftId: draftId,
      type: type,
      body: body,
      bookingId: bookingId,
      propertyId: propertyId,
      attachmentIds: attachmentIds,
    );

    test('the type must be guest-selectable', () async {
      await expectLater(
        server.createCase(draft(type: CaseType.damageDispute)),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.validationFailed,
          ),
        ),
      );
    });

    test('the description is trimmed and 10-4000 characters', () async {
      // Nine characters fail even padded with spaces.
      await expectLater(
        server.createCase(draft(body: '   123456789   ')),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.validationFailed,
          ),
        ),
      );
      // Ten characters after trimming pass.
      final created = await server.createCase(
        draft(draftId: 'draft-trimmed', body: '   1234567890   '),
      );
      expect(created.code, isNotEmpty);
      // Over the maximum fails.
      await expectLater(
        server.createCase(draft(body: List.filled(4001, 'x').join())),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.validationFailed,
          ),
        ),
      );
    });

    test('the same draft id returns the same case', () async {
      final first = await server.createCase(draft());
      final second = await server.createCase(draft());
      expect(second.caseId, first.caseId);
      expect(second.code, first.code);
      expect(server.createCalls, 2);
      final page = await server.listCases();
      expect(
        page.items.where((item) => item.id == first.caseId),
        hasLength(1),
      );
    });

    test('attachments must belong to the draft', () async {
      server.registerDraftAttachment('draft-a', 'attachment-a');
      await expectLater(
        server.createCase(
          draft(draftId: 'draft-b', attachmentIds: const ['attachment-a']),
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.notFound,
          ),
        ),
      );
      // Bound to its own draft the attachment is accepted.
      final created = await server.createCase(
        draft(draftId: 'draft-a', attachmentIds: const ['attachment-a']),
      );
      final details = await server.getCase(created.caseId);
      expect(
        details.messages.first.attachments.map((attachment) => attachment.id),
        contains('attachment-a'),
      );
    });

    test('more than max files is ATTACHMENT_REJECTED too_many', () async {
      const maxFiles = 5;
      final ids = List.generate(maxFiles + 1, (index) => 'attachment-$index');
      for (final id in ids) {
        server.registerDraftAttachment('draft-full', id);
      }
      await expectLater(
        server.createCase(
          draft(draftId: 'draft-full', attachmentIds: ids),
        ),
        throwsA(
          isA<AppFailure>()
              .having(
                (failure) => failure.error.code,
                'code',
                ErrorCode.attachmentRejected,
              )
              .having(
                (failure) => failure.error.details?['reason'],
                'reason',
                'too_many',
              ),
        ),
      );
    });

    test('a foreign booking id is NOT_FOUND', () async {
      await expectLater(
        server.createCase(
          draft(bookingId: 'b9999999-0000-4000-8000-000000000099'),
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.notFound,
          ),
        ),
      );
    });

    test('the new case is listed first with the linked booking', () async {
      final created = await server.createCase(
        draft(bookingId: MockSupportServer.linkedBookingId),
      );
      final page = await server.listCases();
      expect(page.items.first.id, created.caseId);
      final item = page.items.first;
      expect(item.status, CaseStatus.open);
      expect(item.bookingId, MockSupportServer.linkedBookingId);
      expect(item.bookingCode, 'OA-2042');
      expect(item.lastActivityAt, DateTime.utc(2026, 11, 16, 12));
    });
  });
}
