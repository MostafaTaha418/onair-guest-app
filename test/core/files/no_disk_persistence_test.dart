import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/files/file_url_cache.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/domain/stay_results.dart';

final class _CountingStay implements StayRepository {
  _CountingStay(this.now);

  DateTime Function() now;
  int fileUrlCalls = 0;

  @override
  Future<FileUrl> fileUrl(String attachmentId) async {
    fileUrlCalls++;
    return FileUrl(
      url: Uri.parse('https://files.mock.onair.test/$attachmentId.jpg'),
      expiresAt: now().add(const Duration(minutes: 5)),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _FakeSigner implements UploadSigner {
  @override
  Future<UploadSignResponse> sign(UploadSignRequest request) async =>
      UploadSignResponse(
        attachmentId: 'attachment-1',
        uploadUrl: Uri.parse('https://upload.test/object'),
      );
}

final class _FakePut implements RawPutClient {
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
    onProgress(sizeBytes, sizeBytes);
    if (waitForCancel) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (cancelToken.isCancelled) {
        throw DioException.requestCancelled(
          requestOptions: RequestOptions(path: url.toString()),
          reason: cancelToken.cancelError,
        );
      }
    }
  }
}

/// T099: sanitized files and signed URLs never touch disk or outlive the
/// upload. Success, cancel and an abandoned failure leave the temp dir
/// empty; `FileUrlCache` is memory-only; and sign-out drops the cached
/// URLs through the `PersonalDataResetter` wiring in `bootstrap.dart`.
void main() {
  late Directory temp;
  late PrivateFileUploader uploader;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('onair-no-disk-');
    uploader = PrivateFileUploader(
      signer: _FakeSigner(),
      putClient: _FakePut(),
    );
  });

  tearDown(() async {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  Future<PreparedFile> prepared() async {
    final file = File(
      '${temp.path}${Platform.pathSeparator}sanitized.jpg',
    );
    await file.writeAsBytes(List.filled(10, 1));
    return PreparedFile(tempPath: file.path, sizeBytes: 10, mime: 'image/jpeg');
  }

  void expectTempDirEmpty() {
    final leftovers = temp.listSync().whereType<File>().toList();
    expect(leftovers, isEmpty, reason: 'temp files must not outlive uploads');
  }

  test('a successful upload leaves no temp file behind', () async {
    final file = await prepared();

    final events = await uploader.upload(file, draftId: 'draft-1').toList();

    expect(events.last.stage, UploadStage.uploaded);
    expect(File(file.tempPath).existsSync(), isFalse);
    expectTempDirEmpty();
  });

  test('a cancelled upload leaves no temp file behind', () async {
    final file = await prepared();
    (uploader.putClient as _FakePut).waitForCancel = true;

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
      expectTempDirEmpty();
    });
  });

  test(
    'a failed upload keeps the file for retry until it is abandoned',
    () async {
      final file = await prepared();
      final failing = PrivateFileUploader(
        signer: _FailingSigner(),
        putClient: _FakePut(),
      );

      final events = await failing.upload(file, draftId: 'draft-1').toList();

      expect(events.last.stage, UploadStage.failed);
      // The composer keeps the file so the retry can reuse it…
      expect(File(file.tempPath).existsSync(), isTrue);

      // …and deleting the tile (or leaving the screen) must remove it.
      await failing.abandon(file);
      expect(File(file.tempPath).existsSync(), isFalse);
      expectTempDirEmpty();
    },
  );

  test('FileUrlCache is memory-only and clear() drops every URL', () async {
    final cacheSource = File(
      'lib/core/files/file_url_cache.dart',
    ).readAsStringSync();
    expect(cacheSource.contains('JsonFileCache'), isFalse);
    expect(cacheSource.contains('SharedPreferences'), isFalse);
    expect(cacheSource.contains('Directory('), isFalse);

    final now = DateTime.utc(2026, 11, 1, 10);
    final stay = _CountingStay(() => now);
    final cache = FileUrlCache(stay, now: () => now);

    await cache.urlFor('a1');
    await cache.urlFor('a2');
    expect(stay.fileUrlCalls, 2);

    cache.clear();
    await cache.urlFor('a1');
    expect(stay.fileUrlCalls, 3, reason: 'clear() must force a refetch');
  });

  test('bootstrap registers the URL cache in the sign-out resetter', () {
    final bootstrap = File('lib/bootstrap.dart').readAsStringSync();
    expect(
      bootstrap.contains('fileUrls.clear'),
      isTrue,
      reason:
          'SignOutService must drop cached private URLs through the '
          'PersonalDataResetter (T099)',
    );
  });
}

final class _FailingSigner implements UploadSigner {
  @override
  Future<UploadSignResponse> sign(UploadSignRequest request) async =>
      throw DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );
}
