import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/complete_profile_screen.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeAppConfigRepository config;

  setUp(() {
    auth = FakeAuthRepository()
      ..account = GuestAccount(
        id: 'guest',
        phone: '+201012345678',
        fullName: 'Guest Name',
        acceptedTermsVersion: 'v1',
      );
    config = FakeAppConfigRepository(
      const AppConfig(
        minSupportedBuildAndroid: 1,
        minSupportedBuildIos: 1,
        supportPhone: '+201000000000',
        currentTermsVersion: 'v1',
      ),
    );
  });

  testWidgets('requires a trimmed 2-80 character name and terms', (
    tester,
  ) async {
    await tester.pumpOnAirApp(
      const CompleteProfileScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('full-name-field')),
      ' a ',
    );
    await tester.pump();
    final button = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const ValueKey('complete-profile-button')),
        matching: find.byType(TextButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.textContaining('حرفين'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('full-name-field')),
      'Guest Name',
    );
    await tester.pump();
    final withoutTerms = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const ValueKey('complete-profile-button')),
        matching: find.byType(TextButton),
      ),
    );
    expect(withoutTerms.onPressed, isNull);
  });

  testWidgets('TERMS_CHANGED reloads terms and requires agreement again', (
    tester,
  ) async {
    auth.completeProfileError = const ProfileTermsChanged();
    await tester.pumpOnAirApp(
      const CompleteProfileScreen(),
      authRepository: auth,
      appConfigRepository: config,
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('full-name-field')),
      'Guest Name',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('terms-checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('complete-profile-button')));
    await tester.pumpAndSettle();

    expect(config.loadCount, greaterThanOrEqualTo(3));
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('terms-checkbox')),
          )
          .value,
      isFalse,
    );
    expect(find.byKey(const ValueKey('terms-error')), findsOneWidget);
  });
}
