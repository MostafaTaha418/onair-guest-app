import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter/services.dart' show rootBundle;
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/notifications/domain/app_notification.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:uuid/uuid.dart';

const _fixturesRoot = 'lib/features/bookings/data/fixtures';

/// What the mock payment page decides for one attempt (quickstart scenario 5
/// and the US6 interruption cases).
enum MockPaymentResult { success, failure, conflict, silent }

/// The in-memory "server" for mock mode: it plays the backend exactly like
/// contracts/supabase-booking.md describes, so it may compute amounts and
/// statuses — the app still treats every answer as server-made.
final class MockBookingServer
    implements
        BookingsRepository,
        BookingFlowRepository,
        NotificationsRepository {
  MockBookingServer({
    required this._listings,
    required this._signals,
    Future<String> Function(String path)? loader,
    this.latency = const Duration(milliseconds: 300),
    DateTime Function()? now,
    this.startVerified = true,
    this.includeG3Fixtures = true,
  }) : _loader = loader ?? rootBundle.loadString,
       _now = now ?? _defaultNow;

  static DateTime _defaultNow() => DateTime.now().toUtc();

  final ListingsRepository _listings;
  final ControllableNotificationSignalSource _signals;
  final Future<String> Function(String path) _loader;
  final Duration latency;
  final DateTime Function() _now;
  final bool startVerified;
  final bool includeG3Fixtures;

  /// Test hook: shorten the quote TTL to exercise expiry (quickstart 13).
  Duration? quoteTtl;

  Map<String, Map<String, dynamic>>? _bookings;
  List<Map<String, dynamic>>? _notifications;
  final Map<String, BookingQuote> _quotes = {};
  final Map<String, bool> _quoteUsed = {};
  final Map<String, int> _sessionsPerKey = {};
  final Map<String, PaymentSessionInfo> _sessionForKey = {};
  final Map<String, PaymentSessionInfo> _sessionForBooking = {};
  var _bookingCounter = 0;
  int remainingStarts = 0;

  Future<void> _delay() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }

  Never _fail(String code) => throw AppFailure(ErrorMapper.fromCode(code));

  DateOnly _today() => CairoTime.today(now: _now());

  Future<Map<String, Map<String, dynamic>>> get bookings async {
    final cached = _bookings;
    if (cached != null) return cached;
    final decoded = <dynamic>[
      ...(jsonDecode(await _loader('$_fixturesRoot/bookings.json')) as List),
      if (includeG3Fixtures)
        ...(jsonDecode(await _loader('$_fixturesRoot/bookings_g3.json'))
            as List),
    ];
    return _bookings = {
      for (final raw in decoded)
        if (raw is Map) raw['id'] as String: Map<String, dynamic>.from(raw),
    };
  }

  Future<List<Map<String, dynamic>>> get notifications async =>
      _notifications ??= [
        for (final raw
            in (jsonDecode(
                  await _loader('$_fixturesRoot/notifications.json'),
                )
                as List))
          Map<String, dynamic>.from(raw as Map),
      ];

  // -- BookingsRepository ----------------------------------------------------

  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) =>
      _delayed(() async {
        final offset = _parseCursor(cursor);
        final all = await bookings;
        final sorted = _sortedIdsFor(tab, all);
        final page = sorted.skip(offset).take(20).toList();
        return BookingsPage(
          items: [
            for (final id in page) _summaryOf(id, all[id]!),
          ],
          nextCursor: offset + 20 < sorted.length ? '${offset + 20}' : null,
        );
      });

  List<String> _sortedIdsFor(
    BookingTab tab,
    Map<String, Map<String, dynamic>> all,
  ) {
    bool has(String id, Set<String> statuses) =>
        statuses.contains(all[id]!['status']);
    final ids = [
      for (final entry in all.entries)
        if (switch (tab) {
          BookingTab.current => has(entry.key, {
            'payment_verifying',
            'awaiting_owner',
            'confirmed',
            'checked_in',
          }),
          BookingTab.past => has(entry.key, {'completed'}),
          BookingTab.cancelled => has(entry.key, {
            'rejected',
            'expired',
            'cancelled',
            'no_show',
            'payment_conflict',
          }),
          BookingTab.pending => has(entry.key, {'payment_pending'}),
        })
          entry.key,
    ];
    switch (tab) {
      case BookingTab.current:
        ids.sort(
          (a, b) => (all[a]!['check_in'] as String).compareTo(
            all[b]!['check_in'] as String,
          ),
        );
      case BookingTab.past:
        ids.sort(
          (a, b) => (all[b]!['check_out'] as String).compareTo(
            all[a]!['check_out'] as String,
          ),
        );
      case BookingTab.cancelled || BookingTab.pending:
        ids.sort(
          (a, b) => (all[b]!['created_at'] as String).compareTo(
            all[a]!['created_at'] as String,
          ),
        );
    }
    return ids;
  }

  BookingSummary _summaryOf(String id, Map<String, dynamic> json) {
    final property = Map<String, dynamic>.from(json['property'] as Map);
    final refund = json['refund'] as Map<String, dynamic>?;
    return BookingSummary.fromJson({
      'id': id,
      'code': json['code'],
      'property_id': property['id'],
      'title': property['title'],
      'cover_image': property['cover_image'],
      'check_in': json['check_in'],
      'check_out': json['check_out'],
      'status': json['status'],
      'refund_status': refund?['status'],
      'owner_response_deadline': json['owner_response_deadline'],
      'created_at': json['created_at'],
      'available_actions': json['available_actions'],
    });
  }

  @override
  Future<BookingDetails> getBooking(String bookingId) => _delayed(() async {
    final all = await bookings;
    final json = all[bookingId];
    if (json == null) _fail('NOT_FOUND');
    final status = json['status'] as String;
    final visible =
        status == 'confirmed' ||
        status == 'checked_in' ||
        status == 'completed';
    return BookingDetails.fromJson({
      ...json,
      'access_instructions': visible ? json['access_instructions'] : null,
    });
  });

  // -- BookingFlowRepository -------------------------------------------------

  // The booking-flow phone challenge is gone (S005 US6): the flow only
  // reads the canned confirmation status.
  @override
  Future<VerificationStatus> verificationStatus() => _delayed(() {
    return VerificationStatus(
      emailConfirmed: startVerified,
      phoneConfirmed: startVerified,
      email: 'guest@mock.onair.test',
      phone: '+201000000001',
    );
  });

  @override
  Future<BookingQuote> quote({
    required String propertyId,
    required StayRange stay,
    required int guests,
    required String termsHash,
  }) => _delayed(() async {
    final details = await _listings.property(propertyId);
    final today = _today();
    if (stay.checkIn.isBefore(today) ||
        !stay.checkOut.isAfter(stay.checkIn) ||
        stay.nights > 90) {
      _fail('VALIDATION_FAILED');
    }
    if (guests < 1 || guests > details.maxGuests) {
      _fail('GUESTS_EXCEEDED');
    }
    if (termsHash != details.termsVersion) {
      _fail('TERMS_CHANGED');
    }
    final unavailable = await _listings.unavailableNights(
      propertyId,
      stay.checkIn,
      stay.checkOut,
    );
    if (!stay.isSelectable(unavailable)) {
      _fail('DATES_UNAVAILABLE');
    }
    final nights = stay.nights;
    // The mock plays the server, so it computes the amounts the real RPC
    // returns; the app still never derives any of them.
    final total = details.nightlyPrice.amountMinor * nights;
    final payNow = switch (details.policy.depositType) {
      DepositType.percent => _ceilDiv(
        total * details.policy.depositPercentBp!,
        10000,
      ),
      DepositType.fixed => min(
        total,
        details.policy.depositAmount!.amountMinor,
      ),
      DepositType.full => total,
    };
    final quote = BookingQuote(
      quoteId: 'q-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}',
      propertyId: propertyId,
      stay: stay,
      nights: nights,
      guests: guests,
      nightly: Money(details.nightlyPrice.amountMinor),
      total: Money(total),
      payNow: Money(payNow),
      remaining: Money(total - payNow),
      remainingDueAt: payNow < total
          ? DateTime.parse('${stay.checkIn.addDays(-1)}T22:00:00Z')
          : null,
      termsHash: termsHash,
      policySummary: details.policy,
      expiresAt: _now().add(quoteTtl ?? const Duration(minutes: 15)),
    );
    _quotes[quote.quoteId] = quote;
    _quoteUsed[quote.quoteId] = false;
    return quote;
  });

  @override
  Future<PaymentSessionInfo> startPayment({
    required String quoteId,
    required String termsHash,
    required String attemptKey,
  }) => _delayed(() async {
    final quote = _quotes[quoteId];
    if (quote == null || _now().isAfter(quote.expiresAt)) {
      _fail('QUOTE_EXPIRED');
    }
    final existing = _sessionForKey[attemptKey];
    if (existing != null) {
      return existing;
    }
    if (_quoteUsed[quoteId]!) {
      // The quote was already turned into a booking with another key.
      _fail('QUOTE_EXPIRED');
    }
    if (termsHash != quote.termsHash) {
      _fail('TERMS_CHANGED');
    }
    final status = await verificationStatus();
    if (!status.isComplete) {
      _fail('PHONE_NOT_VERIFIED');
    }
    final bookingId = _newBookingId();
    await _createPendingBooking(quote, bookingId);
    _quoteUsed[quoteId] = true;
    _sessionsPerKey[attemptKey] = 1;
    final session = PaymentSessionInfo(
      bookingId: bookingId,
      paymentId: _randomId('p'),
      paymentUrl: Uri.parse('https://pay.mock.onair.test/session/$bookingId'),
      paymentUrlExpiresAt: _now().add(const Duration(minutes: 30)),
    );
    _sessionForKey[attemptKey] = session;
    _sessionForBooking[bookingId] = session;
    return session;
  });

  @override
  Future<PaymentSessionInfo> startRemainingPayment({
    required String bookingId,
    required String attemptKey,
  }) => _delayed(() async {
    remainingStarts++;
    final all = await bookings;
    final json = all[bookingId];
    if (json == null) _fail('NOT_FOUND');
    if (json['status'] != 'confirmed' ||
        (json['remaining_minor'] as int) <= 0) {
      _fail('INVALID_BOOKING_STATE');
    }
    final existing = _sessionForKey[attemptKey];
    if (existing != null) return existing;
    final payments = (json['payments'] as List<dynamic>?) ?? <dynamic>[];
    if (payments.any((raw) {
      final line = raw as Map;
      return line['purpose'] == 'remaining' && line['status'] == 'pending';
    })) {
      _fail('CONFLICT');
    }
    final paymentId = _randomId('r');
    payments.add(<String, dynamic>{
      'id': paymentId,
      'purpose': 'remaining',
      'method': 'kashier',
      'status': 'pending',
      'amount_minor': json['remaining_minor'],
      'paid_at': null,
    });
    json['payments'] = payments;
    json['pending_remaining_payment_id'] = paymentId;
    final session = PaymentSessionInfo(
      bookingId: bookingId,
      paymentId: paymentId,
      paymentUrl: Uri.parse(
        'https://pay.mock.onair.test/remaining/$bookingId',
      ),
      paymentUrlExpiresAt: _now().add(const Duration(minutes: 30)),
    );
    _sessionForKey[attemptKey] = session;
    _sessionForBooking[bookingId] = session;
    return session;
  });

  /// How many payment sessions one attempt key created; always 0 or 1
  /// (AC-023: retries reuse the same session).
  int sessionCount(String key) => _sessionsPerKey[key] ?? 0;

  Future<void> _createPendingBooking(
    BookingQuote quote,
    String bookingId,
  ) async {
    final details = await _listings.property(quote.propertyId);
    final now = _now().toIso8601String();
    (await bookings)[bookingId] = {
      'id': bookingId,
      'code': 'OA-MOCK${(++_bookingCounter).toString().padLeft(3, '0')}',
      'status': 'payment_pending',
      'property': _propertyJson(details),
      'check_in': quote.stay.checkIn.toString(),
      'check_out': quote.stay.checkOut.toString(),
      'nights': quote.nights,
      'guests_count': quote.guests,
      'nightly_minor': quote.nightly.amountMinor,
      'total_minor': quote.total.amountMinor,
      'pay_now_minor': quote.payNow.amountMinor,
      'paid_minor': 0,
      'remaining_minor': quote.remaining.amountMinor,
      'remaining_due_at': quote.remainingDueAt?.toIso8601String(),
      'currency': 'EGP',
      'owner_response_deadline': null,
      'payment_state': 'pending',
      'payments': <Object>[],
      'refund': null,
      'terms_snapshot': quote.policySummary == null
          ? null
          : {
              'policy_summary': {
                'deposit_type': quote.policySummary!.depositType.name,
                'deposit_percent_bp': quote.policySummary!.depositPercentBp,
                'deposit_amount_minor':
                    quote.policySummary!.depositAmount?.amountMinor,
                'free_cancellation_hours':
                    quote.policySummary!.freeCancellationHours,
              },
            },
      'access_instructions': null,
      'available_actions': ['contact_support'],
      'events': [
        {
          'event_type': 'booking.started',
          'to_status': 'payment_pending',
          'created_at': now,
          'note': null,
        },
      ],
      'created_at': now,
    };
  }

  Map<String, dynamic> _propertyJson(PropertyDetails details) => {
    'id': details.id,
    'title': details.title,
    'cover_image': details.images.isEmpty
        ? null
        : {
            'variants': [
              for (final variant in details.images.first.variants)
                {'width': variant.width, 'url': variant.url.toString()},
            ],
            'blurhash': details.images.first.blurhash,
          },
    'area_name': details.areaName,
    'city_name': details.cityName,
    'address_text': details.addressText,
    'check_in_time': details.rules.checkInTime,
    'check_out_time': details.rules.checkOutTime,
  };

  // -- Test and mock-page controls -------------------------------------------

  /// Applies the outcome the mock payment page chose, then (after
  /// [signalDelay]) emits the matching notification signal — never for
  /// [MockPaymentResult.silent].
  Future<void> completePayment(
    String bookingId,
    MockPaymentResult result, {
    Duration signalDelay = Duration.zero,
  }) => _delayed(() async {
    final all = await bookings;
    final json = all[bookingId];
    if (json == null) _fail('NOT_FOUND');
    final now = _now();
    final session = _sessionForBooking[bookingId];
    final payments = (json['payments'] as List<dynamic>?) ?? <dynamic>[];
    Map<dynamic, dynamic>? remainingLine;
    for (final raw in payments) {
      final line = raw as Map<dynamic, dynamic>;
      if (line['purpose'] == 'remaining' && line['status'] == 'pending') {
        remainingLine = line;
        break;
      }
    }
    if (remainingLine != null) {
      switch (result) {
        case MockPaymentResult.success:
          remainingLine['status'] = 'succeeded';
          remainingLine['paid_at'] = now.toIso8601String();
          json['paid_minor'] = json['total_minor'];
          json['remaining_minor'] = 0;
          json['remaining_due_at'] = null;
          json['pending_remaining_payment_id'] = null;
          final actions =
              List<String>.from(
                (json['available_actions'] as List<dynamic>?) ?? const [],
              )..removeWhere(
                (action) =>
                    action == 'pay_remaining' ||
                    action == 'confirm_cash_payment',
              );
          final checkIn = DateOnly.parse(json['check_in'] as String);
          if (!checkIn.isAfter(_today()) &&
              !actions.contains('confirm_checkin')) {
            actions.insert(0, 'confirm_checkin');
          }
          json['available_actions'] = actions;
          appendEvent(json, 'payment.remaining_paid', 'confirmed');
          await notifyGuest('payment.remaining_paid', bookingId);
        case MockPaymentResult.failure:
          remainingLine['status'] = 'failed';
          json['pending_remaining_payment_id'] = null;
          await notifyGuest('payment.failed', bookingId);
        case MockPaymentResult.conflict || MockPaymentResult.silent:
          break;
      }
      return;
    }
    switch (result) {
      case MockPaymentResult.success:
        json['status'] = 'awaiting_owner';
        json['payment_state'] = 'succeeded';
        json['owner_response_deadline'] = now
            .add(const Duration(hours: 24))
            .toIso8601String();
        json['paid_minor'] = json['pay_now_minor'];
        json['payments'] = [
          {
            'id': _randomId('c'),
            'purpose': 'initial',
            'method': 'kashier',
            'status': 'succeeded',
            'amount_minor': json['pay_now_minor'],
            'paid_at': now.toIso8601String(),
          },
        ];
        appendEvent(json, 'booking.request_received', 'awaiting_owner');
        await notifyGuest(
          'booking.request_received',
          bookingId,
          signalDelay: signalDelay,
        );
      case MockPaymentResult.failure:
        json['status'] = 'payment_pending';
        json['payment_state'] = 'failed';
        json['payments'] = [
          {
            'id': _randomId('c'),
            'purpose': 'initial',
            'method': 'kashier',
            'status': 'failed',
            'amount_minor': json['pay_now_minor'],
            'paid_at': null,
          },
        ];
        appendEvent(json, 'payment.failed', 'payment_pending');
        await notifyGuest(
          'payment.failed',
          bookingId,
          signalDelay: signalDelay,
        );
      case MockPaymentResult.conflict:
        json['status'] = 'payment_conflict';
        json['payment_state'] = 'succeeded';
        json['paid_minor'] = json['pay_now_minor'];
        json['refund'] = {
          'id': _randomId('d'),
          'amount_minor': json['pay_now_minor'],
          'status': 'requested',
          'updated_at': now.toIso8601String(),
        };
        appendEvent(json, 'booking.payment_conflict', 'payment_conflict');
        await notifyGuest(
          'booking.payment_conflict',
          bookingId,
          signalDelay: signalDelay,
        );
      case MockPaymentResult.silent:
        json['status'] = 'payment_verifying';
    }
    // Keep the session bookkeeping so a retry still finds the same booking.
    if (session != null) {
      _sessionForKey[session.bookingId] = session;
    }
  });

  void appendEvent(Map<String, dynamic> json, String type, String toStatus) {
    json['events'] = [
      ...?((json['events'] as List?)?.cast<Map<String, dynamic>>()),
      <String, dynamic>{
        'event_type': type,
        'to_status': toStatus,
        'created_at': _now().toIso8601String(),
        'note': null,
      },
    ];
  }

  Future<void> notifyGuest(
    String typeKey,
    String entityId, {
    String entityType = 'booking',
    Map<String, dynamic> params = const {},
    Duration signalDelay = Duration.zero,
  }) async {
    (await notifications).insert(0, {
      'id': _randomId('e'),
      'type_key': typeKey,
      'category': 'booking',
      'priority': 'normal',
      'entity_type': entityType,
      'entity_id': entityId,
      'title_key': typeKey,
      'body_key': typeKey,
      'params': params,
      'read_at': null,
      'created_at': _now().toIso8601String(),
    });
    Future<void> emit() async {
      if (signalDelay > Duration.zero) {
        await Future<void>.delayed(signalDelay);
      }
      _signals.emit(
        NotificationSignal(
          id: typeKey,
          typeKey: typeKey,
          entityType: entityType,
          entityId: entityId,
        ),
      );
    }

    if (signalDelay == Duration.zero) {
      await emit();
    } else {
      unawaited(emit());
    }
  }

  /// Direct status change for tests (the verification-cubit cases).
  void setStatus(String bookingId, String status) {
    _bookings?[bookingId]?['status'] = status;
  }

  // -- NotificationsRepository ------------------------------------------------

  @override
  Future<List<AppNotification>> list({DateTime? before, int limit = 30}) =>
      _delayed(() async {
        final rows = await notifications;
        return [
          for (final row in rows)
            if (before == null ||
                DateTime.parse(row['created_at'] as String).isBefore(before))
              AppNotification.fromJson(row),
        ].take(limit).toList();
      });

  @override
  Future<int> unreadCount() => _delayed(() async {
    final rows = await notifications;
    return rows.where((row) => row['read_at'] == null).length;
  });

  @override
  Future<void> markRead(List<String>? ids) => _delayed(() async {
    final rows = await notifications;
    for (final row in rows) {
      if (ids == null || ids.contains(row['id'])) {
        row['read_at'] = _now().toIso8601String();
      }
    }
  });

  // -- helpers ---------------------------------------------------------------

  Future<T> _delayed<T>(FutureOr<T> Function() action) async {
    await _delay();
    return action();
  }

  int _parseCursor(String? cursor) {
    if (cursor == null) return 0;
    final offset = int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw AppFailure(ErrorMapper.fromCode('VALIDATION_FAILED'));
    }
    return offset;
  }

  int _ceilDiv(int value, int divisor) => (value / divisor).ceil();

  // Every dynamic id is a UUID v4: booking ids from links and payloads are
  // format-validated by the app (Constitution IV).
  static const _uuid = Uuid();

  String _newBookingId() => _uuid.v4();

  String _randomId(String _) => _uuid.v4();
}
