import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/whatsapp_code_step.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';

class _StubRepository implements PhoneVerificationRepository {
  @override
  Future<String> start(
    PhoneVerificationDraft draft,
    PhoneVerificationPurpose purpose,
  ) async => 'challenge-1';

  @override
  Future<WhatsAppChallenge> send(String challengeId) =>
      throw UnimplementedError();

  @override
  Future<(DeliveryStatus, DeliveryFailure?, SendWindow)> status(
    String challengeId,
  ) => throw UnimplementedError();

  @override
  Future<GuestAccount> verify(String challengeId, String code) =>
      throw UnimplementedError();
}

/// T079: the per-second countdown is noise for a screen reader — the
/// resend button exposes one static label while it waits, and the ticking
/// text stays out of the semantics tree.
void main() {
  final l10n = lookupAppLocalizations(const Locale('ar'));

  Future<void> pumpCounting(WidgetTester tester, DateTime now) async {
    final cubit =
        PhoneVerificationCubit(
          _StubRepository(),
          purpose: PhoneVerificationPurpose.register,
          needsName: false,
          needsTerms: false,
          locale: 'ar',
          currentTermsVersion: 'v1',
        )..emit(
          PvCode(
            challenge: WhatsAppChallenge(
              challengeId: 'challenge-1',
              maskedPhone: '+20 10•• ••• 678',
              expiresAt: now.add(const Duration(minutes: 10)),
              window: SendWindow(
                serverTime: now,
                receivedAt: now,
                nextSendAt: now.add(const Duration(seconds: 30)),
              ),
            ),
          ),
        );
    await tester.pumpWidget(
      RepositoryProvider<AppConfigSource>(
        create: (_) => FakeAppConfigRepository(
          const AppConfig(
            minSupportedBuildAndroid: 1,
            minSupportedBuildIos: 1,
            supportPhone: '+201000000000',
            currentTermsVersion: 'v1',
          ),
        ),
        child: BlocProvider<PhoneVerificationCubit>.value(
          value: cubit,
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            darkTheme: OnAirTheme.dark,
            home: Scaffold(
              body: ListView(
                children: [
                  WhatsAppCodeStep(
                    // The frozen emit instant: the countdown text cannot
                    // race the real second hand in the test.
                    clock: () => now,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the waiting resend button announces only its static label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpCounting(tester, DateTime.now().toUtc());

    // The visible text carries the countdown, the semantics do not.
    expect(find.textContaining('00:3'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('whatsapp-resend')),
    );
    expect(semantics.label, l10n.whatsappResend);
    expect(semantics.label, isNot(contains(':')));
    handle.dispose();
  });

  testWidgets('«كلّم الدعم» opens the public FAQ, not a dialer', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    final cubit =
        PhoneVerificationCubit(
          _StubRepository(),
          purpose: PhoneVerificationPurpose.register,
          needsName: false,
          needsTerms: false,
          locale: 'ar',
          currentTermsVersion: 'v1',
        )..emit(
          PvCode(
            challenge: WhatsAppChallenge(
              challengeId: 'challenge-1',
              maskedPhone: '+20 10•• ••• 678',
              expiresAt: now.add(const Duration(minutes: 10)),
              window: SendWindow(
                serverTime: now,
                receivedAt: now,
                nextSendAt: now.add(const Duration(seconds: 30)),
              ),
            ),
            // The delivery notice is what carries the «كلّم الدعم» action.
            notice: PvNotice.notOnWhatsApp,
          ),
        );
    final router = GoRouter(
      initialLocation: '/confirm-phone',
      routes: [
        GoRoute(
          path: '/confirm-phone',
          builder: (context, state) =>
              BlocProvider<PhoneVerificationCubit>.value(
                value: cubit,
                child: Scaffold(body: WhatsAppCodeStep(clock: () => now)),
              ),
        ),
        GoRoute(
          path: AppRoutes.supportFaq,
          builder: (_, _) => const Text('faq'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OnAirTheme.light,
        routerConfig: router,
      ),
    );
    await tester.pump();

    await tester.tap(find.text(l10n.whatsappContactSupport));
    await tester.pumpAndSettle();
    expect(find.text('faq'), findsOneWidget);
  });
}
