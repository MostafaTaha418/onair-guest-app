import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Scaffold(
      body: ListView(
        key: const ValueKey('home-scroll'),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(gradient: colors.gradient('header')),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.welcome,
                        style: context.textStyles.homeWelcome.copyWith(
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                    BlocBuilder<ConnectivityCubit, ConnectivityState>(
                      builder: (context, state) => Semantics(
                        label: l10n.notifications,
                        button: true,
                        child: IconButton(
                          key: const ValueKey('notifications-button'),
                          tooltip: l10n.notifications,
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: colors.onPrimary,
                          ),
                          onPressed: state.isOnline
                              ? () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.notAvailable),
                                      ),
                                    )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const LoadingView(),
          const LoadingView(),
          const LoadingView(),
        ],
      ),
    );
  }
}
