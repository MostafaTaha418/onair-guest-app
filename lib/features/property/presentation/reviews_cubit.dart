import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';

sealed class ReviewsState {
  const ReviewsState();
}

final class ReviewsLoading extends ReviewsState {
  const ReviewsLoading();
}

final class ReviewsReady extends ReviewsState {
  const ReviewsReady({
    required this.items,
    required this.nextCursor,
    this.loadingMore = false,
  });

  final List<ApprovedReview> items;

  /// Null means the end of the list (research R4).
  final String? nextCursor;
  final bool loadingMore;

  ReviewsReady copyWith({
    List<ApprovedReview>? items,
    String? nextCursor,
    bool? loadingMore,
  }) => ReviewsReady(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

final class ReviewsEmpty extends ReviewsState {
  const ReviewsEmpty();
}

final class ReviewsFailed extends ReviewsState {
  const ReviewsFailed(this.error);

  final ApiError error;
}

/// Approved reviews of one apartment, newest first (research R16).
final class ReviewsCubit extends Cubit<ReviewsState> {
  ReviewsCubit({
    required this._repo,
    required this._propertyId,
    this._limit = 20,
  }) : super(const ReviewsLoading());

  final ListingsRepository _repo;
  final String _propertyId;
  final int _limit;

  Future<void> load() async {
    if (state is! ReviewsLoading) emit(const ReviewsLoading());
    try {
      final page = await _repo.reviews(_propertyId, limit: _limit);
      if (isClosed) return;
      emit(
        page.items.isEmpty
            ? const ReviewsEmpty()
            : ReviewsReady(items: page.items, nextCursor: page.nextCursor),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(ReviewsFailed(failure.error));
    }
  }

  Future<void> loadMore() async {
    final ready = state;
    if (ready is! ReviewsReady ||
        ready.loadingMore ||
        ready.nextCursor == null) {
      return;
    }
    emit(ready.copyWith(loadingMore: true));
    try {
      final page = await _repo.reviews(
        _propertyId,
        cursor: ready.nextCursor,
        limit: _limit,
      );
      if (isClosed) return;
      emit(
        ReviewsReady(
          items: [...ready.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(ReviewsFailed(failure.error));
    }
  }

  Future<void> retry() => load();
}
