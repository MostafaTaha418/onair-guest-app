import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/components/booking_flow_kit.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/design_system/typography/on_air_text_styles.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/presentation/home/support_home_cubit.dart';
import 'package:on_air/features/support/presentation/support_texts.dart';
import 'package:on_air/features/support/presentation/widgets/call_support_button.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({this.now, super.key});

  final DateTime Function()? now;

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

final class _SupportHomeScreenState extends State<SupportHomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 240) {
      unawaited(context.read<SupportHomeCubit>().loadMore());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportTitle)),
      body: BlocBuilder<SupportHomeCubit, SupportHomeState>(
        builder: (context, state) => Column(
          children: [
            if ((state is SupportHomeReady && state.offline) ||
                (state is SupportHomeEmpty && state.offline))
              const OfflineBanner(),
            Expanded(child: _body(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SupportHomeState state) {
    final l10n = AppLocalizations.of(context);
    if (state is SupportHomeLoading) return const LoadingView();
    if (state is SupportHomeFailed) {
      return ErrorView(
        message: apiErrorMessage(state.error, l10n),
        referenceNumber: state.error.requestId,
        onRetry: context.read<SupportHomeCubit>().load,
      );
    }
    final items = state is SupportHomeReady
        ? state.items
        : const <SupportCase>[];
    final openCount = items.where((c) => c.status.isOpen).length;
    final finishedCount = items.length - openCount;
    return RefreshIndicator(
      onRefresh: context.read<SupportHomeCubit>().refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _SupportHero()),
          const SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              Dimens.screenSide,
              Dimens.space16,
              Dimens.screenSide,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _SupportActions()),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.forum_outlined,
                message: l10n.supportEmpty,
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Dimens.screenSide,
                Dimens.space20,
                Dimens.screenSide,
                Dimens.space12,
              ),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: l10n.supportMyCases,
                  count: openCount,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Dimens.screenSide,
                0,
                Dimens.screenSide,
                Dimens.space24,
              ),
              sliver: SliverList.builder(
                itemCount:
                    items.length +
                    (state is SupportHomeReady && state.loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(Dimens.space16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final item = items[index];
                  final startsFinished =
                      !item.status.isOpen &&
                      (index == 0 || items[index - 1].status.isOpen);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (startsFinished) ...[
                        const SizedBox(height: Dimens.space8),
                        _SectionHeader(
                          title: l10n.supportFinishedCases,
                          count: finishedCount,
                          muted: true,
                        ),
                        const SizedBox(height: Dimens.space12),
                      ],
                      _CaseCard(item: item, now: widget.now),
                      const SizedBox(height: Dimens.space12),
                    ],
                  );
                },
              ),
            ),
          ],
          // «اتصل بخدمة العملاء» + hours at the bottom when a number is
          // published (US3-4); hidden otherwise.
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              Dimens.screenSide,
              items.isEmpty ? 0 : Dimens.space8,
              Dimens.screenSide,
              Dimens.space24,
            ),
            sliver: const SliverToBoxAdapter(child: CallSupportButton()),
          ),
        ],
      ),
    );
  }
}

final class _SupportHero extends StatelessWidget {
  const _SupportHero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Container(
      margin: const EdgeInsetsDirectional.all(Dimens.screenSide),
      padding: const EdgeInsetsDirectional.all(Dimens.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [colors.primary, colors.primary.withValues(alpha: .72)],
        ),
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: .16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent, color: colors.onPrimary, size: 28),
          ),
          const SizedBox(height: Dimens.space12),
          Text(
            l10n.supportSubtitle,
            style: Theme.of(context).textTheme.titleLarge?.onAirExtraBold
                .copyWith(
                  color: colors.onPrimary,
                ),
          ),
          const SizedBox(height: Dimens.space4),
          Text(
            l10n.supportHeroBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onPrimary.withValues(alpha: .85),
            ),
          ),
        ],
      ),
    );
  }
}

/// The two quick actions under the hero: a filled «حالة جديدة» (the one clear
/// primary action) and a quiet «الأسئلة الشائعة». IntrinsicHeight keeps them
/// level even when a label wraps to two lines at narrow widths or large text.
final class _SupportActions extends StatelessWidget {
  const _SupportActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.add,
              label: l10n.supportNewCase,
              filled: true,
              onTap: () => context.push(AppRoutes.supportNew),
            ),
          ),
          const SizedBox(width: Dimens.space12),
          Expanded(
            child: _ActionCard(
              icon: Icons.quiz_outlined,
              label: l10n.supportFaq,
              filled: false,
              onTap: () => context.push(AppRoutes.supportFaq),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = filled ? colors.onPrimary : colors.textPrimary;
    final iconBg = filled
        ? colors.onPrimary.withValues(alpha: .18)
        : colors['badgeNavActive'];
    final iconFg = filled ? colors.onPrimary : colors.primary;
    return Semantics(
      button: true,
      child: Material(
        color: filled ? colors.primary : colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsetsDirectional.all(Dimens.space12),
            decoration: filled
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimens.radiusCard),
                    border: Border.all(color: colors.border),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(Dimens.radiusField),
                  ),
                  child: Icon(icon, color: iconFg, size: 22),
                ),
                const SizedBox(height: Dimens.space8),
                Text(
                  label,
                  style: flowText(
                    context,
                    base: Theme.of(context).textTheme.bodyLarge,
                    color: foreground,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A section title with a count pill (open cases, finished cases).
final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    this.muted = false,
  });

  final String title;
  final int count;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = muted
        ? Theme.of(context).textTheme.titleMedium?.onAirExtraBold
        : Theme.of(context).textTheme.titleLarge?.onAirExtraBold;
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: muted ? style?.copyWith(color: colors.textSecondary) : style,
          ),
        ),
        const SizedBox(width: Dimens.space8),
        _CountPill(count: count, muted: muted),
      ],
    );
  }
}

final class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, this.muted = false});

  final int count;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = muted
        ? colors['cancelledBackground']
        : colors['badgeNavActive'];
    final foreground = muted
        ? colors['cancelledText']
        : (dark ? colors['textAccent'] : colors.primary);
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      alignment: Alignment.center,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: Dimens.space8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: flowText(
          context,
          base: Theme.of(context).textTheme.labelMedium,
          color: foreground,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// (background, foreground) for a case's leading tile, matching the status
/// chip tones (S005) so color scanning and the chip agree.
(Color, Color) _statusTint(CaseStatus status, BuildContext context) {
  final colors = context.colors;
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (status) {
    CaseStatus.open => (colors['pendingBackground'], colors['pendingText']),
    CaseStatus.inProgress => (
      colors['badgeNavActive'],
      dark ? colors['textAccent'] : colors.primary,
    ),
    CaseStatus.waitingUser => (
      colors['warningContainer'],
      colors['onWarningContainer'],
    ),
    CaseStatus.resolved => (
      colors['successContainer'],
      colors['onSuccessContainer'],
    ),
    CaseStatus.closed => (
      colors['cancelledBackground'],
      colors['cancelledText'],
    ),
    _ => (colors['cancelledBackground'], colors['cancelledText']),
  };
}

final class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.item, this.now});
  final SupportCase item;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final (tintBg, tintFg) = _statusTint(item.status, context);
    return Semantics(
      button: true,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.supportCase(item.id)),
          child: Container(
            padding: const EdgeInsetsDirectional.all(Dimens.space12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimens.radiusCard),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tintBg,
                    borderRadius: BorderRadius.circular(Dimens.radiusField),
                  ),
                  child: Icon(
                    supportTypeIcon(item.type),
                    color: tintFg,
                    size: 22,
                  ),
                ),
                const SizedBox(width: Dimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.code} · '
                              '${supportTypeLabel(item.type, l10n)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.onAirExtraBold,
                            ),
                          ),
                          if (item.hasUnreadStaffReply)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsetsDirectional.symmetric(
                                horizontal: Dimens.space8,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(width: Dimens.space8),
                          CaseStatusChip(status: supportStatus(item.status)),
                        ],
                      ),
                      const SizedBox(height: Dimens.space8),
                      Wrap(
                        spacing: Dimens.space8,
                        runSpacing: Dimens.space4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (item.bookingCode case final code?)
                            _BookingChip(
                              label: l10n.supportLinkedBooking(code),
                            ),
                          _MetaLine(
                            icon: Icons.schedule,
                            text: l10n.supportLastUpdate(
                              supportRelativeTime(
                                item.lastActivityAt,
                                now?.call() ?? DateTime.now(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The linked-booking pill on a case card: a selected-tone chip with a link
/// glyph, so the booking reference reads as a tappable-looking tag.
final class _BookingChip extends StatelessWidget {
  const _BookingChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? colors['textAccent'] : colors.primary;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: Dimens.space8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colors['badgeNavActive'],
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 13, color: foreground),
          const SizedBox(width: Dimens.space4),
          Text(
            label,
            style: flowText(
              context,
              base: Theme.of(context).textTheme.labelSmall,
              color: foreground,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

final class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textSecondary),
        const SizedBox(width: Dimens.space4),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
