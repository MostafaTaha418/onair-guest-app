import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/auth_error_message.dart';
import 'package:on_air/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:on_air/features/auth/presentation/widgets/auth_flow_scaffold.dart';
import 'package:on_air/features/auth/presentation/widgets/rapid_submit_guard.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

final class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _showValidation = false;
  bool _loading = false;
  final _submitGuard = RapidSubmitGuard();

  @override
  void initState() {
    super.initState();
    _email.addListener(_submitGuard.reset);
  }

  bool get _valid => RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  ).hasMatch(_email.text.trim());

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_valid) {
      setState(() => _showValidation = true);
      return;
    }
    if (!_submitGuard.tryEnter()) return;
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      await context.read<AuthCubit>().requestRecovery(_email.text);
      message = l10n.authRecoverySent;
    } on Object catch (error) {
      message = authErrorMessage(error, l10n);
    }
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthFlowScaffold(
      onBack: () => context.go(AppRoutes.login),
      topSpaceFactor: 0.15,
      maxTopSpace: 64,
      children: [
        const AuthBrandHeader(),
        const SizedBox(height: Dimens.space32),
        Text(l10n.authRecoveryTitle, style: context.textStyles.authTitle),
        const SizedBox(height: Dimens.space12),
        Text(
          l10n.authRecoveryDescription,
          style: context.textStyles.authDescription.copyWith(
            color: context.colors['textMuted'],
          ),
        ),
        const SizedBox(height: Dimens.space48),
        OnAirTextField(
          key: const ValueKey('recovery-email-field'),
          controller: _email,
          label: l10n.email,
          prefixIcon: AppIcons.mailOutlineRounded,
          pill: true,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          enabled: !_loading,
          errorText: _showValidation && !_valid
              ? (_email.text.trim().isEmpty
                    ? l10n.authFieldRequired
                    : l10n.authEmailInvalid)
              : null,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: Dimens.space40),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 185,
            child: OnAirPrimaryButton(
              key: const ValueKey('recovery-submit-button'),
              label: l10n.sendCode,
              onPressed: _loading ? null : _submit,
              isLoading: _loading,
              gradient: true,
              pill: true,
              height: 62,
            ),
          ),
        ),
      ],
    );
  }
}
