import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// One versioned JSON document in the app support folder (research R6).
///
/// Holds only public data: the Home feed's public sections and the reference
/// lists. Callers must never write personal data here.
final class JsonFileCache {
  JsonFileCache({
    required this.directory,
    required this.fileName,
    required this.schema,
  });

  /// Opens the cache in the app support directory (path_provider).
  static Future<JsonFileCache> appSupport({
    required String fileName,
    required int schema,
  }) async {
    final directory = await getApplicationSupportDirectory();
    return JsonFileCache(
      directory: directory,
      fileName: fileName,
      schema: schema,
    );
  }

  final Directory directory;
  final String fileName;
  final int schema;

  File get _file => File('${directory.path}${Platform.pathSeparator}$fileName');

  /// The stored data, or null when the file is missing, corrupt, or written
  /// by a different schema version (the file is discarded then).
  ///
  /// The document is small, so the file work is synchronous: callers stay on
  /// a single microtask, which also keeps widget tests deterministic.
  Future<Map<String, dynamic>?> read() async {
    try {
      if (!_file.existsSync()) return null;
      final document = jsonDecode(_file.readAsStringSync());
      if (document is! Map<String, dynamic>) return null;
      if (document['schema'] != schema) {
        await clear();
        return null;
      }
      final data = document['data'];
      return data is Map<String, dynamic> ? data : null;
    } on Object {
      return null;
    }
  }

  /// Writes atomically: `<file>.tmp` first, then a rename, so a crash never
  /// leaves half a file. Failures are swallowed.
  Future<void> write(Map<String, dynamic> data) async {
    try {
      directory.createSync(recursive: true);
      File('${_file.path}.tmp')
        ..writeAsStringSync(
          jsonEncode({'schema': schema, 'data': data}),
          flush: true,
        )
        ..renameSync(_file.path);
    } on Object {
      // The cache is disposable; keep the app running without it.
    }
  }

  Future<void> clear() async {
    try {
      if (_file.existsSync()) {
        _file.deleteSync();
      }
    } on Object {
      // Nothing to recover; the next write recreates the file.
    }
  }
}
