import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// A pulsing loading placeholder matching the content's shape (Constitution
/// VIII). Static when the user disables animations.
final class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    required this.height,
    this.width,
    this.radius = Dimens.radiusCard,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

final class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (animate && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
      unawaited(_controller!.repeat(reverse: true));
    } else if (!animate) {
      _controller?.dispose();
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
    final colors = context.colors;
    final controller = _controller;
    Widget box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: colors['detailCard'],
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );
    if (controller != null) {
      box = AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              colors['detailCard'],
              colors['borderDetail'],
              controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
    }
    return RepaintBoundary(child: box);
  }
}

/// Loading placeholder shaped like `PropertyCard`: a 16:10 image area, two
/// text lines, and a price row.
final class PropertyCardSkeleton extends StatelessWidget {
  const PropertyCardSkeleton({this.width = double.infinity, super.key});

  final double width;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimens.radiusCard);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: radius,
        border: Border.all(color: context.colors['subtleBorder']),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: double.infinity, height: 180, radius: 0),
            Padding(
              padding: EdgeInsetsDirectional.all(Dimens.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                    width: double.infinity,
                    height: Dimens.space16,
                    radius: Dimens.radiusChip,
                  ),
                  SizedBox(height: Dimens.space8),
                  SkeletonBox(
                    width: 140,
                    height: Dimens.space12,
                    radius: Dimens.radiusChip,
                  ),
                  SizedBox(height: Dimens.space12),
                  SkeletonBox(
                    width: 90,
                    height: Dimens.space16,
                    radius: Dimens.radiusChip,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
