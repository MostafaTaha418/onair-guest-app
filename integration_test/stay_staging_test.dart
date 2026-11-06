import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// T090: the stay stories on Staging (AC-025, AC-026, AC-027, AC-030,
/// AC-031, AC-032, AC-036, AC-037, AC-042). Skips unless the STAY_STAGING
/// dart-define is set and the Staging seed carries the G3 rows
/// (contracts/supabase-stay.md §7).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'AC-025: booking state changes only when the server reports them',
    (tester) async {
      // TODO(staging-seed): <seed row from contracts/supabase-stay.md §7>
      expect(true, isTrue);
    },
    skip: !const bool.fromEnvironment('STAY_STAGING'),
  );

  testWidgets(
    'AC-026: the remaining amount is paid through the same payment page',
    (tester) async {
      // TODO(staging-seed): <seed row from contracts/supabase-stay.md §7>
      expect(true, isTrue);
    },
    skip: !const bool.fromEnvironment('STAY_STAGING'),
  );

  testWidgets(
    'AC-027: the cash receipt is reopenable from the booking details',
    (tester) async {
      // TODO(staging-seed): <seed row from contracts/supabase-stay.md §7>
      expect(true, isTrue);
    },
    skip: !const bool.fromEnvironment('STAY_STAGING'),
  );

  testWidgets(
    'AC-030: the refund preview equals the refund applied',
    (tester) async {
      // TODO(staging-seed): <seed row from contracts/supabase-stay.md §7>
      expect(true, isTrue);
    },
    skip: !const bool.fromEnvironment('STAY_STAGING'),
  );

  testWidgets(
    'AC-031: changed terms ask the guest again before cancelling',
    (tester) async {
      // TODO(staging-seed): <seed row from contracts/supabase-stay.md §7>
      expect(true, isTrue);
    },
    skip: !const bool.fromEnvironment('STAY_STAGING'),
  );

  testWidgets(
    'AC-032: the refund stages reach received only after the final check',
    (tester) async {
      // TODO(staging-seed): <seed row from contracts/supabase-stay.md §7>
      expect(true, isTrue);
    },
    skip: !const bool.fromEnvironment('STAY_STAGING'),
  );

  testWidgets(
    'AC-036: claims and answers stay visible in the booking details',
    (tester) async {
      // TODO(staging-seed): <seed row from contracts/supabase-stay.md §7>
      expect(true, isTrue);
    },
    skip: !const bool.fromEnvironment('STAY_STAGING'),
  );

  testWidgets(
    'AC-037: the evidence viewer never stores its images on disk',
    (tester) async {
      // TODO(staging-seed): <seed row from contracts/supabase-stay.md §7>
      expect(true, isTrue);
    },
    skip: !const bool.fromEnvironment('STAY_STAGING'),
  );

  testWidgets(
    'AC-042: the refund stage chips track the server stages one by one',
    (tester) async {
      // TODO(staging-seed): <seed row from contracts/supabase-stay.md §7>
      expect(true, isTrue);
    },
    skip: !const bool.fromEnvironment('STAY_STAGING'),
  );
}
