import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/booking_flow_kit.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/features/stay/data/mock_stay_server.dart';
import 'package:on_air/features/stay/presentation/cash/cash_receipt_cubit.dart';
import 'package:on_air/features/stay/presentation/cash/cash_receipt_screen.dart';
import 'package:on_air/features/stay/presentation/claims/damage_claim_cubit.dart';
import 'package:on_air/features/stay/presentation/claims/damage_claim_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/pump_until_found.dart';

void main() {
  const confirmedId = 'b0000000-0000-4000-8000-000000000001';
  const awaitingId = 'b0000000-0000-4000-8000-000000000002';
  const checkedInId = 'b0000000-0000-4000-8000-000000000004';
  const unknownId = 'b0000000-0000-4000-8000-0000000000ff';
  const instructionsText = 'المفتاح مع حارس العمارة. اطلب منه باسم الحجز.';

  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    CairoTime.initialize();
  });

  setUp(() {
    backend = FakeBookingBackend();
    connectivity = FakeConnectivity();
  });

  tearDown(() {
    backend.dispose();
    connectivity.dispose();
  });

  Future<void> pumpDetails(
    WidgetTester tester,
    String bookingId, {
    bool overrideMockStay = false,
  }) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.bookingDetails(bookingId),
      routes: [
        GoRoute(
          path: AppRoutes.bookingDetailsPattern,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return BlocProvider<BookingDetailsCubit>(
              create: (context) {
                final cubit = BookingDetailsCubit(
                  bookings: backend.server,
                  cache: backend.cache,
                  arrival: backend.arrivalInstructions,
                  signals: backend.signals,
                  connectivity: context.read<ConnectivityCubit>(),
                  bookingId: id,
                );
                unawaited(cubit.load());
                return cubit;
              },
              child: overrideMockStay
                  ? RepositoryProvider<MockStayServer?>.value(
                      value: null,
                      child: BookingDetailsScreen(bookingId: id),
                    )
                  : BookingDetailsScreen(bookingId: id),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.damageClaimPattern,
          name: 'linked-damage-claim',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final claimId = state.pathParameters['claimId']!;
            return BlocProvider<DamageClaimCubit>(
              create: (context) {
                final cubit = DamageClaimCubit(
                  stay: backend.stay,
                  bookings: backend.server,
                  attempts: backend.actionAttempts,
                  registry: BookingActionRegistry.g3(),
                  connectivity: context.read<ConnectivityCubit>(),
                  logger: AppLogger(sink: (_) {}),
                  bookingId: id,
                  claimId: claimId,
                );
                unawaited(cubit.load());
                return cubit;
              },
              child: DamageClaimScreen(bookingId: id, claimId: claimId),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.supportNew,
          builder: (_, _) => const Text('support-stub'),
        ),
        GoRoute(
          path: AppRoutes.receiptPattern,
          name: 'cash-receipt',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final paymentId = state.pathParameters['paymentId']!;
            return BlocProvider<CashReceiptCubit>(
              create: (context) {
                final cubit = CashReceiptCubit(
                  bookings: backend.server,
                  cache: backend.cache,
                  connectivity: context.read<ConnectivityCubit>(),
                  bookingId: id,
                  paymentId: paymentId,
                );
                unawaited(cubit.load());
                return cubit;
              },
              child: CashReceiptScreen(bookingId: id, paymentId: paymentId),
            );
          },
        ),
      ],
    );
    await tester.pumpOnAirApp(
      const SizedBox.shrink(),
      routerConfig: router,
      authRepository: FakeAuthRepository(),
      appConfigRepository: FakeAppConfigRepository(
        const AppConfig(
          minSupportedBuildAndroid: 1,
          minSupportedBuildIos: 1,
          supportPhone: '+201000000000',
          currentTermsVersion: 'mock-terms-1',
        ),
      ),
      bookingBackend: backend,
      connectivityCubit: connectivity.createCubit(),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the confirmed booking shows every section', (tester) async {
    await pumpDetails(tester, confirmedId);

    // Header: code row with the copy button and the status chip.
    expect(find.textContaining(l10n.bookingCode), findsOneWidget);
    expect(find.text('OA-MOCK001'), findsOneWidget);
    expect(find.byTooltip(l10n.bookingCopyCode), findsOneWidget);
    // Once in the header chip and once as the timeline's last event.
    expect(find.text(l10n.bookingStatusConfirmed), findsExactly(2));

    // Status message: confirmed with a remaining amount.
    expect(
      find.text(
        l10n.bookingMsgConfirmedWithRemaining(
          MoneyFormatter().format(Money(337500)),
        ),
      ),
      findsOneWidget,
    );

    // Stay.
    expect(find.text(l10n.bookingStayTitle), findsOneWidget);
    expect(
      find.text(DateOnlyFormatter.dayMonth(DateOnly.parse('2026-11-20'))),
      findsOneWidget,
    );
    expect(
      find.text(DateOnlyFormatter.dayMonth(DateOnly.parse('2026-11-23'))),
      findsOneWidget,
    );
    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);

    // Payments.
    expect(find.text(l10n.bookingPaymentsTitle), findsOneWidget);
    expect(
      find.text(MoneyFormatter().format(Money(450000))),
      findsOneWidget,
    );
    expect(
      find.text(MoneyFormatter().format(Money(337500))),
      findsOneWidget,
    );
    expect(
      find.text(
        l10n.bookingRemainingDue(
          // 2026-11-19T22:00Z is 00:00 on 20 November in Cairo: the due
          // day is Cairo's calendar day, as the remaining screen shows it.
          DateOnlyFormatter.dayMonth(DateOnly(2026, 11, 20)),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.paymentMethodCard), findsOneWidget);
    // The paid row and the payment line both carry the paid amount.
    expect(
      find.textContaining(MoneyFormatter().format(Money(112500))),
      findsExactly(2),
    );
    // The payment line: its status chip and its Cairo date and time.
    expect(find.text(l10n.paymentLineSucceeded), findsOneWidget);
    expect(
      find.text(
        formatCairoDayMonthTime(DateTime.parse('2026-10-28T09:00:00Z')),
      ),
      findsOneWidget,
    );

    // Address and arrival instructions.
    expect(find.text(l10n.bookingAddressTitle), findsOneWidget);
    expect(find.text('شارع 9، المعادي، القاهرة'), findsOneWidget);
    expect(find.text(l10n.bookingArrivalInstructions), findsOneWidget);
    expect(find.text(instructionsText), findsOneWidget);

    // Saved terms and timeline.
    expect(find.text(l10n.bookingSavedTermsTitle), findsOneWidget);
    expect(find.text(l10n.bookingTimelineTitle), findsOneWidget);
    expect(find.text(l10n.bookingStatusPaymentPending), findsOneWidget);

    // Only the support action, and a fresh load has no cache note.
    expect(
      find.byKey(const ValueKey('action-contact_support')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('action-pay_remaining')), findsNothing);
    expect(
      find.byKey(const ValueKey('action-request_cancellation')),
      findsNothing,
    );
    expect(find.textContaining(l10n.lastUpdated('')), findsNothing);
  });

  testWidgets('the copy button copies the code and shows a confirmation', (
    tester,
  ) async {
    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map)['text'] as String?;
          }
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': clipboardText};
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await pumpDetails(tester, confirmedId);
    await tester.tap(find.byTooltip(l10n.bookingCopyCode));
    await tester.pump();
    await tester.pump();

    expect(clipboardText, 'OA-MOCK001');
    expect(find.text(l10n.bookingCodeCopied), findsOneWidget);
  });

  testWidgets('the support action opens the support entry', (tester) async {
    await pumpDetails(tester, confirmedId);
    await tester.tap(find.byKey(const ValueKey('action-contact_support')));
    await tester.pump();
    await tester.pump();
    expect(find.text('support-stub'), findsOneWidget);
  });

  testWidgets('an awaiting-owner booking shows no instructions', (
    tester,
  ) async {
    await pumpDetails(tester, awaitingId);
    expect(find.text(l10n.bookingArrivalInstructions), findsNothing);
    expect(
      find.text(
        l10n.bookingMsgAwaitingOwner(
          formatCairoDayMonthTime(DateTime.parse('2026-11-02T10:00:00Z')),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'three server actions still render only the support button',
    (tester) async {
      await pumpDetails(tester, checkedInId);
      expect(
        find.byKey(const ValueKey('action-contact_support')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('action-pay_remaining')), findsNothing);
      expect(
        find.byKey(const ValueKey('action-request_cancellation')),
        findsNothing,
      );
    },
  );

  testWidgets('offline disables the support button', (tester) async {
    await pumpDetails(tester, confirmedId);
    connectivity.goOffline();
    await tester.pump();
    await tester.pump();

    final button = tester.widget<FlowButton>(
      find.byKey(const ValueKey('action-contact_support')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('an unknown booking shows the not-available view', (
    tester,
  ) async {
    await pumpDetails(tester, unknownId);
    expect(find.text(l10n.notAvailable), findsOneWidget);
  });

  testWidgets('G3 deposit booking shows remaining banner and primary action', (
    tester,
  ) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );

    await pumpDetails(
      tester,
      'b0000000-0000-4000-8000-000000000020',
    );

    expect(find.text(l10n.remainingNote), findsOneWidget);
    expect(
      find.byKey(const ValueKey('primary-pay_remaining')),
      findsOneWidget,
    );
  });

  testWidgets('G2 registry hides G3 remaining banner and action', (
    tester,
  ) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g2(),
    );

    await pumpDetails(
      tester,
      'b0000000-0000-4000-8000-000000000020',
    );

    expect(find.text(l10n.remainingNote), findsNothing);
    expect(
      find.byKey(const ValueKey('primary-pay_remaining')),
      findsNothing,
    );
  });

  testWidgets('G3 cash line opens its receipt', (tester) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );

    await pumpDetails(tester, 'b0000000-0000-4000-8000-000000000022');

    // The cash line row opens the receipt; the label text sits inside
    // its InkWell.
    final cashLine = find.text(l10n.paymentMethodCash);
    await tester.scrollUntilVisible(
      cashLine,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(cashLine);
    await tester.pump();
    await tester.pump();

    expect(find.text('R-2026-000123'), findsOneWidget);
  });

  // --- G3 (US3): the check-in flow on the details screen.

  testWidgets('G3 stay booking shows the check-in primary action', (
    tester,
  ) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );

    await pumpDetails(tester, 'b0000000-0000-4000-8000-000000000021');

    expect(
      find.byKey(const ValueKey('primary-confirm_checkin')),
      findsOneWidget,
    );
  });

  testWidgets('G3 remaining-due booking shows no check-in action', (
    tester,
  ) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );

    await pumpDetails(tester, 'b0000000-0000-4000-8000-000000000020');

    expect(
      find.byKey(const ValueKey('primary-confirm_checkin')),
      findsNothing,
    );
  });

  testWidgets('the check-in sheet opens and «لسه» sends nothing', (
    tester,
  ) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );

    await pumpDetails(tester, 'b0000000-0000-4000-8000-000000000021');

    await tester.tap(find.byKey(const ValueKey('primary-confirm_checkin')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.checkinSheetTitle), findsOneWidget);
    expect(find.text(l10n.checkinProblem), findsOneWidget);

    await tester.tap(find.text(l10n.sheetNotYet));
    await tester.pumpAndSettle();
    expect(find.text(l10n.checkinSheetTitle), findsNothing);
    expect(backend.stay.checkIns, 0);
  });

  testWidgets('confirming check-in refreshes and shows the tracker', (
    tester,
  ) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );

    await pumpDetails(tester, 'b0000000-0000-4000-8000-000000000021');

    await tester.tap(find.byKey(const ValueKey('primary-confirm_checkin')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.checkinSheetConfirm));
    await tester.pumpAndSettle();

    expect(backend.stay.checkIns, 1);
    expect(find.text(l10n.checkinSheetTitle), findsNothing);
    // The refreshed details show the handover tracker.
    expect(find.text(l10n.ackTitleCheckin), findsOneWidget);
    expect(find.text(l10n.ackYou), findsOneWidget);
    expect(find.text(l10n.ackOwner), findsOneWidget);
    expect(find.text(l10n.ackWaiting), findsOneWidget);
  });

  testWidgets('G3 booking with claims shows the claims section', (
    tester,
  ) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );

    await pumpDetails(tester, 'b0000000-0000-4000-8000-000000000025');

    expect(find.text(l10n.claimsSectionTitle), findsOneWidget);
    // Two claim cards: EGP 500.00 (open) and EGP 300.00 (resolved).
    expect(find.textContaining('500.00'), findsWidgets);
    expect(find.text(l10n.claimStatusOpen), findsOneWidget);
    expect(find.text(l10n.claimStatusResolved), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(l10n.claimsSectionTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.textContaining('500.00'));
    await tester.pump();
    await tester.pump();

    expect(find.text(l10n.claimTitle), findsOneWidget);
    expect(find.text(l10n.claimStatusOpen), findsOneWidget);
  });

  testWidgets('mock mode shows the stay tools sheet', (tester) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );

    await pumpDetails(tester, 'b0000000-0000-4000-8000-000000000021');

    final toolsButton = find.byTooltip(l10n.mockToolsTitle);
    expect(toolsButton, findsOneWidget);

    await tester.tap(toolsButton);
    await tester.pumpAndSettle();
    expect(find.text(l10n.mockToolsTitle), findsOneWidget);
    expect(find.text(l10n.mockOwnerHandover), findsOneWidget);
    expect(find.text(l10n.mockChangeTerms), findsOneWidget);

    await tester.tap(find.text(l10n.mockChangeTerms));
    await tester.pumpAndSettle();
    expect(find.text(l10n.mockToolsTitle), findsNothing);
  });

  testWidgets('remote mode (no mock stay) hides the tools icon', (
    tester,
  ) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );

    // A null MockStayServer provider, as the remote bootstrap registers.
    await pumpDetails(
      tester,
      'b0000000-0000-4000-8000-000000000021',
      overrideMockStay: true,
    );

    expect(find.byTooltip(l10n.mockToolsTitle), findsNothing);
  });

  testWidgets('a fast double tap on an action opens its sheet once', (
    tester,
  ) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );

    await pumpDetails(tester, 'b0000000-0000-4000-8000-000000000021');

    final primary = find.byKey(const ValueKey('primary-confirm_checkin'));
    await tester.tap(primary);
    await tester.tap(primary, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(l10n.checkinSheetTitle), findsOneWidget);
    // Closing the one sheet shows the details again, not a second sheet.
    await tester.tap(find.text(l10n.sheetNotYet));
    await tester.pumpAndSettle();
    expect(find.text(l10n.checkinSheetTitle), findsNothing);
    expect(find.byKey(const ValueKey('primary-confirm_checkin')), findsOne);
  });

  testWidgets('answering a claim and going back refreshes the details', (
    tester,
  ) async {
    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );

    await pumpDetails(tester, 'b0000000-0000-4000-8000-000000000025');
    expect(find.text(l10n.claimStatusOpen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('primary-respond_damage_claim')),
      findsNothing,
      reason: 'respond is never the filled primary action',
    );

    await tester.scrollUntilVisible(
      find.text(l10n.claimsSectionTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(l10n.claimStatusOpen));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('claim-agree')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.dialogConfirm));
    await tester.pumpAndSettle();
    expect(backend.stay.claimAnswers, 1);

    // Back to the details: the claim no longer waits for the guest, and
    // the «respond» action is gone without a manual pull-to-refresh.
    // A system back (gesture or button) goes through the claim's PopScope.
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).last,
    );
    await navigator.maybePop();
    for (
      var attempt = 0;
      attempt < 40 && tester.any(find.text(l10n.claimTitle));
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await pumpUntilFound(tester, find.text(l10n.claimStatusAccepted));
    for (
      var attempt = 0;
      attempt < 40 && tester.any(find.text(l10n.claimStatusOpen));
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.text(l10n.claimTitle), findsNothing);
    expect(find.text(l10n.claimStatusOpen), findsNothing);
    expect(find.text(l10n.claimStatusAccepted), findsOneWidget);
    expect(
      find.byKey(const ValueKey('action-respond_damage_claim')),
      findsNothing,
    );
  });
}
