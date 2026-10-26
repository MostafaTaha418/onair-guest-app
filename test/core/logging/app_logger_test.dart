import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/logging/app_logger.dart';

void main() {
  test('redacts phone, email, and token-shaped strings', () {
    final events = <String>[];
    AppLogger(sink: events.add).warning(
      'Call +201012345678 at guest@example.com '
      'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.signature',
    );
    expect(events.single, isNot(contains('+201012345678')));
    expect(events.single, isNot(contains('guest@example.com')));
    expect(events.single, isNot(contains('eyJhbGciOiJIUzI1NiJ9')));
  });

  test('release level drops debug and info', () {
    final events = <String>[];
    AppLogger(release: true, sink: events.add)
      ..debug('debug')
      ..info('info')
      ..warning('warning');
    expect(events, hasLength(1));
  });
}
