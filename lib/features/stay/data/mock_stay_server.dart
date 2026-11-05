import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';
import 'package:on_air/features/bookings/domain/booking_parts.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/stay/domain/cancellation_preview.dart';
import 'package:on_air/features/stay/domain/damage_claim.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/domain/stay_results.dart';
import 'package:uuid/uuid.dart';

const _claimsFixture = 'lib/features/stay/data/fixtures/claims.json';

final class MockStayServer implements StayRepository {
  MockStayServer({
    required this.bookings,
    Future<String> Function(String path)? loader,
    this.latency = const Duration(milliseconds: 300),
    DateTime Function()? now,
  }) : _loader = loader ?? rootBundle.loadString,
       _now = now ?? _defaultNow;

  static DateTime _defaultNow() => DateTime.now().toUtc();

  final MockBookingServer bookings;
  final Future<String> Function(String path) _loader;
  final Duration latency;
  final DateTime Function() _now;
  Map<String, Map<String, dynamic>>? _claims;
  final Set<String> _termsChange = {};
  final Set<String> _termsAdjusted = {};
  final Set<String> _amountChange = {};
  final Map<String, CancellationResult> _cancelResults = {};
  final Map<String, CashRequest> _cashStarts = {};
  final Map<String, ClaimAnswerResult> _claimResults = {};
  final Map<String, OfferAnswerResult> _offerResults = {};

  bool failNextWithNetwork = false;
  bool rateLimitNextSend = false;
  int previews = 0;
  int cancels = 0;
  int checkIns = 0;
  int checkOuts = 0;
  int codesSent = 0;
  int cashConfirms = 0;
  int claimAnswers = 0;
  int offerAnswers = 0;
  Money? lastExpectedRefund;
  Money? lastExpectedAmount;
  String? lastCancelKey;
  String? lastCashStartKey;

  Future<Map<String, Map<String, dynamic>>> get claims async {
    final cached = _claims;
    if (cached != null) return cached;
    final decoded = jsonDecode(await _loader(_claimsFixture)) as List;
    return _claims = {
      for (final raw in decoded)
        if (raw is Map) raw['id'] as String: Map<String, dynamic>.from(raw),
    };
  }

  Never _fail(String code) => throw AppFailure(ErrorMapper.fromCode(code));

  Future<T> _delayed<T>(Future<T> Function() operation) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (failNextWithNetwork) {
      failNextWithNetwork = false;
      throw AppFailure(ErrorMapper.noResponse());
    }
    return operation();
  }

  Future<Map<String, dynamic>> _booking(String id) async {
    final booking = (await bookings.bookings)[id];
    if (booking == null) _fail('NOT_FOUND');
    return booking;
  }

  Map<String, dynamic> _previewMap(Map<String, dynamic> booking) =>
      Map<String, dynamic>.from(
        booking['mock_cancellation_preview'] as Map? ??
            <String, dynamic>{
              'refund_minor': booking['paid_minor'],
              'non_refundable_minor': 0,
              'policy_case': 'free',
              'free_cancellation_until': null,
            },
      );

  @override
  Future<CancellationPreview> previewCancellation(String bookingId) =>
      _delayed(() async {
        previews++;
        final booking = await _booking(bookingId);
        if (booking['status'] != 'confirmed') _fail('INVALID_BOOKING_STATE');
        _applyTermsChange(bookingId, booking);
        return CancellationPreview.fromJson({
          ..._previewMap(booking),
          'preview_token': 'mock-$previews',
          'valid_until': _now()
              .add(const Duration(minutes: 10))
              .toIso8601String(),
        });
      });

  void forceTermsChangeOnce(String bookingId) {
    _termsAdjusted.remove(bookingId);
    _termsChange.add(bookingId);
  }

  void _applyTermsChange(
    String bookingId,
    Map<String, dynamic> booking,
  ) {
    if (!_termsChange.contains(bookingId) || !_termsAdjusted.add(bookingId)) {
      return;
    }
    final preview = _previewMap(booking);
    preview['refund_minor'] = (preview['refund_minor'] as int) - 10000;
    preview['non_refundable_minor'] =
        (preview['non_refundable_minor'] as int) + 10000;
    booking['mock_cancellation_preview'] = preview;
  }

  @override
  Future<CancellationResult> cancelBooking({
    required String bookingId,
    required Money expectedRefund,
    required CancellationReason? reason,
    required String? reasonNote,
    required String idempotencyKey,
  }) => _delayed(() async {
    cancels++;
    lastExpectedRefund = expectedRefund;
    lastCancelKey = idempotencyKey;
    final previous = _cancelResults[idempotencyKey];
    if (previous != null) return previous;
    final booking = await _booking(bookingId);
    _applyTermsChange(bookingId, booking);
    final preview = _previewMap(booking);
    if (_termsChange.remove(bookingId)) {
      _fail('CANCELLATION_TERMS_CHANGED');
    }
    if (booking['status'] != 'confirmed') _fail('INVALID_BOOKING_STATE');
    if (expectedRefund.amountMinor != preview['refund_minor']) {
      _fail('CANCELLATION_TERMS_CHANGED');
    }
    final now = _now().toIso8601String();
    booking['status'] = 'cancelled';
    booking['available_actions'] = ['contact_support'];
    booking['cancellation'] = {
      'cancelled_at': now,
      'by_scope': 'guest',
      'reason_code': reason?.wire,
    };
    final refundMinor = preview['refund_minor'] as int;
    if (refundMinor > 0) {
      booking['refund'] = {
        'id': const Uuid().v4(),
        'amount_minor': refundMinor,
        'status': 'requested',
        'updated_at': now,
      };
    }
    bookings.appendEvent(
      booking,
      'booking.cancelled_by_guest',
      'cancelled',
    );
    await bookings.notifyGuest('booking.cancelled_by_guest', bookingId);
    final result = CancellationResult(
      status: 'cancelled',
      refund: booking['refund'] == null
          ? null
          : RefundInfo.fromJson(
              Map<String, dynamic>.from(booking['refund'] as Map),
            ),
    );
    _cancelResults[idempotencyKey] = result;
    return result;
  });

  @override
  Future<String> confirmCheckIn(String bookingId) => _delayed(() async {
    checkIns++;
    final booking = await _booking(bookingId);
    if (booking['status'] != 'confirmed') _fail('INVALID_BOOKING_STATE');
    if ((booking['paid_minor'] as int) < (booking['total_minor'] as int)) {
      _fail('REMAINING_NOT_PAID');
    }
    final acknowledgements = _acknowledgements(booking);
    acknowledgements['guest_checkin_at'] ??= _now().toIso8601String();
    _removeActions(booking, {'confirm_checkin', 'request_cancellation'});
    await _advance(booking);
    return booking['status'] as String;
  });

  @override
  Future<String> confirmCheckOut(String bookingId) => _delayed(() async {
    checkOuts++;
    final booking = await _booking(bookingId);
    if (booking['status'] != 'checked_in') _fail('INVALID_BOOKING_STATE');
    _acknowledgements(booking)['guest_checkout_at'] = _now().toIso8601String();
    _removeActions(booking, {'confirm_checkout'});
    await _advance(booking);
    return booking['status'] as String;
  });

  Future<void> ownerConfirmsHandover(String bookingId) => _delayed(() async {
    final booking = await _booking(bookingId);
    _acknowledgements(booking)['host_checkin_at'] ??= _now().toIso8601String();
    await _advance(booking);
    if (booking['status'] == 'confirmed') {
      await bookings.notifyGuest('stay.host_handover_confirmed', bookingId);
    }
  });

  Future<void> ownerConfirmsCheckout(
    String bookingId, {
    bool keyLeftSafe = false,
  }) => _delayed(() async {
    final booking = await _booking(bookingId);
    final acknowledgements = _acknowledgements(booking);
    acknowledgements['host_checkout_at'] = _now().toIso8601String();
    acknowledgements['key_left_safe'] = keyLeftSafe;
    await _advance(booking);
  });

  Map<String, dynamic> _acknowledgements(Map<String, dynamic> booking) {
    final current = booking['acknowledgements'];
    if (current is Map<String, dynamic>) return current;
    final created = <String, dynamic>{
      'guest_checkin_at': null,
      'host_checkin_at': null,
      'guest_checkout_at': null,
      'host_checkout_at': null,
      'key_left_safe': false,
    };
    booking['acknowledgements'] = created;
    return created;
  }

  Future<void> _advance(Map<String, dynamic> booking) async {
    final acknowledgements = _acknowledgements(booking);
    final id = booking['id'] as String;
    if (booking['status'] == 'confirmed' &&
        acknowledgements['guest_checkin_at'] != null &&
        acknowledgements['host_checkin_at'] != null) {
      booking['status'] = 'checked_in';
      booking['available_actions'] = ['confirm_checkout', 'contact_support'];
      bookings.appendEvent(booking, 'stay.checked_in', 'checked_in');
      await bookings.notifyGuest('stay.checked_in', id);
    } else if (booking['status'] == 'checked_in' &&
        acknowledgements['guest_checkout_at'] != null &&
        acknowledgements['host_checkout_at'] != null) {
      booking['status'] = 'completed';
      booking['available_actions'] = ['contact_support'];
      bookings.appendEvent(booking, 'stay.completed', 'completed');
      await bookings.notifyGuest('stay.completed', id);
    }
  }

  void changeAmountOnce(String bookingId) => _amountChange.add(bookingId);

  @override
  Future<CashRequest> startCashConfirmation({
    required String bookingId,
    required String collectorPhoneE164,
    required Money expectedAmount,
    required String idempotencyKey,
  }) => _delayed(() async {
    lastExpectedAmount = expectedAmount;
    lastCashStartKey = idempotencyKey;
    final previous = _cashStarts[idempotencyKey];
    if (previous != null) return previous;
    final booking = await _booking(bookingId);
    if (_amountChange.remove(bookingId)) {
      booking['remaining_minor'] = (booking['remaining_minor'] as int) - 12500;
    }
    if (booking['status'] != 'confirmed') _fail('INVALID_BOOKING_STATE');
    if (booking['mock_cash_allowed'] != true) _fail('CASH_NOT_ALLOWED');
    if (collectorPhoneE164 != '+201000000001') {
      _fail('COLLECTOR_NOT_AUTHORIZED');
    }
    if (expectedAmount.amountMinor != booking['remaining_minor']) {
      _fail('CASH_AMOUNT_CHANGED');
    }
    final request = <String, dynamic>{
      'payment_id': const Uuid().v4(),
      'challenge_id': const Uuid().v4(),
      'collector_display_name': 'أحمد م.',
      'amount_minor': booking['remaining_minor'],
      'masked_email': 'g***@mock.onair.test',
      'code_expires_at': _now()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
      'retry_after_seconds': 0,
      'origin': 'guest',
    };
    booking['pending_cash'] = request;
    final result = CashRequest.fromJson(request);
    _cashStarts[idempotencyKey] = result;
    return result;
  });

  @override
  Future<void> sendCashCode(String challengeId) => _delayed(() async {
    if (rateLimitNextSend) {
      rateLimitNextSend = false;
      throw const AppFailure(
        ApiError(
          code: ErrorCode.rateLimited,
          messageKey: 'authRateLimited',
          retryAfter: Duration(seconds: 30),
        ),
      );
    }
    codesSent++;
  });

  @override
  Future<CashReceipt> confirmCashPayment({
    required String paymentId,
    required String challengeId,
    required String code,
  }) => _delayed(() async {
    cashConfirms++;
    Map<String, dynamic>? booking;
    for (final candidate in (await bookings.bookings).values) {
      final cash = candidate['pending_cash'];
      if (cash is Map && cash['payment_id'] == paymentId) {
        booking = candidate;
        break;
      }
    }
    if (booking == null) _fail('NOT_FOUND');
    if (code != '123456') _fail('OTP_INVALID');
    final pending = Map<String, dynamic>.from(booking['pending_cash'] as Map);
    final now = _now().toIso8601String();
    final receipt = <String, dynamic>{
      'receipt_no': 'R-2026-${100000 + cashConfirms}',
      'collector_display_name': 'أحمد م.',
      'confirmed_at': now,
    };
    booking['payments'] = [
      ...(booking['payments'] as List? ?? const []),
      {
        'id': paymentId,
        'purpose': 'remaining',
        'method': 'cash',
        'status': 'succeeded',
        'amount_minor': pending['amount_minor'],
        'paid_at': now,
        'receipt': receipt,
      },
    ];
    booking['paid_minor'] = booking['total_minor'];
    booking['remaining_minor'] = 0;
    booking['remaining_due_at'] = null;
    booking['pending_cash'] = null;
    _removeActions(booking, {'pay_remaining', 'confirm_cash_payment'});
    await bookings.notifyGuest(
      'cash.payment_confirmed',
      paymentId,
      entityType: 'payment',
      params: {'booking_id': booking['id']},
    );
    return CashReceipt.fromJson(receipt);
  });

  Future<void> collectorRecordsCash(String bookingId) => _delayed(() async {
    final booking = await _booking(bookingId);
    booking['pending_cash'] = {
      'payment_id': const Uuid().v4(),
      'challenge_id': const Uuid().v4(),
      'collector_display_name': 'أحمد م.',
      'amount_minor': booking['remaining_minor'],
      'masked_email': 'g***@mock.onair.test',
      'code_expires_at': _now()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
      'retry_after_seconds': 0,
      'origin': 'collector',
    };
    final actions = List<String>.from(
      booking['available_actions'] as List? ?? const [],
    );
    if (!actions.contains('confirm_cash_payment')) {
      actions.add('confirm_cash_payment');
    }
    booking['available_actions'] = actions;
    await bookings.notifyGuest('cash.confirmation_requested', bookingId);
  });

  @override
  Future<DamageClaim> getDamageClaim(String claimId) => _delayed(() async {
    final claim = (await claims)[claimId];
    if (claim == null) _fail('NOT_FOUND');
    return DamageClaim.fromJson(claim);
  });

  @override
  Future<ClaimAnswerResult> respondDamageClaim({
    required String claimId,
    required ClaimDecision decision,
    required String? note,
    required String idempotencyKey,
  }) => _delayed(() async {
    claimAnswers++;
    final previous = _claimResults[idempotencyKey];
    if (previous != null) return previous;
    final claim = (await claims)[claimId];
    if (claim == null) _fail('NOT_FOUND');
    if (claim['status'] != 'open') _fail('CLAIM_ALREADY_ANSWERED');
    if (decision == ClaimDecision.dispute &&
        !ClaimLimits.validDisputeNote(note ?? '')) {
      _fail('VALIDATION_FAILED');
    }
    final status = decision == ClaimDecision.accept
        ? 'guest_accepted'
        : 'guest_disputed';
    claim['status'] = status;
    claim['support_case_number'] = decision == ClaimDecision.dispute
        ? 'SC-1001'
        : null;
    claim['guest_response'] = {
      'decision': decision.wire,
      'note': note,
      'responded_at': _now().toIso8601String(),
    };
    final booking = await _booking(claim['booking_id'] as String);
    final summaries = booking['damage_claims'] as List? ?? const [];
    for (final summary in summaries) {
      if (summary is Map && summary['id'] == claimId) {
        summary['status'] = status;
      }
    }
    if (!summaries.any((item) => item is Map && item['status'] == 'open')) {
      _removeActions(booking, {'respond_damage_claim'});
    }
    final result = ClaimAnswerResult(
      status: DamageClaimStatus.fromWire(status),
      supportCaseNumber: claim['support_case_number'] as String?,
    );
    _claimResults[idempotencyKey] = result;
    return result;
  });

  Future<void> openClaim(String bookingId) => _delayed(() async {
    final booking = await _booking(bookingId);
    final id = const Uuid().v4();
    final claim = <String, dynamic>{
      'id': id,
      'booking_id': bookingId,
      'description': 'مطالبة تجريبية.',
      'amount_minor': 25000,
      'status': 'open',
      'created_at': _now().toIso8601String(),
      'evidence': <dynamic>[],
      'guest_response': null,
      'support_case_number': null,
      'resolution': null,
    };
    (await claims)[id] = claim;
    booking['damage_claims'] = [
      ...(booking['damage_claims'] as List? ?? const []),
      {
        'id': id,
        'amount_minor': 25000,
        'status': 'open',
        'created_at': claim['created_at'],
      },
    ];
    final actions = List<String>.from(
      booking['available_actions'] as List? ?? const [],
    );
    if (!actions.contains('respond_damage_claim')) {
      actions.add('respond_damage_claim');
    }
    booking['available_actions'] = actions;
    await bookings.notifyGuest(
      'damage.claim_opened',
      id,
      entityType: 'damage_claim',
    );
  });

  @override
  Future<FileUrl> fileUrl(String attachmentId) => _delayed(
    () async => FileUrl(
      url: Uri.parse('https://files.mock.onair.test/$attachmentId.jpg'),
      expiresAt: _now().add(const Duration(minutes: 5)),
    ),
  );

  @override
  Future<OfferAnswerResult> respondReplacementOffer({
    required String offerId,
    required bool accept,
    required String idempotencyKey,
  }) => _delayed(() async {
    offerAnswers++;
    final previous = _offerResults[idempotencyKey];
    if (previous != null) return previous;
    Map<String, dynamic>? offer;
    for (final booking in (await bookings.bookings).values) {
      final candidate = booking['replacement_offer'];
      if (candidate is Map && candidate['id'] == offerId) {
        offer = Map<String, dynamic>.from(candidate);
        booking['replacement_offer'] = offer;
        break;
      }
    }
    if (offer == null) _fail('NOT_FOUND');
    if (offer['status'] != 'pending') _fail('OFFER_NOT_AVAILABLE');
    offer['status'] = accept ? 'accepted' : 'declined';
    final result = OfferAnswerResult(
      status: OfferStatus.fromWire(offer['status'] as String),
      newBookingId: null,
    );
    _offerResults[idempotencyKey] = result;
    return result;
  });

  Future<void> advanceRefund(String bookingId) => _delayed(() async {
    final booking = await _booking(bookingId);
    final raw = booking['refund'];
    if (raw is! Map) return;
    final refund = Map<String, dynamic>.from(raw);
    booking['refund'] = refund;
    final next = switch (refund['status']) {
      'requested' => 'approved',
      'approved' => 'executed',
      'executed' => 'verified',
      _ => null,
    };
    if (next == null) return;
    refund['status'] = next;
    refund['updated_at'] = _now().toIso8601String();
    final type = next == 'verified' ? 'refund.verified' : 'refund.executed';
    await bookings.notifyGuest(type, bookingId);
  });

  void _removeActions(Map<String, dynamic> booking, Set<String> removed) {
    booking['available_actions'] = [
      for (final action in booking['available_actions'] as List? ?? const [])
        if (!removed.contains(action)) action,
    ];
  }
}
