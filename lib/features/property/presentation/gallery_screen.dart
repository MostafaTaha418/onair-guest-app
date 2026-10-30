import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The full-screen photo viewer (`/property/:id/gallery?index=n`). Images
/// arrive with the route as `extra` from the details header; a direct link
/// loads the details once (research R9). Only the next photo is precached
/// (research R8).
final class GalleryScreen extends StatefulWidget {
  const GalleryScreen({
    required this.propertyId,
    required this.initialIndex,
    this.images,
    super.key,
  });

  final String propertyId;
  final int initialIndex;

  /// Carried by the details screen's `push`; null on a direct link, in which
  /// case the images are loaded from the repository.
  final List<ListingImage>? images;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

final class _GalleryScreenState extends State<GalleryScreen> {
  List<ListingImage> _images = const [];
  PageController? _controller;
  var _current = 0;
  var _loading = false;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    final provided = widget.images;
    if (provided != null && provided.isNotEmpty) {
      _images = provided;
      _start();
    } else {
      _loading = true;
      unawaited(_loadImages());
    }
  }

  Future<void> _loadImages() async {
    try {
      final details = await context.read<ListingsRepository>().property(
        widget.propertyId,
      );
      if (!mounted) return;
      setState(() {
        _images = details.images;
        _loading = false;
        _failure = null;
      });
      _start();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = failure;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failure = null;
    });
    unawaited(_loadImages());
  }

  void _start() {
    final last = _images.isEmpty ? 0 : _images.length - 1;
    _controller = PageController(
      initialPage: _current.clamp(0, last),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _current = index);
    _precacheNext(index);
  }

  void _precacheNext(int index) {
    final next = index + 1;
    if (next >= _images.length) return;
    final picked = ImageVariants.pick(
      variants: _images[next].variants,
      logicalWidth: MediaQuery.sizeOf(context).width,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    if (picked == null) return;
    unawaited(
      precacheImage(CachedNetworkImageProvider(picked.url.toString()), context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final controller = _controller;
    final total = _images.length;
    final failed = _failure;
    return Scaffold(
      backgroundColor: dark ? colors.surface : colors['background'],
      body: Stack(
        children: [
          // A skeleton, not a spinner (plan §13), roughly the photo's shape.
          if (_loading)
            const Center(child: SkeletonBox(width: 280, height: 210)),
          if (failed != null)
            ErrorView(
              message: apiErrorMessage(failed.error, l10n),
              onRetry: _retry,
            ),
          if (!_loading && failed == null && total == 0)
            EmptyView(
              icon: Icons.image_outlined,
              message: l10n.galleryEmpty,
            ),
          if (!_loading && failed == null && controller != null && total > 0)
            PageView.builder(
              controller: controller,
              itemCount: total,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: OnAirNetworkImage(
                    variants: _images[index].variants,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.galleryClose,
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.close,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (total > 0 && !_loading && failed == null)
                  Semantics(
                    label: l10n.galleryPhotoPosition(_current + 1, total),
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: Dimens.space12,
                      ),
                      child: Text(
                        l10n.galleryPhotoPosition(_current + 1, total),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
