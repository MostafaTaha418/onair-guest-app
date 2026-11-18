import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The full-screen notice a `suspended`/`deleted` account sees on
/// account-gated routes (review fix 6) — the same shape as the
/// not-available screen: one message, one way out.
final class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: EmptyView(
      icon: AppIcons.personOutline,
      message: AppLocalizations.of(context).errorAccountSuspended,
      action: Padding(
        padding: const EdgeInsets.only(top: Dimens.space24),
        child: OutlinedButton.icon(
          key: const ValueKey('suspended-sign-out'),
          onPressed: () async {
            await context.read<AuthCubit>().signOut();
            if (context.mounted) {
              context.go(AppRoutes.home);
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: context.colors['destructive'],
            side: BorderSide(color: context.colors['destructive']),
            minimumSize: const Size(0, 48),
          ),
          icon: const Icon(AppIcons.logout),
          label: Text(AppLocalizations.of(context).signOut),
        ),
      ),
    ),
  );
}
