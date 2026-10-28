import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/property/presentation/gallery_screen.dart';
import 'package:on_air/features/property/presentation/property_cubit.dart';
import 'package:on_air/features/property/presentation/reviews_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../helpers/fake_connectivity.dart';
import '../../helpers/fake_listings_repository.dart';

void main() {
  late FakeListingsRepository listings;
  late FakeConnectivity connectivity;

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  setUp(() {
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

  Future<PropertyCubit> readyCubit() async {
    listings.propertyResponses.add(details(3));
    final cubit = PropertyCubit(
      repo: listings,
      connectivity: connectivity.createCubit(),
      propertyId: 'p1',
    );
    await cubit.load();
    return cubit;
  }

  Future<void> pumpGallery(WidgetTester tester, int initialIndex) async {
    final cubit = await readyCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<PropertyCubit>.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OnAirTheme.light,
          home: GalleryScreen(propertyId: 'p1', initialIndex: initialIndex),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
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
    await pumpGallery(tester, 1);

    expect(find.text(l10n.galleryPhotoPosition(2, 3)), findsOneWidget);
  });

  testWidgets('the close button has a tooltip', (tester) async {
    await pumpGallery(tester, 0);

    final closeButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(IconButton),
      ),
    );
    expect(closeButton.tooltip, l10n.galleryClose);
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
