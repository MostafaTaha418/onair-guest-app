import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/features/booking/domain/verification_outcome.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';

sealed class VerifyState {
  const VerifyState();
}

/// Test-only override for the polling backoff: a harness provides this
/// repository so the «server never answers» journey reaches the timeout in
/// seconds instead of minutes. Production never binds it.
final class PaymentVerificationBackoff {
  const PaymentVerificationBackoff(this.intervals);

  final List<Duration> intervals;
}

final class VerifyWaiting extends VerifyState {
  const VerifyWaiting();
}

final class VerifyResolved extends VerifyState {
  const VerifyResolved(this.outcome, this.details);

  final VerificationOutcome outcome;
  final BookingDetails details;
}

final class VerifyTimeout extends VerifyState {
  const VerifyTimeout(this.bookingId);

  final String bookingId;
}

final class VerifyNotAvailable extends VerifyState {
  const VerifyNotAvailable();
}

/// Waits for the server to decide after the payment page (research R6): the
/// notification stream triggers an immediate refetch, polling with backoff
/// is only the fallback. Returning from Kashier is never a confirmation.
final class PaymentVerificationCubit extends Cubit<VerifyState> {
  PaymentVerificationCubit({
    required this._bookings,
    required this._signals,
    required this._bookingId,
    required this._logger,
    List<Duration>? backoff,
  }) : _backoff =
           backoff ??
           const [
             Duration(seconds: 2),
             Duration(seconds: 4),
             Duration(seconds: 8),
             Duration(seconds: 16),
             Duration(seconds: 30),
             Duration(seconds: 30),
             Duration(seconds: 30),
           ],
       super(const VerifyWaiting());

  final BookingsRepository _bookings;
  final NotificationSignalSource _signals;
  final String _bookingId;
  final AppLogger _logger;
  final List<Duration> _backoff;

  StreamSubscription<NotificationSignal>? _signalSubscription;
  Timer? _pollTimer;
  var _backoffIndex = 0;
  var _fetching = false;
  var _finished = false;

  /// A signal arrived while a fetch was running: one more fetch runs right
  /// after it, without touching the poll timer (FR-013 / SC-005).
  var _refetchRequested = false;

  /// A poll fired while a fetch was running: the deferred fetch must still
  /// count as a poll, or the schedule (and the timeout) would stop.
  var _refetchFromPoll = false;

  void start() {
    _logger.info('payment_return_received booking=$_bookingId');
    _signalSubscription = _signals.signals
        .where((signal) => signal.entityId == _bookingId)
        .listen((_) => unawaited(_fetch(fromPoll: false)));
    // The first fetch counts as poll-triggered: it opens the backoff
    // schedule.
    unawaited(_fetch(fromPoll: true));
  }

  Future<void> _fetch({required bool fromPoll}) async {
    if (_finished || isClosed) return;
    if (_fetching) {
      _refetchRequested = true;
      _refetchFromPoll = _refetchFromPoll || fromPoll;
      return;
    }
    _fetching = true;
    try {
      final details = await _bookings.getBooking(_bookingId);
      if (isClosed) return;
      final outcome = verificationOutcomeFor(details);
      if (outcome == VerificationOutcome.waiting) {
        // Only poll-triggered fetches advance the schedule: a signal just
        // got a fresher answer — the pending poll timer stays as it is, so
        // the total waiting time remains the backoff sum.
        if (fromPoll) _scheduleNextPoll();
        return;
      }
      _finished = true;
      _pollTimer?.cancel();
      // Cleanup runs out of band: awaiting it here delayed the outcome past
      // the frame that should render it.
      unawaited(_signalSubscription?.cancel());
      _logger.info(
        'payment_verified booking=$_bookingId outcome=${outcome.name}',
      );
      emit(VerifyResolved(outcome, details));
    } on AppFailure catch (failure) {
      if (isClosed) return;
      if (failure.error.code == ErrorCode.notFound) {
        _finished = true;
        _pollTimer?.cancel();
        unawaited(_signalSubscription?.cancel());
        emit(const VerifyNotAvailable());
        return;
      }
      // Network and other errors keep waiting.
      if (fromPoll) _scheduleNextPoll();
    } finally {
      _fetching = false;
      if (_refetchRequested && !_finished && !isClosed) {
        final asPoll = _refetchFromPoll;
        _refetchRequested = false;
        _refetchFromPoll = false;
        unawaited(_fetch(fromPoll: asPoll));
      }
    }
  }

  void _scheduleNextPoll() {
    if (_finished || isClosed) return;
    if (_backoffIndex >= _backoff.length) {
      _finished = true;
      _pollTimer?.cancel();
      _logger.warning('payment_verification_timeout booking=$_bookingId');
      emit(VerifyTimeout(_bookingId));
      return;
    }
    _pollTimer?.cancel();
    _pollTimer = Timer(_backoff[_backoffIndex], () {
      _backoffIndex++;
      unawaited(_fetch(fromPoll: true));
    });
  }

  @override
  Future<void> close() async {
    _finished = true;
    _pollTimer?.cancel();
    await _signalSubscription?.cancel();
    await super.close();
  }
}
