import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
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

/// Review fixes 3 + round 2: both steps render every failure through the
/// shared `apiErrorMessage` (via `phoneVerificationErrorText`) — no silent
/// whitelists; an unexpected server error carries its reference number
/// (Constitution VIII); a rate limit without a wait never says «0:00».
void main() {
  final l10n = lookupAppLocalizations(const Locale('ar'));
  const requestId = 'req-9';

  final cases = <String, (ApiError, String)>{
    'internal with a reference': (
      const ApiError(
        code: ErrorCode.internal,
        messageKey: 'errorUnexpected',
        requestId: requestId,
      ),
      l10n.errorUnexpected(requestId),
    ),
    'rate limited without a wait': (
      const ApiError(
        code: ErrorCode.rateLimited,
        messageKey: 'authRateLimited',
      ),
      l10n.authRateLimitedNoTime,
    ),
    'unauthenticated': (
      const ApiError(
        code: ErrorCode.unauthenticated,
        messageKey: 'errorUnauthenticated',
      ),
      l10n.errorUnauthenticated,
    ),
    'blocked without a date': (
      const ApiError(
        code: ErrorCode.otpSendBlocked,
        messageKey: 'otpBlockedUntil',
      ),
      l10n.otpBlockedNoDate,
    ),
    'superseded code': (
      const ApiError(
        code: ErrorCode.otpSuperseded,
        messageKey: 'whatsappUseLatestCode',
      ),
      l10n.whatsappUseLatestCode,
    ),
  };

  Widget harness({required Widget child}) => MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    home: Scaffold(body: ListView(children: [child])),
  );

  PhoneVerificationCubit cubit() => PhoneVerificationCubit(
    _StubRepository(),
    purpose: PhoneVerificationPurpose.register,
    needsName: false,
    needsTerms: false,
    locale: 'ar',
    currentTermsVersion: 'v1',
  );

  WhatsAppChallenge challenge() => WhatsAppChallenge(
    challengeId: 'challenge-1',
    maskedPhone: '+20 10•• ••• 678',
    expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
    window: SendWindow(
      serverTime: DateTime.now().toUtc(),
      receivedAt: DateTime.now().toUtc(),
    ),
  );

  Future<void> pumpStep(
    WidgetTester tester,
    PvState state,
    Widget step,
  ) async {
    final bloc = cubit()..emit(state);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<PhoneVerificationCubit>.value(
        value: bloc,
        child: harness(child: step),
      ),
    );
    await tester.pump();
  }

  for (final MapEntry(key: name, value: (error, text)) in cases.entries) {
    testWidgets('the code step renders $name visibly', (tester) async {
      await pumpStep(
        tester,
        PvCode(challenge: challenge(), error: error),
        const WhatsAppCodeStep(supportPhone: '+201000000000'),
      );
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('the form step renders $name visibly', (tester) async {
      await pumpStep(
        tester,
        PvForm(generalError: error),
        const PhoneFormStep(needsName: false, needsTerms: false),
      );
      expect(find.text(text), findsOneWidget);
    });
  }

  test('a rate limit with a wait keeps the m:ss text', () {
    expect(
      apiErrorMessage(
        const ApiError(
          code: ErrorCode.rateLimited,
          messageKey: 'authRateLimited',
          retryAfter: Duration(seconds: 90),
        ),
        l10n,
      ),
      l10n.authRateLimited('1:30'),
    );
  });

  testWidgets('a rate-limited first send says no code went out yet', (
    tester,
  ) async {
    await pumpStep(
      tester,
      PvCode(challenge: challenge(), codeSent: false),
      const WhatsAppCodeStep(supportPhone: '+201000000000'),
    );
    expect(
      find.text(l10n.whatsappNotSentYet('+20 10•• ••• 678')),
      findsOneWidget,
    );
    expect(
      find.text(l10n.whatsappCodeSentTo('+20 10•• ••• 678')),
      findsNothing,
    );
  });
}
