import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads bookings through `guest_list_bookings` and `guest_get_booking`
/// (contracts/supabase-booking.md). Nothing but this class talks to Supabase
/// for booking records (Constitution VII).
final class SupabaseBookingsRepository implements BookingsRepository {
  SupabaseBookingsRepository({
    required Future<dynamic> Function(String fn, Map<String, dynamic> params)
    rpc,
  }) : this._(rpc);

  SupabaseBookingsRepository._(this._rpc);

  final Future<dynamic> Function(String fn, Map<String, dynamic> params) _rpc;

  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) =>
      _guard(() async {
        final response = await _rpc('guest_list_bookings', {
          'p_tab': tab.wire,
          'p_cursor': ?cursor,
        });
        return BookingsPage.fromJson(_asMap(response));
      });

  @override
  Future<BookingDetails> getBooking(String bookingId) => _guard(() async {
    final response = await _rpc('guest_get_booking', {
      'p_booking_id': bookingId,
    });
    // A booking the caller does not own gives the same empty answer as a
    // missing one (AC-007).
    if (response == null) {
      throw AppFailure(ErrorMapper.fromCode('NOT_FOUND'));
    }
    return BookingDetails.fromJson(_asMap(response));
  });

  /// One wrapper for every call; copied from `SupabaseListingsRepository`
  /// so booking reads behave exactly like discovery reads.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      final code = [error.message, ?error.code].firstWhere(
        ErrorMapper.hasCode,
        orElse: () => 'INTERNAL',
      );
      throw AppFailure(ErrorMapper.fromCode(code));
    } on SocketException {
      throw AppFailure(ErrorMapper.noResponse());
    } on TimeoutException {
      throw AppFailure(ErrorMapper.noResponse());
    } on http.ClientException {
      throw AppFailure(ErrorMapper.noResponse());
    } on AppFailure {
      rethrow;
    } on Object {
      throw AppFailure(ErrorMapper.fromCode('INTERNAL'));
    }
  }

  static Map<String, dynamic> _asMap(Object? value) =>
      Map<String, dynamic>.from(value! as Map);
}
