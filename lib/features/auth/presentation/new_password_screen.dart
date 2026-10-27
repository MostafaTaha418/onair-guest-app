import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/password_rule.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/widgets/password_strength_hint.dart';
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

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!PasswordRule.isValid(_password.text) || _loading) {
      setState(() => _showValidation = true);
      return;
    }
    setState(() => _loading = true);
    await context.read<AuthCubit>().setNewPassword(_password.text);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final valid = PasswordRule.isValid(_password.text);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(Dimens.screenSide),
        children: [
          Text(l10n.authNewPasswordTitle, style: context.textStyles.authTitle),
          const SizedBox(height: Dimens.space24),
          OnAirTextField(
            key: const ValueKey('new-password-field'),
            controller: _password,
            label: l10n.password,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            enabled: !_loading,
            errorText: _showValidation && !valid ? l10n.authPasswordRule : null,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Dimens.space8),
          PasswordStrengthHint(password: _password.text),
          const SizedBox(height: Dimens.space20),
          OnAirPrimaryButton(
            key: const ValueKey('new-password-submit-button'),
            label: l10n.authNewPassword,
            onPressed: valid ? _submit : null,
            isLoading: _loading,
            gradient: true,
          ),
        ],
      ),
    );
  }
}
