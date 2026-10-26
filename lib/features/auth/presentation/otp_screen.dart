import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/platform/secure_screen.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:smart_auth/smart_auth.dart';

abstract interface class SmsCodeReader {
  Future<String?> readCode();
  Future<void> cancel();
}

final class AndroidSmsCodeReader implements SmsCodeReader {
  const AndroidSmsCodeReader();

  @override
  Future<String?> readCode() async {
    final result = await SmartAuth.instance.getSmsWithUserConsentApi(
      matcher: r'\d{6}',
    );
    return result.data?.code;
  }

  @override
  Future<void> cancel() async {
    await SmartAuth.instance.removeUserConsentApiListener();
  }
}

final class OtpScreen extends StatefulWidget {
  const OtpScreen({
    this.codeReader = const AndroidSmsCodeReader(),
    this.secureScreen = const SecureScreen(),
    this.clock = DateTime.now,
    super.key,
  });

  final SmsCodeReader codeReader;
  final SecureScreenControl secureScreen;
  final DateTime Function() clock;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

final class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
  Timer? _ticker;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.secureScreen.setSecure(enabled: true));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        context.read<AuthCubit>().resumeCodeEntry();
      }
    });
    unawaited(_listenForSms());
  }

  Future<void> _listenForSms() async {
    final code = await widget.codeReader.readCode();
    if (!mounted || code == null || code.length != 6) return;
    _controller.text = code;
    setState(() {});
    await _verify(code);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    unawaited(widget.codeReader.cancel());
    unawaited(widget.secureScreen.setSecure(enabled: false));
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await context.read<AuthCubit>().verifyPhoneCode(code);
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _resend(CodeChallenge challenge) async {
    _controller.clear();
    await context.read<AuthCubit>().requestPhoneCode(challenge.target);
  }

  void _changePhone() {
    _controller.clear();
    context.read<AuthCubit>().cancelCodeEntry();
    GoRouter.maybeOf(context)?.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final challenge = switch (state) {
          CodeSent(:final challenge) => challenge,
          RateLimited(:final challenge) => challenge,
          _ => null,
        };
        if (challenge == null) return const SizedBox.shrink();
        final deadline = switch (state) {
          RateLimited(:final until) => until,
          _ => challenge.resendAt,
        };
        final seconds = deadline
            .difference(widget.clock())
            .inSeconds
            .clamp(
              0,
              86400,
            );
        final isRateLimited = state is RateLimited;
        final errorCode = state is CodeSent ? state.errorCode : null;
        final error = switch (errorCode) {
          'OTP_EXPIRED' => l10n.authOtpExpired,
          'OTP_INVALID' => l10n.authOtpInvalid,
          _ => null,
        };
        return Scaffold(
          appBar: AppBar(),
          body: ListView(
            padding: const EdgeInsets.all(Dimens.screenSide),
            children: [
              Text(l10n.authCodeTitle, style: context.textStyles.authTitle),
              const SizedBox(height: Dimens.space12),
              Text(l10n.authCodeDescription(challenge.target)),
              const SizedBox(height: Dimens.space8),
              Text(l10n.authCodeSent),
              const SizedBox(height: Dimens.space24),
              OnAirOtpField(
                key: const ValueKey('otp-field'),
                controller: _controller,
                enabled: !isRateLimited && !_submitting,
                onCompleted: _verify,
              ),
              if (error != null) ...[
                const SizedBox(height: Dimens.space8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    key: const ValueKey('otp-error'),
                    style: TextStyle(color: context.colors.errorText),
                  ),
                ),
              ],
              if (isRateLimited) ...[
                const SizedBox(height: Dimens.space8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.authRateLimited(l10n.authWaitSeconds(seconds)),
                  ),
                ),
              ],
              const SizedBox(height: Dimens.space16),
              TextButton(
                key: const ValueKey('resend-button'),
                onPressed: seconds == 0 && !isRateLimited
                    ? () => _resend(challenge)
                    : null,
                child: Text(
                  seconds == 0 && !isRateLimited
                      ? l10n.authResend
                      : l10n.authResendIn(l10n.authWaitSeconds(seconds)),
                ),
              ),
              TextButton(
                key: const ValueKey('change-phone-button'),
                onPressed: _changePhone,
                child: Text(l10n.authChangePhone),
              ),
            ],
          ),
        );
      },
    );
  }
}
