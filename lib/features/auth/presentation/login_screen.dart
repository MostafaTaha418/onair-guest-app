import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/domain/password_rule.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/auth_error_message.dart';
import 'package:on_air/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:on_air/features/auth/presentation/widgets/auth_flow_scaffold.dart';
import 'package:on_air/features/auth/presentation/widgets/password_strength_hint.dart';
import 'package:on_air/features/auth/presentation/widgets/rapid_submit_guard.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.initialPhone,
    this.registration = false,
    this.phoneAuthEnabled = true,
    super.key,
  });

  final String? initialPhone;
  final bool registration;
  final bool phoneAuthEnabled;

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
  late bool _emailTab = !widget.phoneAuthEnabled;
  bool _acceptedTerms = false;
  String? _requestError;
  String? _generalError;
  final _submitGuard = RapidSubmitGuard();

  @override
  void initState() {
    super.initState();
    for (final controller in [_phone, _name, _email, _password]) {
      controller.addListener(_submitGuard.reset);
    }
  }

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
      (widget.registration
          ? PasswordRule.isValid(_password.text)
          : _password.text.isNotEmpty) &&
      (!widget.registration || (_validName && _validPhone && _acceptedTerms));

  String? _requiredOrInvalid(
    String value,
    bool valid,
    String invalidMessage,
    AppLocalizations l10n,
  ) {
    if (!_showValidation || valid) return null;
    return value.trim().isEmpty ? l10n.authFieldRequired : invalidMessage;
  }

  String? _passwordError(AppLocalizations l10n) {
    if (!_showValidation) return null;
    if (_password.text.isEmpty) return l10n.authFieldRequired;
    if (widget.registration && !PasswordRule.isValid(_password.text)) {
      return l10n.authPasswordRule;
    }
    return null;
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submitPhone() async {
    if (_loading) return;
    if (!_validPhone) {
      setState(() => _showValidation = true);
      return;
    }
    await _runRequest(
      () => context.read<AuthCubit>().requestPhoneCode(_phone.text),
    );
  }

  Future<void> _submitEmail() async {
    if (_loading) return;
    if (!_validEmailForm) {
      setState(() => _showValidation = true);
      return;
    }
    await _runRequest(() async {
      if (widget.registration) {
        final config = await context.read<AppConfigSource>().load(
          refresh: true,
        );
        if (!mounted) return;
        context.read<AuthCubit>().updateTermsVersion(
          config.currentTermsVersion,
        );
        await context.read<AuthCubit>().requestEmailSignup(
          _name.text,
          _email.text,
          _password.text,
          _phone.text,
          config.currentTermsVersion,
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
    if (_loading || !_submitGuard.tryEnter()) return;
    setState(() {
      _loading = true;
      _requestError = null;
      _generalError = null;
    });
    try {
      await request();
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState is SignedIn) {
        final origin = GoRouterState.of(context).uri.queryParameters['from'];
        final destination = resolveAuthReturnDestination(origin);
        context.go(
          authState.isComplete
              ? destination
              : Uri(
                  path: AppRoutes.completeProfile,
                  queryParameters: {'from': destination},
                ).toString(),
        );
        return;
      }
      // Only confirm when a code was really sent (not when rate-limited).
      if (mounted && context.read<AuthCubit>().state is CodeSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).authCodeSent)),
        );
        // The redirect's refresh pass re-evaluates an app route (not this
        // pushed screen) and cannot see this screen's `from`; navigate to
        // the code screen explicitly and carry the return target, so
        // sign-in ends where the guest started (SC-007, research R10).
        // The *return* destination keeps account-gated routes, unlike a
        // cancellation: after the code the guest is signed in.
        final origin = GoRouterState.of(context).uri.queryParameters['from'];
        context.go(
          Uri(
            path: AppRoutes.otp,
            queryParameters: {'from': resolveAuthReturnDestination(origin)},
          ).toString(),
        );
      }
    } on AuthRequestRejected catch (error) {
      if (!mounted) return;
      setState(() {
        _requestError = error.code;
        if (!_inlineCodes.contains(error.code)) {
          _generalError = authErrorMessage(error, AppLocalizations.of(context));
        }
      });
    } on Object catch (error) {
      // Rate limit, no connection, or anything unexpected (FR-029, FR-039).
      if (mounted) {
        setState(
          () => _generalError = authErrorMessage(
            error,
            AppLocalizations.of(context),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Codes that already have their own message next to the related field.
  static const _inlineCodes = {
    'PHONE_COUNTRY_NOT_SUPPORTED',
    'INVALID_CREDENTIALS',
  };

  Widget _generalErrorText() => Padding(
    padding: const EdgeInsetsDirectional.only(top: Dimens.space12),
    child: Semantics(
      liveRegion: true,
      child: Text(
        _generalError!,
        key: const ValueKey('auth-request-error'),
        style: TextStyle(color: context.colors.errorText),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).height < 700;
    final invalidPhone = _showValidation && !_validPhone;
    final countryUnsupported = _requestError == 'PHONE_COUNTRY_NOT_SUPPORTED';
    final invalidCredentials = _requestError == 'INVALID_CREDENTIALS';
    if (!widget.registration) {
      return _buildSignIn(
        l10n,
        invalidPhone: invalidPhone,
        countryUnsupported: countryUnsupported,
        invalidCredentials: invalidCredentials,
      );
    }
    return AuthFlowScaffold(
      topSpaceFactor: 0.08,
      minTopSpace: compact ? 24 : 40,
      maxTopSpace: 56,
      onBack: () => context.go(AppRoutes.login),
      children: [
        const AuthBrandHeader(),
        SizedBox(height: compact ? Dimens.space24 : Dimens.space32),
        Text(l10n.authRegisterTitle, style: context.textStyles.authTitle),
        const SizedBox(height: Dimens.space4),
        _accountSwitch(l10n),
        const SizedBox(height: Dimens.space24),
        if (widget.phoneAuthEnabled) ...[
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
              _generalError = null;
            }),
          ),
          const SizedBox(height: Dimens.space24),
        ],
        if (_emailTab)
          ..._emailFields(l10n, invalidCredentials)
        else
          ..._phoneFields(l10n, invalidPhone, countryUnsupported),
      ],
    );
  }

  Widget _buildSignIn(
    AppLocalizations l10n, {
    required bool invalidPhone,
    required bool countryUnsupported,
    required bool invalidCredentials,
  }) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: colors.gradient('authBackground')),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            key: const ValueKey('close-login-button'),
            tooltip: l10n.authClose,
            onPressed: _cancelSignIn,
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? AppIcons.chevronRight
                  : AppIcons.chevronLeft,
            ),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final topSpace = ((constraints.maxHeight - 560) * 0.15 + 24)
                  .clamp(
                    24.0,
                    64.0,
                  );
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsetsDirectional.fromSTEB(
                      28,
                      topSpace,
                      28,
                      Dimens.space32,
                    ),
                    children: [
                      const AuthBrandHeader(),
                      const SizedBox(height: Dimens.space32),
                      Text(l10n.signIn, style: context.textStyles.authTitle),
                      const SizedBox(height: Dimens.space4),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _accountSwitch(l10n),
                      ),
                      const SizedBox(height: Dimens.space40),
                      if (widget.phoneAuthEnabled) ...[
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: false,
                              label: Text(l10n.authPhoneTab),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(l10n.authEmailTab),
                            ),
                          ],
                          selected: {_emailTab},
                          onSelectionChanged: (selection) => setState(() {
                            _emailTab = selection.single;
                            _showValidation = false;
                            _requestError = null;
                            _generalError = null;
                          }),
                        ),
                        const SizedBox(height: Dimens.space24),
                      ],
                      if (_emailTab)
                        ..._signInEmailFields(l10n, invalidCredentials)
                      else
                        ..._signInPhoneFields(
                          l10n,
                          invalidPhone,
                          countryUnsupported,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _signInEmailFields(
    AppLocalizations l10n,
    bool invalidCredentials,
  ) => [
    OnAirTextField(
      key: const ValueKey('email-field'),
      controller: _email,
      label: l10n.email,
      prefixIcon: AppIcons.mailOutlineRounded,
      pill: true,
      keyboardType: TextInputType.emailAddress,
      enabled: !_loading,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      errorText: _requiredOrInvalid(
        _email.text,
        _validEmail,
        l10n.authEmailInvalid,
        l10n,
      ),
      onChanged: (_) => setState(() {
        _requestError = null;
        _generalError = null;
      }),
    ),
    const SizedBox(height: Dimens.space20),
    OnAirTextField(
      key: const ValueKey('password-field'),
      controller: _password,
      label: l10n.password,
      prefixIcon: AppIcons.lockOutlineRounded,
      suffix: _forgotBelowField ? null : _forgotPasswordAction(l10n),
      pill: true,
      obscureText: true,
      enabled: !_loading,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      errorText: _passwordError(l10n),
      onChanged: (_) => setState(() {
        _requestError = null;
        _generalError = null;
      }),
      onSubmitted: (_) => _submitEmail(),
    ),
    if (_forgotBelowField)
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: _forgotPasswordAction(l10n),
      ),
    if (invalidCredentials) ...[
      const SizedBox(height: Dimens.space12),
      Semantics(
        liveRegion: true,
        child: Text(
          l10n.authInvalidCredentials,
          key: const ValueKey('email-auth-error'),
          style: TextStyle(color: context.colors.errorText),
        ),
      ),
    ],
    if (_generalError != null) _generalErrorText(),
    const SizedBox(height: Dimens.space40),
    Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: 205,
        child: OnAirPrimaryButton(
          key: const ValueKey('email-submit-button'),
          label: l10n.signIn,
          onPressed: _loading ? null : _submitEmail,
          isLoading: _loading,
          gradient: true,
          pill: true,
          height: 62,
        ),
      ),
    ),
  ];

  bool get _forgotBelowField =>
      MediaQuery.textScalerOf(context).scale(1) > 1.15 ||
      MediaQuery.sizeOf(context).width < 350;

  Widget _forgotPasswordAction(AppLocalizations l10n) => TextButton(
    key: const ValueKey('forgot-password-action'),
    onPressed: () => context.go(AppRoutes.forgotPassword),
    style: TextButton.styleFrom(foregroundColor: context.colors['textAccent']),
    child: Text(l10n.authForgotPassword),
  );

  List<Widget> _signInPhoneFields(
    AppLocalizations l10n,
    bool invalidPhone,
    bool countryUnsupported,
  ) => [
    OnAirTextField(
      key: const ValueKey('phone-field'),
      controller: _phone,
      label: l10n.phoneNumber,
      hint: l10n.authPhoneHint,
      prefixIcon: AppIcons.phoneOutlined,
      pill: true,
      keyboardType: TextInputType.phone,
      enabled: !_loading,
      errorText: invalidPhone
          ? _requiredOrInvalid(
              _phone.text,
              _validPhone,
              l10n.authPhoneInvalid,
              l10n,
            )
          : null,
      onChanged: (_) => setState(() {
        _requestError = null;
        _generalError = null;
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
    if (_generalError != null) _generalErrorText(),
    const SizedBox(height: Dimens.space40),
    Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: 205,
        child: OnAirPrimaryButton(
          key: const ValueKey('send-code-button'),
          label: l10n.sendCode,
          onPressed: _loading ? null : _submitPhone,
          isLoading: _loading,
          gradient: true,
          pill: true,
          height: 62,
        ),
      ),
    ),
    const SizedBox(height: Dimens.space24),
    Text(
      '${l10n.authTermsPrefix} ${l10n.terms} و${l10n.privacy}',
      textAlign: TextAlign.center,
    ),
  ];

  void _cancelSignIn() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final origin = GoRouterState.of(context).uri.queryParameters['cancelTo'];
    router.go(resolveAuthCancelDestination(origin));
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
        prefixIcon: AppIcons.personOutlineRounded,
        pill: true,
        enabled: !_loading,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        errorText: _requiredOrInvalid(
          _name.text,
          _validName,
          l10n.authNameInvalid,
          l10n,
        ),
        onChanged: (_) => setState(() => _generalError = null),
      ),
      const SizedBox(height: Dimens.space20),
      OnAirTextField(
        key: const ValueKey('email-phone-field'),
        controller: _phone,
        label: l10n.phoneNumber,
        hint: l10n.authPhoneHint,
        prefixIcon: AppIcons.phoneOutlined,
        pill: true,
        keyboardType: TextInputType.phone,
        enabled: !_loading,
        textInputAction: TextInputAction.next,
        errorText: _requiredOrInvalid(
          _phone.text,
          _validPhone,
          l10n.authPhoneInvalid,
          l10n,
        ),
        onChanged: (_) => setState(() => _generalError = null),
      ),
      const SizedBox(height: Dimens.space20),
    ],
    OnAirTextField(
      key: const ValueKey('email-field'),
      controller: _email,
      label: l10n.email,
      prefixIcon: AppIcons.mailOutlineRounded,
      pill: true,
      keyboardType: TextInputType.emailAddress,
      enabled: !_loading,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      errorText: _requiredOrInvalid(
        _email.text,
        _validEmail,
        l10n.authEmailInvalid,
        l10n,
      ),
      onChanged: (_) => setState(() {
        _requestError = null;
        _generalError = null;
      }),
    ),
    const SizedBox(height: Dimens.space20),
    OnAirTextField(
      key: const ValueKey('password-field'),
      controller: _password,
      label: l10n.password,
      prefixIcon: AppIcons.lockOutlineRounded,
      pill: true,
      obscureText: true,
      enabled: !_loading,
      textInputAction: TextInputAction.done,
      autofillHints: [
        if (widget.registration)
          AutofillHints.newPassword
        else
          AutofillHints.password,
      ],
      errorText: _passwordError(l10n),
      onChanged: (_) => setState(() {
        _requestError = null;
        _generalError = null;
      }),
      onSubmitted: (_) => _submitEmail(),
    ),
    const SizedBox(height: Dimens.space8),
    PasswordStrengthHint(password: _password.text),
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
    if (_generalError != null) _generalErrorText(),
    const SizedBox(height: Dimens.space24),
    Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: 230,
        child: OnAirPrimaryButton(
          key: const ValueKey('email-submit-button'),
          label: l10n.authSignUpWithEmail,
          onPressed: _loading ? null : _submitEmail,
          isLoading: _loading,
          gradient: true,
          pill: true,
          height: 62,
        ),
      ),
    ),
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
      prefixIcon: AppIcons.phoneOutlined,
      pill: true,
      keyboardType: TextInputType.phone,
      enabled: !_loading,
      errorText: invalidPhone
          ? _requiredOrInvalid(
              _phone.text,
              _validPhone,
              l10n.authPhoneInvalid,
              l10n,
            )
          : null,
      onChanged: (_) => setState(() {
        _requestError = null;
        _generalError = null;
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
    if (_generalError != null) _generalErrorText(),
    const SizedBox(height: Dimens.space20),
    Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: 205,
        child: OnAirPrimaryButton(
          key: const ValueKey('send-code-button'),
          label: l10n.sendCode,
          onPressed: _loading ? null : _submitPhone,
          isLoading: _loading,
          gradient: true,
          pill: true,
          height: 62,
        ),
      ),
    ),
    const SizedBox(height: Dimens.space16),
    Text(
      '${l10n.authTermsPrefix} ${l10n.terms} و${l10n.privacy}',
      textAlign: TextAlign.center,
    ),
  ];

  Widget _accountSwitch(AppLocalizations l10n) => Wrap(
    alignment: widget.registration ? WrapAlignment.center : WrapAlignment.start,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(widget.registration ? l10n.authHasAccount : l10n.authNoAccount),
      TextButton(
        onPressed: () {
          final current = GoRouterState.of(context).uri;
          context.go(
            Uri(
              path: widget.registration ? AppRoutes.login : AppRoutes.register,
              queryParameters: {
                if (current.queryParameters['from'] case final String from)
                  'from': from,
                if (current.queryParameters['cancelTo']
                    case final String cancelTo)
                  'cancelTo': cancelTo,
              },
            ).toString(),
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: context.colors['textAccent'],
        ),
        child: Text(widget.registration ? l10n.signIn : l10n.authCreateAccount),
      ),
    ],
  );
}
