import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/push/push_messages.dart';
import 'package:on_air/features/notifications/presentation/in_app_notification_banner.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../helpers/fake_app_config_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  Future<void> pumpBanner(
    WidgetTester tester, {
    required PushMessage message,
    required ValueChanged<PushMessage> onOpen,
    required VoidCallback onDismiss,
  }) async {
    await tester.pumpOnAirApp(
      InAppNotificationBanner(
        message: message,
        onOpen: onOpen,
        onDismiss: onDismiss,
      ),
      authRepository: FakeAuthRepository(),
      appConfigRepository: FakeAppConfigRepository(
        const AppConfig(
          minSupportedBuildAndroid: 1,
          minSupportedBuildIos: 1,
          supportPhone: '+201000000000',
          currentTermsVersion: 'mock-terms-1',
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a foreground push shows the type title and tap opens', (
    tester,
  ) async {
    final opened = <PushMessage>[];
    const message = PushMessage(
      type: 'booking.confirmed',
      targetId: 'b0000000-0000-4000-8000-000000000001',
    );
    await pumpBanner(
      tester,
      message: message,
      onOpen: opened.add,
      onDismiss: () {},
    );

    expect(find.text(l10n.notifBookingConfirmedTitle), findsOneWidget);
    expect(find.text(l10n.notifBookingConfirmedBody), findsOneWidget);

    await tester.tap(find.text(l10n.notifBookingConfirmedTitle));
    await tester.pump();
    expect(opened, [message]);
  });

  testWidgets('the banner hides itself after four seconds', (tester) async {
    var dismissed = false;
    await pumpBanner(
      tester,
      message: const PushMessage(type: 'payment.failed', targetId: 'x'),
      onOpen: (_) {},
      onDismiss: () => dismissed = true,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(dismissed, isTrue);
  });

  testWidgets('an unknown type shows the generic title', (tester) async {
    await pumpBanner(
      tester,
      message: const PushMessage(type: 'weird.push', targetId: 'x'),
      onOpen: (_) {},
      onDismiss: () {},
    );
    expect(find.text(l10n.notifGenericTitle), findsOneWidget);
  });

  testWidgets('the close button dismisses the banner', (tester) async {
    var dismissed = false;
    await pumpBanner(
      tester,
      message: const PushMessage(type: 'refund.verified', targetId: 'x'),
      onOpen: (_) {},
      onDismiss: () => dismissed = true,
    );

    await tester.tap(find.byTooltip(l10n.close));
    await tester.pump();
    expect(dismissed, isTrue);
  });
}
