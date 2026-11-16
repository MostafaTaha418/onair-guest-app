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
}
