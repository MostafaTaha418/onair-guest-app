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
    this.loadMoreError,
  });

  final List<ApprovedReview> items;

  /// Null means the end of the list (research R4).
  final String? nextCursor;
  final bool loadingMore;

  /// The failure of the last extra page; the loaded items stay on screen
  /// and the list tail offers a retry.
  final ApiError? loadMoreError;

  /// Sentinel so an explicit null replaces the old value instead of keeping
  /// it (clearing a consumed cursor or error).
  static const _unset = Object();

  ReviewsReady copyWith({
    List<ApprovedReview>? items,
    Object? nextCursor = _unset,
    bool? loadingMore,
    Object? loadMoreError = _unset,
  }) => ReviewsReady(
    items: items ?? this.items,
    nextCursor: nextCursor == _unset ? this.nextCursor : nextCursor as String?,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: loadMoreError == _unset
        ? this.loadMoreError
        : loadMoreError as ApiError?,
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
    emit(ready.copyWith(loadingMore: true, loadMoreError: null));
    try {
      final page = await _repo.reviews(
        _propertyId,
        cursor: ready.nextCursor,
        limit: _limit,
      );
      if (isClosed) return;
      final current = state;
      if (current is! ReviewsReady) return;
      emit(
        current.copyWith(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          loadingMore: false,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      final current = state;
      if (current is! ReviewsReady) return;
      // The loaded pages stay; only the tail switches to the error row.
      emit(current.copyWith(loadingMore: false, loadMoreError: failure.error));
    }
  }

  Future<void> retry() => load();
}
