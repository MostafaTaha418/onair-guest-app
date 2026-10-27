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
import 'package:on_air/features/auth/domain/password_rule.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/widgets/password_strength_hint.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class LoginScreen extends StatefulWidget {
  const LoginScreen({this.initialPhone, this.registration = false, super.key});

  final String? initialPhone;
  final bool registration;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

final class _LoginScreenState extends State<LoginScreen> {
  late final _phone = TextEditingController(text: widget.initialPhone);
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showValidation = false;
  bool _loading = false;
  bool _emailTab = false;
  bool _acceptedTerms = false;
  String? _requestError;

  bool get _validPhone => EgyptPhone.tryParse(_phone.text) != null;
  bool get _validEmail => RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  ).hasMatch(_email.text.trim());
  bool get _validName {
    final value = _name.text.trim();
    return value.length >= 2 && value.length <= 80;
  }

  bool get _validEmailForm =>
      _validEmail &&
      PasswordRule.isValid(_password.text) &&
      (!widget.registration || (_validName && _acceptedTerms));

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submitPhone() async {
    if (!_validPhone || _loading) {
      setState(() => _showValidation = true);
      return;
    }
    await _runRequest(
      () => context.read<AuthCubit>().requestPhoneCode(_phone.text),
    );
  }

  Future<void> _submitEmail() async {
    if (!_validEmailForm || _loading) {
      setState(() => _showValidation = true);
      return;
    }
    await _runRequest(() async {
      if (widget.registration) {
        await context.read<AuthCubit>().requestEmailSignup(
          _name.text,
          _email.text,
          _password.text,
        );
      } else {
        await context.read<AuthCubit>().signInEmail(
          _email.text,
          _password.text,
        );
      }
    });
  }

  Future<void> _runRequest(Future<void> Function() request) async {
    setState(() {
      _loading = true;
      _requestError = null;
    });
    try {
      await request();
      if (mounted && (widget.registration || !_emailTab)) {
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
    final invalidPhone = _showValidation && !_validPhone;
    final countryUnsupported = _requestError == 'PHONE_COUNTRY_NOT_SUPPORTED';
    final invalidCredentials = _requestError == 'INVALID_CREDENTIALS';
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
              onSelectionChanged: (selection) => setState(() {
                _emailTab = selection.single;
                _showValidation = false;
                _requestError = null;
              }),
            ),
            const SizedBox(height: Dimens.space24),
            if (_emailTab)
              ..._emailFields(l10n, invalidCredentials)
            else
              ..._phoneFields(l10n, invalidPhone, countryUnsupported),
          ],
        ),
      ),
    );
  }

  List<Widget> _emailFields(
    AppLocalizations l10n,
    bool invalidCredentials,
  ) => [
    if (widget.registration) ...[
      OnAirTextField(
        key: const ValueKey('email-name-field'),
        controller: _name,
        label: l10n.fullName,
        enabled: !_loading,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        errorText: _showValidation && !_validName ? l10n.authNameInvalid : null,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: Dimens.space16),
    ],
    OnAirTextField(
      key: const ValueKey('email-field'),
      controller: _email,
      label: l10n.email,
      keyboardType: TextInputType.emailAddress,
      enabled: !_loading,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      errorText: _showValidation && !_validEmail ? l10n.authEmailInvalid : null,
      onChanged: (_) => setState(() => _requestError = null),
    ),
    const SizedBox(height: Dimens.space16),
    OnAirTextField(
      key: const ValueKey('password-field'),
      controller: _password,
      label: l10n.password,
      obscureText: true,
      enabled: !_loading,
      textInputAction: TextInputAction.done,
      autofillHints: [
        if (widget.registration)
          AutofillHints.newPassword
        else
          AutofillHints.password,
      ],
      errorText: _showValidation && !PasswordRule.isValid(_password.text)
          ? l10n.authPasswordRule
          : null,
      onChanged: (_) => setState(() => _requestError = null),
      onSubmitted: (_) => _submitEmail(),
    ),
    const SizedBox(height: Dimens.space8),
    PasswordStrengthHint(password: _password.text),
    if (!widget.registration)
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton(
          key: const ValueKey('forgot-password-action'),
          onPressed: () => context.go(AppRoutes.forgotPassword),
          child: Text(
            l10n.authForgotPassword,
            style: context.textStyles.forgotLink,
          ),
        ),
      ),
    if (widget.registration)
      CheckboxListTile(
        key: const ValueKey('email-terms-checkbox'),
        contentPadding: EdgeInsets.zero,
        value: _acceptedTerms,
        onChanged: _loading
            ? null
            : (value) => setState(() => _acceptedTerms = value ?? false),
        title: Text(l10n.authAcceptTerms),
        subtitle: _showValidation && !_acceptedTerms
            ? Text(l10n.authTermsRequired)
            : null,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    if (invalidCredentials)
      Semantics(
        liveRegion: true,
        child: Text(
          l10n.authInvalidCredentials,
          key: const ValueKey('email-auth-error'),
          style: TextStyle(color: context.colors.errorText),
        ),
      ),
    const SizedBox(height: Dimens.space20),
    OnAirPrimaryButton(
      key: const ValueKey('email-submit-button'),
      label: widget.registration
          ? l10n.authSignUpWithEmail
          : l10n.authSignInWithEmail,
      onPressed: _validEmailForm ? _submitEmail : null,
      isLoading: _loading,
      gradient: true,
    ),
    const SizedBox(height: Dimens.space16),
    _accountSwitch(l10n),
  ];

  List<Widget> _phoneFields(
    AppLocalizations l10n,
    bool invalidPhone,
    bool countryUnsupported,
  ) => [
    OnAirTextField(
      key: const ValueKey('phone-field'),
      controller: _phone,
      label: l10n.phoneNumber,
      hint: l10n.authPhoneHint,
      keyboardType: TextInputType.phone,
      enabled: !_loading,
      errorText: invalidPhone ? l10n.authPhoneInvalid : null,
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
      onPressed: _validPhone ? _submitPhone : null,
      isLoading: _loading,
      gradient: true,
    ),
    const SizedBox(height: Dimens.space16),
    Text(
      '${l10n.authTermsPrefix} ${l10n.terms} و${l10n.privacy}',
      textAlign: TextAlign.center,
    ),
    _accountSwitch(l10n),
  ];

  Widget _accountSwitch(AppLocalizations l10n) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(widget.registration ? l10n.authHasAccount : l10n.authNoAccount),
      TextButton(
        onPressed: () => context.go(
          widget.registration ? AppRoutes.login : AppRoutes.register,
        ),
        child: Text(widget.registration ? l10n.signIn : l10n.authCreateAccount),
      ),
    ],
  );
}
