import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/stay/presentation/cash/cash_receipt_cubit.dart';
import 'package:on_air/features/stay/presentation/cash/cash_receipt_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/pump_app.dart';

const _booking22 = 'b0000000-0000-4000-8000-000000000022';
const _payment22 = 'c0000000-0000-4000-8000-000000000222';

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

  Future<void> pumpReceipt(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpOnAirApp(
      BlocProvider<CashReceiptCubit>(
        create: (context) {
          final cubit = CashReceiptCubit(
            bookings: backend.server,
            cache: backend.cache,
            connectivity: context.read<ConnectivityCubit>(),
            bookingId: _booking22,
            paymentId: _payment22,
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: const CashReceiptScreen(
          bookingId: _booking22,
          paymentId: _payment22,
        ),
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

  testWidgets('the receipt shows amount, collector, date, and number', (
    tester,
  ) async {
    final details = await backend.server.getBooking(_booking22);
    final line = details.payments.firstWhere(
      (payment) => payment.id == _payment22,
    );

    await pumpReceipt(tester);

    expect(find.text(l10n.receiptTitle), findsOneWidget);
    expect(
      find.text(MoneyFormatter().format(Money(225000))),
      findsOneWidget,
    );
    expect(find.text('أحمد م.'), findsOneWidget);
    expect(
      find.text(formatCairoDayMonthTime(line.receipt!.confirmedAt)),
      findsOneWidget,
    );
    expect(find.text('R-2026-000123'), findsOneWidget);
  });

  testWidgets('the copy icon puts the receipt number on the clipboard', (
    tester,
  ) async {
    final clipboardData = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboardData.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await pumpReceipt(tester);

    await tester.tap(find.byTooltip(l10n.bookingCopyCode));
    await tester.pump();

    expect(clipboardData, hasLength(1));
    expect(
      (clipboardData.single.arguments as Map)['text'],
      'R-2026-000123',
    );
    expect(find.text(l10n.receiptCopied), findsOneWidget);
  });
}
