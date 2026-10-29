import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/property/domain/resume_intent.dart';

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
    required this.pendingResume,
    this.termsUpdatedNotice = false,
  });

  final PropertyDetails details;

  /// Replaces the search dates once the guest confirms on the calendar
  /// (FR-022); shown in the bottom bar and carried by "Book now".
  final StayRange? stay;
  final int? guests;

  /// US4 shows a notice instead of continuing when the terms changed.
  final bool termsUpdatedNotice;

  /// The carried-over sign-in intent, still unconsumed. The screen's
  /// BlocListener acts on it exactly once and clears it.
  final ResumeIntent? pendingResume;

  PropertyReady copyWith({
    PropertyDetails? details,
    StayRange? stay,
    Object? guests = _unset,
    bool? termsUpdatedNotice,
    Object? pendingResume = _unset,
  }) => PropertyReady(
    details: details ?? this.details,
    stay: stay ?? this.stay,
    guests: guests == _unset ? this.guests : guests as int?,
    termsUpdatedNotice: termsUpdatedNotice ?? this.termsUpdatedNotice,
    pendingResume: pendingResume == _unset
        ? this.pendingResume
        : pendingResume as ResumeIntent?,
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
    ResumeIntent? pendingResume,
  }) : _stay = initialStay,
       _guests = initialGuests,
       super(const PropertyLoading()) {
    _pendingResume = pendingResume;
  }

  final ListingsRepository _repo;
  final ConnectivityCubit _connectivity;
  final String _propertyId;
  StayRange? _stay;
  final int? _guests;

  /// Set once by the route builder; cleared when the screen consumes it.
  ResumeIntent? _pendingResume;

  Future<void> load() async {
    emit(const PropertyLoading());
    if (!_connectivity.state.isOnline) {
      emit(const PropertyOffline());
      return;
    }
    try {
      final details = await _repo.property(_propertyId);
      if (isClosed) return;
      var notice = false;
      final intent = _pendingResume;
      if (intent != null &&
          intent.action == ResumeAction.book &&
          intent.termsVersion != details.termsVersion) {
        // The guest must review the updated terms and tap "Book now" again
        // (AC-013, research R10).
        notice = true;
      }
      emit(
        PropertyReady(
          details: details,
          stay: _stay,
          guests: _guests,
          pendingResume: intent,
          termsUpdatedNotice: notice,
        ),
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

  /// The screen's listener consumed the resume: it must never act twice.
  void consumeResume() {
    _pendingResume = null;
    final ready = state;
    if (ready is! PropertyReady) return;
    emit(ready.copyWith(pendingResume: null));
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
