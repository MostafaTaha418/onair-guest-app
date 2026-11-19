import 'package:on_air/core/files/attachment_picker.dart';

final class FakeAttachmentPicker implements AttachmentPicker {
  List<PickedFile> camera = const [];
  List<PickedFile> gallery = const [];
  List<PickedFile> pdf = const [];
  int? requestedGalleryMax;

  @override
  Future<List<PickedFile>> pickCamera() async => camera;

  @override
  Future<List<PickedFile>> pickGallery({required int max}) async {
    requestedGalleryMax = max;
    return gallery.take(max).toList(growable: false);
  }

  @override
  Future<List<PickedFile>> pickPdf() async => pdf;
}
