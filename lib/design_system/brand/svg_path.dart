import 'dart:ui';

final _token = RegExp(
  r'[MmLlHhVvCcQqAaZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?',
);

const _commands = 'MmLlHhVvCcQqAaZz';

/// Turns SVG path data (`d`) into a [Path].
///
/// Supports the commands the brand artwork uses: M, L, H, V, C, Q, A and Z,
/// absolute and relative.
Path parseSvgPath(String data) {
  final tokens = [for (final match in _token.allMatches(data)) match[0]!];
  final path = Path();
  var index = 0;
  String? command;
  var x = 0.0;
  var y = 0.0;
  var startX = 0.0;
  var startY = 0.0;

  double next() {
    if (index >= tokens.length || _commands.contains(tokens[index])) {
      throw FormatException('Missing number in SVG path', data);
    }
    return double.parse(tokens[index++]);
  }

  while (index < tokens.length) {
    if (_commands.contains(tokens[index])) {
      command = tokens[index++];
    } else if (command == null || command == 'Z' || command == 'z') {
      throw FormatException('Unexpected number in SVG path', data);
    }
    final relative = command.toLowerCase() == command;
    final baseX = relative ? x : 0.0;
    final baseY = relative ? y : 0.0;
    switch (command.toUpperCase()) {
      case 'M':
        x = baseX + next();
        y = baseY + next();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        // Extra pairs after a move are lines.
        command = relative ? 'l' : 'L';
      case 'L':
        x = baseX + next();
        y = baseY + next();
        path.lineTo(x, y);
      case 'H':
        x = baseX + next();
        path.lineTo(x, y);
      case 'V':
        y = baseY + next();
        path.lineTo(x, y);
      case 'C':
        final x1 = baseX + next();
        final y1 = baseY + next();
        final x2 = baseX + next();
        final y2 = baseY + next();
        x = baseX + next();
        y = baseY + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
      case 'Q':
        final x1 = baseX + next();
        final y1 = baseY + next();
        x = baseX + next();
        y = baseY + next();
        path.quadraticBezierTo(x1, y1, x, y);
      case 'A':
        final rx = next();
        final ry = next();
        final rotation = next();
        final largeArc = next() != 0;
        final sweep = next() != 0;
        x = baseX + next();
        y = baseY + next();
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: largeArc,
          clockwise: sweep,
        );
      case 'Z':
        path.close();
        x = startX;
        y = startY;
    }
  }
  return path;
}
