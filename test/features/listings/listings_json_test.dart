import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';
import 'package:on_air/features/listings/domain/location_suggestion.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';

/// Contract test: every fixture under `lib/features/listings/data/fixtures/`
/// parses with the same models the Supabase repository uses (research R18).

ListingCard _cardFrom(Map<dynamic, dynamic> json) =>
    ListingCard.fromJson(Map<String, dynamic>.from(json));

void main() {
  final fixturesDir = Directory('lib/features/listings/data/fixtures');

  late List<dynamic> propertiesJson;
  late Map<String, dynamic> referenceJson;
  late List<dynamic> locationsJson;
  late Map<String, dynamic> homeFeedJson;
  late Map<String, dynamic> reviewsJson;

  setUpAll(() {
    expect(
      fixturesDir.existsSync(),
      isTrue,
      reason: 'Run the fixture generator in tool/ first (task T026).',
    );
    propertiesJson =
        jsonDecode(
              File('${fixturesDir.path}/properties.json').readAsStringSync(),
            )
            as List<dynamic>;
    referenceJson =
        jsonDecode(
              File('${fixturesDir.path}/reference.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    locationsJson =
        jsonDecode(
              File('${fixturesDir.path}/locations.json').readAsStringSync(),
            )
            as List<dynamic>;
    homeFeedJson =
        jsonDecode(
              File('${fixturesDir.path}/home_feed.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    reviewsJson =
        jsonDecode(File('${fixturesDir.path}/reviews.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  group('PropertyDetails', () {
    test('every property fixture parses', () {
      expect(propertiesJson, isNotEmpty);
      for (final raw in propertiesJson) {
        final details = PropertyDetails.fromJson(
          Map<String, dynamic>.from(raw as Map<dynamic, dynamic>),
        );
        expect(details.id, isNotEmpty);
        expect(details.title, isNotEmpty);
        expect(details.termsVersion, isNotEmpty);
      }
    });

    test('addressText may be null and the row stays optional', () {
      final withoutAddress = propertiesJson
          .map(
            (raw) => PropertyDetails.fromJson(
              Map<String, dynamic>.from(raw as Map<dynamic, dynamic>),
            ),
          )
          .where((details) => details.addressText == null);
      expect(withoutAddress, isNotEmpty);
    });

    test('no latitude or longitude fields exist on the model', () {
      // D-001: coordinates never reach the guest app.
      expect(
        PropertyDetails.fromJson(
          Map<String, dynamic>.from(
            propertiesJson.first as Map<dynamic, dynamic>,
          ),
        ),
        isA<PropertyDetails>(),
      );
      final first = propertiesJson.first as Map<dynamic, dynamic>;
      expect(first.containsKey('latitude'), isFalse);
      expect(first.containsKey('longitude'), isFalse);
    });

    test('latestReviews holds at most 3 items', () {
      for (final raw in propertiesJson) {
        final details = PropertyDetails.fromJson(
          Map<String, dynamic>.from(raw as Map<dynamic, dynamic>),
        );
        expect(details.latestReviews.length, lessThanOrEqualTo(3));
      }
    });

    test('depositType parses percent, fixed, and full', () {
      final types = propertiesJson
          .map(
            (raw) => PropertyDetails.fromJson(
              Map<String, dynamic>.from(raw as Map<dynamic, dynamic>),
            ).policy.depositType,
          )
          .toSet();
      expect(types, containsAll(DepositType.values));
    });
  });

  group('ListingCard', () {
    late List<ListingCard> feedCards;

    setUp(() {
      feedCards = [
        for (final section in ['suggested', 'newest'])
          for (final raw
              in (homeFeedJson[section] as Map<dynamic, dynamic>)['items']
                  as List<dynamic>)
            ListingCard.fromJson(
              Map<String, dynamic>.from(raw as Map<dynamic, dynamic>),
            ),
      ];
    });

    test('nightlyPrice is a Money built from minor units', () {
      expect(feedCards, isNotEmpty);
      for (final card in feedCards) {
        expect(card.nightlyPrice, isA<Money>());
      }
    });

    test('stay is null when the response has no stay section', () {
      // The home feed never carries stay totals.
      for (final card in feedCards) {
        expect(card.stay, isNull);
      }
    });

    test('ratingAvg is null when review_count is 0', () {
      final withoutReviews = propertiesJson
          .map((raw) => raw as Map<dynamic, dynamic>)
          .where((json) => json['review_count'] == 0)
          .map(_cardFrom)
          .toList();
      expect(withoutReviews, isNotEmpty);
      for (final card in withoutReviews) {
        expect(card.ratingAvg, isNull);
        expect(card.reviewCount, 0);
      }
    });

    test('parses a card carrying a stay total', () {
      const withStay = <String, dynamic>{
        'id': '00000000-0000-4000-8000-000000000001',
        'title': 'شقة',
        'property_type': 'apartment',
        'area_name': 'التجمع الخامس',
        'city_name': 'القاهرة الجديدة',
        'nightly_price_minor': 150000,
        'currency': 'EGP',
        'review_count': 3,
        'rating_avg': 4.5,
        'stay': {'nights': 3, 'stay_total_minor': 450000},
      };
      final card = ListingCard.fromJson(withStay);
      expect(card.stay?.nights, 3);
      expect(card.stay?.stayTotal, Money(450000));
    });
  });

  group('ListingImage and variants', () {
    test('variants are sorted by width ascending', () {
      const image = <String, dynamic>{
        'variants': [
          {'width': 720, 'url': 'https://cdn.test/720.jpg'},
          {'width': 320, 'url': 'https://cdn.test/320.jpg'},
        ],
        'blurhash': null,
      };
      final parsed = ListingImage.fromJson(image);
      expect(parsed.variants.map((v) => v.width), [320, 720]);
      expect(parsed.variants.first.url, isA<Uri>());
    });

    test('ImageVariant.fromjson requires width and url', () {
      final variant = ImageVariant.fromJson(const {
        'width': 320,
        'url': 'https://cdn.test/320.jpg',
      });
      expect(variant.width, 320);
      expect(variant.url.host, 'cdn.test');
    });
  });

  group('ReferenceData', () {
    test('parses the guest_get_reference_data shape', () {
      final data = ReferenceData.fromJson(referenceJson);
      expect(data.version, isNotEmpty);
      expect(data.amenities, isNotEmpty);
      expect(data.propertyTypes, isNotEmpty);
      expect(data.priceMin.amountMinor, lessThan(data.priceMax.amountMinor));
      expect(data.priceStep, Money(5000));
    });

    test('priceStep falls back to 5000 piasters when missing', () {
      final withoutStep = Map<String, dynamic>.from(referenceJson)
        ..remove('price_step_minor');
      expect(ReferenceData.fromJson(withoutStep).priceStep, Money(5000));
    });

    test('toJson round-trips for the disk cache', () {
      final data = ReferenceData.fromJson(referenceJson);
      final restored = ReferenceData.fromJson(data.toJson());
      expect(restored, data);
    });
  });

  group('LocationSuggestion', () {
    test('parses levels and nullable parent labels', () {
      final suggestions = [
        for (final raw in locationsJson)
          LocationSuggestion.fromJson(
            Map<String, dynamic>.from(raw as Map<dynamic, dynamic>),
          ),
      ];
      expect(
        suggestions.map((s) => s.level).toSet(),
        containsAll(LocationLevel.values),
      );
    });
  });

  group('ApprovedReview', () {
    test('parses every approved review fixture', () {
      var count = 0;
      reviewsJson.forEach((_, rawReviews) {
        for (final raw in rawReviews as List<dynamic>) {
          final json = Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
          if (json['status'] != 'approved') continue;
          final review = ApprovedReview.fromJson(json);
          expect(review.rating, inInclusiveRange(1, 5));
          expect(review.reviewerShortName, isNotEmpty);
          count++;
        }
      });
      expect(count, greaterThan(0));
    });
  });

  group('HomeFeed', () {
    test('parses the wire shape with ready sections', () {
      final feed = HomeFeed.fromJson(homeFeedJson);
      expect(feed.referenceVersion, isNotEmpty);
      expect(feed.areas, isA<FeedSectionReady<List<AreaTile>>>());
      expect(feed.suggested, isA<FeedSectionReady<List<ListingCard>>>());
      expect(feed.newest, isA<FeedSectionReady<List<ListingCard>>>());
      expect((feed.upcomingBooking as FeedSectionReady).value, isNull);
    });

    test('parses a failed section as FeedSectionFailed', () {
      final withFailure = Map<String, dynamic>.from(homeFeedJson)
        ..['suggested'] = {'status': 'failed', 'error_code': 'INTERNAL'};
      final feed = HomeFeed.fromJson(withFailure);
      final suggested = feed.suggested;
      expect(suggested, isA<FeedSectionFailed<List<ListingCard>>>());
      expect(
        (suggested as FeedSectionFailed<List<ListingCard>>).errorCode,
        'INTERNAL',
      );
    });

    test('toPublicJson never contains upcoming_booking', () {
      const booking = <String, dynamic>{
        'booking_id': 'b-1',
        'property_title': 'شقة',
        'check_in': '2026-12-01',
        'check_out': '2026-12-05',
        'status': 'confirmed',
      };
      final feed = HomeFeed.fromJson(
        Map<String, dynamic>.from(homeFeedJson)
          ..['upcoming_booking'] = {'status': 'ready', 'item': booking},
      );
      final publicJson = feed.toPublicJson();
      expect(publicJson.containsKey('upcoming_booking'), isFalse);
      final encoded = jsonEncode(publicJson);
      expect(encoded.contains('b-1'), isFalse);
      expect(
        publicJson.keys.toSet(),
        {'reference_version', 'areas', 'suggested', 'newest', 'fetched_at'},
      );
    });

    test('fromPublicJson sets upcomingBooking to ready(null)', () {
      final feed = HomeFeed.fromJson(homeFeedJson);
      final restored = HomeFeed.fromPublicJson(feed.toPublicJson());
      expect(
        (restored.upcomingBooking as FeedSectionReady).value,
        isNull,
      );
      expect(restored.suggested, isA<FeedSectionReady<List<ListingCard>>>());
    });
  });
}
