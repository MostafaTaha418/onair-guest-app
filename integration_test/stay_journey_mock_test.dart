import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/stay_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('remaining payment', runRemainingPaymentJourney);

  testWidgets('cash confirmation', runCashJourney);

  testWidgets('stay acknowledgements', runStayAckJourney);

  testWidgets('cancellation', runCancellationJourney);
}
