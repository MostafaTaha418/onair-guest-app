import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/account/domain/deletion.dart';

void main() {
  test('fromDetails parses the three blocker kinds', () {
    final blockers = DeletionBlocker.fromDetails(const {
      'blockers': [
        {'kind': 'booking', 'id': 'b-1', 'code': 'OA-1'},
        {'kind': 'refund', 'id': 'b-2', 'code': 'OA-2'},
        {'kind': 'damage_claim', 'id': 'b-3', 'code': 'OA-3'},
      ],
    });
    expect(blockers, hasLength(3));
    expect(blockers[0].kind, DeletionBlockerKind.booking);
    expect(blockers[1].kind, DeletionBlockerKind.refund);
    expect(blockers[2].kind, DeletionBlockerKind.damageClaim);
    expect(blockers.map((blocker) => blocker.code), ['OA-1', 'OA-2', 'OA-3']);
  });

  test('an unknown kind is kept as other and still listed', () {
    final blockers = DeletionBlocker.fromDetails(const {
      'blockers': [
        {'kind': 'cash_confirmation', 'id': 'b-9', 'code': 'OA-9'},
        {'kind': 'booking', 'id': 'b-1', 'code': 'OA-1'},
      ],
    });
    expect(blockers, hasLength(2));
    expect(blockers.first.kind, DeletionBlockerKind.other);
    expect(blockers.first.code, 'OA-9');
  });

  test('empty or missing blockers yield an empty list', () {
    expect(DeletionBlocker.fromDetails(null), isEmpty);
    expect(DeletionBlocker.fromDetails(const <String, dynamic>{}), isEmpty);
    expect(
      DeletionBlocker.fromDetails(const {'blockers': <String>[]}),
      isEmpty,
    );
    // A malformed payload never throws.
    expect(
      DeletionBlocker.fromDetails(const <String, dynamic>{
        'blockers': 'not-a-list',
      }),
      isEmpty,
    );
  });

  test('parseDetailsJson decodes the Postgrest DETAIL payload', () {
    final details = DeletionBlockedException.parseDetailsJson(
      '{"blockers": [{"kind": "booking", "id": "b-1", "code": "OA-1"}]}',
    );
    expect(DeletionBlocker.fromDetails(details), hasLength(1));
    expect(
      DeletionBlockedException.parseDetailsJson(null),
      isNull,
    );
    expect(DeletionBlockedException.parseDetailsJson('not-json'), isNull);
  });
}
