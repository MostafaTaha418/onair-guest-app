import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/booking/domain/verification_outcome.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';

Future<Map<String, dynamic>> _fixture() async {
  final rows =
      jsonDecode(
            await File(
              'lib/features/bookings/data/fixtures/bookings_g3.json',
            ).readAsString(),
          )
          as List<dynamic>;
  return Map<String, dynamic>.from(
    rows.firstWhere(
          (row) =>
              (row as Map<String, dynamic>)['id'].toString().endsWith('020'),
        )
        as Map,
  );
}

Future<BookingDetails> _detailsWith(String? status) async {
  final json = await _fixture();
  json['status'] = 'confirmed';
  json['payments'] = status == null
      ? <Object>[]
      : <Object>[
          {
            'id': 'p1',
            'purpose': 'remaining',
            'method': 'kashier',
            'status': status,
            'amount_minor': json['remaining_minor'],
            'paid_at': null,
          },
        ];
  return BookingDetails.fromJson(json);
}

void main() {
  test('remaining outcome follows only the matching payment line', () async {
    for (final (status, expected) in <(String?, VerificationOutcome)>[
      ('succeeded', VerificationOutcome.success),
      ('failed', VerificationOutcome.failed),
      ('cancelled', VerificationOutcome.failed),
      ('expired', VerificationOutcome.failed),
      ('pending', VerificationOutcome.waiting),
      ('verifying', VerificationOutcome.waiting),
      (null, VerificationOutcome.waiting),
    ]) {
      expect(
        remainingOutcomeFor('p1')(await _detailsWith(status)),
        expected,
        reason: '$status',
      );
    }
  });

  test('booking status is ignored for remaining success', () async {
    final details = await _detailsWith('succeeded');
    expect(details.status.name, 'confirmed');
    expect(
      remainingOutcomeFor('p1')(details),
      VerificationOutcome.success,
    );
  });
}
