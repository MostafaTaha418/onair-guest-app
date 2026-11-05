import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stay_journey.dart';

void main() {
  testWidgets('remaining payment', runRemainingPaymentJourney);

  testWidgets('cash confirmation', runCashJourney);

  testWidgets('stay acknowledgements', runStayAckJourney);

  testWidgets('cancellation', runCancellationJourney);
}
