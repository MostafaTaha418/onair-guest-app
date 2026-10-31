import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/notifications/presentation/notification_texts.dart';
import 'package:on_air/features/notifications/presentation/notifications_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The notification center (US5): every type's title + body, tap-to-open
/// through the router, and the off-notifications notice when denied.
final class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

final class _NotificationsScreenState extends State<NotificationsScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The guest may flip the permission in the OS settings while the
    // screen stays open; re-check when the app comes back.
    _lifecycle = AppLifecycleListener(onResume: _refreshPermission);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refreshPermission() async {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permission = context.read<NotificationPermission>();
    final cubit = context.read<NotificationsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            onPressed: cubit.markAllRead,
            child: Text(l10n.notificationsMarkAllRead),
          ),
        ],
      ),
      body: FutureBuilder<PushPermission>(
        future: permission.status(),
        builder: (context, snapshot) {
          final denied = snapshot.data == PushPermission.denied;
          return Column(
            children: [
              if (denied)
                NoticeCard(
                  icon: Icons.notifications_off_outlined,
                  message: l10n.notificationsOffNotice,
                  actionLabel: l10n.notificationsOpenSettings,
                  onAction: () => unawaited(permission.openSettings()),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: cubit.load,
                  child: BlocBuilder<NotificationsCubit, NotificationsState>(
                    builder: (context, state) => switch (state) {
                      NotificationsLoading() => const _NotificationsSkeleton(),
                      NotificationsFailed() => ErrorView(
                        message: apiErrorMessage(state.error, l10n),
                        onRetry: cubit.load,
                        referenceNumber: state.error.requestId,
                      ),
                      NotificationsOffline() => ErrorView(
                        message: l10n.offline,
                        onRetry: cubit.load,
                      ),
                      NotificationsReady() =>
                        state.items.isEmpty
                            ? EmptyView(
                                icon: Icons.notifications_none,
                                message: l10n.notificationsEmpty,
                              )
                            : _NotificationList(state: state),
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

final class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.state});

  final NotificationsReady state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<NotificationsCubit>();
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (state.loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.all(Dimens.space12),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        SliverList.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final notification = state.items[index];
            final text = notificationText(notification.typeKey, l10n);
            final unread = notification.isUnread;
            return ListTile(
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: Dimens.screenSide,
                vertical: Dimens.space4,
              ),
              tileColor: unread ? context.colors['badgeNavActive'] : null,
              title: Text(
                text.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              subtitle: Text(
                text.body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              isThreeLine: false,
              dense: false,
              trailing: Text(
                formatCairoDayMonthTime(notification.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              onTap: () async {
                final location = await cubit.open(notification);
                if (context.mounted) await context.push(location);
              },
            );
          },
        ),
      ],
    );
  }
}

final class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.all(Dimens.screenSide),
    child: Column(
      children: [
        SkeletonBox(height: 72),
        SizedBox(height: Dimens.space12),
        SkeletonBox(height: 72),
        SizedBox(height: Dimens.space12),
        SkeletonBox(height: 72),
      ],
    ),
  );
}
