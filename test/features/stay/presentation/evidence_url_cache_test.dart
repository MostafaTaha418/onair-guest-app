import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/domain/stay_results.dart';
import 'package:on_air/features/stay/presentation/claims/evidence_url_cache.dart';

class _CountingStay implements StayRepository {
  _CountingStay(this.now);

  DateTime Function() now;
  int fileUrlCalls = 0;

  @override
  Future<FileUrl> fileUrl(String attachmentId) async {
    fileUrlCalls++;
    return FileUrl(
      url: Uri.parse('https://files.mock.onair.test/$attachmentId.jpg'),
      expiresAt: now().add(const Duration(minutes: 5)),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('the first urlFor fetches and the second reuses', () async {
    final now = DateTime.utc(2026, 11, 1, 10);
    final stay = _CountingStay(() => now);
    final cache = EvidenceUrlCache(stay, now: () => now);

    final first = await cache.urlFor('a1');
    final second = await cache.urlFor('a1');

    expect(first, second);
    expect(stay.fileUrlCalls, 1);
  });

  test('a URL close to expiry is fetched again', () async {
    var now = DateTime.utc(2026, 11, 1, 10);
    final stay = _CountingStay(() => now);
    final cache = EvidenceUrlCache(stay, now: () => now);

    await cache.urlFor('a1');
    // expiresAt - 20 s: only 20 s of life left, below the 30 s reuse rule.
    now = DateTime.utc(2026, 11, 1, 10, 4, 40);
    await cache.urlFor('a1');

    expect(stay.fileUrlCalls, 2);
  });

  test('invalidate forces a refetch', () async {
    final now = DateTime.utc(2026, 11, 1, 10);
    final stay = _CountingStay(() => now);
    final cache = EvidenceUrlCache(stay, now: () => now);

    await cache.urlFor('a1');
    cache.invalidate('a1');
    await cache.urlFor('a1');

    expect(stay.fileUrlCalls, 2);
  });

  test('clear empties the whole cache', () async {
    final now = DateTime.utc(2026, 11, 1, 10);
    final stay = _CountingStay(() => now);
    final cache = EvidenceUrlCache(stay, now: () => now);

    await cache.urlFor('a1');
    await cache.urlFor('a2');
    cache.clear();
    await cache.urlFor('a1');
    await cache.urlFor('a2');

    expect(stay.fileUrlCalls, 4);
  });

  test('the evidence cache stays memory-only (never on disk)', () async {
    final source = utf8.decode(
      File(
        'lib/features/stay/presentation/claims/evidence_url_cache.dart',
      ).readAsBytesSync(),
    );
    for (final forbidden in [
      'JsonFileCache',
      'BookingsCache',
      'CacheManager',
      'path_provider',
    ]) {
      expect(source.contains(forbidden), isFalse, reason: forbidden);
    }
  });
}
