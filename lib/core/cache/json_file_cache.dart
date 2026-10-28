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
  Future<Map<String, dynamic>?> read() async {
    try {
      if (!_file.existsSync()) return null;
      final document = jsonDecode(await _file.readAsString());
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
      await directory.create(recursive: true);
      final temporary = File('${_file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode({'schema': schema, 'data': data}),
        flush: true,
      );
      await temporary.rename(_file.path);
    } on Object {
      // The cache is disposable; keep the app running without it.
    }
  }

  Future<void> clear() async {
    try {
      if (_file.existsSync()) {
        await _file.delete();
      }
    } on Object {
      // Nothing to recover; the next write recreates the file.
    }
  }
}
