import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/presentation/widgets/booking_card.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  BookingSummary booking(List<String> actions) => BookingSummary.fromJson({
    'id': 'b0000000-0000-4000-8000-000000000020',
    'code': 'OA-G3020',
    'property_id': '00000000-0000-4000-8000-00000000001f',
    'title': 'شقة 3 غرف',
    'cover_image': null,
    'check_in': '2026-11-25',
    'check_out': '2026-11-28',
    'status': 'confirmed',
    'refund_status': null,
    'owner_response_deadline': null,
    'available_actions': actions,
    'created_at': '2026-10-20T08:00:00Z',
  });

  Future<void> pump(
    WidgetTester tester,
    BookingActionRegistry registry,
    List<String> actions,
  ) => tester.pumpWidget(
    RepositoryProvider<BookingActionRegistry>.value(
      value: registry,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OnAirTheme.light,
        home: Scaffold(
          body: ListView(
            children: [BookingCard(booking: booking(actions), onTap: () {})],
          ),
        ),
      ),
    ),
  );

  testWidgets('G3 shows the first guest action after support', (tester) async {
    await pump(tester, BookingActionRegistry.g3(), [
      'contact_support',
      'pay_remaining',
    ]);
    expect(
      find.text(l10n.bookingNeedsAction(l10n.actionPayRemaining)),
      findsOneWidget,
    );
  });

  testWidgets('support alone never shows a needs-action line', (tester) async {
    await pump(tester, BookingActionRegistry.g3(), ['contact_support']);
    expect(find.textContaining(l10n.bookingNeedsAction('')), findsNothing);
  });

  testWidgets('G2 never exposes G3 actions', (tester) async {
    await pump(tester, BookingActionRegistry.g2(), ['pay_remaining']);
    expect(find.textContaining(l10n.bookingNeedsAction('')), findsNothing);
  });
}
