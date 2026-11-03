import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/password_rule.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/auth_error_message.dart';
import 'package:on_air/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:on_air/features/auth/presentation/widgets/auth_flow_scaffold.dart';
import 'package:on_air/features/auth/presentation/widgets/password_strength_hint.dart';
import 'package:on_air/features/auth/presentation/widgets/rapid_submit_guard.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

final class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _password = TextEditingController();
  bool _showValidation = false;
  bool _loading = false;
  final _submitGuard = RapidSubmitGuard();

  @override
  void initState() {
    super.initState();
    _password.addListener(_submitGuard.reset);
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!PasswordRule.isValid(_password.text)) {
      setState(() => _showValidation = true);
      return;
    }
    if (!_submitGuard.tryEnter()) return;
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthCubit>().setNewPassword(_password.text);
      if (mounted) context.go(AppRoutes.home);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(authErrorMessage(error, l10n))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final valid = PasswordRule.isValid(_password.text);
    final compact = MediaQuery.sizeOf(context).height < 700;
    return AuthFlowScaffold(
      topSpaceFactor: 0.15,
      minTopSpace: compact ? 24 : 40,
      maxTopSpace: 64,
      onBack: () => context.go(AppRoutes.forgotPassword),
      children: [
        const AuthBrandHeader(),
        SizedBox(height: compact ? Dimens.space24 : Dimens.space32),
        Text(l10n.authNewPasswordTitle, style: context.textStyles.authTitle),
        SizedBox(height: compact ? Dimens.space32 : Dimens.space48),
        OnAirTextField(
          key: const ValueKey('new-password-field'),
          controller: _password,
          label: l10n.password,
          prefixIcon: AppIcons.lockOutlineRounded,
          pill: true,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !_loading,
          errorText: _showValidation && !valid
              ? (_password.text.isEmpty
                    ? l10n.authFieldRequired
                    : l10n.authPasswordRule)
              : null,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: Dimens.space8),
        PasswordStrengthHint(password: _password.text),
        const SizedBox(height: Dimens.space40),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 230,
            child: OnAirPrimaryButton(
              key: const ValueKey('new-password-submit-button'),
              label: l10n.authNewPassword,
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
