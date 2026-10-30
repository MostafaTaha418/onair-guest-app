// Host-side driver for the G1 performance run (T105).
//
//   flutter drive \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/results_scroll_perf_test.dart \
//     --flavor staging -t lib/main_staging.dart
//
// The timeline recorded by `binding.traceAction(..., reportKey: 'results_scroll')`
// arrives here through responseDataCallback and each entry lands in
// build/perf/<reportKey>_timeline_summary.json.
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      final directory = Directory('build/perf');
      await directory.create(recursive: true);
      const encoder = JsonEncoder.withIndent('  ');
      for (final entry in data.entries) {
        // The screenshots entry belongs to the onScreenshot pipeline.
        if (entry.key == 'screenshots') continue;
        final file = File('build/perf/${entry.key}_timeline_summary.json');
        await file.writeAsString(encoder.convert(entry.value));
      }
    },
  );
}
