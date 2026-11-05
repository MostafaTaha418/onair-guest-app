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
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/stay/presentation/cash/cash_confirm_cubit.dart';
import 'package:on_air/features/stay/presentation/cash/cash_confirm_screen.dart';
import 'package:on_air/features/stay/presentation/cash/cash_receipt_cubit.dart';
import 'package:on_air/features/stay/presentation/cash/cash_receipt_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/pump_app.dart';

const _booking20 = 'b0000000-0000-4000-8000-000000000020';
const _booking28 = 'b0000000-0000-4000-8000-000000000028';

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

  Future<void> pumpCash(WidgetTester tester, String bookingId) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.cashConfirm(bookingId),
      routes: [
        GoRoute(
          path: AppRoutes.cashConfirmPattern,
          name: 'cash-confirm',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return BlocProvider<CashConfirmCubit>(
              create: (context) {
                final cubit = CashConfirmCubit(
                  bookings: backend.server,
                  stay: backend.stay,
                  attempts: backend.actionAttempts,
                  registry: BookingActionRegistry.g3(),
                  connectivity: context.read<ConnectivityCubit>(),
                  logger: AppLogger(sink: (_) {}),
                  bookingId: id,
                );
                unawaited(cubit.load());
                return cubit;
              },
              child: CashConfirmScreen(bookingId: id),
            );
          },
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
      connectivityCubit: connectivityCubit,
    );
    for (var i = 0; i < 40 && !tester.any(find.byType(TextField)); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();
  }

  Future<void> reachCodeStep(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), '01000000001');
    await tester.tap(find.byKey(const ValueKey('cash-send')));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('phone step shows a locked amount and one phone field', (
    tester,
  ) async {
    await pumpCash(tester, _booking20);

    final locked = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == l10n.cashAmountLocked,
      ),
    );
    expect(locked.properties.label, l10n.cashAmountLocked);
    expect(find.byType(TextField), findsExactly(1));
    expect(find.text(l10n.cashAmountLabel), findsOneWidget);
  });

  testWidgets('an invalid phone shows the field error', (tester) async {
    await pumpCash(tester, _booking20);

    await tester.enterText(find.byType(TextField), '0100');
    await tester.tap(find.byKey(const ValueKey('cash-send')));
    await tester.pump();

    expect(find.text(l10n.cashPhoneInvalid), findsOneWidget);
    expect(backend.stay.codesSent, 0);
  });

  testWidgets('an unauthorized collector shows the warning and support', (
    tester,
  ) async {
    await pumpCash(tester, _booking20);

    await tester.enterText(find.byType(TextField), '01099999999');
    await tester.tap(find.byKey(const ValueKey('cash-send')));
    await tester.pump();

    expect(find.text(l10n.stayCollectorNotAuthorized), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.text(l10n.cashContactSupport), findsOneWidget);
  });

  testWidgets('a valid phone reaches the code step', (tester) async {
    await pumpCash(tester, _booking20);

    await reachCodeStep(tester);

    expect(
      find.text(l10n.cashCodeSent('g***@mock.onair.test')),
      findsOneWidget,
    );
    expect(find.byType(OnAirOtpField), findsOneWidget);
  });

  testWidgets('the confirm button needs six digits and the statement', (
    tester,
  ) async {
    await pumpCash(tester, _booking20);
    await reachCodeStep(tester);

    VoidCallback? onPressed() => tester
        .widget<OnAirPrimaryButton>(
          find.byKey(const ValueKey('cash-confirm')),
        )
        .onPressed;

    expect(onPressed(), isNull, reason: 'no code and no statement yet');

    final otpField = find.descendant(
      of: find.byType(OnAirOtpField),
      matching: find.byType(TextField),
    );
    await tester.enterText(otpField, '123456');
    await tester.pump();
    expect(onPressed(), isNull, reason: 'the statement is still unchecked');

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(onPressed(), isNotNull);
  });

  testWidgets('a double tap on confirm makes one confirm call', (tester) async {
    await pumpCash(tester, _booking20);
    await reachCodeStep(tester);

    final otpField = find.descendant(
      of: find.byType(OnAirOtpField),
      matching: find.byType(TextField),
    );
    await tester.enterText(otpField, '123456');
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    final button = find.byKey(const ValueKey('cash-confirm'));
    await tester.tap(button, warnIfMissed: false);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    await tester.pump();

    expect(backend.stay.cashConfirms, 1);
  });

  testWidgets('a pending resend shows the countdown', (tester) async {
    final all = await backend.server.bookings;
    final pending = Map<String, dynamic>.from(
      all[_booking28]!['pending_cash'] as Map,
    );
    pending['retry_after_seconds'] = 30;
    all[_booking28]!['pending_cash'] = pending;

    await pumpCash(tester, _booking28);

    final resendPrefix = l10n.cashResendIn('x').split('x').first;
    // The Countdown delivers its first value synchronously inside
    // listen(), which the StreamBuilder drops (its subscription is still
    // null); the first 1 s tick carries the visible value.
    await tester.pump(const Duration(seconds: 1, milliseconds: 100));
    expect(find.textContaining(resendPrefix), findsOneWidget);
  });

  testWidgets('the emailed code is never copied to the clipboard', (
    tester,
  ) async {
    final clipboardCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        clipboardCalls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await pumpCash(tester, _booking20);
    await reachCodeStep(tester);

    final otpField = find.descendant(
      of: find.byType(OnAirOtpField),
      matching: find.byType(TextField),
    );
    await tester.enterText(otpField, '123456');
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('cash-confirm')));
    await tester.pump();
    await tester.pump();

    final copies = clipboardCalls
        .where((call) => call.method == 'Clipboard.setData')
        .toList();
    expect(copies, isEmpty);
    expect(
      clipboardCalls.any(
        (call) => call.arguments.toString().contains('123456'),
      ),
      isFalse,
      reason: 'the code itself never leaves the field',
    );
    // Sanity: the screen really went to the confirming flow.
    expect(backend.stay.cashConfirms, 1);
  });
}
