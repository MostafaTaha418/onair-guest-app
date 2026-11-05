import 'package:on_air/core/storage/secure_store.dart';
import 'package:uuid/uuid.dart';

final class ActionAttemptStore {
  ActionAttemptStore(this._store, {String Function()? newKey})
    : _newKey = newKey ?? (() => const Uuid().v4());

  static const prefix = 'action_attempt.';

  final SecureStore _store;
  final String Function() _newKey;

  Future<String> keyFor(String action, String entityId) async {
    final storageKey = '$prefix$action.$entityId';
    final existing = await _store.read(storageKey);
    if (existing != null) return existing;
    final key = _newKey();
    await _store.write(storageKey, key);
    return key;
  }

  Future<void> clear(String action, String entityId) =>
      _store.delete('$prefix$action.$entityId');

  Future<void> clearAll() async {
    final values = await _store.readAll();
    for (final key in values.keys) {
      if (key.startsWith(prefix)) await _store.delete(key);
    }
  }
}
