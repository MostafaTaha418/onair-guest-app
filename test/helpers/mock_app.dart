import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/app.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/device/device_identity.dart';
import 'package:on_air/core/files/attachment_picker.dart';
import 'package:on_air/core/files/file_url_cache.dart';
import 'package:on_air/core/files/image_sanitizer.dart';
import 'package:on_air/core/files/private_file_uploader.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/core/push/push_messages.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/features/account/data/mock_account_server.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/phone_verification/data/mock_phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/mock_listings_repository.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/notifications/presentation/push_permission_coordinator.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/features/support/data/faq_cache.dart';
import 'package:on_air/features/support/data/mock_support_server.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_booking_backend.dart';
import 'fake_connectivity.dart';
import 'fake_support_files.dart';

/// Boots the full [OnAirApp] on the mock backend: in-memory repositories,
/// no Supabase/Firebase connection. Shared by the integration tests that
/// exercise the real shell (the T095 journey, the T105 scroll-perf run).
///
/// [support] and [attachmentPicker] let the support journeys (T055) share
/// the server instance and feed canned picks through the real pipeline.
///
/// On the host, rootBundle never completes under the fake async zone — the
/// Returns the mock auth repository so social-scenario tests can pick the
/// canned outcome and read the call counter.
///
/// fixture files are read directly (the same reason T027 added `loader`).
Future<MockAuthRepository> bootMockApp(
  WidgetTester tester, {
  MockAuthRepository? auth,
  MockPhoneVerificationRepository? phoneVerification,
  MockSupportServer? support,
  AttachmentPicker? attachmentPicker,
  bool resetPreferences = true,
}) async {
  CairoTime.initialize();
  if (resetPreferences) SharedPreferences.setMockInitialValues({});
  // Detach a previously booted app so calling this helper again in the same
  // test is a genuine process-style restart, not an update of OnAirApp's
  // existing State object.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  // Sync IO: async dart:io futures never complete under the fake async
  // zone of a host widget test.
  final directory = Directory.systemTemp.createTempSync('on_air_mock_app');
  addTearDown(() => directory.deleteSync(recursive: true));
  final cache = JsonFileCache(
    directory: directory,
    fileName: 'discovery_cache.json',
    schema: 1,
  );
  final listings =
      TestWidgetsFlutterBinding.instance is AutomatedTestWidgetsFlutterBinding
      ? MockListingsRepository(
          loader: (path) async => File(path).readAsStringSync(),
        )
      : MockListingsRepository();
  final ownsAuth = auth == null;
  auth ??= MockAuthRepository();
  if (ownsAuth) addTearDown(auth.dispose);
  final phones =
      phoneVerification ??
      MockPhoneVerificationRepository(
        auth: auth,
        deviceIdentity: const MemoryDeviceIdentity(),
      );
  final bookingBackend = FakeBookingBackend();
  addTearDown(bookingBackend.dispose);
  final supportPicker = attachmentPicker ?? const EmptyAttachmentPicker();
  final accountServer = MockAccountServer(auth: auth);
  final pushes = MockPushMessageSource();
  final notificationPermission = FakeNotificationPermission();
  addTearDown(pushes.dispose);
  final supportServer =
      support ??
      MockSupportServer(
        latency: Duration.zero,
        onStaffReply: (caseId) {
          unawaited(
            bookingBackend.server.notifyGuest(
              'support.staff_replied',
              caseId,
              entityType: 'support_case',
              category: 'support',
            ),
          );
          if (accountServer.pushEnabled('support')) {
            pushes.emitForeground(
              PushMessage(type: 'support.staff_replied', targetId: caseId),
            );
          }
        },
      );
  final faqCache = FaqCache(
    JsonFileCache(
      directory: directory,
      fileName: 'faq_v1.json',
      schema: 1,
    ),
  );
  // Integration runners can briefly report `ConnectivityResult.none` while
  // the simulator is booting. Mock-mode journeys use an in-process backend,
  // so tying them to the host network makes otherwise deterministic screens
  // (notably My Bookings) render their empty offline state intermittently.
  final connectivity = FakeConnectivity();
  final connectivityCubit = connectivity.createCubit();
  addTearDown(connectivity.dispose);
  addTearDown(connectivityCubit.close);

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppConfigSource>.value(
          value: const MockAppConfigSource(),
        ),
        RepositoryProvider<AuthRepository>.value(value: auth),
        // The OTP limiter and its stable device id — the same stack the
        // real bootstrap provides (S005 US5).
        RepositoryProvider<DeviceIdentity>.value(
          value: phones.deviceIdentity ?? const MemoryDeviceIdentity(),
        ),
        RepositoryProvider<PhoneVerificationRepository>.value(value: phones),
        RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
        RepositoryProvider<ListingsRepository>.value(value: listings),
        RepositoryProvider<JsonFileCache>.value(value: cache),
        RepositoryProvider<ReferenceDataCache>.value(
          value: ReferenceDataCache(listings, cache),
        ),
        RepositoryProvider<HomeFeedCache>.value(
          value: HomeFeedCache(cache),
        ),
        RepositoryProvider<LastSearchStore>.value(value: LastSearchStore()),
        RepositoryProvider<NotificationSignalSource>.value(
          value: bookingBackend.signals,
        ),
        RepositoryProvider<PushMessageSource>.value(value: pushes),
        RepositoryProvider<NotificationPermission>.value(
          value: notificationPermission,
        ),
        RepositoryProvider<PushPermissionCoordinator>.value(
          value: PushPermissionCoordinator(
            permission: notificationPermission,
            devices: null,
          ),
        ),
        ...bookingBackend.appProviders(),
        // The G4 support stack, mirroring bootstrap's mock mode.
        RepositoryProvider<SupportRepository>.value(value: supportServer),
        RepositoryProvider<MockSupportServer?>.value(value: supportServer),
        RepositoryProvider<AttachmentPicker>.value(value: supportPicker),
        RepositoryProvider<ImageSanitizer>.value(value: ImageSanitizer()),
        RepositoryProvider<PrivateFileUploader>.value(
          value: PrivateFileUploader(
            signer: UniqueUploadSigner(),
            putClient: const FakeRawPutClient(),
          ),
        ),
        RepositoryProvider<FileUrlCache>.value(
          value: FileUrlCache(bookingBackend.stay),
        ),
        RepositoryProvider<FaqCache>.value(value: faqCache),
        RepositoryProvider<AccountRepository>.value(value: accountServer),
        RepositoryProvider<MockAccountServer?>.value(value: accountServer),
      ],
      child: OnAirApp(
        connectivityCubit: connectivityCubit,
        pushMessages: pushes,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}
