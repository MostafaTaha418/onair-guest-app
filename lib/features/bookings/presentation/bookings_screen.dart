import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/presentation/bookings_cubit.dart';
import 'package:on_air/features/bookings/presentation/widgets/booking_card.dart';
import 'package:on_air/features/bookings/presentation/widgets/unfinished_payment_banner.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Space under the last item so the floating navigation capsule never hides
/// it (DESIGN.md, The Safe Area Rule).
const double _listBottomInset = 96;

/// My Bookings (US3): Current / Past / Cancelled tabs over one cubit; the
/// pending tab exists on the server only (banner in US7), never shown here.
final class BookingsScreen extends StatelessWidget {
  const BookingsScreen({this.initialTab = BookingTab.current, super.key});

  final BookingTab initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return DefaultTabController(
      length: 3,
      initialIndex: switch (initialTab) {
        BookingTab.past => 1,
        BookingTab.cancelled => 2,
        _ => 0,
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          toolbarHeight: 56,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: colors.transparent,
          backgroundColor: colors.background,
          foregroundColor: colors.textPrimary,
          centerTitle: false,
          titleSpacing: Dimens.screenSide,
          title: Text(
            l10n.bookings,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: colors.textPrimary,
            ),
          ),
          bottom: _SegmentedTabs(
            labels: [
              l10n.bookingsTabCurrent,
              l10n.bookingsTabPast,
              l10n.bookingsTabCancelled,
            ],
          ),
        ),
        // The banner sits outside the tab pages so it stays above every
        // tab and every load state.
        body: const Column(
          children: [
            UnfinishedPaymentBanner(
              layout: UnfinishedPaymentBannerLayout.bookings,
            ),
            Expanded(
              child: _TabSync(
                child: TabBarView(
                  children: [
                    _TabBody(
                      key: PageStorageKey('bookings-current'),
                      tab: BookingTab.current,
                    ),
                    _TabBody(
                      key: PageStorageKey('bookings-past'),
                      tab: BookingTab.past,
                    ),
                    _TabBody(
                      key: PageStorageKey('bookings-cancelled'),
                      tab: BookingTab.cancelled,
                    ),
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

/// Three equal lists, so a segmented control: one 48dp surface with a
/// filled primary segment. Each segment's whole 48dp height is tappable.
final class _SegmentedTabs extends StatelessWidget
    implements PreferredSizeWidget {
  const _SegmentedTabs({required this.labels});

  final List<String> labels;

  static const double _height = Dimens.minTouchTarget;

  @override
  Size get preferredSize => const Size.fromHeight(_height + 2);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? colors['textAccent'] : colors.primary;
    final label = Theme.of(context).textTheme.labelLarge!.copyWith(
      fontSize: 14,
      height: 1.3,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: Dimens.screenSide,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(
            color: dark ? colors.border : colors['borderNeutral'],
          ),
          borderRadius: BorderRadius.circular(Dimens.radiusField),
        ),
        child: TabBar(
          dividerHeight: 0,
          dividerColor: colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(Dimens.space4),
          indicator: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(Dimens.radiusChip),
          ),
          labelPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: Dimens.space8,
          ),
          labelColor: colors.onPrimary,
          unselectedLabelColor: colors.textSecondary,
          labelStyle: label.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: label.copyWith(fontWeight: FontWeight.w600),
          splashBorderRadius: BorderRadius.circular(Dimens.radiusField),
          overlayColor: WidgetStatePropertyAll(ink.withValues(alpha: 0.08)),
          tabs: [
            for (final text in labels)
              Tab(
                height: _height,
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
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
  const _TabBody({required this.tab, super.key});

  final BookingTab tab;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        // The next page starts loading while 300dp of list is still left.
        if (notification.depth == 0 &&
            metrics.maxScrollExtent > 0 &&
            metrics.extentAfter < 300) {
          unawaited(cubit.loadMore());
        }
        return false;
      },
      child: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () => cubit.retryTab(tab),
        child: BlocBuilder<BookingsCubit, BookingsState>(
          builder: (context, state) => _TabList(tab: tab, state: state),
        ),
      ),
    );
  }
}

final class _TabList extends StatefulWidget {
  const _TabList({required this.tab, required this.state});

  final BookingTab tab;
  final BookingsState state;

  @override
  State<_TabList> createState() => _TabListState();
}

final class _TabListState extends State<_TabList> {
  /// Several cards can pass their deadline in the same moment (FR-029);
  /// they collapse into one server refresh.
  Timer? _deadlineRefresh;

  void _scheduleDeadlineRefresh(BookingsCubit cubit) {
    _deadlineRefresh?.cancel();
    _deadlineRefresh = Timer(const Duration(milliseconds: 250), () {
      _deadlineRefresh = null;
      if (mounted) unawaited(cubit.refresh());
    });
  }

  @override
  void dispose() {
    _deadlineRefresh?.cancel();
    super.dispose();
  }

  String _emptyMessage(AppLocalizations l10n) => switch (widget.tab) {
    BookingTab.past => l10n.bookingsEmptyPast,
    BookingTab.cancelled => l10n.bookingsEmptyCancelled,
    _ => l10n.bookingsEmptyCurrent,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final cubit = context.read<BookingsCubit>();
    final tab = widget.tab;
    final data = widget.state.tabs[tab]!;
    final updated = data.fromCache && data.fetchedAt != null
        ? Padding(
            padding: const EdgeInsetsDirectional.only(bottom: Dimens.space8),
            child: Text(
              l10n.lastUpdated(
                formatCairoDayMonthTime(
                  data.fetchedAt!,
                  locale: l10n.localeName,
                ),
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
          )
        : null;

    Widget message(_StateMessage child) => SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Dimens.space24,
          Dimens.space24,
          Dimens.space24,
          _listBottomInset,
        ),
        child: Column(
          children: [
            ?updated,
            Expanded(child: Center(child: child)),
          ],
        ),
      ),
    );

    final body = switch (data.load) {
      TabLoad.initial || TabLoad.loading => SliverPadding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Dimens.screenSide,
          Dimens.space8,
          Dimens.screenSide,
          _listBottomInset,
        ),
        sliver: SliverList.separated(
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(height: Dimens.space12),
          itemBuilder: (_, index) =>
              _BookingCardSkeleton(titleWidth: const [0.78, 0.64, 0.72][index]),
        ),
      ),
      TabLoad.failed => message(
        _StateMessage(
          kind: _StateKind.error,
          title: apiErrorMessage(data.error!, l10n),
          actionLabel: l10n.retry,
          onAction: () => cubit.retryTab(tab),
          reference: data.error!.requestId,
        ),
      ),
      TabLoad.offline => message(
        _StateMessage(
          kind: _StateKind.offline,
          title: l10n.offline,
          subtitle: l10n.bookingsOfflineHint,
          actionLabel: l10n.retry,
          onAction: () => cubit.retryTab(tab),
          outlined: true,
        ),
      ),
      TabLoad.ready when data.items.isEmpty => message(
        _StateMessage(
          kind: _StateKind.empty,
          title: _emptyMessage(l10n),
          actionLabel: l10n.bookingsFindApartment,
          onAction: () async => context.go(AppRoutes.search),
        ),
      ),
      TabLoad.ready => SliverPadding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Dimens.screenSide,
          Dimens.space8,
          Dimens.screenSide,
          _listBottomInset,
        ),
        sliver: SliverList.separated(
          itemCount: data.items.length + (data.loadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: Dimens.space12),
          itemBuilder: (context, index) {
            if (index == data.items.length) return const _LoadingMore();
            final booking = data.items[index];
            final card = BookingCard(
              key: ValueKey(booking.id),
              booking: booking,
              onTap: () => context.push(AppRoutes.bookingDetails(booking.id)),
              onDeadlineReached: () => _scheduleDeadlineRefresh(cubit),
            );
            if (index == 0 && updated != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [updated, card],
              );
            }
            return card;
          },
        ),
      ),
    };

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [body],
    );
  }
}

final class _LoadingMore extends StatelessWidget {
  const _LoadingMore();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: Dimens.space8,
        bottom: Dimens.space4,
      ),
      child: Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: dark ? colors['textAccent'] : colors.primary,
            backgroundColor: colors.border,
            semanticsLabel: MaterialLocalizations.of(
              context,
            ).refreshIndicatorSemanticLabel,
          ),
        ),
      ),
    );
  }
}

/// A loading card with the booking card's proportions: 72dp cover, two
/// text lines and a chip.
final class _BookingCardSkeleton extends StatelessWidget {
  const _BookingCardSkeleton({required this.titleWidth});

  final double titleWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsetsDirectional.all(Dimens.space12),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(
            color: dark ? colors.border : colors['borderNeutral'],
          ),
          borderRadius: BorderRadius.circular(Dimens.radiusCard),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(
              width: 72,
              height: 72,
              radius: Dimens.radiusField,
            ),
            const SizedBox(width: Dimens.space12),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: Dimens.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: titleWidth,
                      child: const SkeletonBox(
                        height: 14,
                        radius: Dimens.radiusChip,
                      ),
                    ),
                    const SizedBox(height: Dimens.space8),
                    const FractionallySizedBox(
                      widthFactor: 0.42,
                      child: SkeletonBox(height: 12, radius: Dimens.radiusChip),
                    ),
                    const SizedBox(height: Dimens.space12),
                    const SkeletonBox(
                      width: 96,
                      height: 22,
                      radius: Dimens.radiusChip,
                    ),
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

enum _StateKind { error, offline, empty }

/// The centered face of a tab with no cards: a 64dp tone circle, a title,
/// an optional hint, one action and, for errors, a selectable reference.
/// The action disables itself and shows progress while its request runs.
final class _StateMessage extends StatefulWidget {
  const _StateMessage({
    required this.kind,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
    this.reference,
    this.outlined = false,
  });

  final _StateKind kind;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final Future<void> Function() onAction;
  final String? reference;
  final bool outlined;

  @override
  State<_StateMessage> createState() => _StateMessageState();
}

final class _StateMessageState extends State<_StateMessage> {
  var _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onAction();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? colors['textAccent'] : colors.primary;
    final base = theme.textTheme.bodyMedium!;
    final (circle, glyph) = switch (widget.kind) {
      _StateKind.error => (
        colors['rejectedBackground'],
        colors['rejectedText'],
      ),
      _StateKind.offline => (
        colors['cancelledBackground'],
        colors['cancelledText'],
      ),
      _StateKind.empty => (colors['badgeNavActive'], ink),
    };
    final icon = switch (widget.kind) {
      _StateKind.error => AppIcons.errorOutline,
      _StateKind.offline => AppIcons.wifiOff,
      _StateKind.empty => AppIcons.calendarMonth,
    };
    final disabledBg = colors.textPrimary.withValues(alpha: 0.12);
    final disabledFg = colors.textPrimary.withValues(alpha: 0.38);
    final buttonText = base.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(Dimens.radiusButton)),
    );
    const minimum = Size(160, Dimens.minTouchTarget);
    const padding = EdgeInsetsDirectional.symmetric(
      horizontal: Dimens.space24,
    );
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_busy) ...[
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: disabledFg,
            ),
          ),
          const SizedBox(width: Dimens.space8),
        ],
        Flexible(child: Text(widget.actionLabel, textAlign: TextAlign.center)),
      ],
    );
    final onPressed = _busy ? null : _run;
    // While busy both styles fall back to the same filled disabled look.
    final button = widget.outlined && !_busy
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              side: BorderSide(color: ink),
              minimumSize: minimum,
              padding: padding,
              shape: shape,
              textStyle: buttonText,
              overlayColor: ink,
            ),
            child: child,
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor: disabledBg,
              disabledForegroundColor: disabledFg,
              minimumSize: minimum,
              padding: padding,
              shape: shape,
              textStyle: buttonText,
              overlayColor: const Color(0xFF000000),
            ),
            child: child,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: glyph),
          ),
        ),
        const SizedBox(height: Dimens.space16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            style: base.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.5,
              color: colors.textPrimary,
            ),
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: Dimens.space4),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: base.copyWith(
              fontSize: 14,
              height: 1.6,
              color: colors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: Dimens.space20),
        button,
        if (widget.reference != null) ...[
          const SizedBox(height: Dimens.space12),
          SelectableText(
            l10n.referenceNumber(widget.reference!),
            textAlign: TextAlign.center,
            style: base.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}
