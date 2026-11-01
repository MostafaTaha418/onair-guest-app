import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/bookings_cubit.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

/// Delegates to the mock server but records every list request.
final class RecordingBookings implements BookingsRepository {
  RecordingBookings(this._inner);

  final BookingsRepository _inner;
  final List<BookingTab> requestedTabs = [];

  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) async {
    requestedTabs.add(tab);
    return _inner.listBookings(tab, cursor: cursor);
  }

  @override
  Future<BookingDetails> getBooking(String bookingId) =>
      _inner.getBooking(bookingId);
}

/// A first page plus a second page that can be held on purpose, to observe
/// the in-flight pagination state and the concurrent-loadMore guard.
final class TwoPageBookings implements BookingsRepository {
  TwoPageBookings(this._first, this._second);

  final BookingsPage _first;
  final BookingsPage _second;
  int calls = 0;
  Completer<void>? holdSecondPage;

  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) async {
    calls++;
    if (cursor == null) return _first;
    final hold = holdSecondPage;
    if (hold != null) await hold.future;
    return _second;
  }

  @override
  Future<BookingDetails> getBooking(String bookingId) =>
      throw UnimplementedError();
}

BookingSummary _summary(String id, {String status = 'confirmed'}) =>
    BookingSummary.fromJson({
      'id': id,
      'code': 'OA-MOCK999',
      'property_id': '00000000-0000-4000-8000-00000000001f',
      'title': 'شقة مخبأة',
      'cover_image': null,
      'check_in': '2026-11-20',
      'check_out': '2026-11-23',
      'status': status,
      'refund_status': null,
      'owner_response_deadline': null,
      'created_at': '2026-10-20T01:00:00Z',
    });

BookingsPage _page(List<BookingSummary> items, {String? nextCursor}) =>
    BookingsPage(items: items, nextCursor: nextCursor);

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;

  setUp(() {
    backend = FakeBookingBackend();
    connectivity = FakeConnectivity();
  });

  tearDown(() {
    backend.dispose();
    connectivity.dispose();
  });

  BookingsCubit buildCubit({
    BookingsRepository? bookings,
    ConnectivityCubit? connectivityCubit,
  }) => BookingsCubit(
    bookings: bookings ?? backend.server,
    cache: backend.cache,
    connectivity: connectivityCubit ?? connectivity.createCubit(),
  );

  test(
    'start shows the cached page first, then the server page, and caches it',
    () async {
      await backend.cache.saveTab(BookingTab.current, [_summary('b2')]);
      final cubit = buildCubit();
      final emissions = <TabData>[];
      final subscription = cubit.stream.listen(
        (state) => emissions.add(state.tabs[BookingTab.current]!),
      );

      await cubit.start(BookingTab.current);
      await _flush(); // stream events are delivered asynchronously
      await subscription.cancel();

      final shown = emissions.where((data) => data.load != TabLoad.initial);
      expect(shown.first.fromCache, isTrue);
      expect(shown.first.items.single.id, 'b2');
      expect(shown.last.fromCache, isFalse);
      expect(emissions.last.load, TabLoad.ready);
      expect(emissions.last.fetchedAt, isNotNull);

      final cached = await backend.cache.readTab(BookingTab.current);
      expect(
        cached!.items.map((b) => b.id).toList(),
        emissions.last.items.map((b) => b.id).toList(),
      );
      await cubit.close();
    },
  );

  test('tabs load only when selected; a loaded tab is not refetched', () async {
    final recording = RecordingBookings(backend.server);
    final cubit = buildCubit(bookings: recording);
    await cubit.start(BookingTab.current);
    expect(recording.requestedTabs, [BookingTab.current]);

    await cubit.selectTab(BookingTab.past);
    expect(recording.requestedTabs, [BookingTab.current, BookingTab.past]);
    expect(cubit.state.selected, BookingTab.past);
    expect(cubit.state.tabs[BookingTab.past]!.load, TabLoad.ready);

    await cubit.selectTab(BookingTab.current);
    expect(
      recording.requestedTabs,
      [BookingTab.current, BookingTab.past],
      reason: 'an already-loaded tab never refetches',
    );
    await cubit.close();
  });

  test(
    'loadMore appends the next page and a concurrent call is ignored',
    () async {
      final twoPages = TwoPageBookings(
        _page([_summary('b1')], nextCursor: '1'),
        _page([_summary('b2')]),
      );
      final cubit = buildCubit(bookings: twoPages);
      await cubit.start(BookingTab.current);
      expect(cubit.state.tabs[BookingTab.current]!.items.single.id, 'b1');

      twoPages.holdSecondPage = Completer<void>();
      final inFlight = cubit.loadMore();
      expect(cubit.state.tabs[BookingTab.current]!.loadingMore, isTrue);

      await cubit.loadMore(); // ignored: one pagination at a time
      twoPages.holdSecondPage!.complete();
      await inFlight;
      await _flush();

      final data = cubit.state.tabs[BookingTab.current]!;
      expect(data.items.map((b) => b.id).toList(), ['b1', 'b2']);
      expect(data.nextCursor, isNull);
      expect(data.loadingMore, isFalse);
      expect(twoPages.calls, 2);
      await cubit.close();
    },
  );

  test('loadMore stops when the server has no next page', () async {
    final recording = RecordingBookings(backend.server);
    final cubit = buildCubit(bookings: recording);
    await cubit.start(BookingTab.current);
    final before = recording.requestedTabs.length;

    await cubit.loadMore();
    expect(recording.requestedTabs.length, before);
    expect(cubit.state.tabs[BookingTab.current]!.nextCursor, isNull);
    await cubit.close();
  });

  test(
    'offline with a cache shows it; offline without one is offline',
    () async {
      // One connectivity cubit shared by both: a broadcast flip is never
      // replayed to a later subscriber.
      final conn = connectivity.createCubit();
      connectivity.goOffline();
      await _flush();

      final offlineEmpty = buildCubit(connectivityCubit: conn);
      await offlineEmpty.start(BookingTab.current);
      expect(
        offlineEmpty.state.tabs[BookingTab.current]!.load,
        TabLoad.offline,
      );
      await offlineEmpty.close();

      await backend.cache.saveTab(BookingTab.current, [_summary('b2')]);
      final offlineCached = buildCubit(connectivityCubit: conn);
      await offlineCached.start(BookingTab.current);
      final data = offlineCached.state.tabs[BookingTab.current]!;
      expect(data.load, TabLoad.ready);
      expect(data.fromCache, isTrue);
      expect(data.items.single.id, 'b2');
      expect(data.fetchedAt, isNotNull);
      await offlineCached.close();
    },
  );

  test('the cubit never sorts or filters the server list', () async {
    final cubit = buildCubit();
    await cubit.start(BookingTab.current);
    final server = await backend.server.listBookings(BookingTab.current);
    expect(
      cubit.state.tabs[BookingTab.current]!.items.map((b) => b.id).toList(),
      server.items.map((b) => b.id).toList(),
      reason: "the order and membership are exactly the server's",
    );
    await cubit.close();
  });
}
