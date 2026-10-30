import 'package:flutter/foundation.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';

/// What the guest wanted to do before sign-in interrupted them
/// (data-model "Navigation intent", research R10).
enum ResumeAction { book, contact }

/// The carried-over intent, encoded in the `/property/:id` query:
/// `resume=book|contact`, `checkIn`/`checkOut`, `guests`, and — for book —
/// the `terms` version the guest actually saw (AC-013). Consumed once: the
/// screen strips the resume keys from its location before acting.
@immutable
final class ResumeIntent {
  const ResumeIntent({
    required this.action,
    required this.stay,
    required this.guests,
    required this.termsVersion,
  });

  final ResumeAction action;

  /// The picked stay; null when the guest had not picked dates.
  final StayRange? stay;
  final int? guests;

  /// Opaque; set only for `book` (1–128 characters).
  final String? termsVersion;

  /// Null when the query does not describe a resumable intent: an unknown
  /// action, or `book` without 1–128-character terms.
  static ResumeIntent? fromQuery(
    Map<String, String> query, {
    required DateOnly today,
  }) {
    final parsedAction = switch (query['resume']) {
      'book' => ResumeAction.book,
      'contact' => ResumeAction.contact,
      _ => null,
    };
    if (parsedAction == null) return null;
    final action = parsedAction;
    String? termsVersion;
    if (action == ResumeAction.book) {
      final terms = query['terms'];
      if (terms == null || terms.isEmpty || terms.length > 128) return null;
      termsVersion = terms;
    }
    final stay = StayRange.tryCreate(
      DateOnly.tryParse(query['checkIn']),
      DateOnly.tryParse(query['checkOut']),
      today,
    );
    final guestsRaw = int.tryParse(query['guests'] ?? '');
    final guests = guestsRaw != null && guestsRaw >= 1 && guestsRaw <= 50
        ? guestsRaw
        : null;
    return ResumeIntent(
      action: action,
      stay: stay,
      guests: guests,
      termsVersion: termsVersion,
    );
  }

  /// The same location without `resume` and `terms`, so Back never
  /// re-triggers the intent; `checkIn`, `checkOut`, and `guests` survive.
  static Uri stripFrom(Uri location) {
    final queryParameters = {...location.queryParameters}
      ..remove('resume')
      ..remove('terms');
    return Uri(
      path: location.path,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ResumeIntent &&
      other.action == action &&
      other.stay == stay &&
      other.guests == guests &&
      other.termsVersion == termsVersion;

  @override
  int get hashCode => Object.hash(action, stay, guests, termsVersion);
}
