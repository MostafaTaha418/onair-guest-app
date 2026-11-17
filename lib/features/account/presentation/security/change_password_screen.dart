import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/account/presentation/security/change_password_cubit.dart';
import 'package:on_air/features/auth/presentation/widgets/password_strength_hint.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

final class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  Timer? _rateLimitTicker;
  DateTime _now = DateTime.now();
  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<ChangePasswordCubit>().state;
    _current.text = state.current;
    _next.text = state.next;
    _confirm.text = state.confirm;
  }

  @override
  void dispose() {
    _rateLimitTicker?.cancel();
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _listener(BuildContext context, ChangePasswordState state) {
    _syncRateLimitTicker(state.rateLimitedUntil);
    if (!state.done) return;
    final l10n = AppLocalizations.of(context);
    _current.clear();
    _next.clear();
    _confirm.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.accountPasswordChanged)),
    );
    context.pop();
  }

  void _syncRateLimitTicker(DateTime? until) {
    _rateLimitTicker?.cancel();
    _rateLimitTicker = null;
    if (until == null || !until.isAfter(DateTime.now())) return;
    _now = DateTime.now();
    _rateLimitTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      setState(() => _now = now);
      if (!now.isBefore(until)) {
        timer.cancel();
        _rateLimitTicker = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final online = context.watch<ConnectivityCubit>().state.isOnline;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountChangePassword)),
      body: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
        listener: _listener,
        builder: (context, state) {
          final rateLimitRemaining = state.rateLimitedUntil?.difference(_now);
          final rateLimited =
              rateLimitRemaining != null && !rateLimitRemaining.isNegative;
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsetsDirectional.fromSTEB(
              Dimens.screenSide,
              Dimens.space16,
              Dimens.screenSide,
              Dimens.space24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              _field(
                key: const ValueKey('current-password-field'),
                controller: _current,
                label: l10n.accountCurrentPassword,
                visible: _showCurrent,
                onToggle: () => setState(() => _showCurrent = !_showCurrent),
                onChanged: context.read<ChangePasswordCubit>().setCurrent,
                errorText: state.currentError == null
                    ? null
                    : l10n.accountPasswordIncorrect,
                action: TextInputAction.next,
                enabled: online && !state.submitting,
              ),
              const SizedBox(height: Dimens.space16),
              _field(
                key: const ValueKey('new-password-field'),
                controller: _next,
                label: l10n.accountNewPassword,
                visible: _showNext,
                onToggle: () => setState(() => _showNext = !_showNext),
                onChanged: context.read<ChangePasswordCubit>().setNext,
                errorText: state.next.isNotEmpty && state.next == state.current
                    ? l10n.accountPasswordSameAsOld
                    : null,
                action: TextInputAction.next,
                enabled: online && !state.submitting,
              ),
              const SizedBox(height: Dimens.space8),
              PasswordStrengthHint(password: state.next),
              const SizedBox(height: Dimens.space16),
              _field(
                key: const ValueKey('confirm-password-field'),
                controller: _confirm,
                label: l10n.accountConfirmPassword,
                visible: _showConfirm,
                onToggle: () => setState(() => _showConfirm = !_showConfirm),
                onChanged: context.read<ChangePasswordCubit>().setConfirm,
                errorText:
                    state.confirm.isNotEmpty && state.confirm != state.next
                    ? l10n.accountPasswordMismatch
                    : null,
                action: TextInputAction.done,
                enabled: online && !state.submitting,
              ),
              if (state.error case final error?) ...[
                const SizedBox(height: Dimens.space16),
                NoticeCard(
                  icon: Icons.error_outline,
                  message: rateLimited
                      ? l10n.authRateLimited(_waitText(rateLimitRemaining))
                      : apiErrorMessage(error, l10n),
                  tone: NoticeTone.warning,
                ),
              ],
              const SizedBox(height: Dimens.space24),
              OnAirPrimaryButton(
                key: const ValueKey('save-password'),
                label: l10n.accountSave,
                isLoading: state.submitting,
                onPressed: online && state.canSubmit && !rateLimited
                    ? () => unawaited(
                        context.read<ChangePasswordCubit>().submit(),
                      )
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    required ValueChanged<String> onChanged,
    required TextInputAction action,
    required bool enabled,
    String? errorText,
  }) => OnAirTextField(
    key: key,
    controller: controller,
    label: label,
    obscureText: !visible,
    enabled: enabled,
    textInputAction: action,
    autofillHints: const [AutofillHints.password],
    onChanged: onChanged,
    errorText: errorText,
    suffix: IconButton(
      onPressed: enabled ? onToggle : null,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
    ),
  );
}

String _waitText(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 24 * 60 * 60);
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
