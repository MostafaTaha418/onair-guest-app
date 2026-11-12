import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/design_system/tokens/on_air_colors.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The booking-flow kit (dates · summary · details redesign, 2026-11): one
/// card, row, notice, banner, chip, button and state language shared by the
/// three booking screens. Other screens keep the older components until they
/// are redesigned.

/// Emphasized-decelerate, the curve the redesign uses for arrivals.
const Curve flowEmphasized = Cubic(0.2, 0, 0, 1);

/// Durations collapse to zero when the system asks for reduced motion.
Duration flowDuration(BuildContext context, int milliseconds) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

/// The redesign's semantic tones. Warning and info text uses the primary
/// text color: the brief's tone-on-tone pairs fall near 2:1 contrast.
enum FlowTone { success, warning, info, rejected, cancelled, badge }

/// Theme-resolved colors the kit needs beyond the shared tokens.
final class FlowPalette {
  FlowPalette._(this.colors, this.dark);

  factory FlowPalette.of(BuildContext context) => FlowPalette._(
    context.colors,
    Theme.of(context).brightness == Brightness.dark,
  );

  final OnAirColors colors;
  final bool dark;

  /// Quiet card and divider border (`border2` in the brief).
  Color get border2 => dark ? colors.border : colors['borderNeutral'];
  Color get border => colors.border;
  Color get accent => colors['textAccent'];
  Color get highlight => colors['badgeNavActive'];
  Color get badge => dark ? colors['textAccent'] : colors.primary;
  Color get destructive =>
      dark ? colors['rejectedText'] : colors['destructive'];
  Color get disabledBackground => colors.textPrimary.withValues(alpha: 0.12);
  Color get disabledForeground => colors.textPrimary.withValues(alpha: 0.38);
  Color get pressedOverlay => const Color(0xFF000000);

  /// Text, mark (icon/dot), background and border of a tone.
  ({Color text, Color mark, Color background, Color border}) tone(
    FlowTone tone,
  ) {
    final clear = colors.transparent;
    return switch (tone) {
      FlowTone.success => (
        text: colors['success'],
        mark: colors['success'],
        background: colors['completedBackground'],
        border: clear,
      ),
      FlowTone.warning => (
        text: colors.textPrimary,
        mark: dark ? colors.textPrimary : colors['warning'],
        background: dark ? colors['warningContainer'] : clear,
        border: dark ? clear : colors['warning'],
      ),
      FlowTone.info => (
        text: colors.textPrimary,
        mark: colors.textPrimary,
        background: colors['infoContainer'],
        border: clear,
      ),
      FlowTone.rejected => (
        text: colors['rejectedText'],
        mark: colors['rejectedText'],
        background: colors['rejectedBackground'],
        border: clear,
      ),
      FlowTone.cancelled => (
        text: colors['cancelledText'],
        mark: colors['cancelledText'],
        background: colors['cancelledBackground'],
        border: clear,
      ),
      FlowTone.badge => (
        text: badge,
        mark: badge,
        background: colors['badgeNavActive'],
        border: clear,
      ),
    };
  }
}

TextStyle _text(
  BuildContext context,
  double size,
  FontWeight weight, {
  double? height,
  Color? color,
}) => Theme.of(context).textTheme.bodyMedium!.copyWith(
  fontSize: size,
  fontWeight: weight,
  height: height,
  color: color ?? context.colors.textPrimary,
);

/// Applies the booking redesign's type choices while keeping every raw
/// typography property inside the design system. Passing [base] preserves any
/// existing theme features that the caller does not intentionally override.
TextStyle flowText(
  BuildContext context, {
  TextStyle? base,
  double? size,
  FontWeight? weight,
  double? height,
  Color? color,
  double? letterSpacing,
  TextDecoration? decoration,
  List<FontFeature>? fontFeatures,
}) => (base ?? Theme.of(context).textTheme.bodyMedium!).copyWith(
  fontSize: size,
  fontWeight: weight,
  height: height,
  color: color,
  letterSpacing: letterSpacing,
  decoration: decoration,
  fontFeatures: fontFeatures,
);

/// The redesign's app bar: 56dp, a 48dp back button and a 20/w800 title on
/// the page color.
PreferredSizeWidget flowAppBar(
  BuildContext context, {
  required String title,
  VoidCallback? onBack,
  List<Widget>? actions,
}) {
  final colors = context.colors;
  return AppBar(
    toolbarHeight: 56,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: colors.transparent,
    backgroundColor: colors.background,
    foregroundColor: colors.textPrimary,
    centerTitle: false,
    titleSpacing: Dimens.space4,
    // An explicit [onBack] always shows (nested booking navigator);
    // otherwise only a route that can be left gets one.
    automaticallyImplyLeading: false,
    leading:
        onBack != null ||
            (ModalRoute.of(context)?.impliesAppBarDismissal ?? false)
        ? BackButton(onPressed: onBack)
        : null,
    title: Text(
      title,
      style: _text(context, 20, FontWeight.w800, height: 1.3),
    ),
    actions: actions,
  );
}

/// A floating snack bar in the inverted text/page colors.
void showFlowSnack(BuildContext context, String message) {
  final colors = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: colors.textPrimary,
        margin: const EdgeInsetsDirectional.fromSTEB(
          Dimens.screenSide,
          0,
          Dimens.screenSide,
          Dimens.space12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusField),
        ),
        content: Text(
          message,
          style: _text(
            context,
            14,
            FontWeight.w600,
            height: 1.5,
            color: colors.background,
          ),
        ),
      ),
    );
}

/// A surface card with the quiet 1dp border and 16dp corners.
final class FlowCard extends StatelessWidget {
  const FlowCard({
    required this.child,
    this.padding = const EdgeInsetsDirectional.all(Dimens.space16),
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border.all(
        color: borderColor ?? FlowPalette.of(context).border2,
      ),
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
    ),
    child: Padding(padding: padding, child: child),
  );
}

/// The 18/w800 section title; 12dp of extra space above it.
final class FlowSectionTitle extends StatelessWidget {
  const FlowSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: Dimens.space12),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: _text(context, 18, FontWeight.w800, height: 1.4),
      ),
    ),
  );
}

/// A count-up from one server value to another (display only): the number
/// steps in rounded tens and lands exactly on [to].
@immutable
final class FlowCountUp {
  const FlowCountUp({
    required this.from,
    required this.to,
    required this.format,
    this.step = 1000,
  });

  final int from;
  final int to;
  final String Function(int value) format;

  /// The rounding step while counting (minor units: 1000 = 10 EGP).
  final int step;
}

/// Label at the start, value at the end. When both no longer fit on one
/// line the value drops to its own line, still end-aligned — never cut.
/// [changed] paints the highlight and shows [previous] struck through.
final class FlowDataRow extends StatelessWidget {
  const FlowDataRow({
    required this.label,
    required this.value,
    this.previous,
    this.emphasized = false,
    this.changed = false,
    this.countUp,
    super.key,
  });

  final String label;
  final String value;
  final String? previous;
  final bool emphasized;
  final bool changed;
  final FlowCountUp? countUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final labelStyle = emphasized
        ? _text(context, 15, FontWeight.w700)
        : _text(context, 14, FontWeight.w500, color: colors.textSecondary);
    final valueStyle = _text(
      context,
      emphasized ? 17 : 14,
      emphasized ? FontWeight.w800 : FontWeight.w600,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final oldStyle = _text(
      context,
      13,
      FontWeight.w500,
      color: colors.textSecondary,
    ).copyWith(decoration: TextDecoration.lineThrough);
    final shownPrevious = changed ? previous : null;

    Widget valueText() {
      final count = changed ? countUp : null;
      if (count == null || count.from == count.to) {
        return Text(value, textAlign: TextAlign.end, style: valueStyle);
      }
      return TweenAnimationBuilder<double>(
        key: ValueKey('${count.from}->${count.to}'),
        tween: Tween(begin: count.from.toDouble(), end: count.to.toDouble()),
        duration: flowDuration(context, 700),
        curve: Curves.easeOutCubic,
        builder: (context, current, _) {
          final done = current == count.to.toDouble();
          final rounded = (current / count.step).round() * count.step;
          return Text(
            done ? value : count.format(rounded),
            textAlign: TextAlign.end,
            style: valueStyle,
          );
        },
      );
    }

    // The value and, when it changed, the struck old value before it: one
    // group that always ends on the row's end edge.
    final valueParts = [
      if (shownPrevious != null) ...[
        Text(shownPrevious, style: oldStyle),
        const SizedBox(width: Dimens.space8),
      ],
      valueText(),
    ];

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: shownPrevious == null
          ? '$label: $value'
          : '$label: $value، ${l10n.amountWas(shownPrevious)}',
      child: AnimatedContainer(
        duration: flowDuration(context, 500),
        curve: flowEmphasized,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsetsDirectional.all(Dimens.space8),
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          color: changed
              ? FlowPalette.of(context).highlight
              : colors.transparent,
          borderRadius: BorderRadius.circular(Dimens.radiusChip),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context);
            final direction = Directionality.of(context);
            double width(String text, TextStyle style) {
              final painter = TextPainter(
                text: TextSpan(text: text, style: style),
                textDirection: direction,
                textScaler: scaler,
                maxLines: 1,
              )..layout();
              // Whole pixels: a fractional width must not flip the layout.
              final result = painter.width.ceilToDouble();
              painter.dispose();
              return result;
            }

            // While counting up from the old amount the moving number can be
            // as wide as the old one: reserve the wider of the two.
            final valueWidth = shownPrevious == null
                ? width(value, valueStyle)
                : [
                    width(value, valueStyle),
                    width(shownPrevious, valueStyle),
                  ].reduce((a, b) => a > b ? a : b);
            final needed =
                width(label, labelStyle) +
                Dimens.space12 +
                valueWidth +
                (shownPrevious == null
                    ? 0
                    : width(shownPrevious, oldStyle) + Dimens.space8);
            if (needed <= constraints.maxWidth) {
              // The label takes all the free space, so the value sits flush
              // on the end edge whatever the label's length — every row's
              // value lines up with the others.
              return Row(
                children: [
                  Expanded(child: Text(label, style: labelStyle)),
                  const SizedBox(width: Dimens.space12),
                  ...valueParts,
                ],
              );
            }
            // Too long for one line: the value group drops below the label,
            // still end-aligned, and its own parts wrap if they must.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: 2),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: valueParts,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A card of [FlowDataRow]s (6/8 inner padding, 2dp gaps).
final class FlowRowsCard extends StatelessWidget {
  const FlowRowsCard({required this.children, this.bottomPadding, super.key});

  final List<Widget> children;
  final double? bottomPadding;

  @override
  Widget build(BuildContext context) => FlowCard(
    padding: EdgeInsetsDirectional.fromSTEB(
      Dimens.space8,
      6,
      Dimens.space8,
      bottomPadding ?? 6,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          children[i],
        ],
      ],
    ),
  );
}

/// The 1dp separator inside a [FlowRowsCard].
final class FlowRowDivider extends StatelessWidget {
  const FlowRowDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: Dimens.space8,
      vertical: 6,
    ),
    child: Container(height: 1, color: FlowPalette.of(context).border2),
  );
}

/// A 40dp tone circle with a 22dp icon.
final class FlowToneCircle extends StatelessWidget {
  const FlowToneCircle({
    required this.icon,
    required this.tone,
    this.size = 40,
    this.iconSize = 22,
    super.key,
  });

  final IconData icon;
  final FlowTone tone;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = FlowPalette.of(context).tone(tone);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.background,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, size: iconSize, color: colors.mark),
      ),
    );
  }
}

/// A surface card announcing a state: tone circle, 15/w600 message and an
/// optional action below. Announced politely when it appears.
final class FlowNoticeCard extends StatelessWidget {
  const FlowNoticeCard({
    required this.icon,
    required this.message,
    required this.tone,
    this.action,
    super.key,
  });

  final IconData icon;
  final String message;
  final FlowTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    container: true,
    child: FlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FlowToneCircle(icon: icon, tone: tone),
              const SizedBox(width: Dimens.space12),
              Expanded(
                child: Text(
                  message,
                  style: _text(context, 15, FontWeight.w600, height: 1.6),
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: Dimens.space12),
            action!,
          ],
        ],
      ),
    ),
  );
}

enum FlowBannerTone { info, warning, neutral }

/// A 12dp-corner banner: icon, 14sp text, optional outlined action at the
/// end below it.
final class FlowBanner extends StatelessWidget {
  const FlowBanner({
    required this.icon,
    required this.message,
    required this.tone,
    this.action,
    this.liveRegion = false,
    super.key,
  });

  final IconData icon;
  final String message;
  final FlowBannerTone tone;
  final Widget? action;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final palette = FlowPalette.of(context);
    final colors = palette.colors;
    final (background, border, mark, weight) = switch (tone) {
      FlowBannerTone.info => (
        colors['infoContainer'],
        colors.transparent,
        colors.textPrimary,
        FontWeight.w500,
      ),
      FlowBannerTone.warning => (
        palette.tone(FlowTone.warning).background,
        palette.tone(FlowTone.warning).border,
        palette.tone(FlowTone.warning).mark,
        FontWeight.w600,
      ),
      FlowBannerTone.neutral => (
        colors['cancelledBackground'],
        colors.transparent,
        colors['cancelledText'],
        FontWeight.w600,
      ),
    };
    return Semantics(
      liveRegion: liveRegion,
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(Dimens.space12),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(Dimens.radiusField),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(icon, size: 22, color: mark)),
                const SizedBox(width: Dimens.space12),
                Expanded(
                  child: Text(
                    message,
                    style: _text(context, 14, weight, height: 1.6),
                  ),
                ),
              ],
            ),
            if (action != null) ...[
              const SizedBox(height: 10),
              Align(alignment: AlignmentDirectional.centerEnd, child: action),
            ],
          ],
        ),
      ),
    );
  }
}

/// A status chip: 8dp corners, tone dot and 12/w700 label. [dense] is the
/// payment-line variant (22dp, 11sp, no dot).
final class FlowChip extends StatelessWidget {
  const FlowChip({
    required this.label,
    required this.tone,
    this.dense = false,
    super.key,
  });

  final String label;
  final FlowTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = FlowPalette.of(context).tone(tone);
    return Container(
      constraints: BoxConstraints(minHeight: dense ? 22 : 28),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: dense ? Dimens.space8 : 10,
        vertical: dense ? 0 : 2,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(Dimens.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!dense) ...[
            ExcludeSemantics(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colors.mark,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: _text(
                context,
                dense ? 11 : 12,
                FontWeight.w700,
                height: 1.4,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum FlowButtonKind { filled, outlined, destructive }

/// The redesign's button: filled, outlined (accent on surface) or a
/// destructive text button. While [loading] it shows a spinner in place of
/// its label at the same size and ignores taps (no double submit).
final class FlowButton extends StatefulWidget {
  const FlowButton({
    required this.label,
    required this.onPressed,
    this.kind = FlowButtonKind.filled,
    this.loading = false,
    this.icon,
    this.trailing,
    this.minHeight = Dimens.minTouchTarget,
    this.textSize = 15,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final FlowButtonKind kind;
  final bool loading;
  final IconData? icon;

  /// Extra content after the label, excluded from semantics (a cooldown).
  final Widget? trailing;
  final double minHeight;
  final double textSize;
  final bool expand;

  @override
  State<FlowButton> createState() => _FlowButtonState();
}

final class _FlowButtonState extends State<FlowButton> {
  final _states = WidgetStatesController();
  var _pressed = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(_onStates);
  }

  void _onStates() {
    final pressed = _states.value.contains(WidgetState.pressed);
    if (pressed != _pressed) setState(() => _pressed = pressed);
  }

  @override
  void dispose() {
    _states
      ..removeListener(_onStates)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlowPalette.of(context);
    final colors = palette.colors;
    final loading = widget.loading;
    final onPressed = loading ? null : widget.onPressed;
    final textStyle = _text(
      context,
      widget.textSize,
      FontWeight.w700,
      height: 1.4,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Dimens.radiusButton),
    );
    final minimumSize = Size(
      widget.expand ? double.infinity : 0,
      widget.minHeight,
    );
    const padding = EdgeInsetsDirectional.symmetric(
      horizontal: Dimens.space16,
      vertical: 10,
    );
    final (foreground, loadingColor) = switch (widget.kind) {
      FlowButtonKind.filled => (colors.onPrimary, colors.onPrimary),
      FlowButtonKind.outlined => (palette.accent, palette.accent),
      FlowButtonKind.destructive => (palette.destructive, palette.destructive),
    };
    final spinnerSize = widget.minHeight >= 52 ? 20.0 : 18.0;
    final child = loading
        ? SizedBox.square(
            dimension: spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: loadingColor,
              semanticsLabel: widget.label,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: Dimens.space8),
              ],
              Flexible(
                child: Text(widget.label, textAlign: TextAlign.center),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 6),
                ExcludeSemantics(child: widget.trailing),
              ],
            ],
          );
    final Widget button = switch (widget.kind) {
      FlowButtonKind.filled => FilledButton(
        statesController: _states,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: foreground,
          disabledBackgroundColor: loading
              ? colors.primary
              : palette.disabledBackground,
          disabledForegroundColor: loading
              ? foreground
              : palette.disabledForeground,
          minimumSize: minimumSize,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
          // Reduced motion: state colors switch without a fade.
          animationDuration: flowDuration(context, 200),
          overlayColor: palette.pressedOverlay,
        ),
        child: child,
      ),
      FlowButtonKind.outlined => OutlinedButton(
        statesController: _states,
        onPressed: onPressed,
        style:
            OutlinedButton.styleFrom(
              backgroundColor: colors.surface,
              foregroundColor: foreground,
              disabledForegroundColor: loading
                  ? foreground
                  : palette.disabledForeground,
              minimumSize: minimumSize,
              padding: padding,
              shape: shape,
              textStyle: textStyle,
              // Reduced motion: state colors switch without a fade.
              animationDuration: flowDuration(context, 200),
              overlayColor: foreground,
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.disabled) && !loading
                      ? palette.border2
                      : palette.border,
                ),
              ),
            ),
        child: child,
      ),
      FlowButtonKind.destructive => TextButton(
        statesController: _states,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foreground,
          disabledForegroundColor: loading
              ? foreground
              : palette.disabledForeground,
          minimumSize: minimumSize,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
          // Reduced motion: state colors switch without a fade.
          animationDuration: flowDuration(context, 200),
          overlayColor: foreground,
        ),
        child: child,
      ),
    };
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: flowDuration(context, 120),
      child: button,
    );
  }
}

/// The pinned bottom bar: surface, top border, one full-width action.
final class FlowActionBar extends StatelessWidget {
  const FlowActionBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border(top: BorderSide(color: FlowPalette.of(context).border2)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Dimens.screenSide,
          Dimens.space12,
          Dimens.screenSide,
          Dimens.space20,
        ),
        child: child,
      ),
    ),
  );
}

/// The whole-page state: a 72dp circle, a 16/w700 message, an optional
/// action and, for errors, a selectable left-to-right reference.
final class FlowStateView extends StatelessWidget {
  const FlowStateView({
    required this.icon,
    required this.message,
    this.iconColor,
    this.action,
    this.reference,
    super.key,
  });

  final IconData icon;
  final String message;
  final Color? iconColor;
  final Widget? action;
  final String? reference;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    const marker = '\u0000';
    final referenceParts = l10n.referenceNumber(marker).split(marker);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(Dimens.space24),
              child: FlowFadeUp(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FlowPalette.of(context).border2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: iconColor ?? colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimens.space12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: _text(context, 16, FontWeight.w700, height: 1.6),
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: Dimens.space16),
                      action!,
                    ],
                    if (reference != null) ...[
                      const SizedBox(height: Dimens.space12),
                      SelectableText.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: referenceParts.first),
                            TextSpan(
                              text: '\u2066${reference!}\u2069',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontFamilyFallback: ['Courier', 'Cairo'],
                              ),
                            ),
                            if (referenceParts.length > 1)
                              TextSpan(text: referenceParts.last),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: _text(
                          context,
                          12,
                          FontWeight.w500,
                          color: colors.textSecondary,
                        ),
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

/// A one-time arrival: 8dp rise and fade, optionally delayed.
final class FlowFadeUp extends StatelessWidget {
  const FlowFadeUp({required this.child, this.delayMs = 0, super.key});

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = 360 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: flowEmphasized),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// One pulse shared by every [FlowSkeletonBlock] below it, announced once
/// as "loading". Static at 0.75 with reduced motion.
final class FlowSkeletonScope extends StatefulWidget {
  const FlowSkeletonScope({required this.child, super.key});

  final Widget child;

  @override
  State<FlowSkeletonScope> createState() => _FlowSkeletonScopeState();
}

final class _FlowSkeletonScopeState extends State<FlowSkeletonScope>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (animate && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      );
      unawaited(_controller!.repeat(reverse: true));
    } else if (!animate && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final opacity = controller == null
        ? const AlwaysStoppedAnimation<double>(0.75)
        : Tween<double>(begin: 0.5, end: 1).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );
    return Semantics(
      container: true,
      label: AppLocalizations.of(context).loading,
      child: ExcludeSemantics(
        child: _SkeletonPulse(opacity: opacity, child: widget.child),
      ),
    );
  }
}

final class _SkeletonPulse extends InheritedWidget {
  const _SkeletonPulse({required this.opacity, required super.child});

  final Animation<double> opacity;

  @override
  bool updateShouldNotify(_SkeletonPulse oldWidget) =>
      opacity != oldWidget.opacity;
}

/// A loading block in the quiet border color.
final class FlowSkeletonBlock extends StatelessWidget {
  const FlowSkeletonBlock({
    this.width,
    this.height = 12,
    this.radius = Dimens.radiusChip,
    this.circle = false,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final pulse = context
        .dependOnInheritedWidgetOfExactType<_SkeletonPulse>()
        ?.opacity;
    final block = Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: FlowPalette.of(context).border2,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
    if (pulse == null) return block;
    return FadeTransition(opacity: pulse, child: block);
  }
}

/// Cover 96×72 with the property name (two lines at most) and its area.
final class FlowPropertyHeader extends StatelessWidget {
  const FlowPropertyHeader({
    required this.variants,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final List<ImageVariant> variants;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimens.radiusField),
          child: SizedBox(
            width: 96,
            height: 72,
            child: OnAirNetworkImage(variants: variants),
          ),
        ),
      ),
      const SizedBox(width: Dimens.space12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _text(context, 16, FontWeight.w700, height: 1.45),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: _text(
                context,
                14,
                FontWeight.w500,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// A card of short lines, each led by a 6dp primary dot.
final class FlowBulletCard extends StatelessWidget {
  const FlowBulletCard({required this.lines, super.key});

  final List<String> lines;

  @override
  Widget build(BuildContext context) => FlowCard(
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: Dimens.space16,
      vertical: Dimens.space12,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: Dimens.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 9),
                child: ExcludeSemantics(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lines[i],
                  style: _text(context, 14, FontWeight.w500, height: 1.6),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

/// The offline strip at the top of a booking screen.
final class FlowOfflineBanner extends StatelessWidget {
  const FlowOfflineBanner({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => FlowBanner(
    icon: icon,
    message: AppLocalizations.of(context).offline,
    tone: FlowBannerTone.neutral,
    liveRegion: true,
  );
}
