import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:on_air/design_system/brand/svg_path.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

part 'on_air_logo_art.dart';

/// The OnAir brand logo, drawn as vectors from the official artwork in
/// `assets/brand/`.
///
/// The colour follows the theme (`logo` token: brand blue in light mode,
/// white in dark mode) unless [color] is given, e.g. white over the brand
/// gradient. The name follows the app language: Arabic shows the Arabic
/// lockup with the mark mirrored for right-to-left reading.
final class OnAirLogo extends StatelessWidget {
  /// The mark alone. At 32 px and below it switches to the small-size cut
  /// with a larger dot, as the brand guide asks.
  const OnAirLogo.mark({
    this.height = 40,
    this.color,
    this.semanticLabel,
    super.key,
  }) : _kind = _LogoKind.mark;

  /// Mark and name together; [height] is the height of the whole lockup.
  const OnAirLogo.lockup({
    this.height = 40,
    this.color,
    this.semanticLabel,
    super.key,
  }) : _kind = _LogoKind.lockup;

  /// The name alone. [height] works like a font size: both languages get
  /// the same type size, so the Arabic box is taller (dots and descenders).
  const OnAirLogo.wordmark({
    double size = 28,
    this.color,
    this.semanticLabel,
    super.key,
  }) : height = size,
       _kind = _LogoKind.wordmark;

  final double height;
  final Color? color;

  /// Read by screen readers. Defaults to the brand name.
  final String? semanticLabel;
  final _LogoKind _kind;

  static const brandName = 'OnAir';

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final art = switch (_kind) {
      _LogoKind.mark => height <= 32 ? _markSmall : _mark,
      _LogoKind.lockup || _LogoKind.wordmark => arabic ? _logoArabic : _logo,
    };
    final built = _BuiltArt.of(art);
    final wordmarkOnly = _kind == _LogoKind.wordmark;
    final frame = wordmarkOnly ? built.wordmarkBounds : art.viewBox;
    final scale = wordmarkOnly ? height / _wordmarkEm : height / frame.height;
    return Semantics(
      label: semanticLabel ?? brandName,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: frame.width * scale,
          height: frame.height * scale,
          child: CustomPaint(
            painter: _LogoPainter(
              paths: wordmarkOnly ? built.wordmark : built.all,
              frame: frame,
              color: color ?? context.colors['logo'],
            ),
          ),
        ),
      ),
    );
  }
}

enum _LogoKind { mark, lockup, wordmark }

/// Glyphs are drawn at 0.1 scale from 1000-unit fonts: one em is 100 units.
const _wordmarkEm = 100.0;

final class _LogoShape {
  const _LogoShape(this.data, this.affine, {this.isMark = false});

  /// SVG path data.
  final String data;

  /// SVG affine transform `[a, b, c, d, e, f]`.
  final List<double> affine;

  /// Part of the mark rather than the name.
  final bool isMark;

  Path build() {
    final [a, b, c, d, e, f] = affine;
    return parseSvgPath(data).transform(
      Float64List.fromList([a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, e, f, 0, 1]),
    );
  }
}

final class _LogoArt {
  const _LogoArt({required this.viewBox, required this.shapes});

  final Rect viewBox;
  final List<_LogoShape> shapes;
}

/// Parsed paths, built once per artwork.
final class _BuiltArt {
  factory _BuiltArt.of(_LogoArt art) =>
      _cache.putIfAbsent(art, () => _BuiltArt._(art));

  _BuiltArt._(_LogoArt art)
    : all = _combine(art.shapes),
      wordmark = _combine(art.shapes.where((shape) => !shape.isMark));

  static final _cache = <_LogoArt, _BuiltArt>{};

  final Path all;
  final Path wordmark;
  late final Rect wordmarkBounds = wordmark.getBounds();

  static Path _combine(Iterable<_LogoShape> shapes) {
    final path = Path();
    for (final shape in shapes) {
      path.addPath(shape.build(), Offset.zero);
    }
    return path;
  }
}

final class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.paths, required this.frame, required this.color});

  final Path paths;
  final Rect frame;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (frame.isEmpty) return;
    canvas
      ..save()
      ..scale(size.width / frame.width, size.height / frame.height)
      ..translate(-frame.left, -frame.top)
      ..drawPath(paths, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.paths != paths ||
      oldDelegate.frame != frame ||
      oldDelegate.color != color;
}
