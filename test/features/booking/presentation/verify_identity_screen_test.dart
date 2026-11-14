import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
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
/// status (the mock server only flips both flags at once). S005 US6: the
/// phone side is a WhatsApp redirect card — no booking-flow challenge.
final class OverridingFlowRepository implements BookingFlowRepository {
  OverridingFlowRepository(this._inner);

  final BookingFlowRepository _inner;
  VerificationStatus? statusOverride;

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
  Future<PaymentSessionInfo> startRemainingPayment({
    required String bookingId,
    required String attemptKey,
  }) => _inner.startRemainingPayment(
    bookingId: bookingId,
    attemptKey: attemptKey,
  );
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

/// The «أكّد رقمك» route stub: pops `true` or `false` on demand.
final class _AccountPhoneStub extends StatelessWidget {
  const _AccountPhoneStub({required this.popValue});

  final bool popValue;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: const ValueKey('account-phone-pop'),
        onPressed: () => context.pop(popValue),
        child: const Text('pop'),
      ),
    ),
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
        GoRoute(
          path: AppRoutes.accountPhone,
          builder: (_, _) => const _AccountPhoneStub(popValue: true),
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

  testWidgets('the unconfirmed phone shows the WhatsApp redirect card', (
    tester,
  ) async {
    await pumpVerify(tester);
    await tester.tap(find.byKey(const ValueKey('open-verify')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.verifyTitle), findsOneWidget);
    expect(find.text(l10n.bookingPhoneNotVerified), findsOneWidget);
    expect(
      find.byKey(const ValueKey('verify-phone-whatsapp')),
      findsOneWidget,
    );
    // No phone entry and no booking-flow code step any more (T071).
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(OnAirOtpField), findsNothing);
  });

  testWidgets(
    'a confirmed «أكّد رقمك» return re-checks and pops with true',
    (tester) async {
      await pumpVerify(tester);
      await tester.tap(find.byKey(const ValueKey('open-verify')));
      await tester.pumpAndSettle();

      // The change succeeded on the account: the re-check sees both flags.
      flow.statusOverride = const VerificationStatus(
        emailConfirmed: true,
        phoneConfirmed: true,
        email: 'guest@mock.onair.test',
        phone: '+201000000001',
      );
      await tester.tap(find.byKey(const ValueKey('verify-phone-whatsapp')));
      await tester.pumpAndSettle();
      // The /account/phone stub answers with `true` (the change succeeded).
      await tester.tap(find.byKey(const ValueKey('account-phone-pop')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('result')), findsOneWidget);
      expect(find.text('result:true'), findsOneWidget);
    },
  );
}
