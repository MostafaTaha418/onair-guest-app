import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

enum SettingsIconTone { blue, teal, orange, neutral, danger }

final class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.title,
    this.tone = SettingsIconTone.blue,
    this.subtitle,
    this.value,
    this.trailing,
    this.showChevron = false,
    this.enabled = true,
    this.locked = false,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final SettingsIconTone tone;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final bool enabled;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = enabled && !locked;
    final (background, foreground) = switch (tone) {
      SettingsIconTone.blue => (
        colors.settingsIconBlueBg,
        colors.settingsIconBlueFg,
      ),
      SettingsIconTone.teal => (
        colors.settingsIconTealBg,
        colors.settingsIconTealFg,
      ),
      SettingsIconTone.orange => (
        colors.settingsIconOrangeBg,
        colors.settingsIconOrangeFg,
      ),
      SettingsIconTone.neutral => (
        colors.settingsIconNeutralBg,
        colors.settingsIconNeutralFg,
      ),
      SettingsIconTone.danger => (
        colors.settingsIconDangerBg,
        colors.settingsIconDangerFg,
      ),
    };
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        enabled: active,
        readOnly: locked,
        child: InkWell(
          onTap: active ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Opacity(
              opacity: active ? 1 : .55,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: Dimens.space12,
                  vertical: Dimens.space8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(
                          Dimens.radiusField,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: foreground, size: 22),
                    ),
                    const SizedBox(width: Dimens.space12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: tone == SettingsIconTone.danger
                                      ? colors.settingsIconDangerFg
                                      : colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: Dimens.space4),
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.textSecondary),
                            ),
                          ],
                          if (value != null) ...[
                            const SizedBox(height: Dimens.space4),
                            Text(
                              value!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: Dimens.space8),
                      trailing!,
                    ],
                    if (locked) ...[
                      const SizedBox(width: Dimens.space8),
                      Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                    ] else if (showChevron) ...[
                      const SizedBox(width: Dimens.space4),
                      Icon(
                        Icons.chevron_right,
                        textDirection: Directionality.of(context),
                        color: colors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    required this.children,
    this.label,
    super.key,
  });

  final String? label;
  final List<SettingsRow> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: Dimens.space8,
              bottom: Dimens.space8,
            ),
            child: Text(
              label!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimens.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 64,
                      end: Dimens.space12,
                    ),
                    child: Divider(height: 1, color: colors.border),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
