import 'package:flutter/foundation.dart';

enum AttachmentKind { image, pdf, unsupported }

enum AttachmentCheckType { ok, tooLarge, typeNotAllowed, tooMany }

@immutable
final class AttachmentCheck {
  const AttachmentCheck._(this.type, this.limit);
  const AttachmentCheck.ok() : this._(AttachmentCheckType.ok, null);
  const AttachmentCheck.tooLarge(int maxMb)
    : this._(AttachmentCheckType.tooLarge, maxMb);
  const AttachmentCheck.typeNotAllowed()
    : this._(AttachmentCheckType.typeNotAllowed, null);
  const AttachmentCheck.tooMany(int max)
    : this._(AttachmentCheckType.tooMany, max);

  final AttachmentCheckType type;
  final int? limit;

  @override
  bool operator ==(Object other) =>
      other is AttachmentCheck && other.type == type && other.limit == limit;

  @override
  int get hashCode => Object.hash(type, limit);
}

@immutable
final class UploadLimits {
  const UploadLimits({
    this.imageMb = 10,
    this.pdfMb = 15,
    this.maxFiles = 5,
  });

  factory UploadLimits.fromJson(Object? value) {
    final json = value is Map<String, dynamic>
        ? value
        : const <String, dynamic>{};
    return UploadLimits(
      imageMb: _positiveInt(json['image_mb'], 10),
      pdfMb: _positiveInt(json['pdf_mb'], 15),
      maxFiles: _positiveInt(json['max_files'], 5),
    );
  }

  final int imageMb;
  final int pdfMb;
  final int maxFiles;

  AttachmentCheck validate({
    required AttachmentKind kind,
    required int sizeBytes,
    required int currentCount,
  }) {
    if (kind == AttachmentKind.unsupported) {
      return const AttachmentCheck.typeNotAllowed();
    }
    if (currentCount >= maxFiles) return AttachmentCheck.tooMany(maxFiles);
    final maxMb = kind == AttachmentKind.image ? imageMb : pdfMb;
    if (sizeBytes > maxMb * 1024 * 1024) {
      return AttachmentCheck.tooLarge(maxMb);
    }
    return const AttachmentCheck.ok();
  }

  static int _positiveInt(Object? value, int fallback) {
    final parsed = value is int ? value : int.tryParse('$value');
    return parsed == null || parsed <= 0 ? fallback : parsed;
  }
}
