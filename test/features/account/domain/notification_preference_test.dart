import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/account/domain/notification_preference.dart';

void main() {
  test('parses the U9 catalog and drops in_app', () {
    final preference = NotificationPreference.fromJson({
      'category': 'support',
      'is_mandatory': false,
      'channels': [
        {'channel': 'push', 'enabled': false},
        {'channel': 'email', 'enabled': true},
        {'channel': 'in_app', 'enabled': false},
      ],
    });

    expect(preference.key, 'support');
    expect(preference.labelKey, 'notifCategorySupport');
    expect(preference.channels.keys, {
      NotificationChannel.push,
      NotificationChannel.email,
    });
    expect(preference.enabled(NotificationChannel.push), isFalse);
  });

  test('unknown category uses the fallback label', () {
    final preference = NotificationPreference.fromJson({
      'category': 'future_category',
      'is_mandatory': false,
      'channels': <Object>[],
    });
    expect(preference.labelKey, 'notifCategoryUnknown');
  });

  test('mandatory categories force every returned channel on', () {
    final preference = NotificationPreference.fromJson({
      'category': 'booking',
      'is_mandatory': true,
      'channels': [
        {'channel': 'push', 'enabled': false},
        {'channel': 'email', 'enabled': false},
      ],
    });
    expect(preference.isMandatory, isTrue);
    expect(
      preference.channels.values.every((channel) => channel.enabled),
      isTrue,
    );
  });
}
