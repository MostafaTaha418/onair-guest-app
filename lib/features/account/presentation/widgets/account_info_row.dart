import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// One pill info row of the profile card (#12 style), moved out of the
/// S005 placeholder (task T077) so the full account screen reuses it.
final class AccountInfoRow extends StatelessWidget {
  const AccountInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: Dimens.space16,
        vertical: Dimens.space12,
      ),
      decoration: BoxDecoration(
        color: colors['socialFill'],
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: colors['border']),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textStyles.placeholder.copyWith(
                  color: colors['textMuted'],
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.input,
              ),
              if (trailing != null && constraints.maxWidth < 360) ...[
                const SizedBox(height: Dimens.space8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: trailing,
                ),
              ],
            ],
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: Dimens.space4),
                child: Icon(icon, size: 20, color: colors['textMuted']),
              ),
              const SizedBox(width: Dimens.space12),
              Expanded(child: info),
              if (trailing != null && constraints.maxWidth >= 360) trailing!,
            ],
          );
        },
      ),
    );
  }
}
