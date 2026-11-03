import 'package:flutter/material.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// Shared visual frame for the account entry and recovery screens.
final class AuthFlowScaffold extends StatelessWidget {
  const AuthFlowScaffold({
    required this.children,
    this.topSpaceFactor = 0.35,
    this.minTopSpace = 40,
    this.maxTopSpace = 160,
    this.onBack,
    super.key,
  });

  final List<Widget> children;
  final double topSpaceFactor;
  final double minTopSpace;
  final double maxTopSpace;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: colors.gradient('authBackground')),
      child: Scaffold(
        backgroundColor: colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: colors.transparent,
          surfaceTintColor: colors.transparent,
          elevation: 0,
          leading: onBack == null
              ? null
              : IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: onBack,
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
              final topSpace =
                  ((constraints.maxHeight - 560) * topSpaceFactor + 40).clamp(
                    minTopSpace,
                    maxTopSpace,
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
                    children: children,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
