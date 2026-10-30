import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/core/env/env_config.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../test/helpers/mock_app.dart';

/// T105: the frame timeline for scrolling the results list over the mock
/// fixtures (124 published apartments). Mock mode is the default; a remote
/// run would measure the network instead of the list, so it skips with a
/// printed reason.
///
/// Run from the host with `flutter drive` — see
/// docs/perf/g1-results-scroll.md for the command and the result record.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final environment = EnvConfig.fromEnvironment();

  testWidgets(
    'flinging the results list reports a timeline (results_scroll)',
    (tester) async {
      if (environment.backendMode == BackendMode.remote) {
        // The skip reason must reach the console on a device run.
        // ignore: avoid_print
        print(
          'Skipping the scroll-perf run: it measures the mock fixture list '
          '(BACKEND_MODE=remote would measure the network instead).',
        );
        return;
      }

      await bootMockApp(tester);
      final l10n = lookupAppLocalizations(const Locale('ar'));

      // Open the results for «all published apartments» (no criteria).
      await tester.tap(find.byKey(const ValueKey('nav-search')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.searchAction));
      await tester.pumpAndSettle();
      expect(find.byType(PropertyCard), findsWidgets);

      // Fling the list down ten times inside one traced action; the summary
      // reaches test_driver/perf_driver.dart under `results_scroll`.
      await binding.traceAction(() async {
        for (var fling = 0; fling < 10; fling++) {
          await tester.fling(
            find.byType(PropertyCard).first,
            const Offset(0, -800),
            3000,
          );
          await tester.pumpAndSettle();
        }
      }, reportKey: 'results_scroll');
    },
  );
}
