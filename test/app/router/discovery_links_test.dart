import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/incoming_links.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/features/app_update/presentation/not_available_screen.dart';
import 'package:on_air/features/booking/presentation/booking_entry_placeholder_screen.dart';
import 'package:on_air/features/property/presentation/property_screen.dart';
import 'package:on_air/features/search/presentation/results_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../helpers/fake_listings_repository.dart';
import '../test_app_harness.dart';

final class _FakeUriLinkSource implements UriLinkSource {
  final controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get uriLinks => controller.stream;
}

final AppLocalizations l10n = lookupAppLocalizations(const Locale('ar'));

void main() {
  const propertyId = '550e8400-e29b-41d4-a716-446655440000';
  const linkDomain = 'on-air.website';

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  // Dates are relative to the real Cairo clock, so the test never expires.
  final today = CairoTime.today();
  final checkIn = today.addDays(22);
  final checkOut = today.addDays(25);

  late FakeListingsRepository listings;

  Future<void> openLink(WidgetTester tester, Uri link) async {
    final source = _FakeUriLinkSource();
    addTearDown(source.controller.close);
    await pumpVisitorAppWithLinks(
      tester,
      uriLinkSource: source,
      linkDomain: linkDomain,
      listingsRepository: listings,
    );
    source.controller.add(link);
    await tester.pumpAndSettle();
  }

  setUp(() {
    listings = FakeListingsRepository();
  });

  testWidgets('a property link opens the details screen for that id', (
    tester,
  ) async {
    await openLink(
      tester,
      Uri.parse('https://$linkDomain/property/$propertyId'),
    );

    expect(find.byType(PropertyScreen), findsOneWidget);
    expect(find.text('EGP 1,000.00 / الليلة'), findsOneWidget);
  });

  testWidgets('a search link opens the results with the same criteria', (
    tester,
  ) async {
    await openLink(
      tester,
      Uri.parse(
        'https://$linkDomain/search/results?g=2'
        '&in=$checkIn&out=$checkOut&evil=1',
      ),
    );

    expect(find.byType(ResultsScreen), findsOneWidget);
    expect(find.textContaining('${l10n.searchGuestsLabel}: 2'), findsOneWidget);
    expect(
      find.textContaining(
        '${DateOnlyFormatter.dayMonth(checkIn)} – '
        '${DateOnlyFormatter.dayMonth(checkOut)}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a search link with past dates asks for new dates', (
    tester,
  ) async {
    await openLink(
      tester,
      Uri.parse(
        'https://$linkDomain/search/results'
        '?in=${today.addDays(-5)}&out=${today.addDays(-2)}',
      ),
    );

    expect(find.byType(ResultsScreen), findsOneWidget);
    expect(find.textContaining(l10n.searchDatesDropped), findsOneWidget);
  });

  testWidgets('a non-UUID property id lands on not-available', (tester) async {
    await openLink(
      tester,
      Uri.parse('https://$linkDomain/property/not-a-uuid'),
    );

    expect(find.byType(NotAvailableScreen), findsOneWidget);
  });

  testWidgets('a random uuid the repository does not know is not available', (
    tester,
  ) async {
    listings.propertyResponses.add(
      AppFailure(ErrorMapper.fromCode('NOT_FOUND')),
    );
    await openLink(
      tester,
      Uri.parse('https://$linkDomain/property/$propertyId'),
    );

    expect(find.byType(NotAvailableScreen), findsOneWidget);
  });

  testWidgets('a shared property link never carries the resume protocol', (
    tester,
  ) async {
    await openLink(
      tester,
      Uri.parse(
        'https://$linkDomain/property/$propertyId?resume=book&terms=t1',
      ),
    );

    // The parser strips every query key, so the details screen opens as a
    // clean visit instead of pushing the booking entry.
    expect(find.byType(PropertyScreen), findsOneWidget);
    expect(find.byType(BookingEntryPlaceholderScreen), findsNothing);
  });
}
