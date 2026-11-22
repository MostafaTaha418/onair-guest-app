import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/components/booking_flow_kit.dart';
import 'package:on_air/design_system/components/on_air_bottom_nav.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/notifications/presentation/unread_count_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// A back press at a shell root exits the app, so we ask for a second press
  /// within this window instead of leaving on the first one.
  static const _exitWindow = Duration(seconds: 2);
  DateTime? _lastBackAt;

  void _handlePop(bool didPop, Object? result) {
    if (didPop) return;
    final now = DateTime.now();
    final last = _lastBackAt;
    if (last != null && now.difference(last) <= _exitWindow) {
      unawaited(SystemNavigator.pop());
      return;
    }
    _lastBackAt = now;
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            l10n.exitConfirmHint,
            textAlign: TextAlign.center,
            style: flowText(
              context,
              base: Theme.of(context).textTheme.bodyMedium,
              color: colors.onPrimary,
              weight: FontWeight.w600,
            ),
          ),
          duration: _exitWindow,
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.textPrimary,
          elevation: 6,
          shape: const StadiumBorder(),
          dismissDirection: DismissDirection.down,
          margin: const EdgeInsetsDirectional.fromSTEB(
            Dimens.space32,
            0,
            Dimens.space32,
            Dimens.space16,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final navigationShell = widget.navigationShell;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: navigationShell),
            if (navigationShell.currentIndex != 1)
              Align(
                alignment: Alignment.bottomCenter,
                child: BlocBuilder<UnreadCountCubit, int>(
                  builder: (context, unreadCount) => OnAirBottomNav(
                    currentIndex: switch (navigationShell.currentIndex) {
                      0 => 0,
                      final index => index - 1,
                    },
                    unreadCount: unreadCount,
                    labels: [
                      l10n.home,
                      l10n.bookings,
                      l10n.notifications,
                      l10n.account,
                    ],
                    onTap: (index) => _openTab(context, index),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openTab(BuildContext context, int index) {
    const locations = [
      AppRoutes.home,
      AppRoutes.bookings,
      AppRoutes.notifications,
      AppRoutes.account,
    ];
    final target = locations[index];
    if (AppRoutes.requiresAccount(target) &&
        context.read<AuthCubit>().state is! SignedIn) {
      final origin = GoRouterState.of(context).uri.toString();
      unawaited(
        context.push<void>(
          Uri(
            path: AppRoutes.login,
            queryParameters: {'from': target, 'cancelTo': origin},
          ).toString(),
        ),
      );
      return;
    }
    final branchIndex = index == 0 ? 0 : index + 1;
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
  }
}
