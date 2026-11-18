import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/support/presentation/widgets/call_support_button.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The full-screen notice a `suspended`/`deleted` account sees on
/// account-gated routes (review fix 6) — the same shape as the
/// not-available screen: one message, one way out. G4 adds the public FAQ
/// and the call button as the ways forward (task T061).
final class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: EmptyView(
        icon: AppIcons.personOutline,
        message: l10n.errorAccountSuspended,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.supportFaq),
              style: TextButton.styleFrom(
                foregroundColor: context.colors['textAccent'],
                minimumSize: const Size(0, Dimens.minTouchTarget),
              ),
              icon: const Icon(Icons.quiz_outlined),
              label: Text(l10n.supportFaq),
            ),
            const SizedBox(height: Dimens.space12),
            const SizedBox(width: 280, child: CallSupportButton()),
            const SizedBox(height: Dimens.space16),
            OutlinedButton.icon(
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
              label: Text(l10n.signOut),
            ),
          ],
        ),
      ),
    );
  }
}
