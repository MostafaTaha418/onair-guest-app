import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/design_system/typography/on_air_text_styles.dart';
import 'package:on_air/features/support/presentation/faq/faq_cubit.dart';
import 'package:on_air/features/support/presentation/widgets/call_support_button.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// «الأسئلة الشائعة» (US3): public, searchable, cached offline. The Hero
/// gradient carries the search field; stale cache renders the
/// «قد تكون قديمة» banner above the list; the call button sits at the
/// bottom (contracts/ui-screens.md §2).
final class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

final class _FaqScreenState extends State<FaqScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The search field is inside the gradient Hero, so the hint colors come
    // from the theme; the cubit gets the app locale for item localization.
    context.read<FaqCubit>().setLocale(
      AppLocalizations.of(context).localeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportFaq)),
      body: BlocBuilder<FaqCubit, FaqState>(
        builder: (context, state) {
          if (state is FaqLoading) return const LoadingView();
          if (state is FaqFailed) {
            return ErrorView(
              message: apiErrorMessage(state.error, l10n),
              referenceNumber: state.error.requestId,
              onRetry: context.read<FaqCubit>().load,
            );
          }
          final ready = state as FaqReady;
          return Column(
            children: [
              const _FaqHero(),
              if (ready.stale)
                InfoBanner(
                  message: l10n.supportFaqStale,
                  tone: StatusTone.warning,
                ),
              Expanded(child: _list(context, ready)),
              const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  Dimens.screenSide,
                  Dimens.space8,
                  Dimens.screenSide,
                  Dimens.space16,
                ),
                child: CallSupportButton(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _list(BuildContext context, FaqReady state) {
    final l10n = AppLocalizations.of(context);
    if (state.noResults) {
      return ListView(
        children: [
          const SizedBox(height: 96),
          const Center(child: Icon(Icons.search_off, size: 56)),
          const SizedBox(height: Dimens.space16),
          Center(
            child: Text(
              l10n.supportFaqNoResults,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: Dimens.space16),
          Center(
            child: OnAirPrimaryButton(
              label: l10n.supportNewCase,
              // A visitor is routed to sign-in with a return path by the
              // router redirect (SC-007).
              onPressed: () => context.push(AppRoutes.supportNew).ignore(),
            ),
          ),
        ],
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 96),
          const Center(child: Icon(Icons.quiz_outlined, size: 56)),
          const SizedBox(height: Dimens.space16),
          Center(child: Text(l10n.supportFaqNoResults)),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsetsDirectional.fromSTEB(
        Dimens.screenSide,
        Dimens.space16,
        Dimens.screenSide,
        Dimens.space16,
      ),
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: Dimens.space12),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ExpansionTile(
            tilePadding: const EdgeInsetsDirectional.symmetric(
              horizontal: Dimens.space16,
            ),
            childrenPadding: const EdgeInsetsDirectional.fromSTEB(
              Dimens.space16,
              0,
              Dimens.space16,
              Dimens.space16,
            ),
            title: Text(
              item.question,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.onAirExtraBold,
            ),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(item.answer),
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _FaqHero extends StatelessWidget {
  const _FaqHero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(
        Dimens.screenSide,
        Dimens.space16,
        Dimens.screenSide,
        Dimens.space8,
      ),
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
          Text(
            l10n.supportSubtitle,
            style: Theme.of(context).textTheme.titleLarge?.onAirExtraBold
                .copyWith(
                  color: colors.onPrimary,
                ),
          ),
          const SizedBox(height: Dimens.space16),
          OnAirTextField(
            key: const ValueKey('faq-search-field'),
            pill: true,
            prefixIcon: Icons.search,
            hint: l10n.supportFaqSearch,
            onChanged: context.read<FaqCubit>().search,
          ),
        ],
      ),
    );
  }
}
