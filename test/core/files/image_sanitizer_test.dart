import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/image_sanitizer.dart';

final class _FakeCompressor implements CompressorPort {
  ImageDimensions source = const ImageDimensions(4000, 2000);
  CompressRequest? request;
  Exception? error;

  @override
  Future<ImageDimensions> dimensions(String path) async => source;

  @override
  Future<CompressedImage> compress(CompressRequest request) async {
    this.request = request;
    if (error case final value?) throw value;
    await File(request.targetPath).writeAsBytes([1, 2, 3]);
    return CompressedImage(
      path: request.targetPath,
      sizeBytes: 3,
      width: request.minWidth,
      height: request.minHeight,
    );
  }
}

void main() {
  late Directory temp;
  late _FakeCompressor compressor;
  late ImageSanitizer sanitizer;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('onair-sanitize-test-');
    compressor = _FakeCompressor();
    sanitizer = ImageSanitizer(
      compressor: compressor,
      temporaryDirectory: () async => temp,
    );
  });

  tearDown(() async {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test(
    're-encodes as JPEG at quality 80 within 2048 and strips EXIF',
    () async {
      final source = File('${temp.path}${Platform.pathSeparator}source.png');
      await source.writeAsBytes([9]);
      final prepared = await sanitizer.prepare(
        PickedFile(
          path: source.path,
          name: 'source.png',
          sizeBytes: 1,
          mime: 'image/png',
        ),
      );

      final request = compressor.request!;
      expect(request.quality, 80);
      expect(request.keepExif, isFalse);
      expect(request.outputMime, 'image/jpeg');
      expect(request.minWidth, 2048);
      expect(request.minHeight, 1024);
      expect(request.targetPath, startsWith(temp.path));
      expect(prepared.mime, 'image/jpeg');
      expect(prepared.tempPath, endsWith('.jpg'));
    },
  );

  test('wraps compressor errors and removes a partial output', () async {
    final source = File('${temp.path}${Platform.pathSeparator}source.jpg');
    await source.writeAsBytes([9]);
    compressor.error = Exception('failed');
    await expectLater(
      sanitizer.prepare(
        PickedFile(
          path: source.path,
          name: 'source.jpg',
          sizeBytes: 1,
          mime: 'image/jpeg',
        ),
      ),
      throwsA(isA<AttachmentPrepareFailure>()),
    );
  });

  test('copies a PDF unchanged without invoking the compressor', () async {
    final source = File('${temp.path}${Platform.pathSeparator}source.pdf');
    await source.writeAsBytes([1, 2, 3, 4]);
    final prepared = await sanitizer.prepare(
      PickedFile(
        path: source.path,
        name: 'source.pdf',
        sizeBytes: 4,
        mime: 'application/pdf',
      ),
    );
    expect(await File(prepared.tempPath).readAsBytes(), [1, 2, 3, 4]);
    expect(prepared.tempPath, isNot(source.path));
    expect(prepared.mime, 'application/pdf');
    expect(compressor.request, isNull);
  });
}
