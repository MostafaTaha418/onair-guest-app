import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/incoming_links.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/property/presentation/gallery_screen.dart';
import 'package:on_air/features/property/presentation/property_screen.dart';
import 'package:on_air/features/property/presentation/reviews_screen.dart';
import 'package:on_air/features/property/presentation/widgets/property_gallery_header.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/test_app_harness.dart';
import '../../helpers/fake_connectivity.dart';
import '../../helpers/fake_listings_repository.dart';

final class _FakeUriLinkSource implements UriLinkSource {
  final controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get uriLinks => controller.stream;
}

void main() {
  late FakeListingsRepository listings;
  late FakeConnectivity connectivity;

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    listings = FakeListingsRepository();
    connectivity = FakeConnectivity();
  });

  tearDown(() {
    connectivity.dispose();
  });

  final l10n = lookupAppLocalizations(const Locale('ar'));

  PropertyDetails details(int imageCount) => PropertyDetails(
    id: 'p1',
    title: 'شقة 3 غرف بإطلالة',
    description: 'وصف',
    propertyType: 'apartment',
    areaName: 'التجمع الخامس',
    cityName: 'القاهرة الجديدة',
    governorateName: 'القاهرة',
    addressText: null,
    images: [
      for (var index = 0; index < imageCount; index++)
        const ListingImage(variants: []),
    ],
    bedrooms: 3,
    bathrooms: 2,
    maxGuests: 6,
    areaSqm: null,
    amenities: const [],
    rules: const StayRules(
      checkInTime: '14:00',
      checkOutTime: '12:00',
      visitorsAllowed: false,
      maxVisitors: null,
      houseRules: null,
    ),
    policy: const PolicySummary(
      depositType: DepositType.full,
      depositPercentBp: null,
      depositAmount: null,
      freeCancellationHours: 24,
    ),
    nightlyPrice: Money(150000),
    ratingAvg: null,
    reviewCount: 0,
    latestReviews: const [],
    termsVersion: 't1',
  );

  ApprovedReview review(int index) => ApprovedReview(
    id: 'r$index',
    rating: 5,
    comment: 'تعليق $index',
    createdOn: DateOnly(2026, 9, 14),
    reviewerShortName: 'أحمد م.',
  );

  Future<void> pumpGallery(
    WidgetTester tester,
    int initialIndex, {
    List<ListingImage>? images,
  }) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ListingsRepository>.value(value: listings),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OnAirTheme.light,
          home: GalleryScreen(
            propertyId: 'p1',
            initialIndex: initialIndex,
            images: images,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  const propertyId = '550e8400-e29b-41d4-a716-446655440000';
  const linkDomain = 'on-air.website';

  /// The real router, driven the same way `discovery_links_test` drives it:
  /// the app builds `createAppRouter` itself, so a router change cannot
  /// leave these tests green against a stale hand-copied route shape.
  Future<void> pumpVisitorAndOpenLink(WidgetTester tester, Uri link) async {
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

  /// Opens an in-app route on the real router. The gallery path is a
  /// registered location but not a linkable one, so it is reached with
  /// `go` instead of a share link.
  Future<void> pumpVisitorAndGo(WidgetTester tester, String location) async {
    await pumpVisitorApp(tester, listingsRepository: listings);
    tester.element(find.byType(Scaffold).first).go(location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpReviews(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ListingsRepository>.value(value: listings),
        ],
        child: BlocProvider<ConnectivityCubit>.value(
          value: connectivity.createCubit(),
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            home: const ReviewsScreen(propertyId: 'p1'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the gallery opens at the given index', (tester) async {
    await pumpGallery(tester, 1, images: details(3).images);

    expect(find.text(l10n.galleryPhotoPosition(2, 3)), findsOneWidget);
  });

  testWidgets('the close button has a tooltip', (tester) async {
    await pumpGallery(tester, 0, images: details(3).images);

    final closeButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(IconButton),
      ),
    );
    expect(closeButton.tooltip, l10n.galleryClose);
  });

  testWidgets(
    'tapping a photo on the details screen opens the gallery through the '
    'real router',
    (tester) async {
      listings.propertyResponses.add(details(3));
      await pumpVisitorAndOpenLink(
        tester,
        Uri.parse('https://$linkDomain/property/$propertyId'),
      );

      expect(find.byType(PropertyScreen), findsOneWidget);
      expect(find.byType(PropertyGalleryHeader), findsOneWidget);

      await tester.tap(find.byType(PropertyGalleryHeader));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(GalleryScreen), findsOneWidget);
      expect(find.text(l10n.galleryPhotoPosition(1, 3)), findsOneWidget);
    },
  );

  testWidgets(
    'a direct gallery route loads the images from the repository',
    (tester) async {
      // The details page behind the gallery also builds on the route and
      // consumes one response; the gallery's fallback load consumes another.
      listings.propertyResponses
        ..add(details(3))
        ..add(details(3));
      await pumpVisitorAndGo(tester, '/property/$propertyId/gallery?index=1');

      expect(tester.takeException(), isNull);
      expect(find.byType(GalleryScreen), findsOneWidget);
      expect(find.text(l10n.galleryPhotoPosition(2, 3)), findsOneWidget);
    },
  );

  testWidgets(
    'a failed direct gallery route shows an error and retrying succeeds',
    (tester) async {
      listings.propertyResponses
        ..add(AppFailure(ErrorMapper.noResponse()))
        ..add(AppFailure(ErrorMapper.noResponse()));
      await pumpVisitorAndGo(tester, '/property/$propertyId/gallery?index=0');

      expect(find.byType(ErrorView), findsOneWidget);

      listings.propertyResponses.add(details(3));
      await tester.tap(find.text(l10n.retry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(l10n.galleryPhotoPosition(1, 3)), findsOneWidget);
    },
  );

  testWidgets('a property without photos shows the empty message', (
    tester,
  ) async {
    listings.propertyResponses
      ..add(details(0))
      ..add(details(0));
    await pumpVisitorAndGo(tester, '/property/$propertyId/gallery?index=0');

    expect(tester.takeException(), isNull);
    expect(find.text(l10n.galleryEmpty), findsOneWidget);
  });

  testWidgets('reviews paginate until the last page', (tester) async {
    listings.reviewsResponses
      ..add(ReviewsPage(items: [review(1), review(2)], nextCursor: 'c2'))
      ..add(ReviewsPage(items: [review(3)], nextCursor: null));
    await pumpReviews(tester);

    expect(find.text('تعليق 1'), findsOneWidget);
    expect(find.text('تعليق 2'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, -200), 800);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('تعليق 3'), findsOneWidget);
    expect(
      listings.calls.where((call) => call.startsWith('reviews(')),
      hasLength(2),
    );

    await tester.fling(find.byType(ListView), const Offset(0, -200), 800);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      listings.calls.where((call) => call.startsWith('reviews(')),
      hasLength(2),
      reason: 'loadMore is ignored once nextCursor is null',
    );
  });

  testWidgets('the empty reviews state works', (tester) async {
    listings.reviewsResponses.add(
      const ReviewsPage(items: [], nextCursor: null),
    );
    await pumpReviews(tester);

    expect(find.text(l10n.reviewsNone), findsOneWidget);
  });
}
