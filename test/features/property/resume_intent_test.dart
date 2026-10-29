import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/property/domain/resume_intent.dart';

void main() {
  final today = DateOnly(2026, 11, 1);
  DateOnly queryFrom(Map<String, String> query) =>
      ResumeIntent.fromQuery(query, today: today)!.stay!.checkIn;

  test('a missing or unknown resume action gives null', () {
    expect(ResumeIntent.fromQuery({}, today: today), isNull);
    expect(ResumeIntent.fromQuery({'resume': 'share'}, today: today), isNull);
    expect(
      ResumeIntent.fromQuery({'resume': 'BOOK', 'terms': 't1'}, today: today),
      isNull,
      reason: 'the action key is case sensitive',
    );
  });

  test('book requires terms of 1–128 characters', () {
    expect(
      ResumeIntent.fromQuery({'resume': 'book'}, today: today),
      isNull,
      reason: 'no terms at all',
    );
    expect(
      ResumeIntent.fromQuery({'resume': 'book', 'terms': ''}, today: today),
      isNull,
    );
    expect(
      ResumeIntent.fromQuery({
        'resume': 'book',
        'terms': 'a' * 129,
      }, today: today),
      isNull,
      reason: '129 characters is too long',
    );
    final intent = ResumeIntent.fromQuery(
      {'resume': 'book', 'terms': 't1'},
      today: today,
    );
    expect(intent!.action, ResumeAction.book);
    expect(intent.termsVersion, 't1');
    expect(
      ResumeIntent.fromQuery(
        {'resume': 'book', 'terms': 'a' * 128},
        today: today,
      ),
      isNotNull,
      reason: '128 characters is allowed',
    );
  });

  test('contact never carries terms', () {
    final intent = ResumeIntent.fromQuery(
      {'resume': 'contact', 'terms': 't1'},
      today: today,
    );
    expect(intent!.action, ResumeAction.contact);
    expect(intent.termsVersion, isNull);
  });

  test('the stay parses through StayRange.tryCreate', () {
    final valid = ResumeIntent.fromQuery(
      {
        'resume': 'book',
        'terms': 't1',
        'checkIn': '2026-11-20',
        'checkOut': '2026-11-23',
      },
      today: today,
    );
    expect(
      valid!.stay,
      StayRange(DateOnly(2026, 11, 20), DateOnly(2026, 11, 23)),
    );

    // Past dates drop the whole stay (Clarification: invalid stay → null).
    final past = ResumeIntent.fromQuery(
      {
        'resume': 'book',
        'terms': 't1',
        'checkIn': '2026-10-20',
        'checkOut': '2026-10-23',
      },
      today: today,
    );
    expect(past!.stay, isNull);
    expect(
      queryFrom({
        'resume': 'contact',
        'checkIn': '2026-11-20',
        'checkOut': '2026-11-23',
      }),
      DateOnly(2026, 11, 20),
    );
  });

  test('guests accepts 1–50 and drops everything else', () {
    int? guests(Map<String, String> extra) => ResumeIntent.fromQuery({
      ...extra,
      'resume': 'contact',
    }, today: today)!.guests;
    expect(guests({'guests': '1'}), 1);
    expect(guests({'guests': '50'}), 50);
    expect(guests({'guests': '0'}), isNull);
    expect(guests({'guests': '51'}), isNull);
    expect(guests({'guests': 'abc'}), isNull);
    expect(guests({}), isNull);
  });

  test('stripFrom removes resume and terms and keeps the rest', () {
    final stripped = ResumeIntent.stripFrom(
      Uri.parse(
        '/property/550e8400-e29b-41d4-a716-446655440000'
        '?checkIn=2026-11-20&checkOut=2026-11-23&guests=2'
        '&resume=book&terms=t1',
      ),
    );
    expect(stripped.path, '/property/550e8400-e29b-41d4-a716-446655440000');
    expect(stripped.queryParameters['resume'], isNull);
    expect(stripped.queryParameters['terms'], isNull);
    expect(stripped.queryParameters['checkIn'], '2026-11-20');
    expect(stripped.queryParameters['checkOut'], '2026-11-23');
    expect(stripped.queryParameters['guests'], '2');
  });

  test('stripFrom on a location without a query keeps the path only', () {
    final stripped = ResumeIntent.stripFrom(
      Uri.parse('/property/550e8400-e29b-41d4-a716-446655440000'),
    );
    expect(
      stripped.toString(),
      '/property/550e8400-e29b-41d4-a716-446655440000',
    );
  });
}
