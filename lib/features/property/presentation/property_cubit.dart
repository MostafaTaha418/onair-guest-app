import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/property_details.dart';

sealed class PropertyState {
  const PropertyState();
}

final class PropertyLoading extends PropertyState {
  const PropertyLoading();
}

final class PropertyReady extends PropertyState {
  const PropertyReady({
    required this.details,
    required this.stay,
    required this.guests,
    this.termsUpdatedNotice = false,
  });

  final PropertyDetails details;

  /// Replaces the search dates once the guest confirms on the calendar
  /// (FR-022); shown in the bottom bar and carried by "Book now".
  final StayRange? stay;
  final int? guests;

  /// US4 shows a notice instead of continuing when the terms changed.
  final bool termsUpdatedNotice;

  PropertyReady copyWith({
    PropertyDetails? details,
    StayRange? stay,
    Object? guests = _unset,
    bool? termsUpdatedNotice,
  }) => PropertyReady(
    details: details ?? this.details,
    stay: stay ?? this.stay,
    guests: guests == _unset ? this.guests : guests as int?,
    termsUpdatedNotice: termsUpdatedNotice ?? this.termsUpdatedNotice,
  );

  static const _unset = Object();
}

/// The neutral not-available screen: unknown, unpublished, paused, and
/// rejected IDs all land here so existence is never revealed (AC-003).
final class PropertyNotAvailable extends PropertyState {
  const PropertyNotAvailable();
}

final class PropertyFailed extends PropertyState {
  const PropertyFailed(this.error);

  final ApiError error;
}

/// Opening an apartment offline (research R17); retry works when back online.
final class PropertyOffline extends PropertyState {
  const PropertyOffline();
}

/// One cubit per `/property/:id` route instance (research R9).
final class PropertyCubit extends Cubit<PropertyState> {
  PropertyCubit({
    required this._repo,
    required this._connectivity,
    required this._propertyId,
    StayRange? initialStay,
    int? initialGuests,
  }) : _stay = initialStay,
       _guests = initialGuests,
       super(const PropertyLoading());

  final ListingsRepository _repo;
  final ConnectivityCubit _connectivity;
  final String _propertyId;
  StayRange? _stay;
  final int? _guests;

  Future<void> load() async {
    emit(const PropertyLoading());
    if (!_connectivity.state.isOnline) {
      emit(const PropertyOffline());
      return;
    }
    try {
      final details = await _repo.property(_propertyId);
      if (isClosed) return;
      emit(
        PropertyReady(details: details, stay: _stay, guests: _guests),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(_stateFor(failure.error));
    }
  }

  PropertyState _stateFor(ApiError error) {
    if (error.code == ErrorCode.notFound ||
        error.code == ErrorCode.propertyNotAvailable) {
      return const PropertyNotAvailable();
    }
    if (error.code == ErrorCode.network && !_connectivity.state.isOnline) {
      return const PropertyOffline();
    }
    return PropertyFailed(error);
  }

  /// The calendar section confirms a picked range (FR-022).
  void setStay(StayRange stay) {
    final ready = state;
    if (ready is! PropertyReady) return;
    _stay = stay;
    emit(ready.copyWith(stay: stay));
  }

  Future<void> retry() => load();
}
