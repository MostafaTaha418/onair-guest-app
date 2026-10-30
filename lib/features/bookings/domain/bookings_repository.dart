import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';

/// Reads bookings through the `guest_*` RPCs. Every method throws
/// `AppFailure` on error.
abstract interface class BookingsRepository {
  /// One server page of [tab]; the server decides membership and order
  /// (Constitution II).
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor});

  /// Full details of one booking; a booking the caller does not own gives
  /// the same NOT_FOUND as a missing one (AC-007).
  Future<BookingDetails> getBooking(String bookingId);
}
