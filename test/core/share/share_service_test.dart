import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/share/share_service.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';

import '../../helpers/fake_share_service.dart';

void main() {
  const propertyId = '550e8400-e29b-41d4-a716-446655440000';
  const links = ShareLinks(linkDomain: 'onair.test');

  test('property link is the bare https URL for the id', () {
    expect(
      links.property(propertyId),
      'https://onair.test/property/$propertyId',
    );
  });

  test('search link encodes the canonical query and never the label', () {
    final criteria = SearchCriteria(
      locationId: propertyId,
      locationLabel: 'التجمع الخامس',
      stay: StayRange.tryCreate(
        DateOnly(2026, 11, 20),
        DateOnly(2026, 11, 23),
        DateOnly(2026, 11, 1),
      ),
      guests: 2,
    );

    final url = links.search(criteria.toQuery());
    expect(
      url,
      'https://onair.test/search/results?g=2&in=2026-11-20'
      '&loc=$propertyId&out=2026-11-23',
    );
    // The label is display-only and must never leak into a shared link.
    expect(url.contains('التجمع'), isFalse);
  });

  test('FakeShareService records the text passed to share', () async {
    final fake = FakeShareService();
    const text = 'شقة جميلة\nhttps://onair.test/property/$propertyId';

    await fake.share(text);

    expect(fake.shared, [text]);
  });
}
