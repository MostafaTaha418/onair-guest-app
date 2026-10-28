import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class AccountPlaceholderScreen extends StatelessWidget {
  const AccountPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) => Scaffold(
      body: EmptyView(
        icon: Icons.person_outline,
        message: AppLocalizations.of(context).accountEmpty,
        action: state is SignedIn || state is SigningOut
            ? Padding(
                padding: const EdgeInsets.only(top: Dimens.space24),
                child: Column(
                  children: [
                    if (state case SignedIn(
                      :final account,
                    ) when account.email != null && !account.emailVerified) ...[
                      Text(
                        '${AppLocalizations.of(context).authEmailStatus}: '
                        '${AppLocalizations.of(context).authEmailNotVerified}',
                        key: const ValueKey('email-unverified-status'),
                      ),
                      TextButton(
                        key: const ValueKey('verify-email-now'),
                        onPressed: () => context
                            .read<AuthCubit>()
                            .requestEmailVerification(account.email!),
                        child: Text(
                          AppLocalizations.of(context).authVerifyNow,
                        ),
                      ),
                      const SizedBox(height: Dimens.space12),
                    ],
                    OutlinedButton.icon(
                      key: const ValueKey('sign-out-button'),
                      onPressed: state is SigningOut
                          ? null
                          : () async {
                              await context.read<AuthCubit>().signOut();
                              if (context.mounted) {
                                context.go(AppRoutes.home);
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors['destructive'],
                        side: BorderSide(
                          color: context.colors['destructive'],
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                      icon: state is SigningOut
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout),
                      label: Text(AppLocalizations.of(context).signOut),
                    ),
                  ],
                ),
              )
            : null,
      ),
    ),
  );
}
