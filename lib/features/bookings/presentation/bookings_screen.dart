import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/presentation/bookings_cubit.dart';
import 'package:on_air/features/bookings/presentation/widgets/booking_card.dart';
import 'package:on_air/features/bookings/presentation/widgets/unfinished_payment_banner.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// My Bookings (US3): Current / Past / Cancelled tabs over one cubit; the
/// pending tab exists on the server only (banner in US7), never shown here.
final class BookingsScreen extends StatelessWidget {
  const BookingsScreen({this.initialTab = BookingTab.current, super.key});

  final BookingTab initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      initialIndex: switch (initialTab) {
        BookingTab.past => 1,
        BookingTab.cancelled => 2,
        _ => 0,
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.bookings),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.bookingsTabCurrent),
              Tab(text: l10n.bookingsTabPast),
              Tab(text: l10n.bookingsTabCancelled),
            ],
          ),
        ),
        body: const Column(
          children: [
            UnfinishedPaymentBanner(),
            Expanded(
              child: _TabSync(
                child: TabBarView(
                  children: [
                    _TabBody(tab: BookingTab.current),
                    _TabBody(tab: BookingTab.past),
                    _TabBody(tab: BookingTab.cancelled),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lives under [DefaultTabController] so it can drive `selectTab` from the
/// controller the screen itself creates.
final class _TabSync extends StatefulWidget {
  const _TabSync({required this.child});

  final Widget child;

  @override
  State<_TabSync> createState() => _TabSyncState();
}

final class _TabSyncState extends State<_TabSync> {
  TabController? _controller;

  void _onTabChanged() {
    final controller = _controller;
    if (controller == null) return;
    // `index` is already the target while the switch animates, so the
    // tab's data starts loading right away; repeated calls are ignored by
    // the cubit when the tab is unchanged.
    final tab = switch (controller.index) {
      1 => BookingTab.past,
      2 => BookingTab.cancelled,
      _ => BookingTab.current,
    };
    unawaited(context.read<BookingsCubit>().selectTab(tab));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    if (!identical(controller, _controller)) {
      _controller?.removeListener(_onTabChanged);
      _controller = controller..addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

final class _TabBody extends StatelessWidget {
  const _TabBody({required this.tab});

  final BookingTab tab;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (notification.depth == 0 &&
            metrics.maxScrollExtent > 0 &&
            metrics.pixels >= metrics.maxScrollExtent * 0.8) {
          unawaited(cubit.loadMore());
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => cubit.retryTab(tab),
        child: BlocBuilder<BookingsCubit, BookingsState>(
          builder: (context, state) => _TabList(tab: tab, state: state),
        ),
      ),
    );
  }
}

final class _TabList extends StatelessWidget {
  const _TabList({required this.tab, required this.state});

  final BookingTab tab;
  final BookingsState state;

  String _emptyMessage(AppLocalizations l10n) => switch (tab) {
    BookingTab.past => l10n.bookingsEmptyPast,
    BookingTab.cancelled => l10n.bookingsEmptyCancelled,
    _ => l10n.bookingsEmptyCurrent,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BookingsCubit>();
    final data = state.tabs[tab]!;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (data.fromCache && data.fetchedAt != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Dimens.screenSide,
                Dimens.space8,
                Dimens.screenSide,
                Dimens.space4,
              ),
              child: Text(
                l10n.lastUpdated(formatCairoDayMonthTime(data.fetchedAt!)),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ),
        switch (data.load) {
          TabLoad.initial || TabLoad.loading => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.all(Dimens.screenSide),
              child: Column(
                children: [
                  SkeletonBox(height: 96),
                  SizedBox(height: Dimens.space12),
                  SkeletonBox(height: 96),
                  SizedBox(height: Dimens.space12),
                  SkeletonBox(height: 96),
                ],
              ),
            ),
          ),
          TabLoad.failed => SliverToBoxAdapter(
            child: ErrorView(
              message: apiErrorMessage(data.error!, l10n),
              onRetry: () => cubit.retryTab(tab),
              referenceNumber: data.error!.requestId,
            ),
          ),
          TabLoad.offline => SliverToBoxAdapter(
            child: EmptyView(icon: Icons.wifi_off, message: l10n.offline),
          ),
          TabLoad.ready when data.items.isEmpty => SliverToBoxAdapter(
            child: EmptyView(
              icon: Icons.event_busy,
              message: _emptyMessage(l10n),
              action: OnAirPrimaryButton(
                label: l10n.bookingsFindApartment,
                onPressed: () => context.go(AppRoutes.search),
              ),
            ),
          ),
          TabLoad.ready => SliverList.builder(
            itemCount: data.items.length,
            itemBuilder: (context, index) => BookingCard(
              booking: data.items[index],
              onTap: () => context.push(
                AppRoutes.bookingDetails(data.items[index].id),
              ),
            ),
          ),
        },
        if (data.loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.all(Dimens.space12),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
