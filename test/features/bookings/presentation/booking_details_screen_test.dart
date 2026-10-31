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
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/pump_app.dart';

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

  Future<void> pumpDetails(WidgetTester tester, String bookingId) async {
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
              child: BookingDetailsScreen(bookingId: id),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.supportNew,
          builder: (_, _) => const Text('support-stub'),
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
    expect(find.text(l10n.bookingCode), findsOneWidget);
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
          DateOnlyFormatter.dayMonth(
            DateOnly.fromDateTime(DateTime.parse('2026-11-19T22:00:00Z')),
          ),
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
    expect(
      find.text(
        '${MoneyFormatter().format(Money(112500))} · '
        '${l10n.paymentLineSucceeded} · '
        '${formatCairoTime(DateTime.parse('2026-10-28T09:00:00Z'))}',
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

    final button = tester.widget<OutlinedButton>(
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
}
