import 'dart:io';

import 'package:file_picker/file_picker.dart' as files;
import 'package:image_picker/image_picker.dart' as images;

final class PickedFile {
  const PickedFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.mime,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String mime;
}

abstract interface class AttachmentPicker {
  Future<List<PickedFile>> pickCamera();
  Future<List<PickedFile>> pickGallery({required int max});
  Future<List<PickedFile>> pickPdf();
}

final class PluginAttachmentPicker implements AttachmentPicker {
  PluginAttachmentPicker({images.ImagePicker? imagesPicker})
    : _images = imagesPicker ?? images.ImagePicker();

  final images.ImagePicker _images;

  @override
  Future<List<PickedFile>> pickCamera() async {
    final file = await _images.pickImage(source: images.ImageSource.camera);
    return file == null ? const [] : [await _image(file)];
  }

  @override
  Future<List<PickedFile>> pickGallery({required int max}) async {
    if (max <= 0) return const [];
    final picked = await _images.pickMultiImage(limit: max);
    return Future.wait(picked.map(_image));
  }

  @override
  Future<List<PickedFile>> pickPdf() async {
    final result = await files.FilePicker.pickFiles(
      type: files.FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result.isEmpty) return const [];
    return Future.wait(
      result.where((file) => file.path != null).map((file) async {
        final path = file.path!;
        final size = await file.length() ?? await File(path).length();
        return PickedFile(
          path: path,
          name: file.name,
          sizeBytes: size,
          mime: 'application/pdf',
        );
      }),
    );
  }

  static Future<PickedFile> _image(images.XFile file) async {
    final name = file.name;
    final lower = name.toLowerCase();
    final mime = lower.endsWith('.png')
        ? 'image/png'
        : lower.endsWith('.webp')
        ? 'image/webp'
        : lower.endsWith('.heic') || lower.endsWith('.heif')
        ? 'image/heic'
        : 'image/jpeg';
    return PickedFile(
      path: file.path,
      name: name,
      sizeBytes: await file.length(),
      mime: mime,
    );
  }
}
