import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

final class ImageDimensions {
  const ImageDimensions(this.width, this.height);
  final int width;
  final int height;
}

final class CompressRequest {
  const CompressRequest({
    required this.sourcePath,
    required this.targetPath,
    required this.minWidth,
    required this.minHeight,
    required this.quality,
    required this.keepExif,
    this.outputMime = 'image/jpeg',
  });

  final String sourcePath;
  final String targetPath;
  final int minWidth;
  final int minHeight;
  final int quality;
  final bool keepExif;
  final String outputMime;
}

final class CompressedImage {
  const CompressedImage({
    required this.path,
    required this.sizeBytes,
    required this.width,
    required this.height,
  });

  final String path;
  final int sizeBytes;
  final int width;
  final int height;
}

abstract interface class CompressorPort {
  Future<ImageDimensions> dimensions(String path);
  Future<CompressedImage> compress(CompressRequest request);
}

final class FlutterCompressorPort implements CompressorPort {
  const FlutterCompressorPort();

  @override
  Future<ImageDimensions> dimensions(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final result = ImageDimensions(image.width, image.height);
    image.dispose();
    codec.dispose();
    return result;
  }

  @override
  Future<CompressedImage> compress(CompressRequest request) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      request.sourcePath,
      request.targetPath,
      quality: request.quality,
      minWidth: request.minWidth,
      minHeight: request.minHeight,
      keepExif: request.keepExif,
      // Keep the privacy contract explicit even though JPEG is the plugin's
      // current default.
      // ignore: avoid_redundant_argument_values
      format: CompressFormat.jpeg,
    );
    if (result == null) throw StateError('Image compression returned no file');
    final dimensions = await this.dimensions(result.path);
    return CompressedImage(
      path: result.path,
      sizeBytes: await result.length(),
      width: dimensions.width,
      height: dimensions.height,
    );
  }
}

final class PreparedFile {
  const PreparedFile({
    required this.tempPath,
    required this.sizeBytes,
    required this.mime,
    this.width,
    this.height,
  });

  final String tempPath;
  final int sizeBytes;
  final String mime;
  final int? width;
  final int? height;
}

final class AttachmentPrepareFailure implements Exception {
  const AttachmentPrepareFailure([this.cause]);
  final Object? cause;
}

final class ImageSanitizer {
  ImageSanitizer({
    this.compressor = const FlutterCompressorPort(),
    Future<Directory> Function()? temporaryDirectory,
    this.uuid = const Uuid(),
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final CompressorPort compressor;
  final Future<Directory> Function() _temporaryDirectory;
  final Uuid uuid;

  Future<PreparedFile> prepare(PickedFile file) async {
    String? target;
    try {
      final temp = await _temporaryDirectory();
      await temp.create(recursive: true);
      if (file.mime == 'application/pdf') {
        target = '${temp.path}${Platform.pathSeparator}${uuid.v4()}.pdf';
        final copy = await File(file.path).copy(target);
        return PreparedFile(
          tempPath: copy.path,
          sizeBytes: await copy.length(),
          mime: 'application/pdf',
        );
      }
      if (!file.mime.startsWith('image/')) {
        throw const FormatException('Unsupported attachment type');
      }
      final dimensions = await compressor.dimensions(file.path);
      final scale = dimensions.width > dimensions.height
          ? 2048 / dimensions.width
          : 2048 / dimensions.height;
      final clamped = scale.clamp(0.0, 1.0);
      final width = (dimensions.width * clamped).round().clamp(1, 2048);
      final height = (dimensions.height * clamped).round().clamp(1, 2048);
      target = '${temp.path}${Platform.pathSeparator}${uuid.v4()}.jpg';
      final compressed = await compressor.compress(
        CompressRequest(
          sourcePath: file.path,
          targetPath: target,
          minWidth: width,
          minHeight: height,
          quality: 80,
          keepExif: false,
        ),
      );
      return PreparedFile(
        tempPath: compressed.path,
        sizeBytes: compressed.sizeBytes,
        mime: 'image/jpeg',
        width: compressed.width,
        height: compressed.height,
      );
    } on Object catch (error) {
      if (target != null) {
        final partial = File(target);
        if (partial.existsSync()) partial.deleteSync();
      }
      throw AttachmentPrepareFailure(error);
    }
  }
}
