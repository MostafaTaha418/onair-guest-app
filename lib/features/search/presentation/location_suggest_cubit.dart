import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/location_suggestion.dart';

sealed class LocationSuggestState {
  const LocationSuggestState();
}

final class LocationSuggestIdle extends LocationSuggestState {
  const LocationSuggestIdle();
}

final class LocationSuggestLoading extends LocationSuggestState {
  const LocationSuggestLoading(this.query);

  final String query;
}

final class LocationSuggestReady extends LocationSuggestState {
  const LocationSuggestReady(this.query, this.items);

  final String query;
  final List<LocationSuggestion> items;
}

final class LocationSuggestFailed extends LocationSuggestState {
  const LocationSuggestFailed(this.query);

  final String query;
}

/// Debounced location suggestions (~350 ms, Guest Plan §6.4.4). Every request
/// carries an increasing sequence number and an older response never
/// replaces a newer one (research R12).
final class LocationSuggestCubit extends Cubit<LocationSuggestState> {
  LocationSuggestCubit({
    required this._repo,
    this._debounce = const Duration(milliseconds: 350),
  }) : super(const LocationSuggestIdle());

  final ListingsRepository _repo;
  final Duration _debounce;
  Timer? _timer;
  int _sequence = 0;

  void onQueryChanged(String text) {
    final query = text.trim();
    _timer?.cancel();
    if (query.length < 2) {
      // Invalidate any in-flight request and show the short-query state.
      _sequence++;
      emit(const LocationSuggestIdle());
      return;
    }
    _timer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final sequence = ++_sequence;
    emit(LocationSuggestLoading(query));
    try {
      final items = await _repo.searchLocations(query);
      if (isClosed || sequence != _sequence) return;
      emit(LocationSuggestReady(query, items));
    } on AppFailure {
      if (isClosed || sequence != _sequence) return;
      emit(LocationSuggestFailed(query));
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _sequence++;
    await super.close();
  }
}
