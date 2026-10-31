import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/booking/data/payment_attempt_store.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';

sealed class UnfinishedPaymentState {
  const UnfinishedPaymentState();
}

final class UnfinishedNone extends UnfinishedPaymentState {
  const UnfinishedNone();
}

final class UnfinishedSome extends UnfinishedPaymentState {
  const UnfinishedSome(this.booking);

  final BookingSummary booking;
}

/// App-scoped (US6): watches the server's `pending` tab so a payment
/// interrupted by a killed app comes back as a banner — and reconciles the
/// stored attempt when the server already decided the outcome.
final class UnfinishedPaymentCubit extends Cubit<UnfinishedPaymentState> {
  UnfinishedPaymentCubit({
    required this._bookings,
    required this._attempts,
  }) : super(const UnfinishedNone());

  final BookingsRepository _bookings;
  final PaymentAttemptStore _attempts;

  /// Errors keep the previous state: the banner is a hint, not a fact the
  /// screen depends on. The next refresh retries.
  Future<void> refresh() async {
    try {
      final page = await _bookings.listBookings(BookingTab.pending);
      final newest = page.items.isEmpty ? null : page.items.first;
      await _reconcileAttempt(page);
      if (isClosed) return;
      emit(newest == null ? const UnfinishedNone() : UnfinishedSome(newest));
    } on AppFailure {
      // Keep the previous state.
    }
  }

  /// A stored attempt whose booking left the pending tab is stale: when the
  /// server is no longer verifying it either, the record goes.
  Future<void> _reconcileAttempt(BookingsPage pendingPage) async {
    final attempt = await _attempts.read();
    final bookingId = attempt?.bookingId;
    if (bookingId == null) return;
    if (pendingPage.items.any((booking) => booking.id == bookingId)) return;
    try {
      final details = await _bookings.getBooking(bookingId);
      if (details.status != BookingStatus.paymentVerifying) {
        await _attempts.clear();
      }
    } on AppFailure catch (failure) {
      if (failure.error.code == ErrorCode.notFound) {
        await _attempts.clear();
      }
      // Other errors: the record stays for the next refresh.
    }
  }

  /// Where the banner opens: an attempt still waiting for the server goes to
  /// the verification screen; anything else to the booking's details.
  Future<String> targetFor(BookingSummary booking) async {
    final attempt = await _attempts.read();
    if (attempt?.bookingId == booking.id) {
      return AppRoutes.paymentReturn(bookingId: booking.id);
    }
    return AppRoutes.bookingDetails(booking.id);
  }

  /// Sign-out (and other full resets): nothing is unfinished any more.
  void reset() => emit(const UnfinishedNone());
}
