import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/core/files/upload_limits.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/support/domain/attachment_draft.dart';
import 'package:on_air/features/support/presentation/widgets/reply_composer.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  Future<void> pump(
    WidgetTester tester, {
    String body = '',
    List<AttachmentDraft> attachments = const [],
    bool online = true,
  }) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: OnAirTheme.light,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ReplyComposer(
            draftId: 'draft',
            body: body,
            attachments: attachments,
            onBodyChanged: (_) {},
            onAttachmentsChanged: (_) {},
            onSend: () {},
            picker: const _Picker(),
            sanitizer: ImageSanitizer(),
            uploader: const PrivateFileUploader(
              signer: _Signer(),
              putClient: _Put(),
            ),
            online: online,
          ),
        ),
      ),
    ),
  );

  testWidgets('send is disabled for empty, pending, and offline states', (
    tester,
  ) async {
    await pump(tester);
    expect(_sendButton(tester).onPressed, isNull);

    await pump(tester, body: 'رد', online: false);
    expect(_sendButton(tester).onPressed, isNull);

    await pump(
      tester,
      body: 'رد',
      attachments: const [
        AttachmentDraft(
          localId: 'a',
          kind: AttachmentKind.image,
          displayName: 'a.jpg',
          tempPath: 'a.jpg',
          sizeBytes: 1,
          state: AttachmentUploadState.uploading(.5),
        ),
      ],
    );
    expect(_sendButton(tester).onPressed, isNull);
  });

  testWidgets('attach opens camera, gallery, and PDF choices', (tester) async {
    await pump(tester);
    await tester.tap(find.text(l10n.supportAttach));
    await tester.pumpAndSettle();
    expect(find.text(l10n.supportAttachCamera), findsOneWidget);
    expect(find.text(l10n.supportAttachGallery), findsOneWidget);
    expect(find.text(l10n.supportAttachPdf), findsOneWidget);
  });

  testWidgets('shows the configured limit and accessible controls', (
    tester,
  ) async {
    await pump(
      tester,
      attachments: const [
        AttachmentDraft(
          localId: 'failed',
          kind: AttachmentKind.pdf,
          displayName: 'claim.pdf',
          tempPath: 'claim.pdf',
          sizeBytes: 20,
          state: AttachmentUploadState.failed(UploadFailureReason.network),
        ),
      ],
    );
    expect(
      find.text(l10n.supportAttachHint(const UploadLimits().maxFiles)),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(l10n.supportAttachRemove), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.supportAttachRetry), findsOneWidget);
  });

  testWidgets('composer remains mounted with the keyboard open', (
    tester,
  ) async {
    await pump(tester, body: 'رد');
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.byType(ReplyComposer), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.supportSend), findsOneWidget);
  });
}

IconButton _sendButton(WidgetTester tester) => tester.widget<IconButton>(
  find.descendant(
    of: find.bySemanticsLabel('إرسال'),
    matching: find.byType(IconButton),
  ),
);

final class _Picker implements AttachmentPicker {
  const _Picker();
  @override
  Future<List<PickedFile>> pickCamera() async => const [];
  @override
  Future<List<PickedFile>> pickGallery({required int max}) async => const [];
  @override
  Future<List<PickedFile>> pickPdf() async => const [];
}

final class _Signer implements UploadSigner {
  const _Signer();
  @override
  Future<UploadSignResponse> sign(UploadSignRequest request) async =>
      UploadSignResponse(
        attachmentId: 'a',
        uploadUrl: Uri.parse('https://example.invalid'),
      );
}

final class _Put implements RawPutClient {
  const _Put();
  @override
  Future<void> put({
    required Uri url,
    required String filePath,
    required String mime,
    required int sizeBytes,
    required CancelToken cancelToken,
    required void Function(int sent, int total) onProgress,
  }) async {}
}
