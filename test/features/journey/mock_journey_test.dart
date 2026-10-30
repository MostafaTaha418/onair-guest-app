import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_journey.dart';

/// Host run of the SC-007 visitor-resume journey (T095) on the mock
/// backend. The same body runs on a device through
/// `integration_test/discovery_journey_test.dart`.
void main() {
  testWidgets(
    'a visitor signs in from «احجز الآن» and continues to the booking entry',
    (tester) async {
      await runVisitorBookingJourney(tester);
    },
  );
}
