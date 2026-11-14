import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/phone_verification/data/mock_phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../test/helpers/mock_app.dart';
import '../test/helpers/pump_until_found.dart';

/// S005 US5 end-to-end (T066): the ladder and the 7-day block over the
/// mock backend, driven through `MockBackend.clock` — the server moves
/// forward while the device clock stays real, which is exactly the skew
/// `SendWindow.remainingUntilSend` must neutralise (R8).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('ar'));

  final base = DateTime.now();
  var serverAhead = Duration.zero;
  void advanceServer(Duration delta) => serverAhead += delta;

  /// Home → first apartment → «احجز الآن» → the login screen's Google row.
  Future<void> openLoginFromApartment(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpUntilFound(tester, find.byType(PropertyCard));
    await tester.tap(find.byType(PropertyCard).first);
    await pumpUntilFound(tester, find.text(l10n.bookNow));
    await tester.tap(find.text(l10n.bookNow));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('social-google-button')),
    );
  }

  /// The «أكّد رقمك» journey down to the code step: a fresh Google user,
  /// the number, the terms, «متابعة» — the first send sits at the top of
  /// the ladder.
  Future<MockPhoneVerificationRepository> reachCodeStep(
    WidgetTester tester,
    MockAuthRepository auth,
  ) async {
    auth.scenario = MockSocialScenario.newUser;
    await openLoginFromApartment(tester);
    await tester.tap(find.byKey(const ValueKey('social-google-button')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('confirm-phone-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-phone-field')),
      '01012345678',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-phone-terms')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-phone-continue')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('whatsapp-otp-field')),
    );
    return tester
            .element(find.byType(OnAirApp))
            .read<PhoneVerificationRepository>()
        as MockPhoneVerificationRepository;
  }

  /// Waits the ladder out on the mock server, then asks for a fresh code.
  Future<void> resendWhenReady(WidgetTester tester, Duration wait) async {
    advanceServer(wait);
    // The window is over: «ابعت كود جديد» comes back enabled.
    await pumpUntilFound(tester, find.text(l10n.whatsappResend));
    await tester.tap(find.byKey(const ValueKey('whatsapp-resend')));
  }

  /// Sends 10 codes across the ladder and trips the 11th request — the
  /// blocked notice answers it.
  Future<MockPhoneVerificationRepository> reachBlock(
    WidgetTester tester,
    MockAuthRepository auth,
  ) async {
    final phones = await reachCodeStep(tester, auth);
    const waits = [
      Duration(seconds: 30),
      Duration(minutes: 5),
      Duration(hours: 1),
      Duration(hours: 24),
      Duration(hours: 1),
      Duration(hours: 24),
      Duration(hours: 1),
      Duration(hours: 24),
      Duration(hours: 1),
    ];
    for (final wait in waits) {
      await resendWhenReady(tester, wait);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('whatsapp-otp-field')),
      );
    }
    // Send #10 is in; its 24 h window is next — the 11th request blocks.
    advanceServer(const Duration(hours: 24));
    await pumpUntilFound(tester, find.text(l10n.whatsappResend));
    await tester.tap(find.byKey(const ValueKey('whatsapp-resend')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('pv-blocked-notice')),
    );
    return phones;
  }

  /// The «أكّد رقمك» form of a rebooted app (same mock backend): the number,
  /// the terms (the mock keeps them unaccepted) and «متابعة».
  Future<void> submitRebootedForm(WidgetTester tester) async {
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('confirm-phone-field')),
    );
    final nameField = find.byKey(const ValueKey('confirm-phone-name-field'));
    if (tester.any(nameField)) {
      await tester.enterText(nameField, 'زائر تجريبي');
      await tester.pump();
    }
    await tester.enterText(
      find.byKey(const ValueKey('confirm-phone-field')),
      '01012345678',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-phone-terms')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-phone-continue')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('pv-blocked-notice')),
    );
  }

  testWidgets(
    '(a) the countdown text follows the ladder steps',
    (tester) async {
      MockBackend.clock = () => base.add(serverAhead);
      addTearDown(() => MockBackend.clock = DateTime.now);
      final auth = await bootMockApp(tester);
      await reachCodeStep(tester, auth);

      // Sends 1–4: 30 s, 5 min, 1 h, 24 h.
      expect(
        find.text(l10n.whatsappResendIn('00:30')),
        findsOneWidget,
      );
      await resendWhenReady(tester, const Duration(seconds: 30));
      await pumpUntilFound(
        tester,
        find.text(l10n.whatsappResendIn('05:00')),
      );
      await resendWhenReady(tester, const Duration(minutes: 5));
      await pumpUntilFound(
        tester,
        find.text(l10n.whatsappResendIn(l10n.durationHoursMinutes('1', '0'))),
      );
      await resendWhenReady(tester, const Duration(hours: 1));
      await pumpUntilFound(
        tester,
        find.text(l10n.whatsappResendIn(l10n.durationHoursMinutes('24', '0'))),
      );
    },
  );

  testWidgets(
    '(b) the 11th request shows the block date, (c) the reboot and (d) a '
    'new account stay blocked',
    (tester) async {
      MockBackend.clock = () => base.add(serverAhead);
      addTearDown(() => MockBackend.clock = DateTime.now);
      final auth = MockAuthRepository();
      await bootMockApp(tester, auth: auth);
      final phones = await reachBlock(tester, auth);

      // (b) The block date is the server's now + 7 days, Cairo-rendered.
      final blockedUntil = base.add(
        serverAhead + const Duration(days: 7),
      );
      expect(
        find.text(
          l10n.otpBlockedUntil(
            formatCairoDayMonthTime(blockedUntil, locale: l10n.localeName),
          ),
        ),
        findsOneWidget,
      );

      // (c) A fresh app over the SAME mock backend: the device key still
      // blocks — this time from the form step.
      await bootMockApp(tester, auth: auth, phoneVerification: phones);
      await submitRebootedForm(tester);

      // (d) Signed out, a brand-new account on the same device: still
      // blocked.
      await auth.signOut();
      await pumpUntilFound(tester, find.byType(PropertyCard));
      await reachBlockViaFormAfterSignIn(tester, auth);
    },
  );

  testWidgets(
    '(e) a failed attestation shows the notice and counts nothing',
    (tester) async {
      MockBackend.clock = () => base.add(serverAhead);
      addTearDown(() => MockBackend.clock = DateTime.now);
      final auth = await bootMockApp(tester);
      final phones = await reachCodeStep(tester, auth);
      expect(phones.otpServer.callLog, ['send']);

      phones.otpServer.attestationFails = true;
      await resendWhenReady(tester, const Duration(seconds: 30));
      await pumpUntilFound(tester, find.text(l10n.otpAttestationFailed));

      // Nothing counted: the keys still hold only the first send.
      final accountId = auth.account!.id;
      for (final key in [
        'acct:$accountId',
        'phone:+201012345678',
        'dev:mock-device',
      ]) {
        expect(phones.otpServer.counters(key).sendCount, 1, reason: key);
      }
      expect(phones.otpServer.callLog, ['send', 'send.attestationFailed']);
    },
  );
}

/// After the rebooted-app sign-out, the guest signs in again and reaches a
/// blocked first send from the form step (the device key of case (d)).
Future<void> reachBlockViaFormAfterSignIn(
  WidgetTester tester,
  MockAuthRepository auth,
) async {
  final l10n = lookupAppLocalizations(const Locale('ar'));
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.tap(find.byType(PropertyCard).first);
  await pumpUntilFound(tester, find.text(l10n.bookNow));
  await tester.tap(find.text(l10n.bookNow));
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('social-google-button')),
  );
  auth.scenario = MockSocialScenario.newUser;
  await tester.tap(find.byKey(const ValueKey('social-google-button')));
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('confirm-phone-field')),
  );
  final nameField = find.byKey(const ValueKey('confirm-phone-name-field'));
  if (tester.any(nameField)) {
    await tester.enterText(nameField, 'زائر تجريبي');
    await tester.pump();
  }
  await tester.enterText(
    find.byKey(const ValueKey('confirm-phone-field')),
    '01098765432',
  );
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('confirm-phone-terms')));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('confirm-phone-continue')));
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('pv-blocked-notice')),
  );
}
