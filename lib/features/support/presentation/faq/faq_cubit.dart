import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/text/arabic_normalizer.dart';
import 'package:on_air/features/support/data/faq_cache.dart';
import 'package:on_air/features/support/domain/faq_item.dart';
import 'package:on_air/features/support/domain/support_repository.dart';

sealed class FaqState {
  const FaqState();
}

final class FaqLoading extends FaqState {
  const FaqLoading();
}

final class FaqReady extends FaqState {
  const FaqReady({required this.items, this.query = '', this.stale = false});

  final List<FaqItem> items;

  /// The active search needle; empty means «no filter».
  final String query;
  final bool stale;

  /// A non-empty query that matched nothing shows «مفيش نتايج».
  bool get noResults => query.trim().isNotEmpty && items.isEmpty;
}

final class FaqFailed extends FaqState {
  const FaqFailed(this.error);

  final ApiError error;
}

/// The public FAQ (US3): server-first, cache-on-failure, searchable with the
/// shared Arabic normalisation, localized per the app locale.
final class FaqCubit extends Cubit<FaqState> {
  FaqCubit({
    required this.repository,
    required this.cache,
    String locale = 'ar',
    DateTime Function()? now,
    // Named parameters cannot be private, so `_locale` takes the value in
    // the body below.
  }) : _now = now ?? (() => DateTime.now().toUtc()),
       super(const FaqLoading()) {
    _locale = locale;
  }

  /// Starts from a fully formed state; goldens and previews only.
  FaqCubit.seeded({
    required this.repository,
    required this.cache,
    required FaqReady state,
  }) : _now = (() => DateTime.now().toUtc()),
       super(state) {
    _query = state.query;
    _stale = state.stale;
    _items = state.items;
  }

  final SupportRepository repository;
  final FaqCache cache;
  final DateTime Function() _now;

  String _locale = 'ar';
  String _query = '';
  bool _stale = false;

  /// The raw server rows; null when the content came from the offline
  /// cache (already localized at fetch time).
  List<Map<String, dynamic>>? _rows;

  /// The localized items in use — server-localized or cached.
  List<FaqItem> _items = const [];

  /// The screen re-applies the app locale on dependency changes so a live
  /// language switch re-localizes the loaded rows; a cache-only session
  /// keeps its snapshot language under the stale banner.
  void setLocale(String locale) {
    if (_locale == locale) return;
    _locale = locale;
    final rows = _rows;
    if (rows != null) {
      _items = _localize(rows);
    }
    if (state is FaqReady) emit(_ready());
  }

  void search(String query) {
    _query = query;
    if (state is FaqLoading) return;
    emit(_ready());
  }

  Future<void> load() async {
    emit(const FaqLoading());
    _query = '';
    try {
      final rows = await repository.listFaq();
      _rows = [
        for (final row in rows) Map<String, dynamic>.from(row),
      ];
      _items = _localize(_rows!);
      _stale = false;
      await cache.save(
        FaqSnapshot(items: _items, fetchedAt: _now(), locale: _locale),
      );
      if (!isClosed) emit(_ready());
    } on AppFailure catch (failure) {
      final snapshot = await cache.load();
      if (snapshot != null && snapshot.items.isNotEmpty) {
        _rows = null;
        _items = snapshot.items;
        _stale = true;
        if (!isClosed) emit(_ready());
      } else if (!isClosed) {
        emit(FaqFailed(failure.error));
      }
    }
  }

  List<FaqItem> _localize(List<Map<String, dynamic>> rows) => [
    for (final row in rows) FaqItem.fromRow(row, _locale),
  ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  FaqReady _ready() {
    final needle = normalizeArabic(_query.trim().toLowerCase());
    final items = needle.isEmpty
        ? _items
        : _items
              .where(
                (item) =>
                    normalizeArabic(item.question.toLowerCase()).contains(
                      needle,
                    ) ||
                    normalizeArabic(item.answer.toLowerCase()).contains(
                      needle,
                    ),
              )
              .toList();
    return FaqReady(items: items, query: _query, stale: _stale);
  }
}
