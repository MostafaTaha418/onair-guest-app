import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/core/env/env_config.dart';

import '../test/helpers/mock_journey.dart';

/// SC-007 end-to-end journey for device runs (Android emulator on CI).
///
/// Mock mode is the default and needs no configuration. In remote mode the
/// journey needs the deployed `guest_*` RPCs and the Staging seed
/// (`env/staging_seed.json`); until then it skips with a printed reason.
/// The same body runs on the host in
/// `test/features/journey/mock_journey_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final environment = EnvConfig.fromEnvironment();
  final remote = environment.backendMode == BackendMode.remote;
  final seed = File('env/staging_seed.json');

  testWidgets(
    'a visitor signs in from «احجز الآن» and continues to the booking entry',
    (tester) async {
      if (remote) {
        // The skip reason must reach the console on a device run.
        // ignore: avoid_print
        print(
          'Skipping the journey: BACKEND_MODE=remote needs a device with the '
          'Staging seed (${seed.path}).',
        );
        return;
      }

      await runVisitorBookingJourney(tester);
    },
  );
}
