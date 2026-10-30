import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/storage/secure_store.dart';
import 'package:on_air/features/booking/data/payment_attempt_store.dart';
import 'package:on_air/features/booking/domain/payment_attempt.dart';
import 'package:on_air/features/bookings/data/arrival_instructions_store.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';

PaymentAttempt _attempt() => PaymentAttempt(
  attemptKey: '11111111-2222-4333-8444-555555555555',
  quoteId: '22222222-3333-4444-8555-666666666666',
  propertyId: '00000000-0000-4000-8000-00000000001f',
  termsHash: 'mock-terms-1',
  startedAt: DateTime.utc(2026, 11, 1, 10),
);

BookingSummary _summary() => BookingSummary.fromJson(const {
  'id': 'b0000000-0000-4000-8000-000000000001',
  'code': 'OA-MOCK001',
  'property_id': '00000000-0000-4000-8000-00000000001f',
  'title': 'شقة',
  'cover_image': null,
  'check_in': '2026-11-20',
  'check_out': '2026-11-23',
  'status': 'confirmed',
  'refund_status': null,
  'owner_response_deadline': null,
  'created_at': '2026-10-20T01:00:00Z',
});

BookingDetails _details() => BookingDetails.fromJson(const {
  'id': 'b0000000-0000-4000-8000-000000000001',
  'code': 'OA-MOCK001',
  'status': 'confirmed',
  'property': {
    'id': '00000000-0000-4000-8000-00000000001f',
    'title': 'شقة',
    'cover_image': null,
    'area_name': 'المعادي',
    'city_name': 'القاهرة',
    'address_text': null,
    'check_in_time': '14:00',
    'check_out_time': '12:00',
  },
  'check_in': '2026-11-20',
  'check_out': '2026-11-23',
  'nights': 3,
  'guests_count': 2,
  'nightly_minor': 150000,
  'total_minor': 450000,
  'pay_now_minor': 112500,
  'paid_minor': 112500,
  'remaining_minor': 337500,
  'remaining_due_at': null,
  'currency': 'EGP',
  'owner_response_deadline': null,
  'payment_state': 'succeeded',
  'payments': <Object>[],
  'refund': null,
  'terms_snapshot': null,
  'access_instructions': 'سر',
  'available_actions': <String>['contact_support'],
  'events': <Object>[],
  'created_at': '2026-10-28T08:55:00Z',
});

JsonFileCache _tempCache() {
  final directory = Directory.systemTemp.createTempSync('on_air_g2_cache');
  addTearDown(() => directory.deleteSync(recursive: true));
  return JsonFileCache(
    directory: directory,
    fileName: 'bookings_cache.json',
    schema: 1,
  );
}

void main() {
  group('PaymentAttemptStore', () {
    test('read is empty, then saves, then clears', () async {
      final store = PaymentAttemptStore(InMemorySecureStore());
      expect(await store.read(), isNull);
      final attempt = _attempt();
      await store.save(attempt);
      expect(await store.read(), attempt);
      await store.clear();
      expect(await store.read(), isNull);
    });

    test('a corrupt value is dropped and removed', () async {
      final backing = InMemorySecureStore();
      await backing.write(PaymentAttemptStore.key, 'not json');
      final store = PaymentAttemptStore(backing);
      expect(await store.read(), isNull);
      expect(await backing.read(PaymentAttemptStore.key), isNull);
    });
  });

  group('ArrivalInstructionsStore', () {
    test('write, read, remove', () async {
      final store = ArrivalInstructionsStore(InMemorySecureStore());
      expect(await store.read('b1'), isNull);
      await store.write('b1', 'text');
      expect(await store.read('b1'), 'text');
      await store.remove('b1');
      expect(await store.read('b1'), isNull);
    });

    test('clearAll removes only arrival keys', () async {
      final backing = InMemorySecureStore();
      final store = ArrivalInstructionsStore(backing);
      await store.write('b1', 'one');
      await store.write('b2', 'two');
      await backing.write(PaymentAttemptStore.key, 'attempt');
      await store.clearAll();
      expect(await backing.read('arrival.b1'), isNull);
      expect(await backing.read('arrival.b2'), isNull);
      expect(await backing.read(PaymentAttemptStore.key), 'attempt');
    });
  });

  group('BookingsCache', () {
    test('tab round trip keeps the fetch time', () async {
      final cache = BookingsCache(_tempCache());
      expect((await cache.readTab(BookingTab.current))?.items, isNull);
      await cache.saveTab(BookingTab.current, [_summary()]);
      final cached = await cache.readTab(BookingTab.current);
      expect(cached, isNotNull);
      expect(cached!.items, [_summary()]);
      expect(cached.fetchedAt, isNotNull);
      await cache.clear();
      expect((await cache.readTab(BookingTab.current))?.items, isNull);
    });

    test('details are stored without the arrival instructions', () async {
      final cache = BookingsCache(_tempCache());
      final details = _details();
      await cache.saveDetails(details);
      final cached = await cache.readDetails(details.id);
      expect(cached, isNotNull);
      expect(cached!.details.accessInstructions, isNull);
      await cache.clear();
      expect(await cache.readDetails(details.id), isNull);
    });
  });

  test('StayRange import used by the summary stays consistent', () {
    final summary = _summary();
    expect(summary.stay.nights, 3);
  });
}
