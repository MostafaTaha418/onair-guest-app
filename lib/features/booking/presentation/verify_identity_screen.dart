import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/booking/presentation/verify_identity_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// US2: the email is confirmed with one code; an unconfirmed phone hands
/// the guest to the account's «أكّد رقمك» WhatsApp step (S005 US6). The
/// booking draft underneath stays intact; the screen pops with `true` when
/// done.
final class VerifyIdentityScreen extends StatelessWidget {
  const VerifyIdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyTitle)),
      body: BlocConsumer<VerifyIdentityCubit, VerifyIdentityState>(
        listener: (context, state) {
          if (state is VerifyDone) context.pop(true);
        },
        builder: (context, state) {
          final cubit = context.read<VerifyIdentityCubit>();
          return ListView(
            padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
            children: [
              Text(
                l10n.verifyIntro,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: Dimens.space16),
              switch (state) {
                VerifyChecking() => const Center(
                  child: Padding(
                    padding: EdgeInsetsDirectional.all(Dimens.space32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                VerifyEmailStep() => _EmailStep(state: state),
                VerifyPhoneStep() => _PhoneCard(state: state),
                VerifyFailed() => ErrorView(
                  message: apiErrorMessage(state.error, l10n),
                  onRetry: cubit.start,
                  referenceNumber: state.error.requestId,
                ),
                _ => const SizedBox.shrink(),
              },
            ],
          );
        },
      ),
    );
  }
}

final class _EmailStep extends StatelessWidget {
  const _EmailStep({required this.state});

  final VerifyEmailStep state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<VerifyIdentityCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          state.email,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: Dimens.space16),
        if (!state.codeSent)
          OnAirPrimaryButton(
            key: const ValueKey('verify-send-email'),
            label: l10n.sendCode,
            isLoading: state.sending,
            onPressed: state.sending ? null : cubit.sendEmailCode,
          )
        else ...[
          OnAirOtpField(onCompleted: cubit.submitEmailCode),
          const SizedBox(height: Dimens.space8),
          Text(
            l10n.verifyEmailCodeHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: Dimens.space8),
          Text(
            apiErrorMessage(ApiError(code: state.error!, messageKey: ''), l10n),
            style: TextStyle(color: context.colors.errorText),
          ),
        ],
      ],
    );
  }
}

/// The unconfirmed phone (S005 US6, T071): no phone entry here any more —
/// the card hands the guest to the account's WhatsApp step and re-checks
/// the booking status when it returns with `true`.
final class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.state});

  final VerifyPhoneStep state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<VerifyIdentityCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.bookingPhoneNotVerified,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: Dimens.space16),
        OnAirPrimaryButton(
          key: const ValueKey('verify-phone-whatsapp'),
          label: l10n.verifyPhoneOnWhatsApp,
          onPressed: () async {
            final ok = await context.push<bool>(AppRoutes.accountPhone);
            if (ok == true) unawaited(cubit.start());
          },
        ),
      ],
    );
  }
}
