import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The Home header: the greeting over the header gradient, plus the
/// notifications bell with the exact G0 behaviour.
final class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(gradient: colors.gradient('header')),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.homeHello,
                      style: context.textStyles.homeWelcome.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        final name = switch (authState) {
                          SignedIn(:final account) => account.fullName,
                          _ => null,
                        };
                        if (name == null || name.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          name,
                          style: context.textStyles.homeUserName.copyWith(
                            color: colors.onPrimary,
                          ),
                        );
                      },
                    ),
                  ],
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
                        ? () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.notAvailable)),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
