import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/password_rule.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class PasswordStrengthHint extends StatelessWidget {
  const PasswordStrengthHint({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final strength = PasswordRule.strengthOf(password);
    final label = switch (strength) {
      PasswordStrength.weak => l10n.authPasswordWeak,
      PasswordStrength.medium => l10n.authPasswordMedium,
      PasswordStrength.strong => l10n.authPasswordStrong,
    };
    return Semantics(
      liveRegion: true,
      child: Text(
        '${l10n.authPasswordRule} · $label',
        key: const ValueKey('password-strength'),
        style: context.textStyles.passwordHint,
      ),
    );
  }
}
