import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/account/domain/active_session.dart';

void main() {
  test('parses the U6 item and falls back for unknown platform and label', () {
    final session = ActiveSession.fromJson({
      'id': 'session-1',
      'device_label': '  ',
      'platform': 'tvos',
      'created_at': '2026-11-01T10:00:00Z',
      'last_active_at': '2026-11-17T10:00:00Z',
      'is_current': false,
    });
    expect(session.platform, SessionPlatform.unknown);
    expect(session.usesUnknownDeviceLabel, isTrue);
    expect(session.createdAt.isUtc, isTrue);
  });

  test('sorting puts current first then last activity descending', () {
    ActiveSession item(String id, int hour, {bool current = false}) =>
        ActiveSession(
          id: id,
          deviceLabel: id,
          platform: SessionPlatform.android,
          createdAt: DateTime.utc(2026),
          lastActiveAt: DateTime.utc(2026, 1, 1, hour),
          isCurrent: current,
        );
    expect(
      ActiveSession.sorted([
        item('old', 1),
        item('current', 0, current: true),
        item('new', 2),
      ]).map((session) => session.id),
      ['current', 'new', 'old'],
    );
  });
}
