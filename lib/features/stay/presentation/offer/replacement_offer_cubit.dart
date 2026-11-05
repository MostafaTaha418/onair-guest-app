import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/stay/data/action_attempt_store.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';

sealed class ReplacementOfferState {
  const ReplacementOfferState();
}

final class OfferIdle extends ReplacementOfferState {
  const OfferIdle({this.error});

  final ApiError? error;
}

final class OfferSubmitting extends ReplacementOfferState {
  // The spec's state shape: a positional accept flag.
  // ignore: avoid_positional_boolean_parameters
  const OfferSubmitting(this.accept);

  final bool accept;
}

final class OfferAnswered extends ReplacementOfferState {
  const OfferAnswered({required this.accepted});

  final bool accepted;
}

final class OfferGone extends ReplacementOfferState {
  const OfferGone();
}

/// Answers an OnAir replacement offer (US6). Nothing changes without the
/// guest's confirmed answer.
final class ReplacementOfferCubit extends Cubit<ReplacementOfferState> {
  ReplacementOfferCubit({
    required StayRepository stay,
    required ActionAttemptStore attempts,
    required AppLogger logger,
    required String offerId,
  }) : this._(stay, attempts, logger, offerId);

  ReplacementOfferCubit._(
    this._stay,
    this._attempts,
    this._logger,
    this._offerId,
  ) : super(const OfferIdle());

  final StayRepository _stay;
  final ActionAttemptStore _attempts;
  final AppLogger _logger;
  final String _offerId;
  bool _busy = false;

  Future<void> accept() => _answer(true);

  Future<void> decline() => _answer(false);

  Future<void> _answer(bool accept) async {
    if (_busy) return;
    _busy = true;
    try {
      final key = await _attempts.keyFor('offer_answer', _offerId);
      if (isClosed) return;
      emit(OfferSubmitting(accept));
      try {
        await _stay.respondReplacementOffer(
          offerId: _offerId,
          accept: accept,
          idempotencyKey: key,
        );
        await _attempts.clear('offer_answer', _offerId);
        if (isClosed) return;
        _logger.info('offer_answered offer=$_offerId accept=$accept');
        emit(OfferAnswered(accepted: accept));
      } on AppFailure catch (failure) {
        if (isClosed) return;
        switch (failure.error.code) {
          case ErrorCode.offerNotAvailable:
            await _attempts.clear('offer_answer', _offerId);
            if (isClosed) return;
            emit(const OfferGone());
          case ErrorCode.network:
            // The key stays: the retry reuses the same attempt.
            emit(OfferIdle(error: failure.error));
          case _:
            await _attempts.clear('offer_answer', _offerId);
            if (isClosed) return;
            emit(OfferIdle(error: failure.error));
        }
      }
    } finally {
      _busy = false;
    }
  }
}
