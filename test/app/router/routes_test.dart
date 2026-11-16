import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/router/routes.dart';

void main() {
  const uuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

  test('G4 account routes are registered with the correct gate', () {
    for (final path in [
      AppRoutes.support,
      AppRoutes.accountSecurity,
      AppRoutes.accountPassword,
      AppRoutes.accountNotifications,
      AppRoutes.accountDelete,
    ]) {
      expect(AppRoutes.isRegisteredLocation(path), isTrue, reason: path);
      expect(AppRoutes.requiresAccount(path), isTrue, reason: path);
    }
    expect(AppRoutes.isRegisteredLocation(AppRoutes.supportFaq), isTrue);
    expect(AppRoutes.requiresAccount(AppRoutes.supportFaq), isFalse);
  });

  test(
    'support case links require UUID v4 and static routes never collide',
    () {
      expect(AppRoutes.requiresAccount('/support/$uuid'), isTrue);
      expect(AppRoutes.isLinkablePath('/support/$uuid'), isTrue);
      expect(AppRoutes.isRegisteredLocation('/support/not-a-uuid'), isFalse);
      expect(AppRoutes.isLinkablePath(AppRoutes.supportNew), isFalse);
      expect(AppRoutes.isLinkablePath(AppRoutes.supportFaq), isFalse);
    },
  );
}
