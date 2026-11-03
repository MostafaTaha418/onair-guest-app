import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/components/on_air_bottom_nav.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/notifications/presentation/unread_count_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
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
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }
}
