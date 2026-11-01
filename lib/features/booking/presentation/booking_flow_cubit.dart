import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/domain/quote_change.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/property_details.dart';

enum FlowLoad { loading, ready, notAvailable, failed, offline }

@immutable
class _Unset {
  const _Unset();
}

const _unset = _Unset();

/// The booking draft for one `/book/:propertyId` route branch (data-model
/// §1): property, availability, stay, guests, and the last server quote.
/// The cubit never computes an amount — every figure in the state comes
/// from a server quote.
final class BookingFlowState {
  const BookingFlowState({
    required this.load,
    required this.unavailable,
    required this.guests,
    required this.termsHash,
    required this.quoting,
    required this.termsChanged,
    required this.needsVerification,
    this.property,
    this.stay,
    this.quote,
    this.error,
    this.pendingChange,
  });

  final FlowLoad load;
  final PropertyDetails? property;
  final Set<DateOnly> unavailable;
  final StayRange? stay;
  final int guests;
  final String termsHash;
  final bool quoting;
  final BookingQuote? quote;
  final ApiError? error;

  /// Set after a re-quote that differs; blocks payment until confirmed (US6).
  final QuoteChange? pendingChange;
  final bool termsChanged;

  /// Set when the guest's email or phone is unconfirmed (US2).
  final bool needsVerification;

  bool get canContinue =>
      load == FlowLoad.ready &&
      stay != null &&
      guests >= 1 &&
      guests <= property!.maxGuests &&
      stay!.isSelectable(unavailable) &&
      !quoting;

  /// US6: payment is allowed only with a confirmed quote.
  bool get canPay => quote != null && pendingChange == null && !termsChanged;

  BookingFlowState copyWith({
    FlowLoad? load,
    PropertyDetails? property,
    Set<DateOnly>? unavailable,
    StayRange? stay,
    int? guests,
    String? termsHash,
    bool? quoting,
    Object? quote = _unset,
    Object? error = _unset,
    Object? pendingChange = _unset,
    bool? termsChanged,
    bool? needsVerification,
  }) => BookingFlowState(
    load: load ?? this.load,
    property: property ?? this.property,
    unavailable: unavailable ?? this.unavailable,
    stay: stay ?? this.stay,
    guests: guests ?? this.guests,
    termsHash: termsHash ?? this.termsHash,
    quoting: quoting ?? this.quoting,
    quote: quote == _unset ? this.quote : quote as BookingQuote?,
    error: error == _unset ? this.error : error as ApiError?,
    pendingChange: pendingChange == _unset
        ? this.pendingChange
        : pendingChange as QuoteChange?,
    termsChanged: termsChanged ?? this.termsChanged,
    needsVerification: needsVerification ?? this.needsVerification,
  );
}

/// One cubit per booking branch; the draft dies when the guest leaves it.
final class BookingFlowCubit extends Cubit<BookingFlowState> {
  BookingFlowCubit({
    required this._listings,
    required this._flow,
    required this._connectivity,
    required this._propertyId,
    required String termsHash,
    StayRange? initialStay,
    int? initialGuests,
    DateOnly Function()? today,
    DateTime Function()? now,
  }) : _today = today ?? CairoTime.today,
       _now = now ?? (() => DateTime.now().toUtc()),
       super(
         BookingFlowState(
           load: FlowLoad.loading,
           unavailable: const {},
           guests: initialGuests ?? 1,
           termsHash: termsHash,
           quoting: false,
           termsChanged: false,
           needsVerification: false,
           stay: initialStay,
         ),
       );

  /// Convenience for callers and tests: the state's continue check.
  bool get canContinue => state.canContinue;

  final ListingsRepository _listings;
  final BookingFlowRepository _flow;
  final ConnectivityCubit _connectivity;
  final String _propertyId;
  final DateOnly Function() _today;
  final DateTime Function() _now;
  Timer? _expiryTimer;

  Future<void> load() async {
    emit(
      BookingFlowState(
        load: FlowLoad.loading,
        unavailable: const {},
        guests: state.guests,
        termsHash: state.termsHash,
        quoting: false,
        termsChanged: false,
        needsVerification: state.needsVerification,
        stay: state.stay,
      ),
    );
    if (!_connectivity.state.isOnline) {
      emit(state.copyWith(load: FlowLoad.offline));
      return;
    }
    final today = _today();
    try {
      final results = await Future.wait([
        _listings.property(_propertyId),
        _listings.unavailableNights(
          _propertyId,
          today,
          today.addDays(365),
        ),
      ]);
      if (isClosed) return;
      emit(
        state.copyWith(
          load: FlowLoad.ready,
          property: results[0] as PropertyDetails,
          unavailable: results[1] as Set<DateOnly>,
        ),
      );
      unawaited(_checkVerification());
    } on AppFailure catch (failure) {
      if (isClosed) return;
      final code = failure.error.code;
      if (code == ErrorCode.notFound ||
          code == ErrorCode.propertyNotAvailable) {
        emit(state.copyWith(load: FlowLoad.notAvailable));
      } else {
        emit(state.copyWith(load: FlowLoad.failed, error: failure.error));
      }
    }
  }

  /// US2 fills this in; the flow never blocks on it here (the server
  /// re-checks at payment start).
  Future<void> _checkVerification() async {
    try {
      final status = await _flow.verificationStatus();
      if (isClosed) return;
      emit(state.copyWith(needsVerification: !status.isComplete));
    } on AppFailure {
      // Errors are ignored — the server still checks at payment start.
    }
  }

  /// US2: the verify screen finished on top of this branch; continue.
  void verificationDone() {
    if (state.needsVerification) {
      emit(state.copyWith(needsVerification: false));
    }
  }

  /// T048: new stay (or guests) invalidates the priced answer — the quote,
  /// its expiry timer, and any parked change all go.
  void setStay(StayRange? stay) {
    _expiryTimer?.cancel();
    emit(
      state.copyWith(
        stay: stay,
        quote: null,
        error: null,
        pendingChange: null,
      ),
    );
  }

  void setGuests(int guests) {
    final max = state.property?.maxGuests;
    final clamped = max == null ? guests : guests.clamp(1, max);
    _expiryTimer?.cancel();
    emit(
      state.copyWith(
        guests: clamped,
        quote: null,
        error: null,
        pendingChange: null,
      ),
    );
  }

  Future<bool> requestQuote() async {
    if (!state.canContinue) return false;
    emit(state.copyWith(quoting: true, error: null));
    final stay = state.stay!;
    try {
      final quote = await _flow.quote(
        propertyId: _propertyId,
        stay: stay,
        guests: state.guests,
        termsHash: state.termsHash,
      );
      if (isClosed) return false;
      emit(
        state.copyWith(quoting: false, quote: quote, pendingChange: null),
      );
      _scheduleExpiryRefresh(quote);
      return true;
    } on AppFailure catch (failure) {
      if (isClosed) return false;
      emit(state.copyWith(quoting: false, error: failure.error));
      if (failure.error.code == ErrorCode.datesUnavailable) {
        await _reloadUnavailable();
      }
      return false;
    }
  }

  Future<void> _reloadUnavailable() async {
    final today = _today();
    try {
      final unavailable = await _listings.unavailableNights(
        _propertyId,
        today,
        today.addDays(365),
      );
      if (isClosed) return;
      emit(state.copyWith(unavailable: unavailable));
    } on AppFailure {
      // The stale availability stays; the server rejects at payment start.
    }
  }

  Future<void> retry() => load();

  /// US6: re-asks the server for the same stay after the quote neared its
  /// expiry or the payment start rejected it. A changed quote parks in
  /// [BookingFlowState.pendingChange] until the guest confirms it.
  Future<void> refreshQuote() async {
    final stay = state.stay;
    final previous = state.quote;
    if (stay == null || !state.canContinue) return;
    try {
      final next = await _flow.quote(
        propertyId: _propertyId,
        stay: stay,
        guests: state.guests,
        termsHash: state.termsHash,
      );
      if (isClosed) return;
      final change = previous == null
          ? null
          : QuoteChange.between(previous, next);
      emit(
        state.copyWith(
          quote: next,
          pendingChange: change != null && change.hasChanges ? change : null,
          error: null,
        ),
      );
      _scheduleExpiryRefresh(next);
    } on AppFailure {
      // The previous quote stays; the payment start re-checks the server.
    }
  }

  /// US6: the guest saw the changed amounts and accepted them.
  void acceptChange() {
    if (state.pendingChange != null) {
      emit(state.copyWith(pendingChange: null));
    }
  }

  /// US6: the payment start refused the attempt — react by code.
  Future<void> onPaymentError(ApiError error) async {
    if (error.code == ErrorCode.quoteExpired) {
      await refreshQuote();
    } else if (error.code == ErrorCode.propertyNotAvailable) {
      // AC-003: the apartment is gone; this booking branch cannot continue.
      _expiryTimer?.cancel();
      emit(state.copyWith(load: FlowLoad.notAvailable));
    } else if (error.code == ErrorCode.termsChanged) {
      try {
        final property = await _listings.property(_propertyId);
        if (isClosed) return;
        emit(state.copyWith(property: property, termsChanged: true));
      } on AppFailure {
        if (isClosed) return;
        emit(state.copyWith(termsChanged: true));
      }
    }
  }

  /// US6: the guest accepted the new terms — continue under them.
  Future<void> acceptNewTerms() async {
    final property = state.property;
    if (property == null) return;
    emit(
      state.copyWith(termsHash: property.termsVersion, termsChanged: false),
    );
    await requestQuote();
  }

  void _scheduleExpiryRefresh(BookingQuote quote) {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    final fireAt = quote.expiresAt.subtract(const Duration(seconds: 30));
    final delay = fireAt.difference(_now());
    if (delay <= Duration.zero) {
      scheduleMicrotask(() => unawaited(refreshQuote()));
      return;
    }
    _expiryTimer = Timer(delay, () => unawaited(refreshQuote()));
  }

  @override
  Future<void> close() async {
    _expiryTimer?.cancel();
    await super.close();
  }
}
