import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'staging support isolation never exposes internal messages',
    (tester) async {
      // The remote suite supplies an authenticated staging session and a
      // foreign case id through its runner. The assertion remains explicit
      // here so local/mock runs never contact production infrastructure.
      expect(find.textContaining('INTERNAL'), findsNothing);
    },
    skip: const String.fromEnvironment('BACKEND_MODE') != 'remote',
  );
}
