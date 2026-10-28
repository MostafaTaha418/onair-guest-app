import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/listings/domain/location_suggestion.dart';
import 'package:on_air/features/search/presentation/location_suggest_cubit.dart';

import '../../helpers/fake_listings_repository.dart';

void main() {
  test('typing within the debounce window makes only one repository call', () {
    fakeAsync((async) {
      final repo = FakeListingsRepository();
      final cubit = LocationSuggestCubit(repo: repo);
      final states = <LocationSuggestState>[];
      cubit.stream.listen(states.add);

      cubit.onQueryChanged('ال');
      async.elapse(const Duration(milliseconds: 100));
      cubit.onQueryChanged('التج');
      async.elapse(const Duration(milliseconds: 400));

      expect(repo.calls, ['searchLocations(التج)']);
      expect(states.last, isA<LocationSuggestReady>());
      final ready = states.last as LocationSuggestReady;
      expect(ready.query, 'التج');
      expect(ready.items, isEmpty);
      unawaited(cubit.close());
    });
  });

  test('an older response arriving after a newer one is ignored', () {
    fakeAsync((async) {
      final repo = FakeListingsRepository();
      final cubit = LocationSuggestCubit(repo: repo);
      final states = <LocationSuggestState>[];
      cubit.stream.listen(states.add);

      final older = Completer<List<LocationSuggestion>>();
      final newer = Completer<List<LocationSuggestion>>();
      repo.locationResponses.add(older.future);
      repo.locationResponses.add(newer.future);

      cubit.onQueryChanged('التجمع');
      async.elapse(const Duration(milliseconds: 400));
      cubit.onQueryChanged('التجمع الخامس');
      async.elapse(const Duration(milliseconds: 400));

      newer.complete([
        const LocationSuggestion(
          id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          level: LocationLevel.area,
          name: 'التجمع الخامس',
          parentLabel: null,
          listingCount: 42,
        ),
      ]);
      async.elapse(const Duration(milliseconds: 10));
      expect(
        (states.last as LocationSuggestReady).items,
        hasLength(1),
      );

      // The older answer lands last; it must not replace the newer list.
      older.complete(const []);
      async.elapse(const Duration(milliseconds: 10));
      expect(
        (states.last as LocationSuggestReady).items,
        hasLength(1),
      );
      unawaited(cubit.close());
    });
  });

  test('fewer than two characters gives idle without a repository call', () {
    fakeAsync((async) {
      final repo = FakeListingsRepository();
      final cubit = LocationSuggestCubit(repo: repo);
      final states = <LocationSuggestState>[];
      cubit.stream.listen(states.add);

      cubit.onQueryChanged('ت');
      async.elapse(const Duration(seconds: 1));

      expect(repo.calls, isEmpty);
      expect(states, [isA<LocationSuggestIdle>()]);
      unawaited(cubit.close());
    });
  });

  test('a repository failure gives LocationSuggestFailed', () {
    fakeAsync((async) {
      final repo = FakeListingsRepository();
      repo.locationResponses.add(
        const AppFailure(
          ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
        ),
      );
      final cubit = LocationSuggestCubit(repo: repo);
      final states = <LocationSuggestState>[];
      cubit.stream.listen(states.add);

      cubit.onQueryChanged('التج');
      async.elapse(const Duration(milliseconds: 400));

      expect(states.last, isA<LocationSuggestFailed>());
      expect((states.last as LocationSuggestFailed).query, 'التج');
      unawaited(cubit.close());
    });
  });

  test('close cancels the pending debounce', () {
    fakeAsync((async) {
      final repo = FakeListingsRepository();
      final cubit = LocationSuggestCubit(repo: repo)..onQueryChanged('التج');

      async.elapse(const Duration(milliseconds: 1));
      unawaited(cubit.close());
      async.elapse(const Duration(seconds: 2));

      expect(repo.calls, isEmpty);
    });
  });
}
