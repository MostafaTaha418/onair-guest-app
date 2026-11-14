import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/phone_verification/presentation/phone_verification_cubit.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/send_window_notice.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// The WhatsApp code step (contracts/ui-screens.md §4.2): the masked target,
/// the 6-digit field, «افتح واتساب», «تعديل الرقم» and the delivery notices.
/// The countdown on «ابعت كود جديد» arrives with US5.
final class WhatsAppCodeStep extends StatefulWidget {
  const WhatsAppCodeStep({required this.supportPhone, super.key});

  /// From `app_config`; the «كلّم الدعم» notices dial it (G4 brings the
  /// support screens).
  final String supportPhone;

  @override
  State<WhatsAppCodeStep> createState() => _WhatsAppCodeStepState();
}

class _WhatsAppCodeStepState extends State<WhatsAppCodeStep> {
  final _codeController = TextEditingController();
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    // The countdown text rebuilds alone; the field does not (§4.2, R8).
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  String? _errorText(String? key, AppLocalizations l10n) => switch (key) {
    'authOtpInvalid' => l10n.authOtpInvalid,
    'authOtpExpired' => l10n.authOtpExpired,
    'whatsappUseLatestCode' => l10n.whatsappUseLatestCode,
    'otpAttemptsExceeded' => l10n.otpAttemptsExceeded,
    'errorNoConnection' => l10n.errorNoConnection,
    'errorUnexpectedNoRef' => l10n.errorUnexpectedNoRef,
    _ => null,
  };

  Future<void> _openWhatsApp() async {
    try {
      await launchUrl(Uri.parse('whatsapp://'));
    } on Object {
      // Not installed (or blocked): silently do nothing (§4.2).
    }
  }

  Future<void> _contactSupport() async {
    try {
      await launchUrl(Uri.parse('tel:${widget.supportPhone}'));
    } on Object {
      // No dialer: silently do nothing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return BlocBuilder<PhoneVerificationCubit, PvState>(
      builder: (context, state) {
        if (state is! PvCode) return const SizedBox.shrink();
        final code = state;
        if (_codeController.text != code.code) {
          _codeController.text = code.code;
        }
        final cubit = context.read<PhoneVerificationCubit>();
        final noticeMessage = switch (code.notice) {
          PvNotice.notOnWhatsApp => l10n.whatsappNotOnWhatsApp,
          PvNotice.attestationFailed => l10n.otpAttestationFailed,
          PvNotice.temporarilyUnavailable => l10n.otpTemporarilyUnavailable,
          null => null,
        };
        final error = _errorText(code.errorKey, l10n);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.whatsappCodeTitle,
              key: const ValueKey('whatsapp-code-title'),
              style: context.textStyles.authTitle,
            ),
            const SizedBox(height: Dimens.space12),
            Text(
              l10n.whatsappCodeSentTo(code.challenge.maskedPhone),
              style: context.textStyles.authDescription.copyWith(
                color: colors['textMuted'],
              ),
            ),
            const SizedBox(height: Dimens.space32),
            if (noticeMessage != null) ...[
              NoticeCard(
                icon: AppIcons.errorOutline,
                message: noticeMessage,
                actionLabel: l10n.whatsappContactSupport,
                onAction: _contactSupport,
              ),
              const SizedBox(height: Dimens.space16),
            ],
            OnAirOtpField(
              key: const ValueKey('whatsapp-otp-field'),
              controller: _codeController,
              enabled: code.codeFieldEnabled && !code.verifying,
              onCompleted: (_) => cubit.verify(),
              onChanged: cubit.onCodeChanged,
            ),
            if (error != null) ...[
              const SizedBox(height: Dimens.space8),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  key: const ValueKey('whatsapp-code-error'),
                  style: TextStyle(color: colors.errorText),
                ),
              ),
            ],
            const SizedBox(height: Dimens.space24),
            Center(
              child: SizedBox(
                width: 230,
                child: OnAirPrimaryButton(
                  key: const ValueKey('whatsapp-confirm'),
                  label: l10n.whatsappConfirm,
                  onPressed:
                      code.code.length == 6 &&
                          code.codeFieldEnabled &&
                          !code.verifying
                      ? cubit.verify
                      : null,
                  isLoading: code.verifying,
                  gradient: true,
                  pill: true,
                  height: 62,
                ),
              ),
            ),
            const SizedBox(height: Dimens.space12),
            Center(
              child: OutlinedButton(
                key: const ValueKey('whatsapp-open'),
                onPressed: _openWhatsApp,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors['textAccent'],
                  shape: const StadiumBorder(),
                  side: BorderSide(color: colors['border']),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: Dimens.space24,
                    vertical: Dimens.space12,
                  ),
                ),
                child: Text(l10n.whatsappOpen),
              ),
            ),
            const SizedBox(height: Dimens.space16),
            // The server's window decides the wait (Constitution II): while
            // `next_send_at` is ahead the button is disabled and shows the
            // rendered remaining time.
            BlocBuilder<PhoneVerificationCubit, PvState>(
              builder: (context, state) {
                final codeState = state is PvCode ? state : code;
                final remaining = codeState.challenge.window.remainingUntilSend(
                  DateTime.now(),
                );
                final counting = remaining > Duration.zero;
                return TextButton(
                  key: const ValueKey('whatsapp-resend'),
                  onPressed:
                      counting || codeState.resending || codeState.verifying
                      ? null
                      : cubit.resend,
                  style: TextButton.styleFrom(
                    foregroundColor: colors['textAccent'],
                  ),
                  child: Text(
                    counting
                        ? l10n.whatsappResendIn(formatSendWait(remaining, l10n))
                        : l10n.whatsappResend,
                  ),
                );
              },
            ),
            const SizedBox(height: Dimens.space8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  key: const ValueKey('whatsapp-edit-number'),
                  onPressed: code.resending || code.verifying
                      ? null
                      : cubit.editNumber,
                  style: TextButton.styleFrom(
                    foregroundColor: colors['textAccent'],
                  ),
                  child: Text(l10n.whatsappEditNumber),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
