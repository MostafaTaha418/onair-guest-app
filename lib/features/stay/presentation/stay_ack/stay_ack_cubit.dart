import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';

sealed class StayAckState {
  const StayAckState();
}

final class AckIdle extends StayAckState {
  const AckIdle();
}

final class AckSubmitting extends StayAckState {
  const AckSubmitting();
}

final class AckDone extends StayAckState {
  const AckDone(this.newStatus);

  final String newStatus;
}

final class AckFailed extends StayAckState {
  const AckFailed(this.error);

  final ApiError error;
}

/// Confirms receiving or leaving the apartment (US3). The status change
/// itself comes only from the refreshed server details.
final class StayAckCubit extends Cubit<StayAckState> {
  StayAckCubit({
    required StayRepository stay,
    required AppLogger logger,
    required String bookingId,
  }) : this._(stay, logger, bookingId);

  StayAckCubit._(this._stay, this._logger, this._bookingId)
    : super(const AckIdle());

  final StayRepository _stay;
  final AppLogger _logger;
  final String _bookingId;
  bool _busy = false;

  Future<void> confirmCheckIn() => _confirm(
    submit: () => _stay.confirmCheckIn(_bookingId),
    logLine: 'checkin_confirmed booking=$_bookingId',
  );

  Future<void> confirmCheckOut() => _confirm(
    submit: () => _stay.confirmCheckOut(_bookingId),
    logLine: 'checkout_confirmed booking=$_bookingId',
  );

  Future<void> _confirm({
    required Future<String> Function() submit,
    required String logLine,
  }) async {
    if (_busy) return;
    _busy = true;
    try {
      emit(const AckSubmitting());
      try {
        final newStatus = await submit();
        _logger.info(logLine);
        if (isClosed) return;
        emit(AckDone(newStatus));
      } on AppFailure catch (failure) {
        if (isClosed) return;
        emit(AckFailed(failure.error));
      }
    } finally {
      _busy = false;
    }
  }
}
