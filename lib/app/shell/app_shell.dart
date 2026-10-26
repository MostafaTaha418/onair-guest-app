import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/design_system/components/on_air_bottom_nav.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: OnAirBottomNav(
        currentIndex: navigationShell.currentIndex,
        labels: [
          l10n.home,
          l10n.search,
          l10n.bookings,
          l10n.favorites,
          l10n.account,
        ],
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
