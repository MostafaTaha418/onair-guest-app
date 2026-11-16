import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/files/upload_limits.dart';
import 'package:on_air/features/support/domain/attachment_draft.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:on_air/features/support/presentation/case/case_details_cubit.dart';

import '../../../helpers/fake_support_repository.dart';

void main() {
  late FakeSupportRepository repository;
  late CaseDetailsCubit cubit;

  setUp(() {
    repository = FakeSupportRepository();
    cubit = CaseDetailsCubit(
      caseId: sampleSupportCase().id,
      repository: repository,
    );
  });

  tearDown(() => cubit.close());

  test('load returns ready with ascending messages', () async {
    await cubit.load();
    final ready = cubit.state as CaseDetailsReady;
    expect(ready.details.messages, hasLength(1));
    expect(repository.liveCaseId, sampleSupportCase().id);
  });

  test('channel event triggers exactly one reread', () async {
    await cubit.load();
    repository.changes.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(repository.getCalls, 2);
  });

  test('poll runs while disconnected and stops when connected', () {
    fakeAsync((async) {
      final pollRepository = FakeSupportRepository();
      final local = CaseDetailsCubit(
        caseId: sampleSupportCase().id,
        repository: pollRepository,
      );

      unawaited(local.load());
      async.flushMicrotasks();
      expect(pollRepository.getCalls, 1);

      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();
      expect(pollRepository.getCalls, 2);

      pollRepository.connected.add(true);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 20));
      async.flushMicrotasks();
      expect(pollRepository.getCalls, 2);

      unawaited(local.close());
      async.flushMicrotasks();
    });
  });

  test('send is optimistic then clears draft with a new id', () async {
    await cubit.load();
    final oldDraft = (cubit.state as CaseDetailsReady).draftId;
    cubit.updateBody(' محتاج مساعدة ');
    final future = cubit.send();
    final sending = cubit.state as CaseDetailsReady;
    expect(sending.details.messages.last.sendState, MessageSendState.sending);
    await future;
    final ready = cubit.state as CaseDetailsReady;
    expect(ready.details.messages.last.id, 'm-server');
    expect(ready.details.messages.last.sendState, MessageSendState.sent);
    expect(ready.body, isEmpty);
    expect(ready.draftId, isNot(oldDraft));
  });

  test('double send results in one repository call', () async {
    await cubit.load();
    cubit.updateBody('رد واحد');
    await Future.wait([cubit.send(), cubit.send()]);
    expect(repository.replies, hasLength(1));
  });

  test('CASE_CLOSED keeps text and switches status', () async {
    repository.nextReplyError = const AppFailure(
      ApiError(code: ErrorCode.caseClosed, messageKey: 'caseClosed'),
    );
    await cubit.load();
    cubit.updateBody('النص يفضل موجود');
    await cubit.send();
    final ready = cubit.state as CaseDetailsReady;
    expect(ready.body, 'النص يفضل موجود');
    expect(ready.details.supportCase.status, CaseStatus.closed);
  });

  test('resolved reply shows open response status', () async {
    repository.detailPages.add(sampleDetails(status: CaseStatus.resolved));
    repository.replyResult = const ReplyResult(
      messageId: 'm-open',
      caseStatus: CaseStatus.open,
    );
    await cubit.load();
    cubit.updateBody('لسه محتاج مساعدة');
    await cubit.send();
    expect(
      (cubit.state as CaseDetailsReady).details.supportCase.status,
      CaseStatus.open,
    );
  });

  test('NOT_FOUND becomes neutral not found', () async {
    repository.nextError = const AppFailure(
      ApiError(code: ErrorCode.notFound, messageKey: 'notFound'),
    );
    await cubit.load();
    expect(cubit.state, isA<CaseDetailsNotFound>());
  });

  test('send is blocked while an attachment is not uploaded', () async {
    await cubit.load();
    cubit
      ..updateBody('مع مرفق')
      ..updateAttachments(const [
        AttachmentDraft(
          localId: 'a',
          kind: AttachmentKind.image,
          displayName: 'a.jpg',
          tempPath: 'a.jpg',
          sizeBytes: 2,
          state: AttachmentUploadState.uploading(.5),
        ),
      ]);
    await cubit.send();
    expect(repository.replies, isEmpty);
  });
}
