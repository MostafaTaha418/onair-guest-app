import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/notifications/presentation/unread_count_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The Home header: the greeting over the header gradient, plus the
/// notifications bell with the live unread badge (US5).
final class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  /// The app-scoped cubit; harnesses that pump the header without the app
  /// (older tests) simply get the bare bell.
  UnreadCountCubit? _unread(BuildContext context) {
    try {
      return context.read<UnreadCountCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final unread = _unread(context);
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
                builder: (context, state) => unread == null
                    ? _Bell(
                        online: state.isOnline,
                      )
                    : BlocBuilder<UnreadCountCubit, int>(
                        builder: (context, count) => _Bell(
                          online: state.isOnline,
                          unreadCount: count,
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

final class _Bell extends StatelessWidget {
  const _Bell({required this.online, this.unreadCount});

  final bool online;

  /// Null for visitors and harnesses without the cubit: no badge shows.
  final int? unreadCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final count = unreadCount ?? 0;
    final signedIn = unreadCount != null;
    return Semantics(
      label: signedIn && count > 0
          ? l10n.unreadBadge('$count')
          : l10n.notifications,
      button: true,
      child: IconButton(
        key: const ValueKey('notifications-button'),
        tooltip: l10n.notifications,
        icon: Badge(
          isLabelVisible: signedIn && count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: Icon(
            Icons.notifications_outlined,
            color: colors.onPrimary,
          ),
        ),
        onPressed: online
            ? () => unawaited(context.push(AppRoutes.notifications))
            : null,
      ),
    );
  }
}
