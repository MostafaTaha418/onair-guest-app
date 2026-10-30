import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/property/presentation/reviews_cubit.dart';

import '../../helpers/fake_listings_repository.dart';

ApprovedReview _review(int index) => ApprovedReview(
  id: 'r$index',
  rating: 5,
  comment: 'تعليق $index',
  createdOn: DateOnly(2026, 9, 14),
  reviewerShortName: 'أحمد م.',
);

void main() {
  late FakeListingsRepository listings;

  setUp(() {
    listings = FakeListingsRepository();
  });

  ReviewsCubit buildCubit() => ReviewsCubit(repo: listings, propertyId: 'p1');

  blocTest<ReviewsCubit, ReviewsState>(
    'the first page becomes ready',
    build: () {
      listings.reviewsResponses.add(
        ReviewsPage(items: [_review(1)], nextCursor: 'c2'),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<ReviewsReady>()],
  );

  blocTest<ReviewsCubit, ReviewsState>(
    'no items becomes the empty state',
    build: () {
      listings.reviewsResponses.add(
        const ReviewsPage(items: [], nextCursor: null),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<ReviewsEmpty>()],
  );

  blocTest<ReviewsCubit, ReviewsState>(
    'loadMore appends and stops at the last page',
    build: () {
      listings.reviewsResponses
        ..add(ReviewsPage(items: [_review(1)], nextCursor: 'c2'))
        ..add(ReviewsPage(items: [_review(2)], nextCursor: null));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
      await cubit.loadMore();
    },
    expect: () => [
      isA<ReviewsReady>(),
      isA<ReviewsReady>().having(
        (state) => state.loadingMore,
        'loadingMore',
        true,
      ),
      isA<ReviewsReady>(),
    ],
    verify: (cubit) {
      expect(cubit.state, isA<ReviewsReady>());
      final ready = cubit.state as ReviewsReady;
      expect(ready.items, hasLength(2));
      expect(ready.loadingMore, isFalse);
      expect(
        listings.calls.where((call) => call.startsWith('reviews(')),
        hasLength(2),
        reason: 'loadMore is ignored once nextCursor is null',
      );
    },
  );

  blocTest<ReviewsCubit, ReviewsState>(
    'errors become failed, and retry loads again',
    build: () {
      listings.reviewsResponses
        ..add(AppFailure(ErrorMapper.noResponse()))
        ..add(ReviewsPage(items: [_review(1)], nextCursor: null));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.retry();
    },
    expect: () => [
      isA<ReviewsFailed>(),
      isA<ReviewsLoading>(),
      isA<ReviewsReady>(),
    ],
  );

  blocTest<ReviewsCubit, ReviewsState>(
    'a failed loadMore keeps the list, and the retry clears the error',
    build: () {
      listings.reviewsResponses
        ..add(ReviewsPage(items: [_review(1)], nextCursor: 'c2'))
        ..add(AppFailure(ErrorMapper.noResponse()))
        ..add(ReviewsPage(items: [_review(2)], nextCursor: null));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
      await cubit.loadMore();
    },
    expect: () => [
      isA<ReviewsReady>(),
      isA<ReviewsReady>().having(
        (state) => state.loadingMore,
        'loadingMore',
        true,
      ),
      isA<ReviewsReady>()
          .having((state) => state.items, 'items', hasLength(1))
          .having((state) => state.loadMoreError, 'loadMoreError', isNotNull)
          .having((state) => state.loadingMore, 'loadingMore', false),
      isA<ReviewsReady>().having(
        (state) => state.loadingMore,
        'loadingMore',
        true,
      ),
      isA<ReviewsReady>()
          .having((state) => state.items, 'items', hasLength(2))
          .having((state) => state.loadMoreError, 'loadMoreError', isNull)
          .having((state) => state.nextCursor, 'nextCursor', isNull),
    ],
  );
}
