import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/cache/json_file_cache.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('json_file_cache_test');
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  JsonFileCache cacheOf({required int schema, String fileName = 'x.json'}) =>
      JsonFileCache(directory: directory, fileName: fileName, schema: schema);

  test('read returns null when the file is missing', () async {
    final cache = cacheOf(schema: 1);
    expect(await cache.read(), isNull);
  });

  test('write then read returns an equal map', () async {
    final cache = cacheOf(schema: 1);
    const data = {
      'home': {'areas': 1},
      'reference': {'version': 'v1'},
    };
    await cache.write(data);
    expect(await cache.read(), data);
  });

  test('a schema mismatch discards the file', () async {
    await cacheOf(schema: 1).write({
      'reference': {'version': 'v1'},
    });
    final newer = cacheOf(schema: 2);
    expect(await newer.read(), isNull);
    expect(File('${directory.path}/x.json').existsSync(), isFalse);
  });

  test('a corrupt file returns null without throwing', () async {
    File('${directory.path}/x.json').writeAsStringSync('not json {{{');
    final cache = cacheOf(schema: 1);
    expect(await cache.read(), isNull);
  });

  test('a file with the wrong document shape returns null', () async {
    File(
      '${directory.path}/x.json',
    ).writeAsStringSync(jsonEncode({'unexpected': 'shape'}));
    expect(await cacheOf(schema: 1).read(), isNull);
  });

  test('clear deletes the file', () async {
    final cache = cacheOf(schema: 1);
    await cache.write({'a': 1});
    expect(File('${directory.path}/x.json').existsSync(), isTrue);
    await cache.clear();
    expect(File('${directory.path}/x.json').existsSync(), isFalse);
    expect(await cache.read(), isNull);
  });
}
