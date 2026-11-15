import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The social providers with official-mark buttons. Lives here (not in
/// `features/`) because the design system must not import features;
/// `social_identity.dart` re-exports it.
enum SocialProvider { google, apple }

/// A circular, logo-only social sign-in button (contracts/ui-screens.md §1):
/// 56dp circle on the Social Fill token with a quiet border and the official
/// 24dp mark. `busy` replaces the logo with a same-size loader and ignores
/// taps; `onPressed == null` is the disabled state.
final class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    required this.provider,
    required this.onPressed,
    this.busy = false,
    this.onLongPress,
    super.key,
  });

  final SocialProvider provider;
  final VoidCallback? onPressed;
  final bool busy;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null && !busy;
    final label = switch (provider) {
      SocialProvider.google => l10n.authContinueWithGoogle,
      SocialProvider.apple => l10n.authContinueWithApple,
    };
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Material(
          color: colors['socialFill'],
          shape: CircleBorder(
            side: BorderSide(color: colors['border']),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('social-${provider.name}-button'),
            onTap: enabled ? onPressed : null,
            onLongPress: enabled ? onLongPress : null,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Image.asset(
                      switch (provider) {
                        SocialProvider.google =>
                          'assets/images/social/google_g.png',
                        SocialProvider.apple =>
                          dark
                              ? 'assets/images/social/apple_logo_white.png'
                              : 'assets/images/social/apple_logo_black.png',
                      },
                      width: 24,
                      height: 24,
                      excludeFromSemantics: true,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
