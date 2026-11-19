import 'package:dio/dio.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';

final class EmptyAttachmentPicker implements AttachmentPicker {
  const EmptyAttachmentPicker();
  @override
  Future<List<PickedFile>> pickCamera() async => const [];
  @override
  Future<List<PickedFile>> pickGallery({required int max}) async => const [];
  @override
  Future<List<PickedFile>> pickPdf() async => const [];
}

final class FakeUploadSigner implements UploadSigner {
  const FakeUploadSigner();
  @override
  Future<UploadSignResponse> sign(UploadSignRequest request) async =>
      UploadSignResponse(
        attachmentId: 'attachment-test',
        uploadUrl: Uri.parse('https://example.invalid/upload'),
      );
}

/// Gives every upload its own attachment id, like the real Node signer.
///
/// The real sign endpoint records the attachment against its draft server-side
/// so the later create-case call can verify it. [onSigned] lets a mock server
/// mirror that (draft id, attachment id) bookkeeping; without it createCase
/// rejects the attachments with NOT_FOUND.
final class UniqueUploadSigner implements UploadSigner {
  UniqueUploadSigner({this.onSigned});

  final void Function(String draftId, String attachmentId)? onSigned;

  int _counter = 0;
  @override
  Future<UploadSignResponse> sign(UploadSignRequest request) async {
    final attachmentId = 'attachment-${++_counter}';
    onSigned?.call(request.entityId, attachmentId);
    return UploadSignResponse(
      attachmentId: attachmentId,
      uploadUrl: Uri.parse('https://example.invalid/upload'),
    );
  }
}

final class FakeRawPutClient implements RawPutClient {
  const FakeRawPutClient();
  @override
  Future<void> put({
    required Uri url,
    required String filePath,
    required String mime,
    required int sizeBytes,
    required CancelToken cancelToken,
    required void Function(int sent, int total) onProgress,
  }) async {
    onProgress(sizeBytes, sizeBytes);
  }
}

const fakeSupportUploader = PrivateFileUploader(
  signer: FakeUploadSigner(),
  putClient: FakeRawPutClient(),
);

ImageSanitizer fakeSupportSanitizer() => ImageSanitizer();
