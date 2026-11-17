import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';

/// An in-memory [BookingsRepository]: fixed pages per tab and a details map,
/// with `NOT_FOUND` for unknown ids (the server rule, Constitution II).
final class FakeBookingsRepository implements BookingsRepository {
  final Map<BookingTab, List<BookingSummary>> pages = {};
  final Map<String, BookingDetails> bookings = {};
  Exception? nextError;
  final List<BookingTab> requestedTabs = [];

  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) async {
    requestedTabs.add(tab);
    if (nextError case final error?) {
      nextError = null;
      throw error;
    }
    return BookingsPage(items: pages[tab] ?? const [], nextCursor: null);
  }

  @override
  Future<BookingDetails> getBooking(String bookingId) async {
    final booking = bookings[bookingId];
    if (booking == null) {
      throw AppFailure(ErrorMapper.fromCode('NOT_FOUND'));
    }
    return booking;
  }
}

BookingDetails sampleBookingDetails({
  String id = 'b0000000-0000-4000-8000-000000000021',
  String code = 'OA-2042',
}) => BookingDetails.fromJson({
  'id': id,
  'code': code,
  'status': 'confirmed',
  'property': const {
    'id': '00000000-0000-4000-8000-00000000001f',
    'title': 'شقة الساحل',
    'area_name': 'الغردقة',
    'city_name': 'الغردقة',
  },
  'check_in': '2026-12-01',
  'check_out': '2026-12-05',
  'nights': 4,
  'guests_count': 2,
  'nightly_minor': 100000,
  'total_minor': 400000,
  'pay_now_minor': 200000,
  'paid_minor': 0,
  'remaining_minor': 200000,
  'payment_state': null,
  'payments': const <Object>[],
  'created_at': '2026-11-16T10:00:00Z',
});

BookingSummary sampleBookingSummary({
  String id = 'b0000000-0000-4000-8000-000000000021',
  String code = 'OA-2042',
  BookingStatus status = BookingStatus.confirmed,
}) => BookingSummary(
  id: id,
  code: code,
  propertyId: '00000000-0000-4000-8000-00000000001f',
  title: 'شقة الساحل',
  coverImage: null,
  stay: StayRange(
    DateOnly.parse('2026-12-01'),
    DateOnly.parse('2026-12-05'),
  ),
  status: status,
  refundStage: null,
  ownerResponseDeadline: null,
  createdAt: DateTime.utc(2026, 11, 16, 10),
);
