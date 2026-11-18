import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/files/upload_limits.dart';

void main() {
  const limits = UploadLimits();

  test('accepts only supported image and PDF kinds', () {
    expect(
      limits.validate(
        kind: AttachmentKind.image,
        sizeBytes: 1,
        currentCount: 0,
      ),
      const AttachmentCheck.ok(),
    );
    expect(
      limits.validate(kind: AttachmentKind.pdf, sizeBytes: 1, currentCount: 0),
      const AttachmentCheck.ok(),
    );
    expect(
      limits.validate(
        kind: AttachmentKind.unsupported,
        sizeBytes: 1,
        currentCount: 0,
      ),
      const AttachmentCheck.typeNotAllowed(),
    );
  });

  test('checks sanitized size with binary megabytes', () {
    expect(
      limits.validate(
        kind: AttachmentKind.image,
        sizeBytes: 10 * 1024 * 1024 + 1,
        currentCount: 0,
      ),
      const AttachmentCheck.tooLarge(10),
    );
    expect(
      limits.validate(
        kind: AttachmentKind.pdf,
        sizeBytes: 15 * 1024 * 1024 + 1,
        currentCount: 0,
      ),
      const AttachmentCheck.tooLarge(15),
    );
  });

  test('rejects the sixth file when the maximum is five', () {
    expect(
      limits.validate(
        kind: AttachmentKind.image,
        sizeBytes: 1,
        currentCount: 5,
      ),
      const AttachmentCheck.tooMany(5),
    );
  });
}
