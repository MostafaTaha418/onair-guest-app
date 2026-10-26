import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

final class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _name = TextEditingController();
  String? _termsVersion;
  bool _accepted = false;
  bool _loading = false;
  bool _showErrors = false;
  bool _termsChanged = false;

  bool get _validName {
    final length = _name.text.trim().length;
    return length >= 2 && length <= 80;
  }

  bool get _canSubmit => _validName && _accepted && _termsVersion != null;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTerms());
  }

  Future<void> _loadTerms({bool refresh = false}) async {
    final config = await context.read<AppConfigSource>().load(refresh: refresh);
    if (!mounted) return;
    context.read<AuthCubit>().updateTermsVersion(config.currentTermsVersion);
    setState(() => _termsVersion = config.currentTermsVersion);
  }

  Future<void> _submit() async {
    setState(() => _showErrors = true);
    if (!_canSubmit || _loading) return;
    setState(() {
      _loading = true;
      _termsChanged = false;
    });
    try {
      await context.read<AuthCubit>().completeProfile(
        _name.text.trim(),
        _termsVersion!,
      );
    } on ProfileTermsChanged {
      if (!mounted) return;
      setState(() {
        _accepted = false;
        _termsChanged = true;
      });
      await _loadTerms(refresh: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Dimens.screenSide),
          children: [
            const SizedBox(height: Dimens.space32),
            Text(
              l10n.authCompleteProfileTitle,
              style: context.textStyles.authTitle,
            ),
            const SizedBox(height: Dimens.space24),
            OnAirTextField(
              key: const ValueKey('full-name-field'),
              controller: _name,
              label: l10n.fullName,
              enabled: !_loading,
              errorText: (_showErrors || _name.text.isNotEmpty) && !_validName
                  ? l10n.authNameInvalid
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            CheckboxListTile(
              key: const ValueKey('terms-checkbox'),
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: _loading
                  ? null
                  : (value) => setState(() {
                      _accepted = value ?? false;
                      _termsChanged = false;
                    }),
              title: Text(l10n.authAcceptTerms),
            ),
            if ((_showErrors && !_accepted) || _termsChanged)
              Semantics(
                liveRegion: true,
                child: Text(
                  _termsChanged
                      ? l10n.authTermsChanged
                      : l10n.authTermsRequired,
                  key: const ValueKey('terms-error'),
                  style: TextStyle(color: context.colors.errorText),
                ),
              ),
            const SizedBox(height: Dimens.space20),
            OnAirPrimaryButton(
              key: const ValueKey('complete-profile-button'),
              label: l10n.confirm,
              onPressed: _canSubmit ? _submit : null,
              isLoading: _loading,
              gradient: true,
            ),
          ],
        ),
      ),
    );
  }
}
