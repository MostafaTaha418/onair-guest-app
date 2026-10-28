import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/features/booking/presentation/booking_entry_placeholder_screen.dart';

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

  Future<void> pumpViaNavigation(
    WidgetTester tester,
    Map<String, String> query,
  ) async {
    await tester.pumpOnAirApp(
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BookingEntryPlaceholderScreen(
                  propertyId: 'p-1',
                  query: query,
                ),
              ),
            ),
            child: const Text('فتح'),
          ),
        ),
      ),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the title, the coming-soon message, and a back button', (
    tester,
  ) async {
    await pumpViaNavigation(tester, {});
    expect(find.text('الحجز'), findsOneWidget);
    expect(find.text('الحجز من التطبيق هيتفتح قريب.'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('carried dates and guests are echoed from the query', (
    tester,
  ) async {
    await tester.pumpOnAirApp(
      const BookingEntryPlaceholderScreen(
        propertyId: 'p-1',
        query: {
          'checkIn': '2026-11-20',
          'checkOut': '2026-11-23',
          'guests': '4',
        },
      ),
      authRepository: auth,
      appConfigRepository: config,
    );
    expect(find.textContaining('20 نوفمبر'), findsOneWidget);
    expect(find.textContaining('23 نوفمبر'), findsOneWidget);
    expect(find.textContaining('4'), findsOneWidget);
  });

  testWidgets('the terms value is never shown; only the carried note', (
    tester,
  ) async {
    await tester.pumpOnAirApp(
      const BookingEntryPlaceholderScreen(
        propertyId: 'p-1',
        query: {'terms': 'sha256:secret-value'},
      ),
      authRepository: auth,
      appConfigRepository: config,
    );
    expect(find.text('الشروط اللي شفتها اتسجّلت مع الطلب.'), findsOneWidget);
    expect(find.textContaining('sha256:secret-value'), findsNothing);
  });

  testWidgets('without dates or terms nothing extra renders', (tester) async {
    await tester.pumpOnAirApp(
      const BookingEntryPlaceholderScreen(propertyId: 'p-1', query: {}),
      authRepository: auth,
      appConfigRepository: config,
    );
    expect(find.text('الشروط اللي شفتها اتسجّلت مع الطلب.'), findsNothing);
    expect(find.textContaining('نوفمبر'), findsNothing);
  });
}
