import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.initialPhone,
    this.registration = false,
    super.key,
  });
  final String? initialPhone;
  final bool registration;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

final class _LoginScreenState extends State<LoginScreen> {
  late final _phone = TextEditingController(text: widget.initialPhone);
  bool _showValidation = false;
  bool _loading = false;
  bool _emailTab = false;
  String? _requestError;

  bool get _valid => EgyptPhone.tryParse(_phone.text) != null;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_valid || _loading) {
      setState(() => _showValidation = true);
      return;
    }
    setState(() {
      _loading = true;
      _requestError = null;
    });
    try {
      await context.read<AuthCubit>().requestPhoneCode(_phone.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).authCodeSent)),
        );
      }
    } on AuthRequestRejected catch (error) {
      if (mounted) setState(() => _requestError = error.code);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final invalid = _showValidation && !_valid;
    final countryUnsupported = _requestError == 'PHONE_COUNTRY_NOT_SUPPORTED';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Dimens.screenSide),
          children: [
            const SizedBox(height: Dimens.space32),
            Text(
              widget.registration
                  ? l10n.authRegisterTitle
                  : l10n.authLoginTitle,
              style: context.textStyles.authTitle,
            ),
            const SizedBox(height: Dimens.space24),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.authPhoneTab)),
                ButtonSegment(value: true, label: Text(l10n.authEmailTab)),
              ],
              selected: {_emailTab},
              onSelectionChanged: (selection) =>
                  setState(() => _emailTab = selection.single),
            ),
            const SizedBox(height: Dimens.space24),
            if (_emailTab)
              Text(l10n.authEmailComingSoon)
            else ...[
              OnAirTextField(
                key: const ValueKey('phone-field'),
                controller: _phone,
                label: l10n.phoneNumber,
                hint: l10n.authPhoneHint,
                keyboardType: TextInputType.phone,
                enabled: !_loading,
                errorText: invalid ? l10n.authPhoneInvalid : null,
                onChanged: (_) => setState(() {
                  _showValidation = true;
                  _requestError = null;
                }),
              ),
              if (countryUnsupported) ...[
                const SizedBox(height: Dimens.space12),
                Semantics(
                  liveRegion: true,
                  child: Text(l10n.authPhoneCountryNotSupported),
                ),
                TextButton(
                  key: const ValueKey('use-email-action'),
                  onPressed: () => setState(() => _emailTab = true),
                  child: Text(l10n.authEmailTab),
                ),
              ],
              const SizedBox(height: Dimens.space20),
              OnAirPrimaryButton(
                key: const ValueKey('send-code-button'),
                label: l10n.sendCode,
                onPressed: _valid ? _submit : null,
                isLoading: _loading,
                gradient: true,
              ),
              const SizedBox(height: Dimens.space16),
              Text(
                '${l10n.authTermsPrefix} ${l10n.terms} و${l10n.privacy}',
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.registration
                        ? l10n.authHasAccount
                        : l10n.authNoAccount,
                  ),
                  TextButton(
                    onPressed: () => context.go(
                      widget.registration
                          ? AppRoutes.login
                          : AppRoutes.register,
                    ),
                    child: Text(
                      widget.registration
                          ? l10n.signIn
                          : l10n.authCreateAccount,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
