import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_parts.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';

sealed class CashReceiptState {
  const CashReceiptState();
}

final class ReceiptLoading extends CashReceiptState {
  const ReceiptLoading();
}

final class ReceiptReady extends CashReceiptState {
  const ReceiptReady({required this.line});

  final PaymentLine line;
}

final class ReceiptMissing extends CashReceiptState {
  const ReceiptMissing();
}

/// The cash receipt can be reopened from the booking details, including
/// offline from the local cache (data-model §3).
final class CashReceiptCubit extends Cubit<CashReceiptState> {
  CashReceiptCubit({
    required BookingsRepository bookings,
    required BookingsCache cache,
    required ConnectivityCubit connectivity,
    required String bookingId,
    required String paymentId,
  }) : this._(bookings, cache, connectivity, bookingId, paymentId);

  CashReceiptCubit._(
    this._bookings,
    this._cache,
    this._connectivity,
    this._bookingId,
    this._paymentId,
  ) : super(const ReceiptLoading());

  final BookingsRepository _bookings;
  final BookingsCache _cache;
  final ConnectivityCubit _connectivity;
  final String _bookingId;
  final String _paymentId;

  Future<void> load() async {
    BookingDetails? details;
    final cached = await _cache.readDetails(_bookingId);
    details = cached?.details;
    if (_connectivity.state.isOnline) {
      try {
        details = await _bookings.getBooking(_bookingId);
      } on AppFailure {
        // Keep the cached copy; the receipt is still readable offline.
      }
    }
    final line = details?.payments
        .where((payment) => payment.id == _paymentId && payment.receipt != null)
        .firstOrNull;
    if (isClosed) return;
    if (line == null) {
      emit(const ReceiptMissing());
    } else {
      emit(ReceiptReady(line: line));
    }
  }
}
