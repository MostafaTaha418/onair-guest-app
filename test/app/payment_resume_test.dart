import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';
import 'package:on_air/features/booking/presentation/payment_return_screen.dart';

import '../helpers/fake_in_app_browser.dart';
import 'test_app_harness.dart';

/// US6: resuming the app must pull the guest to the verification screen
/// only while the attempt is still truly open — never again after the
/// verification screen was reached once.
void main() {
  const property1f = '00000000-0000-4000-8000-00000000001f';

  setUpAll(() async {
    await initializeDateFormatting('ar');
    CairoTime.initialize();
  });

  Future<AttemptOpened> payAndOpen(WidgetTester tester) async {
    final browser = FakeInAppBrowser();
    await pumpSignedInApp(tester, inAppBrowser: browser);
    final context = tester.element(find.byType(Navigator).first);
    final cubit = context.read<PaymentAttemptCubit>();
    final flow = context.read<BookingFlowRepository>();
    final quote = await flow.quote(
      propertyId: property1f,
      stay: StayRange(
        CairoTime.today().addDays(20),
        CairoTime.today().addDays(23),
      ),
      guests: 2,
      termsHash: 'mock-terms-1',
    );
    await cubit.pay(quote);
    return cubit.state as AttemptOpened;
  }

  void resumeApp(WidgetTester tester) {
    // The real platform sequence on the way back to the foreground.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  testWidgets('a resume with an open attempt opens the verification screen', (
    tester,
  ) async {
    await payAndOpen(tester);
    final context = tester.element(find.byType(Navigator).first);
    final pathBefore = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.path;
    expect(pathBefore, isNot(AppRoutes.paymentReturnPath));

    resumeApp(tester);
    await tester.pump();
    await tester.pump();

    expect(find.byType(PaymentReturnScreen), findsOneWidget);
    expect(
      GoRouter.of(context).routerDelegate.currentConfiguration.uri.path,
      AppRoutes.paymentReturnPath,
    );
  });

  testWidgets('a resume after the verification screen was seen stays put', (
    tester,
  ) async {
    final opened = await payAndOpen(tester);
    final context = tester.element(find.byType(Navigator).first);

    // The guest reaches the verification screen once; that marks the
    // attempt returned.
    GoRouter.of(
      context,
    ).go(AppRoutes.paymentReturn(bookingId: opened.attempt.bookingId));
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .element(find.byType(Navigator).first)
          .read<PaymentAttemptCubit>()
          .state,
      isA<AttemptReturned>(),
    );

    // Back on the bookings tab, the phone call ends, the app resumes.
    GoRouter.of(context).go(AppRoutes.bookings);
    await tester.pump();
    await tester.pump();
    resumeApp(tester);
    await tester.pump();
    await tester.pump();

    expect(find.byType(PaymentReturnScreen), findsNothing);
    expect(
      GoRouter.of(context).routerDelegate.currentConfiguration.uri.path,
      AppRoutes.bookings,
    );
  });
}
