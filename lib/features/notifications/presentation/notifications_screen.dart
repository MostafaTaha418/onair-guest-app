import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/notifications/domain/app_notification.dart';
import 'package:on_air/features/notifications/presentation/notification_texts.dart';
import 'package:on_air/features/notifications/presentation/notifications_cubit.dart';
import 'package:on_air/features/notifications/presentation/push_permission_coordinator.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

enum _NotificationFilter { all, booking, payment, offers, replies }

extension on _NotificationFilter {
  String label(AppLocalizations l10n) => switch (this) {
    _NotificationFilter.all => l10n.notificationsFilterAll,
    _NotificationFilter.booking => l10n.notificationsFilterBooking,
    _NotificationFilter.payment => l10n.notificationsFilterPayment,
    _NotificationFilter.offers => l10n.notificationsFilterOffers,
    _NotificationFilter.replies => l10n.notificationsFilterReplies,
  };

  bool includes(AppNotification item) {
    final type = item.typeKey;
    return switch (this) {
      _NotificationFilter.all => true,
      _NotificationFilter.booking =>
        (type.startsWith('booking.') &&
                type != 'booking.replacement_offered') ||
            type.startsWith('stay.') ||
            type.startsWith('damage.'),
      _NotificationFilter.payment =>
        type.startsWith('payment.') ||
            type.startsWith('cash.') ||
            type.startsWith('refund.'),
      _NotificationFilter.offers =>
        type == 'booking.replacement_offered' || type.startsWith('offer.'),
      _NotificationFilter.replies =>
        type.startsWith('support.') || type.startsWith('review.'),
    };
  }
}

/// The real notification feed, styled to the supplied notification reference.
final class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({this.now, super.key});

  /// Keeps relative timestamps stable in snapshot tests.
  final DateTime Function()? now;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

final class _NotificationsScreenState extends State<NotificationsScreen> {
  late final AppLifecycleListener _lifecycle;
  _NotificationFilter _filter = _NotificationFilter.all;
  bool _markingAll = false;
  final Set<String> _opening = {};

  @override
  void initState() {
    super.initState();
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

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await context.read<NotificationsCubit>().markAllRead();
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _open(AppNotification item) async {
    if (!_opening.add(item.id)) return;
    try {
      final location = await context.read<NotificationsCubit>().open(item);
      if (mounted) await context.push(location);
    } finally {
      _opening.remove(item.id);
    }
  }

  bool _loadMoreOnScroll(ScrollNotification event) {
    if (event.metrics.extentAfter < 320) {
      unawaited(context.read<NotificationsCubit>().loadMore());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final coordinator = context.read<PushPermissionCoordinator>();
    final cubit = context.read<NotificationsCubit>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<bool>(
          future: coordinator.shouldShowOffNotice(),
          builder: (context, snapshot) {
            final off = snapshot.data ?? false;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(l10n),
                if (off)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      Dimens.screenSide,
                      0,
                      Dimens.screenSide,
                      Dimens.space12,
                    ),
                    child: NoticeCard(
                      icon: AppIcons.notificationsOffOutlined,
                      message: l10n.notificationsOffNotice,
                      actionLabel: l10n.notificationsOpenSettings,
                      onAction: () async {
                        await coordinator.enableFromNotice();
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: cubit.load,
                    child: BlocBuilder<NotificationsCubit, NotificationsState>(
                      builder: (context, state) => switch (state) {
                        NotificationsLoading() =>
                          const _NotificationsSkeleton(),
                        NotificationsFailed() => ErrorView(
                          message: apiErrorMessage(state.error, l10n),
                          onRetry: cubit.load,
                          referenceNumber: state.error.requestId,
                        ),
                        NotificationsOffline() => ErrorView(
                          message: l10n.offline,
                          onRetry: cubit.load,
                        ),
                        NotificationsReady() => _feed(state, l10n),
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    final colors = context.colors;
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        Dimens.screenSide,
        Dimens.space12,
        Dimens.screenSide,
        Dimens.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PopupMenuButton<_NotificationFilter>(
              tooltip: l10n.notificationsFilterHint,
              icon: Icon(AppIcons.tuneOutlined, color: colors.textPrimary),
              onSelected: (filter) => setState(() => _filter = filter),
              itemBuilder: (context) => [
                for (final filter in _NotificationFilter.values)
                  PopupMenuItem(value: filter, child: Text(filter.label(l10n))),
              ],
            ),
          ),
          const SizedBox(height: Dimens.space12),
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              final hasUnread =
                  state is NotificationsReady &&
                  state.items.any((item) => item.isUnread);
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.notifications,
                      style:
                          (isNarrow
                                  ? context.textStyles.notificationsTitleNarrow
                                  : context.textStyles.notificationsTitle)
                              .copyWith(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? colors['textAccent']
                                    : colors['primaryDark'],
                              ),
                    ),
                  ),
                  TextButton(
                    onPressed: hasUnread && !_markingAll ? _markAllRead : null,
                    child: Text(
                      l10n.notificationsMarkAllRead,
                      style: isNarrow
                          ? context.textStyles.notificationsActionNarrow
                          : context.textStyles.notificationsAction,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: Dimens.space16),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _NotificationFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: Dimens.space8),
              itemBuilder: (context, index) {
                final filter = _NotificationFilter.values[index];
                final selected = filter == _filter;
                return Center(
                  child: Semantics(
                    selected: selected,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _filter = filter),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(56, 42),
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: Dimens.space16,
                        ),
                        backgroundColor: selected
                            ? colors.primary
                            : colors.surface,
                        foregroundColor: selected
                            ? colors.onPrimary
                            : colors.textSecondary,
                        side: BorderSide(
                          color: selected
                              ? colors.primary
                              : colors['chipBorder'],
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(filter.label(l10n)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _feed(NotificationsReady state, AppLocalizations l10n) {
    final filtered = state.items.where(_filter.includes).toList();
    if (state.items.isEmpty || filtered.isEmpty) {
      return EmptyView(
        icon: AppIcons.notificationsNone,
        message: state.items.isEmpty
            ? l10n.notificationsEmpty
            : l10n.notificationsFilterEmpty,
        action: state.hasMore
            ? TextButton(
                onPressed: state.loadingMore
                    ? null
                    : context.read<NotificationsCubit>().loadMore,
                child: state.loadingMore
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.showMore),
              )
            : null,
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _loadMoreOnScroll,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(
          Dimens.screenSide,
          0,
          Dimens.screenSide,
          96,
        ),
        itemCount: filtered.length + (state.loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: Dimens.space12),
        itemBuilder: (context, index) => index == filtered.length
            ? const Center(child: CircularProgressIndicator())
            : _NotificationCard(
                item: filtered[index],
                onTap: () => _open(filtered[index]),
                now: widget.now?.call() ?? DateTime.now(),
              ),
      ),
    );
  }
}

final class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.now,
  });

  final AppNotification item;
  final VoidCallback onTap;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = notificationText(item.typeKey, l10n);
    final (icon, background, foreground) = _appearance(context, item.typeKey);
    return Material(
      key: ValueKey('notification-${item.id}'),
      color: colors.surface,
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Dimens.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: background,
                    child: Icon(icon, color: foreground, size: 25),
                  ),
                  if (item.isUnread)
                    PositionedDirectional(
                      top: -1,
                      end: -2,
                      child: Container(
                        key: ValueKey('unread-${item.id}'),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors['favorite'],
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: Dimens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            text.title,
                            style: context.textStyles.notificationItemTitle
                                .copyWith(
                                  color: colors.textPrimary,
                                ),
                          ),
                        ),
                        const SizedBox(width: Dimens.space8),
                        Text(
                          _relativeTime(item.createdAt, now, l10n),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimens.space4),
                    Text(
                      text.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

(IconData, Color, Color) _appearance(BuildContext context, String type) {
  final colors = context.colors;
  if (type.startsWith('support.') || type.startsWith('review.')) {
    return (
      AppIcons.supportAgent,
      colors['settingsTealBg'],
      colors['settingsTealIcon'],
    );
  }
  if (type.startsWith('payment.') ||
      type.startsWith('cash.') ||
      type.startsWith('refund.')) {
    return (
      AppIcons.creditcard,
      colors['settingsBlueBg'],
      colors['settingsBlueIcon'],
    );
  }
  if (type == 'booking.replacement_offered' || type.startsWith('offer.')) {
    return (
      AppIcons.tag,
      colors['settingsOrangeBg'],
      colors['settingsOrangeIcon'],
    );
  }
  if (type.startsWith('account.')) {
    return (
      AppIcons.lockOutlineRounded,
      colors['settingsNeutralBg'],
      colors['settingsNeutralIcon'],
    );
  }
  return (
    AppIcons.calendarMonthOutlined,
    colors['settingsBlueBg'],
    colors['settingsBlueIcon'],
  );
}

String _relativeTime(DateTime date, DateTime now, AppLocalizations l10n) {
  final elapsed = now.difference(date);
  if (elapsed.isNegative || elapsed.inMinutes < 1) {
    return l10n.notificationsJustNow;
  }
  if (elapsed.inHours < 1) {
    return l10n.notificationsMinutesAgo(elapsed.inMinutes);
  }
  if (elapsed.inDays < 1) {
    return l10n.notificationsHoursAgo(elapsed.inHours);
  }
  if (elapsed.inDays < 7) return l10n.notificationsDaysAgo(elapsed.inDays);
  if (elapsed.inDays < 28) {
    return l10n.notificationsWeeksAgo(elapsed.inDays ~/ 7);
  }
  return DateFormat(
    'd MMM – HH:mm',
    l10n.localeName,
  ).format(CairoTime.inCairo(date));
}

final class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.all(Dimens.screenSide),
    child: Column(
      children: [
        SkeletonBox(height: 108),
        SizedBox(height: Dimens.space12),
        SkeletonBox(height: 108),
        SizedBox(height: Dimens.space12),
        SkeletonBox(height: 108),
      ],
    ),
  );
}
