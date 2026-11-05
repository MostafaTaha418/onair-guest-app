import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/stay/presentation/remaining_payment/remaining_payment_cubit.dart';
import 'package:on_air/features/stay/presentation/remaining_payment/remaining_payment_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_in_app_browser.dart';
import '../../../helpers/pump_app.dart';

const _booking20 = 'b0000000-0000-4000-8000-000000000020';
const _booking23 = 'b0000000-0000-4000-8000-000000000023';

void main() {
  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late ConnectivityCubit connectivityCubit;
  late FakeInAppBrowser browser;
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
    browser = FakeInAppBrowser();
  });

  tearDown(() async {
    await connectivityCubit.close();
    connectivity.dispose();
    backend.dispose();
  });

  Future<void> pumpRemaining(WidgetTester tester, String bookingId) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpOnAirApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<PaymentAttemptCubit>(
            create: (_) => PaymentAttemptCubit(
              flow: backend.server,
              store: backend.paymentAttempts,
              browser: () => browser,
              logger: AppLogger(sink: (_) {}),
            ),
          ),
          BlocProvider<RemainingPaymentCubit>(
            create: (context) {
              final cubit = RemainingPaymentCubit(
                bookings: backend.server,
                registry: BookingActionRegistry.g3(),
                connectivity: context.read<ConnectivityCubit>(),
                bookingId: bookingId,
              );
              unawaited(cubit.load());
              return cubit;
            },
          ),
        ],
        child: RemainingPaymentScreen(bookingId: bookingId),
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
      bookingBackend: backend,
      connectivityCubit: connectivityCubit,
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('ready shows property, server amounts, due date, and note', (
    tester,
  ) async {
    final details = await backend.server.getBooking(_booking20);
    await pumpRemaining(tester, _booking20);

    expect(find.text('شقة 3 غرف للتجربة'), findsOneWidget);
    for (final label in [
      l10n.bookingTotal,
      l10n.bookingPaid,
      l10n.bookingRemaining,
      l10n.remainingDueLabel,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text(MoneyFormatter().format(Money(450000))), findsOneWidget);
    expect(find.text(MoneyFormatter().format(Money(112500))), findsOneWidget);
    expect(find.text(MoneyFormatter().format(Money(337500))), findsAtLeast(1));
    expect(
      find.text(formatCairoDayMonthTime(details.remainingDueAt!)),
      findsOneWidget,
    );
    expect(find.text(l10n.remainingNote), findsOneWidget);
  });

  testWidgets('cash options default online and change the action', (
    tester,
  ) async {
    await pumpRemaining(tester, _booking20);

    expect(find.text(l10n.remainingOptionOnline), findsOneWidget);
    expect(find.text(l10n.remainingOptionCash), findsOneWidget);
    expect(
      find.text(
        l10n.remainingPayButton(MoneyFormatter().format(Money(337500))),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.remainingOptionCash));
    await tester.pump();
    expect(find.byKey(const ValueKey('remaining-cash')), findsOneWidget);
    expect(find.text(l10n.remainingCashButton), findsOneWidget);
  });

  testWidgets('without cash action there are no option cards', (tester) async {
    final all = await backend.server.bookings;
    all[_booking23]!['available_actions'] = [
      'pay_remaining',
      'request_cancellation',
      'contact_support',
    ];
    await pumpRemaining(tester, _booking23);

    expect(find.text(l10n.remainingOptionOnline), findsNothing);
    expect(find.text(l10n.remainingOptionCash), findsNothing);
    expect(find.byKey(const ValueKey('remaining-pay')), findsOneWidget);
  });

  testWidgets('rapid double pay starts one remaining payment', (tester) async {
    await pumpRemaining(tester, _booking20);

    final button = find.byKey(const ValueKey('remaining-pay'));
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump();

    expect(backend.server.remainingStarts, 1);
    expect(browser.opened, hasLength(1));
  });
}
