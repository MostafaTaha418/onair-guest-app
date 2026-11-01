import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// The call that opens the notification settings page (the `app_settings`
/// dependency added in G2 T001):
/// `AppSettings.openAppSettings(type: AppSettingsType.notification)`.
enum PushPermission { notDetermined, granted, denied }

/// The push-permission surface; [FirebaseNotificationPermission] in remote
/// mode, [FakeNotificationPermission] in mock mode and tests.
abstract interface class NotificationPermission {
  Future<PushPermission> status();
  Future<PushPermission> request();
  Future<void> openSettings();
}

final class FirebaseNotificationPermission implements NotificationPermission {
  PushPermission _map(AuthorizationStatus status) => switch (status) {
    AuthorizationStatus.authorized ||
    AuthorizationStatus.provisional => PushPermission.granted,
    AuthorizationStatus.denied ||
    AuthorizationStatus.deniedPermanently => PushPermission.denied,
    AuthorizationStatus.notDetermined => PushPermission.notDetermined,
  };

  @override
  Future<PushPermission> status() async => _map(
    (await FirebaseMessaging.instance.getNotificationSettings())
        .authorizationStatus,
  );

  @override
  Future<PushPermission> request() async => _map(
    (await FirebaseMessaging.instance.requestPermission()).authorizationStatus,
  );

  @override
  Future<void> openSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }
}

/// In-memory source for mock mode and tests.
final class FakeNotificationPermission implements NotificationPermission {
  FakeNotificationPermission({
    this.current = PushPermission.notDetermined,
    this.answer = PushPermission.granted,
  });

  PushPermission current;
  PushPermission answer;
  int requestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<PushPermission> status() async => current;

  @override
  Future<PushPermission> request() async {
    requestCalls++;
    current = answer;
    return answer;
  }

  @override
  Future<void> openSettings() async {
    openSettingsCalls++;
  }
}
