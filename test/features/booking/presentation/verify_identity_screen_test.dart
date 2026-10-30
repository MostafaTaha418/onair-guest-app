import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/presentation/verify_identity_cubit.dart';
import 'package:on_air/features/booking/presentation/verify_identity_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/pump_app.dart';

/// Delegates to the mock server but can override the reported verification
/// status (the mock server only flips both flags at once).
final class OverridingFlowRepository implements BookingFlowRepository {
  OverridingFlowRepository(this._inner);

  final BookingFlowRepository _inner;
  VerificationStatus? statusOverride;
  int sendCodeCalls = 0;

  @override
  Future<VerificationStatus> verificationStatus() async =>
      statusOverride ?? await _inner.verificationStatus();

  @override
  Future<BookingQuote> quote({
    required String propertyId,
    required StayRange stay,
    required int guests,
    required String termsHash,
  }) => _inner.quote(
    propertyId: propertyId,
    stay: stay,
    guests: guests,
    termsHash: termsHash,
  );

  @override
  Future<PaymentSessionInfo> startPayment({
    required String quoteId,
    required String termsHash,
    required String attemptKey,
  }) => _inner.startPayment(
    quoteId: quoteId,
    termsHash: termsHash,
    attemptKey: attemptKey,
  );

  @override
  Future<PhoneChallenge> requestPhoneChange({
    required String phoneE164,
    required bool hasWhatsapp,
    String? whatsappE164,
  }) => _inner.requestPhoneChange(
    phoneE164: phoneE164,
    hasWhatsapp: hasWhatsapp,
    whatsappE164: whatsappE164,
  );

  @override
  Future<void> sendCode(String challengeId) async {
    sendCodeCalls++;
    await _inner.sendCode(challengeId);
  }

  @override
  Future<void> verifyCode({
    required String challengeId,
    required String code,
  }) => _inner.verifyCode(challengeId: challengeId, code: code);
}

/// Opens the verify screen the way DatesScreen does and shows the result.
final class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

final class _HostState extends State<_Host> {
  bool? result;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(
        key: const ValueKey('open-verify'),
        onPressed: () async {
          final ok = await context.push<bool>('/verify');
          if (mounted) setState(() => result = ok);
        },
        child: const Text('open'),
      ),
      if (result != null) Text('result:$result', key: const ValueKey('result')),
    ],
  );
}

void main() {
  late FakeBookingBackend backend;
  late FakeAuthRepository auth;
  late OverridingFlowRepository flow;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    backend = FakeBookingBackend(startVerified: false);
    auth = FakeAuthRepository();
    flow = OverridingFlowRepository(backend.server);
  });

  tearDown(() => backend.dispose());

  Future<void> pumpVerify(WidgetTester tester) async {
    const emailOnlyStatus = VerificationStatus(
      emailConfirmed: true,
      phoneConfirmed: false,
      email: 'guest@mock.onair.test',
      phone: '+201000000001',
    );
    final router = GoRouter(
      initialLocation: '/host',
      routes: [
        GoRoute(
          path: '/host',
          builder: (_, _) => const _Host(),
        ),
        GoRoute(
          path: '/verify',
          builder: (context, _) =>
              RepositoryProvider<BookingFlowRepository>.value(
                value: flow,
                child: BlocProvider<VerifyIdentityCubit>(
                  create: (context) {
                    final cubit = VerifyIdentityCubit(
                      flow: context.read<BookingFlowRepository>(),
                      auth: context.read<AuthRepository>(),
                    );
                    unawaited(cubit.start());
                    return cubit;
                  },
                  child: const VerifyIdentityScreen(),
                ),
              ),
        ),
      ],
    );
    await tester.pumpOnAirApp(
      const SizedBox.shrink(),
      routerConfig: router,
      authRepository: auth,
      appConfigRepository: FakeAppConfigRepository(
        const AppConfig(
          minSupportedBuildAndroid: 1,
          minSupportedBuildIos: 1,
          supportPhone: '+201000000000',
          currentTermsVersion: 'mock-terms-1',
        ),
      ),
      bookingBackend: backend,
    );
    await tester.pumpAndSettle();
    // The screen starts after the first status round-trip.
    flow.statusOverride = emailOnlyStatus;
  }

  testWidgets('the email step shows the address, then the code field', (
    tester,
  ) async {
    await pumpVerify(tester);
    flow.statusOverride = null; // the server itself: email unconfirmed first
    await tester.tap(find.byKey(const ValueKey('open-verify')));
    await tester.pumpAndSettle();

    expect(find.text('guest@mock.onair.test'), findsOneWidget);
    expect(find.text(l10n.sendCode), findsOneWidget);
    expect(find.byType(OnAirOtpField), findsNothing);

    await tester.tap(find.text(l10n.sendCode));
    await tester.pumpAndSettle();
    expect(find.byType(OnAirOtpField), findsOneWidget);
    expect(find.text(l10n.verifyEmailCodeHint), findsOneWidget);
  });

  testWidgets(
    'the phone step hides the WhatsApp field while the switch is on',
    (
      tester,
    ) async {
      await pumpVerify(tester);
      await tester.tap(find.byKey(const ValueKey('open-verify')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.verifyTitle), findsOneWidget);
      expect(find.text(l10n.verifyIntro), findsOneWidget);
      final fields = tester
          .widgetList<OnAirTextField>(find.byType(OnAirTextField))
          .toList();
      expect(fields, hasLength(1));
      expect(fields.single.label, l10n.phoneNumber);
      expect(find.text(l10n.verifyHasWhatsapp), findsOneWidget);

      await tester.tap(find.text(l10n.verifyHasWhatsapp));
      await tester.pump();
      final withWhatsapp = tester
          .widgetList<OnAirTextField>(find.byType(OnAirTextField))
          .toList();
      expect(withWhatsapp, hasLength(2));
      expect(withWhatsapp.last.label, l10n.verifyWhatsappNumber);
    },
  );

  testWidgets('the resend button is disabled until retryAfter passes', (
    tester,
  ) async {
    await pumpVerify(tester);
    await tester.tap(find.byKey(const ValueKey('open-verify')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '01012345678');
    await tester.tap(find.text(l10n.sendCode));
    await tester.pump();
    await tester.pump();

    expect(find.text(l10n.verifyCodeSentToEmail), findsOneWidget);
    expect(find.byType(OnAirOtpField), findsOneWidget);
    final resend = tester.widget<TextButton>(
      find.byKey(const ValueKey('verify-resend')),
    );
    expect(resend.onPressed, isNull);
    expect(find.text(l10n.verifyResendIn('60')), findsOneWidget);

    await tester.pump(const Duration(seconds: 61));
    final afterWindow = tester.widget<TextButton>(
      find.byKey(const ValueKey('verify-resend')),
    );
    expect(afterWindow.onPressed, isNotNull);
    expect(find.text(l10n.authResend), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('verify-resend')));
    await tester.pump();
    expect(flow.sendCodeCalls, 2);
  });

  testWidgets('a wrong code shows the error; the right one pops with true', (
    tester,
  ) async {
    await pumpVerify(tester);
    await tester.tap(find.byKey(const ValueKey('open-verify')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '01012345678');
    await tester.tap(find.text(l10n.sendCode));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.authOtpInvalid), findsOneWidget);

    flow.statusOverride = null; // the re-check reads the server's own status
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('result')), findsOneWidget);
    expect(find.text('result:true'), findsOneWidget);
  });
}
