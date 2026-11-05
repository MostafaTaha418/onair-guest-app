import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';

sealed class RemainingPaymentState {
  const RemainingPaymentState();
}

final class RemainingLoading extends RemainingPaymentState {
  const RemainingLoading();
}

final class RemainingReady extends RemainingPaymentState {
  const RemainingReady({required this.details, required this.cashAllowed});

  final BookingDetails details;
  final bool cashAllowed;
}

final class RemainingGoVerify extends RemainingPaymentState {
  const RemainingGoVerify(this.bookingId);

  final String bookingId;
}

final class RemainingNotAllowed extends RemainingPaymentState {
  const RemainingNotAllowed();
}

final class RemainingNotAvailable extends RemainingPaymentState {
  const RemainingNotAvailable();
}

final class RemainingOffline extends RemainingPaymentState {
  const RemainingOffline();
}

final class RemainingFailed extends RemainingPaymentState {
  const RemainingFailed(this.error);

  final ApiError error;
}

final class RemainingPaymentCubit extends Cubit<RemainingPaymentState> {
  RemainingPaymentCubit({
    required BookingsRepository bookings,
    required BookingActionRegistry registry,
    required ConnectivityCubit connectivity,
    required String bookingId,
  }) : this._(
         bookings,
         registry,
         connectivity,
         bookingId,
       );

  RemainingPaymentCubit._(
    this._bookings,
    this._registry,
    this._connectivity,
    this._bookingId,
  ) : super(const RemainingLoading());

  final BookingsRepository _bookings;
  final BookingActionRegistry _registry;
  final ConnectivityCubit _connectivity;
  final String _bookingId;

  Future<void> load() async {
    emit(const RemainingLoading());
    if (!_connectivity.state.isOnline) {
      emit(const RemainingOffline());
      return;
    }
    try {
      final details = await _bookings.getBooking(_bookingId);
      if (details.pendingRemainingPaymentId != null) {
        emit(RemainingGoVerify(_bookingId));
        return;
      }
      final visible = _registry.visible(details.availableActions);
      if (!visible.contains(BookingActionCode.payRemaining)) {
        emit(const RemainingNotAllowed());
        return;
      }
      emit(
        RemainingReady(
          details: details,
          cashAllowed: visible.contains(
            BookingActionCode.confirmCashPayment,
          ),
        ),
      );
    } on AppFailure catch (failure) {
      if (failure.error.code == ErrorCode.notFound) {
        emit(const RemainingNotAvailable());
      } else {
        emit(RemainingFailed(failure.error));
      }
    }
  }
}
