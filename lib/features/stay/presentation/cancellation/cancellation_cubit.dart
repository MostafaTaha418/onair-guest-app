import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/stay/data/action_attempt_store.dart';
import 'package:on_air/features/stay/domain/cancellation_preview.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/domain/stay_results.dart';

sealed class CancellationState {
  const CancellationState();
}

final class CancelLoading extends CancellationState {
  const CancelLoading();
}

final class CancelReady extends CancellationState {
  const CancelReady({
    required this.preview,
    required this.changes,
    this.previous,
    this.reason,
    this.note = '',
    this.error,
  });

  final CancellationPreview preview;
  final CancellationPreview? previous;
  final PreviewChange changes;
  final CancellationReason? reason;
  final String note;
  final ApiError? error;

  CancelReady copyWith({
    CancellationReason? reason,
    String? note,
    ApiError? error,
  }) => CancelReady(
    preview: preview,
    previous: previous,
    changes: changes,
    reason: reason ?? this.reason,
    note: note ?? this.note,
    error: error,
  );
}

final class CancelSubmitting extends CancellationState {
  const CancelSubmitting({required this.from});

  final CancelReady from;
}

final class CancelDone extends CancellationState {
  const CancelDone(this.result);

  final CancellationResult result;
}

final class CancelNotAllowed extends CancellationState {
  const CancelNotAllowed();
}

final class CancelOffline extends CancellationState {
  const CancelOffline();
}

final class CancelNotAvailable extends CancellationState {
  const CancelNotAvailable();
}

final class CancelFailed extends CancellationState {
  const CancelFailed(this.error);

  final ApiError error;
}

final class CancellationCubit extends Cubit<CancellationState> {
  CancellationCubit({
    required StayRepository stay,
    required ActionAttemptStore attempts,
    required ConnectivityCubit connectivity,
    required AppLogger logger,
    required String bookingId,
  }) : this._(stay, attempts, connectivity, logger, bookingId);

  CancellationCubit._(
    this._stay,
    this._attempts,
    this._connectivity,
    this._logger,
    this._bookingId,
  ) : super(const CancelLoading());

  final StayRepository _stay;
  final ActionAttemptStore _attempts;
  final ConnectivityCubit _connectivity;
  final AppLogger _logger;
  final String _bookingId;
  bool _busy = false;

  Future<void> load() async {
    emit(const CancelLoading());
    if (!_connectivity.state.isOnline) {
      emit(const CancelOffline());
      return;
    }
    try {
      final preview = await _stay.previewCancellation(_bookingId);
      _logger.info('cancellation_previewed booking=$_bookingId');
      if (isClosed) return;
      emit(
        CancelReady(preview: preview, changes: PreviewChange.none),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      switch (failure.error.code) {
        case ErrorCode.notFound:
          emit(const CancelNotAvailable());
        case ErrorCode.invalidBookingState || ErrorCode.actionNotAllowed:
          emit(const CancelNotAllowed());
        case _:
          emit(CancelFailed(failure.error));
      }
    }
  }

  void selectReason(CancellationReason? reason) {
    final ready = state;
    if (ready is! CancelReady) return;
    emit(ready.copyWith(reason: reason));
  }

  void setNote(String note) {
    final ready = state;
    if (ready is! CancelReady) return;
    const maxLength = CancellationReason.noteMaxLength;
    emit(
      ready.copyWith(
        note: note.substring(0, note.length.clamp(0, maxLength)),
      ),
    );
  }

  Future<void> submit() async {
    if (_busy) return;
    final ready = state;
    if (ready is! CancelReady) return;
    _busy = true;
    try {
      final key = await _attempts.keyFor('cancel', _bookingId);
      if (isClosed) return;
      emit(CancelSubmitting(from: ready));
      try {
        final result = await _stay.cancelBooking(
          bookingId: _bookingId,
          expectedRefund: ready.preview.refund,
          reason: ready.reason,
          reasonNote: ready.reason == CancellationReason.other
              ? ready.note.trim()
              : null,
          idempotencyKey: key,
        );
        await _attempts.clear('cancel', _bookingId);
        if (isClosed) return;
        _logger.info('cancellation_confirmed booking=$_bookingId');
        emit(CancelDone(result));
      } on AppFailure catch (failure) {
        if (isClosed) return;
        switch (failure.error.code) {
          case ErrorCode.cancellationTermsChanged:
            await _attempts.clear('cancel', _bookingId);
            final fresh = await _stay.previewCancellation(_bookingId);
            _logger.info('cancellation_terms_changed booking=$_bookingId');
            if (isClosed) return;
            emit(
              CancelReady(
                preview: fresh,
                previous: ready.preview,
                changes: PreviewChange.between(ready.preview, fresh),
                reason: ready.reason,
                note: ready.note,
                error: failure.error,
              ),
            );
          case ErrorCode.invalidBookingState || ErrorCode.actionNotAllowed:
            await _attempts.clear('cancel', _bookingId);
            if (isClosed) return;
            emit(const CancelNotAllowed());
          case ErrorCode.network:
            // The key stays: the retry reuses the same attempt.
            emit(ready.copyWith(error: failure.error));
          case _:
            await _attempts.clear('cancel', _bookingId);
            if (isClosed) return;
            emit(ready.copyWith(error: failure.error));
        }
      }
    } finally {
      _busy = false;
    }
  }
}
