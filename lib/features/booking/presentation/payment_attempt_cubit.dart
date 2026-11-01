import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/payments/in_app_browser.dart';
import 'package:on_air/features/booking/data/payment_attempt_store.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/domain/payment_attempt.dart';
import 'package:uuid/uuid.dart';

sealed class PaymentAttemptState {
  const PaymentAttemptState();
}

final class AttemptIdle extends PaymentAttemptState {
  const AttemptIdle();
}

final class AttemptStarting extends PaymentAttemptState {
  const AttemptStarting(this.attempt);

  final PaymentAttempt attempt;
}

final class AttemptOpened extends PaymentAttemptState {
  const AttemptOpened(this.attempt);

  final PaymentAttempt attempt;
}

/// The guest already reached the verification screen for this attempt:
/// a resume must not pull them there again (US6).
final class AttemptReturned extends PaymentAttemptState {
  const AttemptReturned(this.attempt);

  final PaymentAttempt attempt;
}

final class AttemptFailed extends PaymentAttemptState {
  const AttemptFailed(this.error, this.attempt);

  final ApiError error;
  final PaymentAttempt? attempt;
}

/// App-scoped (one instance for the whole app, research R5): the open
/// attempt survives navigation and app resume. The app never sends an
/// amount, and a sent start request is never cancelled (Constitution III).
final class PaymentAttemptCubit extends Cubit<PaymentAttemptState> {
  PaymentAttemptCubit({
    required this._flow,
    required this._store,
    required this._browser,
    required this._logger,
    String Function()? newKey,
    DateTime Function()? now,
  }) : _newKey = newKey ?? _defaultKey,
       _now = now ?? (() => DateTime.now().toUtc()),
       super(const AttemptIdle());

  static const Uuid _uuid = Uuid();

  static String _defaultKey() => _uuid.v4();

  final BookingFlowRepository _flow;
  final PaymentAttemptStore _store;
  final InAppBrowser Function() _browser;
  final AppLogger _logger;
  final String Function() _newKey;
  final DateTime Function() _now;
  bool _starting = false;

  /// Restores the record saved before a killed app (US6). An attempt the
  /// app never started (no booking id) stays idle — the unfinished-payment
  /// banner handles a cold start, and the next `pay()` reuses its key.
  Future<void> restore() async {
    final attempt = await _store.read();
    if (isClosed || attempt == null) return;
    if (attempt.bookingId == null) return;
    emit(AttemptReturned(attempt));
  }

  /// The verification screen was reached for the open attempt (US6).
  void markReturned() {
    final state = this.state;
    if (state is AttemptOpened) emit(AttemptReturned(state.attempt));
  }

  /// Follows the store after another component (the unfinished-payment
  /// reconciliation) cleared a stale attempt. Never loops: it emits nothing
  /// when the state is already idle.
  Future<void> syncWithStore() async {
    final stored = await _store.read();
    if (isClosed || stored != null) return;
    if (state is AttemptOpened || state is AttemptReturned) {
      emit(const AttemptIdle());
    }
  }

  Future<void> pay(BookingQuote quote) async {
    if (state is AttemptStarting || _starting) return;
    _starting = true;
    try {
      final stored = await _store.read();
      final attempt = stored != null && stored.quoteId == quote.quoteId
          ? stored
          : PaymentAttempt(
              attemptKey: _newKey(),
              quoteId: quote.quoteId,
              propertyId: quote.propertyId,
              termsHash: quote.termsHash,
              startedAt: _now(),
            );
      // Saved before the request: a kill mid-flight still finds the key.
      await _store.save(attempt);
      if (isClosed) return;
      emit(AttemptStarting(attempt));
      final session = await _flow.startPayment(
        quoteId: quote.quoteId,
        termsHash: quote.termsHash,
        attemptKey: attempt.attemptKey,
      );
      final opened = attempt.copyWith(
        bookingId: session.bookingId,
        paymentUrl: session.paymentUrl.toString(),
        paymentUrlExpiresAt: session.paymentUrlExpiresAt,
      );
      await _store.save(opened);
      if (isClosed) return;
      _logger.info(
        'payment_started booking=${session.bookingId} '
        'key=${attempt.attemptKey.substring(0, 8)}',
      );
      emit(AttemptOpened(opened));
      await _browser().open(
        session.paymentUrl,
        bookingId: session.bookingId,
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      final attempt = await _store.read();
      emit(AttemptFailed(failure.error, attempt));
    } finally {
      _starting = false;
    }
  }

  /// Reopens the Kashier page while the session is still valid (iOS
  /// fallback, research R4).
  Future<void> reopenPage() async {
    final state = this.state;
    if (state is! AttemptOpened) return;
    final url = state.attempt.paymentUrl;
    final expiresAt = state.attempt.paymentUrlExpiresAt;
    if (url == null || expiresAt == null || !expiresAt.isAfter(_now())) {
      return;
    }
    await _browser().open(Uri.parse(url), bookingId: state.attempt.bookingId!);
  }

  /// The server confirmed a final outcome: the record goes.
  Future<void> finish() async {
    await _store.clear();
    if (isClosed) return;
    emit(const AttemptIdle());
  }

  /// «Try again»: a new attempt (and a new key) replaces the old one.
  Future<void> newAttempt() => finish();
}
