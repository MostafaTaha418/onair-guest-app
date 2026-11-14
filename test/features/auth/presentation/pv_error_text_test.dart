import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/phone_form_step.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/whatsapp_code_step.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

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

/// Review fix 3: the two steps render every error key through the shared
/// `localizedErrorText` resolver — no silent whitelists, and the request id
/// rides `errorUnexpected` (Constitution VIII).
void main() {
  final l10n = lookupAppLocalizations(const Locale('ar'));
  const requestId = 'req-9';

  final keys = <String, Matcher>{
    'errorUnexpected': contains('req-9'),
    'authRateLimited': isNotEmpty,
    'errorUnauthenticated': isNotEmpty,
    'otpBlockedUntil': isNotEmpty,
  };

  Widget harness({required Widget child}) => MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    home: Scaffold(body: ListView(children: [child])),
  );

  Future<void> pumpCodeStep(WidgetTester tester, String key) async {
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
              expiresAt: DateTime.now().toUtc().add(
                const Duration(minutes: 10),
              ),
              window: SendWindow(
                serverTime: DateTime.now().toUtc(),
                receivedAt: DateTime.now().toUtc(),
              ),
            ),
            errorKey: key,
            errorRequestId: requestId,
          ),
        );
    await tester.pumpWidget(
      BlocProvider<PhoneVerificationCubit>.value(
        value: cubit,
        child: harness(
          child: const WhatsAppCodeStep(supportPhone: '+201000000000'),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpFormStep(WidgetTester tester, String key) async {
    final cubit = PhoneVerificationCubit(
      _StubRepository(),
      purpose: PhoneVerificationPurpose.register,
      needsName: false,
      needsTerms: false,
      locale: 'ar',
      currentTermsVersion: 'v1',
    )..emit(PvForm(generalErrorKey: key, generalErrorRequestId: requestId));
    await tester.pumpWidget(
      BlocProvider<PhoneVerificationCubit>.value(
        value: cubit,
        child: harness(
          child: const PhoneFormStep(needsName: false, needsTerms: false),
        ),
      ),
    );
    await tester.pump();
  }

  for (final entry in keys.entries) {
    testWidgets('the code step renders ${entry.key} visibly', (tester) async {
      await pumpCodeStep(tester, entry.key);
      expect(
        find.text(localizedErrorText(entry.key, l10n, requestId: requestId)),
        findsOneWidget,
      );
    });

    testWidgets('the form step renders ${entry.key} visibly', (tester) async {
      await pumpFormStep(tester, entry.key);
      expect(
        find.text(localizedErrorText(entry.key, l10n, requestId: requestId)),
        findsOneWidget,
      );
    });
  }

  testWidgets('an unknown key falls back to the no-reference text', (
    tester,
  ) async {
    await pumpCodeStep(tester, 'totally-unknown-key');
    expect(find.text(l10n.errorUnexpectedNoRef), findsOneWidget);
  });
}
