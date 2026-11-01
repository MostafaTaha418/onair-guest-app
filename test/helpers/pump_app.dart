import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/core/push/push_messages.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/core/share/share_service.dart';
import 'package:on_air/core/storage/secure_store.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/booking/data/payment_attempt_store.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/bookings/data/arrival_instructions_store.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:on_air/features/notifications/presentation/unread_count_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import 'controllable_push_message_source.dart';
import 'fake_booking_backend.dart';
import 'fake_listings_repository.dart';
import 'fake_share_service.dart';

extension PumpOnAirApp on WidgetTester {
  Future<void> pumpOnAirApp(
    Widget child, {
    required AuthRepository authRepository,
    required AppConfigSource appConfigRepository,
    AuthCubit? authCubit,
    ThemeMode themeMode = ThemeMode.light,
    ListingsRepository? listingsRepository,
    FakeBookingBackend? bookingBackend,
    ConnectivityCubit? connectivityCubit,
    RouterConfig<Object>? routerConfig,
  }) async {
    final listings = listingsRepository ?? FakeListingsRepository();
    final cache = _tempCache();
    final backend = bookingBackend ?? FakeBookingBackend();
    addTearDown(backend.dispose);
    final unreadCubit = UnreadCountCubit(
      notifications: backend.server,
      signals: backend.signals,
    );
    addTearDown(unreadCubit.close);
    final pushSource = ControllablePushMessageSource();
    addTearDown(pushSource.dispose);
    final cubit =
        authCubit ??
        AuthCubit(
          authRepository,
          currentTermsVersion:
              (await appConfigRepository.load()).currentTermsVersion,
        );
    await pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepository),
          RepositoryProvider<AppConfigSource>.value(
            value: appConfigRepository,
          ),
          RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
          RepositoryProvider<ListingsRepository>.value(value: listings),
          RepositoryProvider<JsonFileCache>.value(value: cache),
          RepositoryProvider<ReferenceDataCache>.value(
            value: ReferenceDataCache(listings, cache),
          ),
          RepositoryProvider<HomeFeedCache>.value(value: HomeFeedCache(cache)),
          RepositoryProvider<ShareService>.value(value: FakeShareService()),
          RepositoryProvider<ShareLinks>.value(
            value: const ShareLinks(linkDomain: 'on-air.website'),
          ),
          RepositoryProvider<BookingsRepository>.value(value: backend.server),
          RepositoryProvider<BookingFlowRepository>.value(
            value: backend.server,
          ),
          RepositoryProvider<NotificationsRepository>.value(
            value: backend.server,
          ),
          RepositoryProvider<NotificationSignalSource>.value(
            value: backend.signals,
          ),
          RepositoryProvider<SecureStore>.value(value: backend.secureStore),
          RepositoryProvider<PaymentAttemptStore>.value(
            value: backend.paymentAttempts,
          ),
          RepositoryProvider<ArrivalInstructionsStore>.value(
            value: backend.arrivalInstructions,
          ),
          RepositoryProvider<BookingsCache>.value(value: backend.cache),
          RepositoryProvider<BookingActionRegistry>.value(
            value: BookingActionRegistry.g2(),
          ),
          RepositoryProvider<NotificationPermission>.value(
            value: FakeNotificationPermission(),
          ),
          RepositoryProvider<PushMessageSource>.value(value: pushSource),
          BlocProvider<UnreadCountCubit>.value(value: unreadCubit),
        ],
        // A connectivity cubit is provided only when a test hands one in:
        // constructing the real one touches the platform channel.
        child: connectivityCubit == null
            ? _inner(cubit, child, routerConfig)
            : BlocProvider<ConnectivityCubit>.value(
                value: connectivityCubit,
                child: _inner(cubit, child, routerConfig),
              ),
      ),
    );
    addTearDown(cubit.close);
  }

  Widget _inner(
    AuthCubit cubit,
    Widget child,
    RouterConfig<Object>? routerConfig,
  ) => BlocProvider<AuthCubit>.value(
    value: cubit,
    child: routerConfig == null
        ? MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            darkTheme: OnAirTheme.dark,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: child,
            ),
          )
        : MaterialApp.router(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            darkTheme: OnAirTheme.dark,
            routerConfig: routerConfig,
          ),
  );
}

JsonFileCache _tempCache() {
  final directory = Directory.systemTemp.createTempSync('on_air_test_cache');
  addTearDown(() => directory.deleteSync(recursive: true));
  return JsonFileCache(
    directory: directory,
    fileName: 'discovery_cache.json',
    schema: 1,
  );
}
