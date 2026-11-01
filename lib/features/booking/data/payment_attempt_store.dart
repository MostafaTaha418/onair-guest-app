import 'dart:convert';

import 'package:on_air/core/storage/secure_store.dart';
import 'package:on_air/features/booking/domain/payment_attempt.dart';

/// Holds the single open payment attempt (data-model §4). A corrupt record
/// is dropped rather than trusted: the guest simply starts a fresh attempt.
final class PaymentAttemptStore {
  PaymentAttemptStore(this._store);

  static const key = 'payment_attempt.current';

  final SecureStore _store;

  Future<PaymentAttempt?> read() async {
    final raw = await _store.read(key);
    if (raw == null) return null;
    try {
      return PaymentAttempt.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      await _store.delete(key);
      return null;
    }
  }

  Future<void> save(PaymentAttempt attempt) =>
      _store.write(key, jsonEncode(attempt.toJson()));

  Future<void> clear() => _store.delete(key);
}
