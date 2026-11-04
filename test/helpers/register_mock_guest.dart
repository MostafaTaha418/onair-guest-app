import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/features/auth/presentation/widgets/auth_flow_scaffold.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import 'pump_until_found.dart';

/// Completes the email-only registration flow used by the full-app tests.
Future<void> registerMockGuest(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.tap(find.text(l10n.authCreateAccount));
  await tester.pumpAndSettle();
  final nameField = find.byKey(const ValueKey('email-name-field'));
  final phoneField = find.byKey(const ValueKey('email-phone-field'));
  final emailField = find.byKey(const ValueKey('email-field'));
  final passwordField = find.byKey(const ValueKey('password-field'));
  final terms = find.byKey(const ValueKey('email-terms-checkbox'));
  final submit = find.byKey(const ValueKey('email-submit-button'));
  await pumpUntilFound(tester, nameField);
  await _scrollToRegistrationField(tester, nameField);
  await tester.enterText(
    nameField,
    'زائر تجريبي',
  );
  await _scrollToRegistrationField(tester, phoneField);
  await tester.enterText(phoneField, '01012345678');
  await _scrollToRegistrationField(tester, emailField);
  await tester.enterText(emailField, 'journey@example.com');
  await _scrollToRegistrationField(tester, passwordField);
  await tester.enterText(passwordField, 'Password123!');
  // On a real iOS simulator the software keyboard can keep covering the
  // lower half of the registration route after enterText completes. Dismiss
  // it before scrolling to the controls below the password field so the tap
  // is delivered to the active route rather than the keyboard/route overlay.
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await _scrollToRegistrationField(tester, terms);
  await pumpUntilFound(tester, terms.hitTestable());
  await tester.tap(terms.hitTestable());
  await tester.pump();
  await _scrollToRegistrationField(tester, submit);
  await pumpUntilFound(tester, submit.hitTestable());
  await tester.tap(submit.hitTestable());
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

Future<void> _scrollToRegistrationField(
  WidgetTester tester,
  Finder field,
) async {
  final registrationList = find
      .descendant(
        of: find.byType(AuthFlowScaffold),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(field, 200, scrollable: registrationList);
}
