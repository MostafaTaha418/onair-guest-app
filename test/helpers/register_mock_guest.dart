import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Completes the email-only registration flow used by the full-app tests.
Future<void> registerMockGuest(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.tap(find.text(l10n.authCreateAccount));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('email-name-field')),
    'زائر تجريبي',
  );
  await tester.enterText(
    find.byKey(const ValueKey('email-phone-field')),
    '01012345678',
  );
  await tester.enterText(
    find.byKey(const ValueKey('email-field')),
    'journey@example.com',
  );
  await tester.ensureVisible(find.byKey(const ValueKey('password-field')));
  await tester.enterText(
    find.byKey(const ValueKey('password-field')),
    'Password123!',
  );
  await tester.ensureVisible(
    find.byKey(const ValueKey('email-terms-checkbox')),
  );
  await tester.tap(find.byKey(const ValueKey('email-terms-checkbox')));
  await tester.ensureVisible(find.byKey(const ValueKey('email-submit-button')));
  await tester.tap(find.byKey(const ValueKey('email-submit-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byKey(const ValueKey('otp-field')),
      matching: find.byType(TextField),
    ),
    MockBackend.verificationCode,
  );
  await tester.pumpAndSettle();
}
