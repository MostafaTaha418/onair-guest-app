import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
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

  bool get _valid => RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  ).hasMatch(_email.text.trim());

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_valid || _loading) {
      setState(() => _showValidation = true);
      return;
    }
    setState(() => _loading = true);
    await context.read<AuthCubit>().requestRecovery(_email.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).authRecoverySent)),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(Dimens.screenSide),
        children: [
          Text(l10n.authRecoveryTitle, style: context.textStyles.authTitle),
          const SizedBox(height: Dimens.space12),
          Text(l10n.authRecoveryDescription),
          const SizedBox(height: Dimens.space24),
          OnAirTextField(
            key: const ValueKey('recovery-email-field'),
            controller: _email,
            label: l10n.email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            enabled: !_loading,
            errorText: _showValidation && !_valid
                ? l10n.authEmailInvalid
                : null,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Dimens.space20),
          OnAirPrimaryButton(
            key: const ValueKey('recovery-submit-button'),
            label: l10n.sendCode,
            onPressed: _valid ? _submit : null,
            isLoading: _loading,
            gradient: true,
          ),
        ],
      ),
    );
  }
}
