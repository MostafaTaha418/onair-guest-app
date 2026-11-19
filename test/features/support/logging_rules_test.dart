import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tasks rule 6 (privacy): log lines and crash reports carry IDs only —
/// never message bodies, names, emails, passwords, file names or signed
/// URLs. This test walks every support, account and core file-pipeline
/// file and fails when a `logger` / crash-reporter line mentions one of
/// the private words. Same approach as the stay suite's logging rules.
void main() {
  final dirs = [
    Directory('lib/features/support'),
    Directory('lib/features/account'),
    Directory('lib/core/files'),
  ];

  final files = <File>[
    for (final dir in dirs)
      ...dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
  ]..sort((a, b) => a.path.compareTo(b.path));

  final forbidden = RegExp(
    'body|fullName|email|password|url|name',
    caseSensitive: false,
  );

  test('every G4 folder exists and the scan is not empty', () {
    expect(files, isNotEmpty);
    bool covered(String suffix) => files.any(
      (file) => file.path.replaceAll(RegExp(r'\\'), '/').endsWith(suffix),
    );
    expect(
      covered('mock_support_server.dart'),
      isTrue,
      reason: 'the scan must cover the support folder',
    );
    expect(
      covered('mock_account_server.dart'),
      isTrue,
      reason: 'the scan must cover the account folder',
    );
    expect(
      covered('private_file_uploader.dart'),
      isTrue,
      reason: 'the scan must cover the file pipeline',
    );
  });

  test('log lines never mention private words (rule 6)', () {
    final violations = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final isLogLine =
            line.contains('logger.') ||
            line.contains('_logger.') ||
            line.contains('CrashReporter') ||
            line.contains('crashReporter.');
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
