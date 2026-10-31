import 'package:flutter_test/flutter_test.dart';

import '../../helpers/booking_journey.dart';

/// Host run of the T101 payment journey (US1 + US6) on the mock backend.
/// The same body runs on a device through
/// `integration_test/booking_journey_mock_test.dart`.
void main() {
  testWidgets('the full payment journey ends in a recoverable state', (
    tester,
  ) async {
    await runPaymentJourney(tester);
  });
}
