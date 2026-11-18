import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';

final class _FakeSigner implements UploadSigner {
  final requests = <UploadSignRequest>[];
  Exception? error;

  @override
  Future<UploadSignResponse> sign(UploadSignRequest request) async {
    requests.add(request);
    if (error case final value?) throw value;
    return UploadSignResponse(
      attachmentId: 'attachment-1',
      uploadUrl: Uri.parse('https://upload.test/object'),
    );
  }
}

final class _FakePut implements RawPutClient {
  int calls = 0;
  Exception? error;
  CancelToken? token;
  bool waitForCancel = false;

  @override
  Future<void> put({
    required Uri url,
    required String filePath,
    required String mime,
    required int sizeBytes,
    required CancelToken cancelToken,
    required void Function(int sent, int total) onProgress,
  }) async {
    calls++;
    token = cancelToken;
    onProgress(5, 10);
    if (waitForCancel) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (cancelToken.isCancelled) {
        throw DioException.requestCancelled(
          requestOptions: RequestOptions(path: url.toString()),
          reason: cancelToken.cancelError,
        );
      }
    }
    if (error case final value?) throw value;
  }
}

void main() {
  late Directory temp;
  late _FakeSigner signer;
  late _FakePut put;
  late PrivateFileUploader uploader;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('onair-upload-test-');
    signer = _FakeSigner();
    put = _FakePut();
    uploader = PrivateFileUploader(signer: signer, putClient: put);
  });

  tearDown(() async {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  Future<PreparedFile> prepared() async {
    final file = File('${temp.path}${Platform.pathSeparator}prepared.jpg');
    await file.writeAsBytes(List.filled(10, 1));
    return PreparedFile(
      tempPath: file.path,
      sizeBytes: 10,
      mime: 'image/jpeg',
    );
  }

  test(
    'emits progress, signs a support draft, uploads and cleans up',
    () async {
      final file = await prepared();
      final events = await uploader.upload(file, draftId: 'draft-1').toList();

      expect(events.map((event) => event.stage), [
        UploadStage.preparing,
        UploadStage.uploading,
        UploadStage.uploading,
        UploadStage.uploaded,
      ]);
      expect(events[2].fraction, .5);
      expect(events.last.attachmentId, 'attachment-1');
      expect(signer.requests.single.entityType, 'support_draft');
      expect(signer.requests.single.entityId, 'draft-1');
      expect(File(file.tempPath).existsSync(), isFalse);
    },
  );

  test('server rejection skips PUT and exposes the reason', () async {
    final file = await prepared();
    signer.error = AppFailure(
      ErrorMapper.fromCode(
        'ATTACHMENT_REJECTED',
        details: {'reason': 'too_large'},
      ),
    );
    final events = await uploader.upload(file, draftId: 'draft-1').toList();
    expect(events.last.failure, UploadFailureReason.tooLarge);
    expect(put.calls, 0);
  });

  test('network retry signs again and can succeed', () async {
    final file = await prepared();
    put.error = DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionError,
    );
    final first = await uploader.upload(file, draftId: 'draft-1').toList();
    expect(first.last.failure, UploadFailureReason.network);
    expect(File(file.tempPath).existsSync(), isTrue);

    put.error = null;
    final second = await uploader.upload(file, draftId: 'draft-1').toList();
    expect(second.last.stage, UploadStage.uploaded);
    expect(signer.requests, hasLength(2));
  });

  test('cancel aborts the PUT and deletes the temp file', () async {
    final file = await prepared();
    put.waitForCancel = true;
    fakeAsync((async) {
      final token = CancelToken();
      final events = <UploadProgress>[];
      uploader
          .upload(file, draftId: 'draft-1', cancelToken: token)
          .listen(events.add);
      async.flushMicrotasks();
      token.cancel();
      async
        ..elapse(const Duration(milliseconds: 20))
        ..flushMicrotasks();
      expect(events.last.stage, UploadStage.cancelled);
      expect(File(file.tempPath).existsSync(), isFalse);
    });
  });
}
