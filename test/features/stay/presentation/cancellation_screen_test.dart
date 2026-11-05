import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/stay/data/action_attempt_store.dart';
import 'package:on_air/features/stay/domain/cancellation_preview.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/presentation/cancellation/cancellation_cubit.dart';
import 'package:on_air/features/stay/presentation/cancellation/cancellation_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/pump_app.dart';

const _booking21 = 'b0000000-0000-4000-8000-000000000021';
const _booking23 = 'b0000000-0000-4000-8000-000000000023';
const _booking24 = 'b0000000-0000-4000-8000-000000000024';

void main() {
  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late ConnectivityCubit connectivityCubit;
  late AppLocalizations l10n;

  setUpAll(() async {
    CairoTime.initialize();
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );
    connectivity = FakeConnectivity();
    connectivityCubit = connectivity.createCubit();
  });

  tearDown(() async {
    await connectivityCubit.close();
    connectivity.dispose();
    backend.dispose();
  });

  /// Pumps the real route shape: a details stub page that pushes the
  /// cancellation route, so «خليني محتفظ بالحجز» can pop back.
  Future<void> pumpCancellation(WidgetTester tester, String bookingId) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.bookingDetails(bookingId),
      routes: [
        GoRoute(
          path: AppRoutes.bookingDetailsPattern,
          builder: (_, _) => const Text('details-stub'),
        ),
        GoRoute(
          path: AppRoutes.cancelBookingPattern,
          name: 'cancel-booking',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return BlocProvider<CancellationCubit>(
              create: (context) {
                final cubit = CancellationCubit(
                  stay: context.read<StayRepository>(),
                  attempts: context.read<ActionAttemptStore>(),
                  connectivity: context.read<ConnectivityCubit>(),
                  logger: AppLogger(sink: (_) {}),
                  bookingId: id,
                );
                unawaited(cubit.load());
                return cubit;
              },
              child: CancellationScreen(bookingId: id),
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
      connectivityCubit: connectivityCubit,
    );
    unawaited(
      GoRouter.of(tester.element(find.text('details-stub'))).push(
        AppRoutes.cancelBooking(bookingId),
      ),
    );
    for (var i = 0; i < 40 && !tester.any(find.text(l10n.cancelTitle)); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();
  }

  CancellationCubit cubitOf(WidgetTester tester) =>
      tester.element(find.byType(CancellationScreen)).read<CancellationCubit>();

  testWidgets('the free case shows its sentence and hides the forfeit row', (
    tester,
  ) async {
    await pumpCancellation(tester, _booking23);

    expect(
      find.text(l10n.cancelReasonFree(MoneyFormatter().format(Money(450000)))),
      findsOneWidget,
    );
    expect(find.text(l10n.cancelNonRefundable), findsNothing);
  });

  testWidgets('the deposit-lost case names the forfeited deposit and date', (
    tester,
  ) async {
    await pumpCancellation(tester, _booking21);

    expect(
      find.text(
        l10n.cancelReasonDepositLost(
          MoneyFormatter().format(Money(270000)),
          MoneyFormatter().format(Money(90000)),
          formatCairoDayMonthTime(DateTime.parse('2026-10-29T10:00:00Z')),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.cancelNonRefundable), findsOneWidget);
  });

  testWidgets('the no-refund case uses its own sentence', (tester) async {
    await pumpCancellation(tester, _booking24);

    expect(find.text(l10n.cancelReasonNoRefund), findsOneWidget);
  });

  testWidgets('a terms change highlights the refund row with the old value', (
    tester,
  ) async {
    await pumpCancellation(tester, _booking21);

    backend.stay.forceTermsChangeOnce(_booking21);
    await cubitOf(tester).submit();
    await tester.pump();
    await tester.pump();

    final refundRow = tester.widget<AmountRow>(
      find.byWidgetPredicate(
        (widget) => widget is AmountRow && widget.label == l10n.cancelRefund,
      ),
    );
    expect(refundRow.highlighted, isTrue);
    expect(
      refundRow.previousValue,
      MoneyFormatter().format(Money(270000)),
    );
    expect(find.text(l10n.cancellationTermsChanged), findsOneWidget);
  });

  testWidgets('the dialog backs out without sending anything', (tester) async {
    await pumpCancellation(tester, _booking23);

    await tester.tap(find.byKey(const ValueKey('cancel-confirm')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        l10n.cancelDialogBody(MoneyFormatter().format(Money(450000))),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.dialogBack));
    await tester.pumpAndSettle();
    expect(backend.stay.cancels, 0);
  });

  testWidgets('keep pops without any call', (tester) async {
    await pumpCancellation(tester, _booking23);

    await tester.tap(find.text(l10n.cancelKeep));
    await tester.pumpAndSettle();

    expect(find.text('details-stub'), findsOneWidget);
    expect(backend.stay.cancels, 0);
  });

  testWidgets('reason chips are single-select and other opens a capped field', (
    tester,
  ) async {
    await pumpCancellation(tester, _booking23);

    bool selected(String label) => tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .firstWhere((chip) => (chip.label as Text).data == label)
        .selected;

    await tester.tap(find.text(l10n.cancelReasonChangeOfPlans));
    await tester.pump();
    expect(selected(l10n.cancelReasonChangeOfPlans), isTrue);

    await tester.tap(find.text(l10n.cancelReasonTravelProblem));
    await tester.pump();
    expect(selected(l10n.cancelReasonChangeOfPlans), isFalse);
    expect(selected(l10n.cancelReasonTravelProblem), isTrue);
    expect(
      tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((chip) => chip.selected)
          .length,
      1,
    );

    await tester.tap(find.text(l10n.cancelReasonOther));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).maxLength,
      CancellationReason.noteMaxLength,
    );
  });

  testWidgets('offline shows the connection error', (tester) async {
    // The cubit already listens, so the offline event lands on the next
    // microtask — no Future.delayed here: timers never fire in testWidgets.
    connectivity.goOffline();
    await pumpCancellation(tester, _booking23);

    expect(find.text(l10n.stayNeedsConnection), findsOneWidget);
  });
}
