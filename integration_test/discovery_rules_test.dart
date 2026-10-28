import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/env/env_config.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/data/supabase_listings_repository.dart';
import 'package:on_air/features/listings/domain/results_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

/// Staging security checks for AC-003 and AC-012
/// (contracts/supabase-discovery.md §10–§11).
///
/// Run against Staging with:
/// `flutter test integration_test/discovery_rules_test.dart -d <device>`
/// with `BACKEND_MODE=remote` and the seed IDs in the git-ignored
/// `env/staging_seed.json`:
/// ```json
/// {
///   "unpublishedPropertyIds": ["<uuid>", "..."],
///   "busyPropertyId": "<uuid>",
///   "freePropertyId": "<uuid>"
/// }
/// ```
///
/// In mock mode every check is skipped with a printed reason; the same
/// assertions run against the mock in `test/features/listings/`.
void main() {
  final environment = EnvConfig.fromEnvironment();
  final remote = environment.backendMode == BackendMode.remote;

  if (!remote) {
    test('AC-003 and AC-012 run against Staging only in remote mode', () {
      // Mock mode cannot reach the Staging seed these checks need.
      // ignore: avoid_print
      print(
        'Skipping discovery rules: BACKEND_MODE=mock. The equivalent checks '
        'run against the mock fixtures in '
        'test/features/listings/mock_listings_repository_test.dart; these '
        'Staging checks need BACKEND_MODE=remote and env/staging_seed.json.',
      );
    });
    return;
  }

  final seedJson = File('env/staging_seed.json');
  final seed = seedJson.existsSync()
      ? jsonDecode(seedJson.readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};
  final unpublishedIds = [
    for (final id in (seed['unpublishedPropertyIds'] as List? ?? const []))
      id as String,
  ];
  final busyId = seed['busyPropertyId'] as String?;
  final freeId = seed['freePropertyId'] as String?;

  TestWidgetsFlutterBinding.ensureInitialized();
  CairoTime.initialize();
  final repository = SupabaseListingsRepository(
    rpc: (fn, params) => Supabase.instance.client.rpc<dynamic>(
      fn,
      params: params,
    ),
  );

  test(
    'AC-003: unpublished and unknown IDs give NOT_FOUND',
    () async {
      for (final id in [
        ...unpublishedIds,
        'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      ]) {
        await expectLater(
          repository.property(id),
          throwsA(
            isA<AppFailure>().having(
              (failure) => failure.error.code,
              'code',
              ErrorCode.notFound,
            ),
          ),
        );
      }
    },
    skip: unpublishedIds.isEmpty
        ? 'env/staging_seed.json has no unpublished IDs'
        : null,
  );

  test(
    'AC-012: dates covering a busy night exclude the apartment',
    () async {
      final today = CairoTime.today();
      // The seed documents the busy nights as day offsets from today.
      final busyOffsets = [
        for (final offset in (seed['busyOffsets'] as List? ?? const []))
          offset as int,
      ];
      for (final offset in busyOffsets) {
        final stay = StayRange(
          today.addDays(offset - 1),
          today.addDays(offset + 1),
        );
        final page = await repository.searchProperties(
          PropertySearchParams(stay: stay),
        );
        expect(
          page.items.map((card) => card.id),
          isNot(contains(busyId)),
          reason: 'night today+$offset must exclude the busy apartment',
        );
      }
      if (busyOffsets.isNotEmpty && freeId != null) {
        final freeStay = StayRange(today.addDays(1), today.addDays(5));
        final freePage = await repository.searchProperties(
          PropertySearchParams(stay: freeStay),
        );
        expect(freePage.items.map((card) => card.id), contains(freeId));
      }
    },
    skip: busyId == null ? 'env/staging_seed.json has no busy property' : null,
  );
}
