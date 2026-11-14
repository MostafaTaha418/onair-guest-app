import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The account placeholder (contracts/ui-screens.md §5): the sign-in
/// method and the confirmed phone with the change entry until G4 builds
/// the full settings.
final class AccountPlaceholderScreen extends StatelessWidget {
  const AccountPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) => Scaffold(
      body: state is SignedIn
          ? _SignedInBody(account: state.account)
          : EmptyView(
              icon: AppIcons.personOutline,
              message: AppLocalizations.of(context).accountEmpty,
              action: state is SigningOut ? const _SignOutButton() : null,
            ),
    ),
  );
}

final class _SignedInBody extends StatelessWidget {
  const _SignedInBody({required this.account});

  final GuestAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final providers = account.authProviders
        .map(
          (provider) => switch (provider) {
            AuthProvider.google => l10n.accountMethodGoogle,
            AuthProvider.apple => l10n.accountMethodApple,
            AuthProvider.email => l10n.accountMethodEmail,
          },
        )
        .toList();
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        _AccountRow(
          icon: AppIcons.keyOutline,
          label: l10n.accountSignInMethod,
          value: providers.join('، '),
        ),
        if (account.phone != null) ...[
          const SizedBox(height: Dimens.space12),
          _AccountRow(
            icon: AppIcons.phoneOutlined,
            label: l10n.accountPhone,
            value: maskPhone(account.phone!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (account.phoneVerified)
                  StatusChip(
                    key: const ValueKey('account-phone-chip'),
                    label: l10n.accountPhoneConfirmed,
                    tone: StatusTone.success,
                  ),
                TextButton(
                  key: const ValueKey('account-change-phone'),
                  onPressed: () =>
                      unawaited(context.push(AppRoutes.accountPhone)),
                  style: TextButton.styleFrom(
                    foregroundColor: colors['textAccent'],
                  ),
                  child: Text(l10n.accountChangePhone),
                ),
              ],
            ),
          ),
        ],
        // G4: hide «تغيير كلمة المرور» when !account.hasPassword (FR-043)
        if (account.email != null && !account.emailVerified) ...[
          const SizedBox(height: Dimens.space16),
          Text(
            '${l10n.authEmailStatus}: ${l10n.authEmailNotVerified}',
            key: const ValueKey('email-unverified-status'),
          ),
          TextButton(
            key: const ValueKey('verify-email-now'),
            onPressed: () => unawaited(
              context.read<AuthCubit>().requestEmailVerification(
                account.email!,
              ),
            ),
            child: Text(l10n.authVerifyNow),
          ),
        ],
        const SizedBox(height: Dimens.space24),
        const _SignOutButton(),
      ],
    );
  }
}

/// One pill info row, the same shape the «أكّد رقمك» email row uses.
final class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: Dimens.space16,
        vertical: Dimens.space12,
      ),
      decoration: BoxDecoration(
        color: colors['socialFill'],
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: colors['border']),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors['textMuted']),
          const SizedBox(width: Dimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textStyles.placeholder.copyWith(
                    color: colors['textMuted'],
                  ),
                ),
                Text(value, style: context.textStyles.input),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

final class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    final signingOut = context.watch<AuthCubit>().state is SigningOut;
    return OutlinedButton.icon(
      key: const ValueKey('sign-out-button'),
      onPressed: signingOut
          ? null
          : () async {
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
      icon: signingOut
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(AppIcons.logout),
      label: Text(AppLocalizations.of(context).signOut),
    );
  }
}
