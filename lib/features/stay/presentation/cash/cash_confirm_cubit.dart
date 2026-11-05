import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/stay/data/action_attempt_store.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';

sealed class CashConfirmState {
  const CashConfirmState();
}

final class CashLoading extends CashConfirmState {
  const CashLoading();
}

final class CashPhoneEntry extends CashConfirmState {
  const CashPhoneEntry({
    required this.amount,
    this.phoneError = false,
    this.error,
  });

  final Money amount;
  final bool phoneError;
  final ApiError? error;
}

final class CashStarting extends CashConfirmState {
  const CashStarting({required this.amount});

  final Money amount;
}

final class CashNotAuthorized extends CashConfirmState {
  const CashNotAuthorized({required this.amount});

  final Money amount;
}

final class CashNotAllowed extends CashConfirmState {
  const CashNotAllowed();
}

final class CashCodeEntry extends CashConfirmState {
  const CashCodeEntry({
    required this.request,
    this.error,
    this.resendAvailableAt,
  });

  final CashRequest request;
  final ApiError? error;
  final DateTime? resendAvailableAt;
}

final class CashConfirming extends CashConfirmState {
  const CashConfirming({required this.request});

  final CashRequest request;
}

final class CashDone extends CashConfirmState {
  const CashDone({required this.paymentId});

  final String paymentId;
}

final class CashOffline extends CashConfirmState {
  const CashOffline();
}

final class CashNotAvailable extends CashConfirmState {
  const CashNotAvailable();
}

final class CashFailed extends CashConfirmState {
  const CashFailed(this.error);

  final ApiError error;
}

final class CashConfirmCubit extends Cubit<CashConfirmState> {
  CashConfirmCubit({
    required BookingsRepository bookings,
    required StayRepository stay,
    required ActionAttemptStore attempts,
    required BookingActionRegistry registry,
    required ConnectivityCubit connectivity,
    required AppLogger logger,
    required String bookingId,
    DateTime Function()? now,
  }) : this._(
         bookings,
         stay,
         attempts,
         registry,
         connectivity,
         logger,
         bookingId,
         now,
       );

  CashConfirmCubit._(
    this._bookings,
    this._stay,
    this._attempts,
    this._registry,
    this._connectivity,
    this._logger,
    this._bookingId,
    DateTime Function()? now,
  ) : _now = now ?? _defaultNow,
      super(const CashLoading());

  static DateTime _defaultNow() => DateTime.now().toUtc();

  final BookingsRepository _bookings;
  final StayRepository _stay;
  final ActionAttemptStore _attempts;
  final BookingActionRegistry _registry;
  final ConnectivityCubit _connectivity;
  final AppLogger _logger;
  final String _bookingId;
  final DateTime Function() _now;

  Money? _amount;
  bool _busy = false;

  Future<void> load() async {
    emit(const CashLoading());
    if (!_connectivity.state.isOnline) {
      emit(const CashOffline());
      return;
    }
    try {
      final details = await _bookings.getBooking(_bookingId);
      if (isClosed) return;
      final pendingCash = details.pendingCash;
      if (pendingCash != null) {
        final retryAfter = pendingCash.retryAfterSeconds;
        emit(
          CashCodeEntry(
            request: pendingCash,
            resendAvailableAt: retryAfter > 0
                ? _now().add(Duration(seconds: retryAfter))
                : null,
          ),
        );
        return;
      }
      final visible = _registry.visible(details.availableActions);
      if (!visible.contains(BookingActionCode.confirmCashPayment)) {
        emit(const CashNotAllowed());
        return;
      }
      _amount = details.remaining;
      emit(CashPhoneEntry(amount: details.remaining));
    } on AppFailure catch (failure) {
      if (isClosed) return;
      if (failure.error.code == ErrorCode.notFound) {
        emit(const CashNotAvailable());
      } else {
        emit(CashFailed(failure.error));
      }
    }
  }

  Future<void> submitPhone(String raw) async {
    if (_busy) return;
    final phone = EgyptPhone.tryParse(raw);
    if (phone == null) {
      final amount = _amount;
      if (amount != null) {
        emit(CashPhoneEntry(amount: amount, phoneError: true));
      }
      return;
    }
    _busy = true;
    try {
      final key = await _attempts.keyFor('cash_start', _bookingId);
      if (isClosed) return;
      final amount = _amount;
      if (amount == null) return;
      emit(CashStarting(amount: amount));
      CashRequest request;
      try {
        request = await _stay.startCashConfirmation(
          bookingId: _bookingId,
          collectorPhoneE164: phone.e164,
          expectedAmount: amount,
          idempotencyKey: key,
        );
      } on AppFailure catch (failure) {
        if (isClosed) return;
        switch (failure.error.code) {
          case ErrorCode.collectorNotAuthorized:
            await _attempts.clear('cash_start', _bookingId);
            if (isClosed) return;
            emit(CashNotAuthorized(amount: amount));
          case ErrorCode.cashNotAllowed:
            await _attempts.clear('cash_start', _bookingId);
            if (isClosed) return;
            emit(const CashNotAllowed());
          case ErrorCode.cashAmountChanged:
            await _attempts.clear('cash_start', _bookingId);
            if (isClosed) return;
            await load();
          case ErrorCode.network:
            // The key stays: the retry reuses the same attempt.
            emit(CashPhoneEntry(amount: amount, error: failure.error));
          case _:
            await _attempts.clear('cash_start', _bookingId);
            if (isClosed) return;
            emit(CashPhoneEntry(amount: amount, error: failure.error));
        }
        return;
      }
      await _attempts.clear('cash_start', _bookingId);
      if (isClosed) return;
      _logger.info(
        'cash_confirm_started booking=$_bookingId payment=${request.paymentId}',
      );
      try {
        await _stay.sendCashCode(request.challengeId);
      } on AppFailure catch (failure) {
        if (isClosed) return;
        if (failure.error.code == ErrorCode.rateLimited) {
          emit(
            CashCodeEntry(
              request: request,
              resendAvailableAt: _now().add(
                failure.error.retryAfter ?? const Duration(seconds: 30),
              ),
            ),
          );
          return;
        }
        emit(CashPhoneEntry(amount: amount, error: failure.error));
        return;
      }
      if (isClosed) return;
      emit(CashCodeEntry(request: request));
    } finally {
      _busy = false;
    }
  }

  Future<void> resend() async {
    if (_busy) return;
    final current = state;
    if (current is! CashCodeEntry) return;
    _busy = true;
    try {
      try {
        await _stay.sendCashCode(current.request.challengeId);
      } on AppFailure catch (failure) {
        if (isClosed) return;
        if (failure.error.code == ErrorCode.rateLimited) {
          emit(
            CashCodeEntry(
              request: current.request,
              error: current.error,
              resendAvailableAt: _now().add(
                failure.error.retryAfter ?? const Duration(seconds: 30),
              ),
            ),
          );
          return;
        }
        emit(
          CashCodeEntry(request: current.request, error: failure.error),
        );
        return;
      }
      if (isClosed) return;
      emit(CashCodeEntry(request: current.request));
    } finally {
      _busy = false;
    }
  }

  Future<void> confirm(String code) async {
    if (_busy) return;
    if (code.length != 6) return;
    final current = state;
    if (current is! CashCodeEntry) return;
    _busy = true;
    try {
      emit(CashConfirming(request: current.request));
      try {
        await _stay.confirmCashPayment(
          paymentId: current.request.paymentId,
          challengeId: current.request.challengeId,
          code: code,
        );
      } on AppFailure catch (failure) {
        if (isClosed) return;
        emit(CashCodeEntry(request: current.request, error: failure.error));
        return;
      }
      if (isClosed) return;
      _logger.info(
        'cash_confirmed booking=$_bookingId payment=${current.request.paymentId}',
      );
      emit(CashDone(paymentId: current.request.paymentId));
    } finally {
      _busy = false;
    }
  }
}
