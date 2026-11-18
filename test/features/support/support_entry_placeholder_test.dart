import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/features/support/presentation/support_entry_placeholder_screen.dart';

import '../../helpers/fake_app_config_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  final auth = FakeAuthRepository();
  final config = FakeAppConfigRepository(
    const AppConfig(
      minSupportedBuildAndroid: 1,
      minSupportedBuildIos: 1,
      supportPhone: '+201000000000',
      currentTermsVersion: 'v1',
    ),
  );

  testWidgets('shows the support title and the coming-soon message', (
    tester,
  ) async {
    await tester.pumpOnAirApp(
      const SupportEntryPlaceholderScreen(propertyId: 'p-1'),
      authRepository: auth,
      appConfigRepository: config,
    );
    expect(find.text('تواصل مع OnAir'), findsOneWidget);
    expect(find.text('خدمة الدعم من التطبيق هتتفتح قريب.'), findsOneWidget);
  });
}
