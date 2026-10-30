import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';
import 'package:on_air/features/search/presentation/filters_count_cubit.dart';

import '../../helpers/fake_listings_repository.dart';

void main() {
  test('a change triggers countProperties after 400 ms', () {
    fakeAsync((async) {
      final repo = FakeListingsRepository();
      repo.countResponses.add(42);
      final cubit = FiltersCountCubit(repo: repo);
      final states = <FiltersCountState>[];
      cubit.stream.listen(states.add);

      cubit.recount(const SearchCriteria(guests: 2));
      async.elapse(const Duration(milliseconds: 100));
      expect(states, isEmpty, reason: 'still debouncing');
      async.elapse(const Duration(milliseconds: 400));

      expect(repo.calls, hasLength(1));
      expect(states, hasLength(2));
      expect(states[0], isA<FiltersCounting>());
      expect(states[1], isA<FiltersCount>());
      expect((states[1] as FiltersCount).count, 42);
      unawaited(cubit.close());
    });
  });

  test('quick consecutive changes give one call', () {
    fakeAsync((async) {
      final repo = FakeListingsRepository();
      repo.countResponses.add(7);
      final cubit = FiltersCountCubit(repo: repo)
        ..recount(const SearchCriteria(guests: 2))
        ..recount(const SearchCriteria(guests: 3))
        ..recount(const SearchCriteria(guests: 4));
      async
        ..elapse(const Duration(milliseconds: 100))
        ..elapse(const Duration(seconds: 1));

      expect(repo.calls, hasLength(1));
      expect((cubit.state as FiltersCount).count, 7);
      unawaited(cubit.close());
    });
  });

  test('a stale count is ignored', () {
    fakeAsync((async) {
      final repo = FakeListingsRepository();
      final stale = Completer<int>();
      final fresh = Completer<int>();
      repo.countResponses.add(stale.future);
      repo.countResponses.add(fresh.future);
      final cubit = FiltersCountCubit(repo: repo);
      final states = <FiltersCountState>[];
      cubit.stream.listen(states.add);

      cubit.recount(const SearchCriteria(guests: 2));
      async.elapse(const Duration(milliseconds: 400));
      cubit.recount(const SearchCriteria(guests: 5));
      async.elapse(const Duration(milliseconds: 400));

      fresh.complete(10);
      async.flushMicrotasks();
      expect(
        (states.last as FiltersCount).count,
        10,
      );

      stale.complete(999);
      async.flushMicrotasks();
      expect(
        (states.last as FiltersCount).count,
        10,
        reason: 'the older count must never replace the newer one',
      );
      unawaited(cubit.close());
    });
  });

  test('a failure gives FiltersCountFailed', () {
    fakeAsync((async) {
      final repo = FakeListingsRepository();
      repo.countResponses.add(
        const AppFailure(
          ApiError(code: ErrorCode.internal, messageKey: 'errorUnexpected'),
        ),
      );
      final cubit = FiltersCountCubit(repo: repo);
      final states = <FiltersCountState>[];
      cubit.stream.listen(states.add);

      cubit.recount(SearchCriteria.empty);
      async.elapse(const Duration(milliseconds: 400));

      expect(states.last, isA<FiltersCountFailed>());
      unawaited(cubit.close());
    });
  });
}
