import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';

import '../../helpers/fake_listings_repository.dart';

ReferenceData _reference(String version) => ReferenceData(
  version: version,
  amenities: const [],
  propertyTypes: const [],
  priceMin: Money(50000),
  priceMax: Money(1500000),
  priceStep: Money(5000),
);

void main() {
  late Directory directory;
  late JsonFileCache cache;
  late FakeListingsRepository repo;
  late ReferenceDataCache referenceCache;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('reference_cache_test');
    cache = JsonFileCache(directory: directory, fileName: 'x.json', schema: 1);
    repo = FakeListingsRepository();
    referenceCache = ReferenceDataCache(repo, cache);
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  test('an empty cache loads from the repository once and saves', () async {
    repo.referenceDataResponses.add(_reference('v1'));
    final data = await referenceCache.load();
    expect(data.version, 'v1');
    expect(repo.calls, hasLength(1));

    final stored = await cache.read();
    expect(stored?['reference'], isNotNull);
  });

  test(
    'a second load returns the cached data without the repository',
    () async {
      repo.referenceDataResponses.add(_reference('v1'));
      await referenceCache.load();
      final again = await referenceCache.load();
      expect(again.version, 'v1');
      expect(repo.calls, hasLength(1));
    },
  );

  test('refreshIfVersionChanged refetches only on a version change', () async {
    repo.referenceDataResponses.add(_reference('v1'));
    await referenceCache.load();
    expect(repo.calls, hasLength(1));

    // Cached v1 differs from v2: refetch (the fake serves v2 this time).
    repo.referenceDataResponses.add(_reference('v2'));
    await referenceCache.refreshIfVersionChanged('v2');
    expect(repo.calls, hasLength(2));
    expect((await referenceCache.load()).version, 'v2');

    // Now the cache already holds v2: no more calls.
    await referenceCache.refreshIfVersionChanged('v2');
    expect(repo.calls, hasLength(2));
  });

  test(
    'a repository failure with an existing cache returns the cache',
    () async {
      repo.referenceDataResponses.add(_reference('v1'));
      await referenceCache.load();
      repo.referenceDataResponses.add(
        const AppFailure(
          ApiError(code: ErrorCode.internal, messageKey: 'errorUnexpected'),
        ),
      );
      final data = await referenceCache.load();
      expect(data.version, 'v1');
    },
  );

  test('a repository failure with no cache rethrows', () async {
    repo.referenceDataResponses.add(
      const AppFailure(
        ApiError(code: ErrorCode.network, messageKey: 'errorNoConnection'),
      ),
    );
    await expectLater(referenceCache.load(), throwsA(isA<AppFailure>()));
  });

  test('read-modify-write keeps the home key in the same file', () async {
    await cache.write({
      'home': {'reference_version': 'v1'},
    });
    repo.referenceDataResponses.add(_reference('v1'));
    await referenceCache.load();

    final stored = await cache.read();
    expect(stored?['home'], {
      'reference_version': 'v1',
    });
    expect(stored?['reference'], isNotNull);
  });
}
