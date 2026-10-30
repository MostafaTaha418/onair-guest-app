import 'package:flutter/foundation.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';

/// The fields a re-quote may change (data-model §3). The quote id and the
/// expiry are deliberately absent: a fresh quote for the same stay is not a
/// price change.
enum QuoteField { nightly, total, payNow, remaining, remainingDueAt, termsHash }

/// Field-by-field comparison of two server quotes (research R7). Pure
/// comparison: the diff never creates a computed amount — the summary
/// highlights the changed rows and requires an explicit confirmation before
/// payment (FR-009). No computed amount is produced here.
@immutable
final class QuoteChange {
  const QuoteChange({
    required this.previous,
    required this.next,
    required this.changedFields,
  });

  factory QuoteChange.between(BookingQuote previous, BookingQuote next) {
    final changed = <QuoteField>{};
    if (previous.nightly != next.nightly) changed.add(QuoteField.nightly);
    if (previous.total != next.total) changed.add(QuoteField.total);
    if (previous.payNow != next.payNow) changed.add(QuoteField.payNow);
    if (previous.remaining != next.remaining) {
      changed.add(QuoteField.remaining);
    }
    if (previous.remainingDueAt != next.remainingDueAt) {
      changed.add(QuoteField.remainingDueAt);
    }
    if (previous.termsHash != next.termsHash) {
      changed.add(QuoteField.termsHash);
    }
    return QuoteChange(
      previous: previous,
      next: next,
      changedFields: changed,
    );
  }

  final BookingQuote previous;
  final BookingQuote next;
  final Set<QuoteField> changedFields;

  bool get hasChanges => changedFields.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is QuoteChange &&
      other.previous == previous &&
      other.next == next &&
      setEquals(other.changedFields, changedFields);

  @override
  int get hashCode =>
      Object.hash(previous, next, Object.hashAll(changedFields));
}
