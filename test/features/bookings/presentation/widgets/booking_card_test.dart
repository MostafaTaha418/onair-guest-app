import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/presentation/widgets/booking_card.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// FR-038 / Constitution VI: the owner-deadline countdown is announced once
/// with a static absolute-deadline label — never on every tick.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    CairoTime.initialize();
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  BookingSummary awaitingOwner(DateTime deadline) => BookingSummary.fromJson({
    'id': 'b0000000-0000-4000-8000-000000000002',
    'code': 'OA-MOCK002',
    'property_id': '00000000-0000-4000-8000-000000000020',
    'title': 'شقة 3 غرف',
    'cover_image': null,
    'check_in': '2026-11-10',
    'check_out': '2026-11-12',
    'status': 'awaiting_owner',
    'refund_status': null,
    'owner_response_deadline': deadline.toIso8601String(),
    'created_at': '2026-10-20T02:00:00Z',
  });

  testWidgets('the card announces one static deadline, not every second', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final fixedNow = DateTime.utc(2026, 11, 1, 10);
    var now = fixedNow;
    final deadline = fixedNow.add(const Duration(minutes: 30));
    final expected = l10n.bookingMsgAwaitingOwner(
      formatCairoDayMonthTime(deadline),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OnAirTheme.light,
        home: Scaffold(
          body: ListView(
            children: [
              BookingCard(
                booking: awaitingOwner(deadline),
                onTap: () {},
                now: () => now,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    SemanticsNode cardNode() =>
        tester.getSemantics(find.bySemanticsLabel(RegExp(expected)));
    final announcement = cardNode().label;
    // The ticking remaining-time template never reaches semantics.
    final ticking = RegExp(l10n.ownerDeadlineCountdown('x').split('x').first);
    expect(find.bySemanticsLabel(ticking), findsNothing);

    // Under one hour the countdown ticks every second; the announcement
    // must not move with it.
    now = fixedNow.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    expect(cardNode().label, announcement);
    expect(find.bySemanticsLabel(ticking), findsNothing);
    handle.dispose();
  });

  testWidgets('a booking not awaiting the owner carries no deadline label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final booking = BookingSummary.fromJson(
      awaitingOwner(
        DateTime.utc(2026, 11, 2, 10),
      ).toJson()..['status'] = 'confirmed',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OnAirTheme.light,
        home: Scaffold(
          body: ListView(
            children: [BookingCard(booking: booking, onTap: () {})],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel(RegExp('حتى')), findsNothing);
    handle.dispose();
  });
}
