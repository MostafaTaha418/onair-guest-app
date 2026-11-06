import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Research R14: log lines carry IDs only — never names, phones, emails,
/// codes, notes, tokens, or file URLs. This test walks every stay file
/// (plus the payment cubits that open the browser flow) and fails when a
/// `logger.` / `_logger.` line mentions one of the private words.
void main() {
  final files = <File>[
    ...Directory('lib/features/stay')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart')),
    File('lib/features/booking/presentation/payment_attempt_cubit.dart'),
    File('lib/features/bookings/presentation/unfinished_payment_cubit.dart'),
  ]..sort((a, b) => a.path.compareTo(b.path));

  final forbidden = RegExp(
    'phone|e164|email|code|note|url|name|receipt',
    caseSensitive: false,
  );

  test('every stay file exists and the scan is not empty', () {
    expect(files, isNotEmpty);
    expect(
      files.any((file) => file.path.endsWith('mock_stay_server.dart')),
      isTrue,
      reason: 'the scan must cover the stay folder',
    );
  });

  test('log lines never mention private words (research R14)', () {
    final violations = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final isLogLine = line.contains('logger.') || line.contains('_logger.');
        if (!isLogLine) continue;
        final match = forbidden.firstMatch(line);
        if (match != null) {
          violations.add(
            '${file.path}:${i + 1} — "${match.group(0)}" in: '
            '${line.trim()}',
          );
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
