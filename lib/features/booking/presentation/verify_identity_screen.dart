import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/booking/presentation/verify_identity_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// US2: email then phone, both confirmed with one code. The booking draft
/// underneath stays intact; the screen pops with `true` when done.
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
                VerifyPhoneStep() => _PhoneStep(state: state),
                VerifyCodeStep() => _CodeStep(state: state),
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

final class _PhoneStep extends StatefulWidget {
  const _PhoneStep({required this.state});

  final VerifyPhoneStep state;

  @override
  State<_PhoneStep> createState() => _PhoneStepState();
}

final class _PhoneStepState extends State<_PhoneStep> {
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _hasWhatsapp = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<VerifyIdentityCubit>();
    final state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnAirTextField(
          controller: _phoneController,
          label: l10n.phoneNumber,
          hint: l10n.authPhoneHint,
          keyboardType: TextInputType.phone,
          enabled: !state.sending,
          errorText: state.error == null
              ? null
              : apiErrorMessage(
                  ApiError(code: state.error!, messageKey: ''),
                  l10n,
                ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          value: _hasWhatsapp,
          onChanged: state.sending
              ? null
              : (value) => setState(() => _hasWhatsapp = value),
          title: Text(
            l10n.verifyHasWhatsapp,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
        ),
        if (!_hasWhatsapp)
          OnAirTextField(
            controller: _whatsappController,
            label: l10n.verifyWhatsappNumber,
            keyboardType: TextInputType.phone,
            enabled: !state.sending,
          ),
        const SizedBox(height: Dimens.space16),
        OnAirPrimaryButton(
          key: const ValueKey('verify-send-phone'),
          label: l10n.sendCode,
          isLoading: state.sending,
          onPressed: state.sending
              ? null
              : () => cubit.submitPhone(
                  _phoneController.text,
                  hasWhatsapp: _hasWhatsapp,
                  whatsapp: _hasWhatsapp ? null : _whatsappController.text,
                ),
        ),
      ],
    );
  }
}

final class _CodeStep extends StatefulWidget {
  const _CodeStep({required this.state});

  final VerifyCodeStep state;

  @override
  State<_CodeStep> createState() => _CodeStepState();
}

final class _CodeStepState extends State<_CodeStep> {
  late int _secondsLeft = widget.state.retryAfter?.inSeconds ?? 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
      });
    });
  }

  @override
  void didUpdateWidget(_CodeStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new challenge or a fresh rate-limit window restarts the countdown.
    if (widget.state.retryAfter != oldWidget.state.retryAfter ||
        widget.state.challengeId != oldWidget.state.challengeId) {
      setState(() {
        _secondsLeft = widget.state.retryAfter?.inSeconds ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<VerifyIdentityCubit>();
    final state = widget.state;
    final canResend = _secondsLeft == 0 && !state.verifying;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.verifyCodeSentToEmail,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: Dimens.space16),
        OnAirOtpField(onCompleted: cubit.submitCode, enabled: !state.verifying),
        if (state.error != null) ...[
          const SizedBox(height: Dimens.space8),
          Text(
            apiErrorMessage(ApiError(code: state.error!, messageKey: ''), l10n),
            style: TextStyle(color: context.colors.errorText),
          ),
        ],
        const SizedBox(height: Dimens.space16),
        TextButton(
          key: const ValueKey('verify-resend'),
          onPressed: canResend ? cubit.resendCode : null,
          child: Text(
            canResend ? l10n.authResend : l10n.verifyResendIn('$_secondsLeft'),
          ),
        ),
      ],
    );
  }
}
