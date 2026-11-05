import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/stay/data/action_attempt_store.dart';
import 'package:on_air/features/stay/domain/damage_claim.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';

sealed class ClaimState {
  const ClaimState();
}

final class ClaimLoading extends ClaimState {
  const ClaimLoading();
}

final class ClaimReady extends ClaimState {
  const ClaimReady({
    required this.claim,
    required this.canRespond,
    this.disputeOpen = false,
    this.noteError = false,
    this.error,
  });

  final DamageClaim claim;
  final bool canRespond;
  final bool disputeOpen;
  final bool noteError;
  final ApiError? error;

  ClaimReady copyWith({
    bool? disputeOpen,
    bool? noteError,
    ApiError? error,
  }) => ClaimReady(
    claim: claim,
    canRespond: canRespond,
    disputeOpen: disputeOpen ?? this.disputeOpen,
    noteError: noteError ?? this.noteError,
    error: error,
  );
}

final class ClaimSubmitting extends ClaimState {
  const ClaimSubmitting({required this.from});

  final ClaimReady from;
}

final class ClaimNotAvailable extends ClaimState {
  const ClaimNotAvailable();
}

final class ClaimOffline extends ClaimState {
  const ClaimOffline();
}

final class ClaimFailed extends ClaimState {
  const ClaimFailed(this.error);

  final ApiError error;
}

final class DamageClaimCubit extends Cubit<ClaimState> {
  DamageClaimCubit({
    required StayRepository stay,
    required BookingsRepository bookings,
    required ActionAttemptStore attempts,
    required BookingActionRegistry registry,
    required ConnectivityCubit connectivity,
    required AppLogger logger,
    required String bookingId,
    required String claimId,
  }) : this._(
         stay,
         bookings,
         attempts,
         registry,
         connectivity,
         logger,
         bookingId,
         claimId,
       );

  DamageClaimCubit._(
    this._stay,
    this._bookings,
    this._attempts,
    this._registry,
    this._connectivity,
    this._logger,
    this._bookingId,
    this._claimId,
  ) : super(const ClaimLoading());

  final StayRepository _stay;
  final BookingsRepository _bookings;
  final ActionAttemptStore _attempts;
  final BookingActionRegistry _registry;
  final ConnectivityCubit _connectivity;
  final AppLogger _logger;
  final String _bookingId;
  final String _claimId;
  bool _busy = false;

  Future<void> load() async {
    emit(const ClaimLoading());
    if (!_connectivity.state.isOnline) {
      emit(const ClaimOffline());
      return;
    }
    try {
      final claim = await _stay.getDamageClaim(_claimId);
      if (claim.bookingId != _bookingId) {
        emit(const ClaimNotAvailable());
        return;
      }
      final details = await _bookings.getBooking(_bookingId);
      if (isClosed) return;
      final canRespond =
          claim.status == DamageClaimStatus.open &&
          _registry
              .visible(details.availableActions)
              .contains(
                BookingActionCode.respondDamageClaim,
              );
      emit(ClaimReady(claim: claim, canRespond: canRespond));
    } on AppFailure catch (failure) {
      if (isClosed) return;
      if (failure.error.code == ErrorCode.notFound) {
        emit(const ClaimNotAvailable());
      } else {
        emit(ClaimFailed(failure.error));
      }
    }
  }

  void openDispute() {
    final ready = state;
    if (ready is! ClaimReady) return;
    emit(ready.copyWith(disputeOpen: true));
  }

  Future<void> agree() => _respond(ClaimDecision.accept, null);

  Future<void> dispute(String note) async {
    final ready = state;
    if (ready is! ClaimReady) return;
    if (!ClaimLimits.validDisputeNote(note)) {
      emit(ready.copyWith(noteError: true));
      return;
    }
    await _respond(ClaimDecision.dispute, note);
  }

  Future<void> _respond(ClaimDecision decision, String? note) async {
    if (_busy) return;
    final ready = state;
    if (ready is! ClaimReady) return;
    _busy = true;
    try {
      final key = await _attempts.keyFor('claim_answer', _claimId);
      if (isClosed) return;
      emit(ClaimSubmitting(from: ready));
      try {
        await _stay.respondDamageClaim(
          claimId: _claimId,
          decision: decision,
          note: decision == ClaimDecision.dispute ? note?.trim() : null,
          idempotencyKey: key,
        );
        await _attempts.clear('claim_answer', _claimId);
        if (isClosed) return;
        _logger.info(
          'claim_answered claim=$_claimId decision=${decision.wire}',
        );
        await load();
      } on AppFailure catch (failure) {
        if (isClosed) return;
        switch (failure.error.code) {
          case ErrorCode.claimAlreadyAnswered:
            await _attempts.clear('claim_answer', _claimId);
            if (isClosed) return;
            await load();
          case ErrorCode.network:
            // The key stays: the retry reuses the same attempt.
            emit(ready.copyWith(error: failure.error));
          case _:
            await _attempts.clear('claim_answer', _claimId);
            if (isClosed) return;
            emit(ready.copyWith(error: failure.error));
        }
      }
    } finally {
      _busy = false;
    }
  }
}
