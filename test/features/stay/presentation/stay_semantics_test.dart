import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/features/stay/presentation/cancellation/cancellation_cubit.dart';
import 'package:on_air/features/stay/presentation/cancellation/cancellation_screen.dart';
import 'package:on_air/features/stay/presentation/cash/cash_confirm_cubit.dart';
import 'package:on_air/features/stay/presentation/cash/cash_confirm_screen.dart';
import 'package:on_air/features/stay/presentation/cash/cash_receipt_cubit.dart';
import 'package:on_air/features/stay/presentation/cash/cash_receipt_screen.dart';
import 'package:on_air/features/stay/presentation/claims/damage_claim_cubit.dart';
import 'package:on_air/features/stay/presentation/claims/damage_claim_screen.dart';
import 'package:on_air/features/stay/presentation/offer/offer_card.dart';
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
const _booking21 = 'b0000000-0000-4000-8000-000000000021';
const _booking22 = 'b0000000-0000-4000-8000-000000000022';
const _booking25 = 'b0000000-0000-4000-8000-000000000025';
const _claim1 = 'e0000000-0000-4000-8000-000000000001';
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

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpOnAirApp(
      child,
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
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The sweep itself: every icon button labelled, every tappable at
  /// least 48 dp tall, and the tap guidelines met.
  Future<void> expectAccessible(WidgetTester tester) async {
    for (final button in tester.widgetList<IconButton>(
      find.byType(IconButton),
    )) {
      expect(button.tooltip, isNotNull);
      expect(button.tooltip, isNotEmpty);
    }
    for (final button in [
      ...tester.widgetList<OutlinedButton>(find.byType(OutlinedButton)),
      ...tester.widgetList<TextButton>(find.byType(TextButton)),
    ]) {
      final size = tester.getSize(find.byWidget(button));
      expect(size.height, greaterThanOrEqualTo(48), reason: '$button');
      expect(size.width, greaterThanOrEqualTo(48), reason: '$button');
    }
    await expectLater(
      tester,
      meetsGuideline(androidTapTargetGuideline),
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  }

  testWidgets('remaining payment screen', (tester) async {
    final handle = tester.ensureSemantics();
    final browser = FakeInAppBrowser();
    await pumpScreen(
      tester,
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
                bookingId: _booking20,
              );
              unawaited(cubit.load());
              return cubit;
            },
          ),
        ],
        child: const RemainingPaymentScreen(bookingId: _booking20),
      ),
    );
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('cash phone step', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      BlocProvider<CashConfirmCubit>(
        create: (context) {
          final cubit = CashConfirmCubit(
            bookings: backend.server,
            stay: backend.stay,
            attempts: backend.actionAttempts,
            registry: BookingActionRegistry.g3(),
            connectivity: context.read<ConnectivityCubit>(),
            logger: AppLogger(sink: (_) {}),
            bookingId: _booking20,
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: const CashConfirmScreen(bookingId: _booking20),
      ),
    );
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('cash code step', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      BlocProvider<CashConfirmCubit>(
        create: (context) {
          final cubit = CashConfirmCubit(
            bookings: backend.server,
            stay: backend.stay,
            attempts: backend.actionAttempts,
            registry: BookingActionRegistry.g3(),
            connectivity: context.read<ConnectivityCubit>(),
            logger: AppLogger(sink: (_) {}),
            bookingId: _booking28,
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: const CashConfirmScreen(bookingId: _booking28),
      ),
    );
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('cash receipt', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
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
    );
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('cancellation', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      BlocProvider<CancellationCubit>(
        create: (context) {
          final cubit = CancellationCubit(
            stay: backend.stay,
            attempts: backend.actionAttempts,
            connectivity: context.read<ConnectivityCubit>(),
            logger: AppLogger(sink: (_) {}),
            bookingId: _booking23,
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: const CancellationScreen(bookingId: _booking23),
      ),
    );
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('damage claim', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      BlocProvider<DamageClaimCubit>(
        create: (context) {
          final cubit = DamageClaimCubit(
            stay: backend.stay,
            bookings: backend.server,
            attempts: backend.actionAttempts,
            registry: BookingActionRegistry.g3(),
            connectivity: context.read<ConnectivityCubit>(),
            logger: AppLogger(sink: (_) {}),
            bookingId: _booking25,
            claimId: _claim1,
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: const DamageClaimScreen(bookingId: _booking25, claimId: _claim1),
      ),
    );
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('offer card', (tester) async {
    final handle = tester.ensureSemantics();
    final details = await backend.server.getBooking(_booking26);
    final offer = details.replacementOffer!;
    await pumpScreen(tester, OfferCard(offer: offer, onAnswered: () {}));
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('check-in sheet over the details', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      BlocProvider<BookingDetailsCubit>(
        create: (context) {
          final cubit = BookingDetailsCubit(
            bookings: backend.server,
            cache: backend.cache,
            arrival: backend.arrivalInstructions,
            signals: backend.signals,
            connectivity: context.read<ConnectivityCubit>(),
            bookingId: _booking21,
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: const BookingDetailsScreen(bookingId: _booking21),
      ),
    );
    // Open the sheet: the primary check-in action.
    await tester.tap(find.byKey(const ValueKey('primary-confirm_checkin')));
    await tester.pumpAndSettle();

    // The sheet title is a semantics header.
    final titleNode = tester.getSemantics(
      find.text(l10n.checkinSheetTitle),
    );
    expect(
      titleNode.flagsCollection.isHeader,
      isTrue,
    );

    await expectAccessible(tester);
    handle.dispose();
  });
}

const _booking28 = 'b0000000-0000-4000-8000-000000000028';
const _booking26 = 'b0000000-0000-4000-8000-000000000026';
const _booking23 = 'b0000000-0000-4000-8000-000000000023';
