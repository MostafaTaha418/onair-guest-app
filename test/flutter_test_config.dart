import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/time/cairo_time.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  CairoTime.initialize();
  await AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      // Real Cairo text makes these baselines renderer-specific. CI uses Windows,
      // matching the environment where the reviewed reference PNGs were generated.
      ciGoldensConfig: CiGoldensConfig(obscureText: false),
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
