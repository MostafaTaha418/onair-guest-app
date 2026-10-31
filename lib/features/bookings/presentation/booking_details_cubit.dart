import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/features/bookings/data/arrival_instructions_store.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';

sealed class BookingDetailsState {
  const BookingDetailsState();
}

final class DetailsLoading extends BookingDetailsState {
  const DetailsLoading();
}

final class DetailsReady extends BookingDetailsState {
  const DetailsReady({
    required this.details,
    required this.instructions,
    required this.fetchedAt,
    required this.fromCache,
  });

  /// Instructions-stripped details (the raw text lives only in the store).
  final BookingDetails details;

  /// From `ArrivalInstructionsStore`, never from the cached JSON.
  final String? instructions;
  final DateTime fetchedAt;
  final bool fromCache;
}

final class DetailsNotAvailable extends BookingDetailsState {
  const DetailsNotAvailable();
}

final class DetailsFailed extends BookingDetailsState {
  const DetailsFailed(this.error);

  final ApiError error;
}

final class DetailsOffline extends BookingDetailsState {
  const DetailsOffline();
}

/// One booking's details (US3): cache-first, fresh when online, instructions
/// in secure storage only, and refreshed by a signal for this booking.
final class BookingDetailsCubit extends Cubit<BookingDetailsState> {
  BookingDetailsCubit({
    required this._bookings,
    required this._cache,
    required this._arrival,
    required this._signals,
    required this._connectivity,
    required this._bookingId,
  }) : super(const DetailsLoading()) {
    _signalSubscription = _signals.signals
        .where((signal) => signal.entityId == _bookingId)
        .listen((_) => unawaited(refresh()));
  }

  final BookingsRepository _bookings;
  final BookingsCache _cache;
  final ArrivalInstructionsStore _arrival;
  final NotificationSignalSource _signals;
  final ConnectivityCubit _connectivity;
  final String _bookingId;
  StreamSubscription<NotificationSignal>? _signalSubscription;

  /// Bumped by every load so a superseded response never overwrites a
  /// newer one (research R12 pattern).
  int _generation = 0;

  bool _stale(int generation) => isClosed || generation != _generation;

  Future<void> load() async {
    final generation = ++_generation;
    final cached = await _cache.readDetails(_bookingId);
    if (_stale(generation)) return;
    final stored = await _arrival.read(_bookingId);
    if (_stale(generation)) return;
    if (cached != null) {
      emit(
        DetailsReady(
          details: cached.details,
          instructions: cached.details.status.showsArrivalInstructions
              ? stored
              : null,
          fetchedAt: cached.fetchedAt,
          fromCache: true,
        ),
      );
    } else {
      emit(const DetailsLoading());
    }
    if (!_connectivity.state.isOnline) {
      if (_stale(generation)) return;
      if (cached == null) emit(const DetailsOffline());
      return;
    }
    try {
      final details = await _bookings.getBooking(_bookingId);
      if (_stale(generation)) return;
      await _cache.saveDetails(details);
      if (details.status.showsArrivalInstructions &&
          details.accessInstructions != null) {
        await _arrival.write(_bookingId, details.accessInstructions!);
      }
      if (details.status.isTerminal) {
        await _arrival.remove(_bookingId);
      }
      if (_stale(generation)) return;
      final instructions = details.status.showsArrivalInstructions
          ? await _arrival.read(_bookingId)
          : null;
      if (_stale(generation)) return;
      emit(
        DetailsReady(
          details: details.copyWithoutInstructions(),
          instructions: instructions,
          fetchedAt: DateTime.now().toUtc(),
          fromCache: false,
        ),
      );
    } on AppFailure catch (failure) {
      if (_stale(generation)) return;
      if (failure.error.code == ErrorCode.notFound) {
        emit(const DetailsNotAvailable());
      } else {
        emit(DetailsFailed(failure.error));
      }
    }
  }

  Future<void> refresh() => load();

  @override
  Future<void> close() async {
    await _signalSubscription?.cancel();
    await super.close();
  }
}
