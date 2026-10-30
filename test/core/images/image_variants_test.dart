import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/images/image_variants.dart';

List<ImageVariant> _variants(List<int> widths) => [
  for (final width in widths)
    ImageVariant(width: width, url: Uri.parse('https://cdn.test/$width.jpg')),
];

void main() {
  test(
    'picks the smallest variant at least as wide as the rendered pixels',
    () {
      // 160 logical px × 2 dpr = 320 device px.
      final picked = ImageVariants.pick(
        variants: _variants([320, 720, 1440]),
        logicalWidth: 160,
        devicePixelRatio: 2,
      );
      expect(picked?.width, 320);
    },
  );

  test('a higher device pixel ratio needs a larger variant', () {
    // 160 × 3 = 480 device px, so 320 is too small and 720 wins.
    final picked = ImageVariants.pick(
      variants: _variants([320, 720, 1440]),
      logicalWidth: 160,
      devicePixelRatio: 3,
    );
    expect(picked?.width, 720);
  });

  test('returns the widest variant when none is big enough', () {
    final picked = ImageVariants.pick(
      variants: _variants([320, 720, 1440]),
      logicalWidth: 1000,
      devicePixelRatio: 3,
    );
    expect(picked?.width, 1440);
  });

  test('an empty variant list returns null', () {
    expect(
      ImageVariants.pick(
        variants: const [],
        logicalWidth: 160,
        devicePixelRatio: 2,
      ),
      isNull,
    );
  });

  test('unsorted input still picks correctly', () {
    final picked = ImageVariants.pick(
      variants: _variants([1440, 320, 720]),
      logicalWidth: 160,
      devicePixelRatio: 3,
    );
    expect(picked?.width, 720);
  });
}
