import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/error_message.dart';
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
    return RefreshIndicator(
      onRefresh: context.read<SupportHomeCubit>().refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _SupportHero()),
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              Dimens.screenSide,
              Dimens.space20,
              Dimens.screenSide,
              Dimens.space8,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.supportMyCases,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.onAirExtraBold,
              ),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.forum_outlined,
                message: l10n.supportEmpty,
              ),
            )
          else
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
                        const SizedBox(height: Dimens.space16),
                        Text(
                          l10n.supportFinishedCases,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.onAirExtraBold,
                        ),
                        const SizedBox(height: Dimens.space8),
                      ],
                      _CaseCard(item: item, now: widget.now),
                      const SizedBox(height: Dimens.space12),
                    ],
                  );
                },
              ),
            ),
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
          Icon(Icons.support_agent, color: colors.onPrimary, size: 36),
          const SizedBox(height: Dimens.space8),
          Text(
            l10n.supportSubtitle,
            style: Theme.of(context).textTheme.titleLarge?.onAirExtraBold
                .copyWith(
                  color: colors.onPrimary,
                ),
          ),
          const SizedBox(height: Dimens.space16),
          Wrap(
            spacing: Dimens.space8,
            runSpacing: Dimens.space8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => context.push(AppRoutes.supportNew),
                icon: const Icon(Icons.add),
                label: Text(l10n.supportNewCase),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.push(AppRoutes.supportFaq),
                icon: const Icon(Icons.quiz_outlined),
                label: Text(l10n.supportFaq),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.item, this.now});
  final SupportCase item;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimens.radiusCard),
          onTap: () => context.push(AppRoutes.supportCase(item.id)),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Dimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.code} · ${supportTypeLabel(item.type, l10n)}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.onAirExtraBold,
                      ),
                    ),
                    if (item.hasUnreadStaffReply)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsetsDirectional.only(
                          end: Dimens.space8,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    CaseStatusChip(status: supportStatus(item.status)),
                  ],
                ),
                if (item.bookingCode case final code?) ...[
                  const SizedBox(height: Dimens.space8),
                  Text(l10n.supportLinkedBooking(code)),
                ],
                const SizedBox(height: Dimens.space8),
                Text(
                  l10n.supportLastUpdate(
                    supportRelativeTime(
                      item.lastActivityAt,
                      now?.call() ?? DateTime.now(),
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
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
