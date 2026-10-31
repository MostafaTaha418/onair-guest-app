import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/features/notifications/domain/app_notification.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:on_air/features/notifications/presentation/notifications_cubit.dart';
import 'package:on_air/features/notifications/presentation/notifications_screen.dart';
import 'package:on_air/features/notifications/presentation/unread_count_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../helpers/fake_app_config_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_booking_backend.dart';
import '../../helpers/fake_connectivity.dart';
import '../../helpers/pump_app.dart';

/// Serves an empty center.
final class EmptyNotifications implements NotificationsRepository {
  @override
  Future<List<AppNotification>> list({DateTime? before, int limit = 30}) async {
    return const [];
  }

  @override
  Future<int> unreadCount() async => 0;

  @override
  Future<void> markRead(List<String>? ids) async {}
}

void main() {
  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    backend = FakeBookingBackend();
    connectivity = FakeConnectivity();
  });

  tearDown(() {
    backend.dispose();
    connectivity.dispose();
  });

  Future<UnreadCountCubit> pumpCenter(
    WidgetTester tester, {
    NotificationsRepository? repo,
    NotificationPermission? permission,
  }) async {
    final effectiveRepo = repo ?? backend.server;
    UnreadCountCubit? createdUnread;
    final router = GoRouter(
      initialLocation: AppRoutes.notifications,
      routes: [
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) {
            final unread = UnreadCountCubit(
              notifications: effectiveRepo,
              signals: backend.signals,
            );
            createdUnread = unread;
            unawaited(unread.refresh());
            return RepositoryProvider<NotificationPermission>.value(
              value: permission ?? FakeNotificationPermission(),
              child: BlocProvider<UnreadCountCubit>.value(
                value: unread,
                child: BlocProvider<NotificationsCubit>(
                  create: (context) {
                    final cubit = NotificationsCubit(
                      notifications: effectiveRepo,
                      signals: backend.signals,
                      connectivity: context.read<ConnectivityCubit>(),
                      unread: context.read<UnreadCountCubit>(),
                    );
                    unawaited(cubit.load());
                    return cubit;
                  },
                  child: const NotificationsScreen(),
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.bookingDetailsPattern,
          builder: (_, state) => Text('details:${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: AppRoutes.supportNew,
          builder: (_, _) => const Text('support-stub'),
        ),
      ],
    );
    await tester.pumpOnAirApp(
      const SizedBox.shrink(),
      routerConfig: router,
      authRepository: FakeAuthRepository(),
      appConfigRepository: FakeAppConfigRepository(
        const AppConfig(
          minSupportedBuildAndroid: 1,
          minSupportedBuildIos: 1,
          supportPhone: '+201000000000',
          currentTermsVersion: 'mock-terms-1',
        ),
      ),
      bookingBackend: backend,
      connectivityCubit: connectivity.createCubit(),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    return createdUnread!;
  }

  testWidgets('the list shows the server order with unread highlights', (
    tester,
  ) async {
    await pumpCenter(tester);
    // The fixtures: three unread (rows 01-03) then three read.
    expect(find.text(l10n.notifBookingRequestReceivedTitle), findsOneWidget);
    expect(find.text(l10n.notifBookingConfirmedTitle), findsOneWidget);
    expect(find.text(l10n.notifRefundVerifiedTitle), findsOneWidget);

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles, hasLength(6));
    expect(tiles.take(3).every((t) => t.tileColor != null), isTrue);
    expect(tiles.skip(3).every((t) => t.tileColor == null), isTrue);
  });

  testWidgets('a tap opens the booking and drops the unread count', (
    tester,
  ) async {
    final unread = await pumpCenter(tester);
    expect(unread.state, 3);

    await tester.tap(find.text(l10n.notifBookingRequestReceivedTitle).first);
    await tester.pump();
    await tester.pump();
    expect(
      find.text('details:b0000000-0000-4000-8000-000000000002'),
      findsOneWidget,
    );
    expect(unread.state, 2);
  });

  testWidgets('"Mark all as read" clears every highlight', (tester) async {
    final unread = await pumpCenter(tester);
    expect(unread.state, 3);

    await tester.tap(find.text(l10n.notificationsMarkAllRead));
    await tester.pump();
    await tester.pump();
    expect(unread.state, 0);
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles.every((t) => t.tileColor == null), isTrue);
  });

  testWidgets('an empty center shows its empty view', (tester) async {
    await pumpCenter(tester, repo: EmptyNotifications());
    expect(find.text(l10n.notificationsEmpty), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  testWidgets('a denied permission shows the off notice with an action', (
    tester,
  ) async {
    final permission = FakeNotificationPermission(
      current: PushPermission.denied,
    );
    await pumpCenter(tester, permission: permission);
    expect(find.text(l10n.notificationsOffNotice), findsOneWidget);
    expect(find.byType(NoticeCard), findsOneWidget);

    await tester.tap(find.text(l10n.notificationsOpenSettings));
    await tester.pump();
    expect(permission.openSettingsCalls, 1);
  });

  testWidgets('a granted permission hides the off notice', (tester) async {
    await pumpCenter(
      tester,
      permission: FakeNotificationPermission(
        current: PushPermission.granted,
      ),
    );
    expect(find.text(l10n.notificationsOffNotice), findsNothing);
  });
}
