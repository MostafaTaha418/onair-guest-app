import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/storage/secure_store.dart';
import 'package:on_air/features/stay/data/action_attempt_store.dart';

void main() {
  late InMemorySecureStore backing;
  late ActionAttemptStore store;
  var calls = 0;

  setUp(() {
    backing = InMemorySecureStore();
    calls = 0;
    store = ActionAttemptStore(
      backing,
      newKey: () => 'key-${++calls}',
    );
  });

  test('reuses the same key for one action and entity', () async {
    expect(await store.keyFor('cancel', 'b1'), 'key-1');
    expect(await store.keyFor('cancel', 'b1'), 'key-1');
    expect(calls, 1);
  });

  test('clear makes the next attempt create a new key', () async {
    expect(await store.keyFor('cancel', 'b1'), 'key-1');
    await store.clear('cancel', 'b1');
    expect(await store.keyFor('cancel', 'b1'), 'key-2');
  });

  test('different entities get different keys', () async {
    expect(await store.keyFor('cancel', 'b1'), 'key-1');
    expect(await store.keyFor('cancel', 'b2'), 'key-2');
  });

  test('clearAll removes action attempts only', () async {
    await store.keyFor('cancel', 'b1');
    await store.keyFor('claim_answer', 'c1');
    await backing.write('payment_attempt.current', 'keep');

    await store.clearAll();

    expect(await backing.read('action_attempt.cancel.b1'), isNull);
    expect(await backing.read('action_attempt.claim_answer.c1'), isNull);
    expect(await backing.read('payment_attempt.current'), 'keep');
  });
}
