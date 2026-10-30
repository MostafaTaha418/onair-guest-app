import 'package:on_air/core/storage/secure_store.dart';

/// Arrival instructions live only in secure storage (research R13): they can
/// contain door codes, so they never touch the plain JSON cache.
final class ArrivalInstructionsStore {
  ArrivalInstructionsStore(this._store);

  static const prefix = 'arrival.';

  final SecureStore _store;

  String _key(String bookingId) => '$prefix$bookingId';

  Future<String?> read(String bookingId) => _store.read(_key(bookingId));

  Future<void> write(String bookingId, String text) =>
      _store.write(_key(bookingId), text);

  Future<void> remove(String bookingId) => _store.delete(_key(bookingId));

  /// Sign-out purge: every arrival key goes, nothing else (the open payment
  /// attempt has its own resetter entry).
  Future<void> clearAll() async {
    final all = await _store.readAll();
    for (final key in all.keys) {
      if (key.startsWith(prefix)) {
        await _store.delete(key);
      }
    }
  }
}
