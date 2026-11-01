import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/booking_journey.dart';

/// The T101 payment journey on a device run (US1 + US6). The same body runs
/// on the host in `test/features/journey/booking_journey_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the full payment journey ends in a recoverable state', (
    tester,
  ) async {
    await runPaymentJourney(tester);
  });
}
