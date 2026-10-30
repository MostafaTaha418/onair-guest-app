import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';

sealed class FiltersCountState {
  const FiltersCountState();
}

final class FiltersCounting extends FiltersCountState {
  const FiltersCounting();
}

final class FiltersCount extends FiltersCountState {
  const FiltersCount(this.count);

  final int count;
}

final class FiltersCountFailed extends FiltersCountState {
  const FiltersCountFailed();
}

/// Debounced result count for the filters sheet (~400 ms, research R4), with
/// stale answers dropped by sequence number.
final class FiltersCountCubit extends Cubit<FiltersCountState> {
  FiltersCountCubit({
    required this._repo,
    this._debounce = const Duration(milliseconds: 400),
  }) : super(const FiltersCounting());

  final ListingsRepository _repo;
  final Duration _debounce;
  Timer? _timer;
  int _sequence = 0;

  void recount(SearchCriteria criteria) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => _count(criteria));
  }

  Future<void> _count(SearchCriteria criteria) async {
    final sequence = ++_sequence;
    emit(const FiltersCounting());
    try {
      final count = await _repo.countProperties(criteria.toParams());
      if (isClosed || sequence != _sequence) return;
      emit(FiltersCount(count));
    } on AppFailure {
      if (isClosed || sequence != _sequence) return;
      emit(const FiltersCountFailed());
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _sequence++;
    await super.close();
  }
}
