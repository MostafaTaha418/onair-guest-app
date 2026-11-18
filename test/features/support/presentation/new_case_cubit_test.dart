import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/core/files/upload_limits.dart';
import 'package:on_air/features/support/domain/attachment_draft.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:on_air/features/support/presentation/new_case/new_case_cubit.dart';

import '../../../helpers/fake_bookings_repository.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_support_repository.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

void main() {
  late FakeSupportRepository repository;
  late FakeBookingsRepository bookings;
  late NewCaseCubit cubit;

  setUp(() {
    repository = FakeSupportRepository();
    bookings = FakeBookingsRepository();
    cubit = NewCaseCubit(repository: repository, bookings: bookings);
  });

  tearDown(() => cubit.close());

  NewCaseReady ready() => cubit.state as NewCaseReady;

  AttachmentDraft attachment({
    String id = 'a1',
    AttachmentUploadState? state,
  }) => AttachmentDraft(
    localId: id,
    kind: AttachmentKind.image,
    displayName: 'photo.jpg',
    tempPath: 'photo.jpg',
    sizeBytes: 1024,
    state: state ?? const AttachmentUploadState.uploaded('attachment-1'),
  );

  test('a fresh form creates one v4 draft id', () {
    final before = ready().draftId;
    expect(before, matches(_uuidV4));
    // open() twice keeps the same id: one per form.
    cubit
      ..open()
      ..open();
    expect(ready().draftId, before);
  });

  group('open', () {
    test('a booking entry links it and preselects «حجز»', () async {
      bookings.bookings['b0000000-0000-4000-8000-000000000021'] =
          sampleBookingDetails();
      cubit.open(bookingId: 'b0000000-0000-4000-8000-000000000021');
      expect(ready().bookingId, 'b0000000-0000-4000-8000-000000000021');
      expect(ready().type, CaseType.booking);
      await Future<void>.delayed(Duration.zero);
      expect(ready().bookingCode, 'OA-2042');
    });

    test('a property entry links it and preselects «أخرى»', () async {
      var resolved = 0;
      final local = NewCaseCubit(
        repository: repository,
        resolvePropertyTitle: (propertyId) async {
          resolved++;
          return 'شقة الساحل';
        },
      );
      addTearDown(local.close);
      local.open(propertyId: 'e0000000-0000-4000-8000-000000000031');
      final state = local.state as NewCaseReady;
      expect(state.propertyId, 'e0000000-0000-4000-8000-000000000031');
      expect(state.type, CaseType.other);
      await Future<void>.delayed(Duration.zero);
      expect((local.state as NewCaseReady).propertyTitle, 'شقة الساحل');
      expect(resolved, 1);
    });

    test('invalid params are ignored', () {
      cubit.open(bookingId: 'not-a-uuid', propertyId: 'also-not');
      expect(ready().bookingId, isNull);
      expect(ready().propertyId, isNull);
      expect(ready().type, isNull);
    });

    test('an explicit guest type wins over the entry-point default', () {
      cubit.open(
        bookingId: 'b0000000-0000-4000-8000-000000000021',
        type: 'refund',
      );
      expect(ready().type, CaseType.refund);
    });
  });

  group('canSend', () {
    const longEnough = 'الوصف طويل بما يكفي للإرسال';

    test('needs a type and a body of 10-4000 trimmed characters', () {
      expect(ready().canSend, isFalse);
      cubit
        ..updateType(CaseType.booking)
        ..updateBody('قصير');
      expect(ready().canSend, isFalse);
      cubit.updateBody('  $longEnough  ');
      expect(ready().canSend, isTrue);
    });

    test('four thousand passes, four thousand and one does not', () {
      cubit
        ..updateType(CaseType.booking)
        ..updateBody(List.filled(4000, 'x').join());
      expect(ready().canSend, isTrue);
      cubit.updateBody('${List.filled(4000, 'x').join()}x');
      expect(ready().canSend, isFalse);
    });

    test('no attachment may be preparing, uploading or failed', () {
      cubit
        ..updateType(CaseType.booking)
        ..updateBody(longEnough)
        ..updateAttachments([
          attachment(state: const AttachmentUploadState.uploading(.5)),
        ]);
      expect(ready().canSend, isFalse);
      cubit.updateAttachments([
        attachment(
          state: const AttachmentUploadState.failed(
            UploadFailureReason.network,
          ),
        ),
      ]);
      expect(ready().canSend, isFalse);
      cubit.updateAttachments([attachment()]);
      expect(ready().canSend, isTrue);
    });

    test('offline blocks send', () async {
      final connectivity = FakeConnectivity();
      addTearDown(connectivity.dispose);
      final connectionCubit = connectivity.createCubit();
      addTearDown(connectionCubit.close);
      final local = NewCaseCubit(
        repository: repository,
        connection: connectionCubit,
      );
      addTearDown(local.close);
      local
        ..open()
        ..updateType(CaseType.booking)
        ..updateBody(longEnough);
      expect((local.state as NewCaseReady).canSend, isTrue);
      connectivity.goOffline();
      await Future<void>.delayed(Duration.zero);
      expect((local.state as NewCaseReady).online, isFalse);
      expect((local.state as NewCaseReady).canSend, isFalse);
    });
  });

  test('submit sends the trimmed body, ids and links once', () async {
    bookings.bookings['b0000000-0000-4000-8000-000000000021'] =
        sampleBookingDetails();
    cubit
      ..open(bookingId: 'b0000000-0000-4000-8000-000000000021')
      ..updateType(CaseType.booking)
      ..updateBody('  الوصف طويل بما يكفي للإرسال  ')
      ..updateAttachments([attachment()]);
    final draftId = ready().draftId;
    await cubit.submit();
    expect(repository.creations, hasLength(1));
    final draft = repository.creations.single;
    expect(draft.draftId, draftId);
    expect(draft.type, CaseType.booking);
    expect(draft.body, 'الوصف طويل بما يكفي للإرسال');
    expect(draft.bookingId, 'b0000000-0000-4000-8000-000000000021');
    expect(draft.attachmentIds, ['attachment-1']);
  });

  test('success lands in created(caseId, code)', () async {
    repository.createResult = const CreatedCase(
      caseId: 'c-new',
      code: 'SC-2001',
    );
    cubit
      ..updateType(CaseType.booking)
      ..updateBody('الوصف طويل بما يكفي للإرسال');
    await cubit.submit();
    final created = cubit.state;
    expect(created, isA<NewCaseCreated>());
    expect((created as NewCaseCreated).caseId, 'c-new');
    expect(created.code, 'SC-2001');
  });

  test('a network failure keeps the draft and the same draft id', () async {
    repository.nextCreateError = const AppFailure(
      ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
    );
    final before = ready().draftId;
    cubit
      ..updateType(CaseType.booking)
      ..updateBody('الوصف طويل بما يكفي للإرسال');
    await cubit.submit();
    expect(ready().draftId, before);
    expect(ready().submitting, isFalse);
    expect(ready().error, isNotNull);
    expect(ready().body, 'الوصف طويل بما يكفي للإرسال');
    // The retry reuses the same id (FR-009) and lands on the created state.
    await cubit.submit();
    expect(repository.creations, hasLength(2));
    expect(repository.creations.last.draftId, before);
    expect(cubit.state, isA<NewCaseCreated>());
  });

  test('a double submit reaches the repository once', () async {
    cubit
      ..updateType(CaseType.booking)
      ..updateBody('الوصف طويل بما يكفي للإرسال');
    await Future.wait([cubit.submit(), cubit.submit()]);
    expect(repository.creations, hasLength(1));
  });

  group('hasContent', () {
    test('a type or a link alone is not content', () {
      bookings.bookings['b0000000-0000-4000-8000-000000000021'] =
          sampleBookingDetails();
      cubit
        ..open(bookingId: 'b0000000-0000-4000-8000-000000000021')
        ..updateType(CaseType.booking);
      expect(ready().hasContent, isFalse);
    });

    test('text makes content', () {
      cubit.updateBody('نص');
      expect(ready().hasContent, isTrue);
    });

    test('files make content', () {
      cubit.updateAttachments([attachment()]);
      expect(ready().hasContent, isTrue);
    });

    test('trimmed whitespace alone is not content', () {
      cubit.updateBody('   ');
      expect(ready().hasContent, isFalse);
    });
  });
}
