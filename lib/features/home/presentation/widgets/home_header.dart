import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/brand/on_air_logo.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Guest identity and favorites, following the supplied home header reference.
final class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  void _openAccountRoute(BuildContext context, String target) {
    if (context.read<AuthCubit>().state is SignedIn) {
      context.go(target);
      return;
    }
    unawaited(
      context.push<void>(
        Uri(
          path: AppRoutes.login,
          queryParameters: {'from': target, 'cancelTo': AppRoutes.home},
        ).toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Dimens.screenSide,
          Dimens.space16,
          Dimens.screenSide,
          Dimens.space8,
        ),
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final name = switch (authState) {
              SignedIn(:final account) => account.fullName,
              _ => null,
            };
            final signedIn = authState is SignedIn;
            return Row(
              children: [
                if (signedIn) ...[
                  OnAirLogo.mark(
                    key: const ValueKey('home-brand-mark'),
                    height: 42,
                    color: context.colors.onPrimary,
                  ),
                  const SizedBox(width: Dimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.homeHello,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.homeWelcome.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                        if (name != null && name.isNotEmpty)
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.homeUserName.copyWith(
                              color: colors.onPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OnAirLogo.lockup(
                        key: const ValueKey('home-brand-lockup'),
                        height: 38,
                        color: context.colors.onPrimary,
                      ),
                    ),
                  ),
                const SizedBox(width: Dimens.space12),
                _HeaderAction(
                  key: const ValueKey('home-favorites-button'),
                  label: l10n.favorites,
                  icon: AppIcons.favorite,
                  iconColor: colors['favorite'],
                  onTap: () => _openAccountRoute(context, AppRoutes.favorites),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconColor,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: colors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 56,
            child: Icon(icon, size: 26, color: iconColor ?? colors.primary),
          ),
        ),
      ),
    );
  }
}
