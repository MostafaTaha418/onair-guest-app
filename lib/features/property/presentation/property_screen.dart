import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/share/share_service.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/bottom_action_bar.dart';
import 'package:on_air/design_system/components/expandable_text.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/price_text.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/app_update/presentation/not_available_screen.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/property/domain/resume_intent.dart';
import 'package:on_air/features/property/presentation/property_cubit.dart';
import 'package:on_air/features/property/presentation/widgets/property_address_section.dart';
import 'package:on_air/features/property/presentation/widgets/property_amenities_section.dart';
import 'package:on_air/features/property/presentation/widgets/property_availability_section.dart';
import 'package:on_air/features/property/presentation/widgets/property_gallery_header.dart';
import 'package:on_air/features/property/presentation/widgets/property_policy_section.dart';
import 'package:on_air/features/property/presentation/widgets/property_reviews_section.dart';
import 'package:on_air/features/property/presentation/widgets/property_rules_section.dart';
import 'package:on_air/features/property/presentation/widgets/property_specs_row.dart';
import 'package:on_air/features/property/presentation/widgets/property_title_section.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The apartment details screen (US2). Every section comes from the server;
/// there is no owner contact anywhere (AC-047) and the only money shown is
/// the final nightly price (AC-010).
final class PropertyScreen extends StatefulWidget {
  const PropertyScreen({
    required this.propertyId,
    this.heroVariants,
    this.today,
    super.key,
  });

  final String propertyId;

  /// The card cover's variants from `GoRouterState.extra` (research R9); the
  /// loading state shows this photo while the details load (SC-006).
  final List<ImageVariant>? heroVariants;

  /// Injectable Cairo date for goldens/tests; null uses the real clock.
  /// Pinning it keeps the availability calendar deterministic in reference
  /// images.
  final DateOnly? today;

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

final class _PropertyScreenState extends State<PropertyScreen> {
  Map<String, String> _typeLabels = const {};

  /// The rules section target for the terms-updated notice (AC-013).
  final GlobalKey _rulesKey = const GlobalObjectKey('property-rules');
  final ScrollController _scrollController = ScrollController();
  bool _noticeBannerShown = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTypeLabels());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// The carried-over sign-in intent (research R10): strip the resume keys
  /// from the location so Back never re-triggers it, then continue the
  /// action — booking entry only when the terms still match (AC-013).
  void _consumeResume(BuildContext context, PropertyReady state) {
    final intent = state.pendingResume!;
    context.read<PropertyCubit>().consumeResume();
    unawaited(
      GoRouter.of(context).replace(
        ResumeIntent.stripFrom(GoRouterState.of(context).uri).toString(),
      ),
    );
    switch (intent.action) {
      case ResumeAction.book:
        if (state.details.termsVersion == intent.termsVersion) {
          unawaited(
            context.push(
              _bookingEntryUri(
                state.details,
                state.stay,
                state.guests,
              ).toString(),
            ),
          );
        }
      case ResumeAction.contact:
        unawaited(
          context.push(
            Uri(
              path: AppRoutes.supportNew,
              queryParameters: {'property': state.details.id},
            ).toString(),
          ),
        );
    }
  }

  void _showTermsNotice(BuildContext context) {
    _noticeBannerShown = true;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          content: Text(l10n.propertyTermsUpdated),
          actions: [
            TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
              child: Text(l10n.calendarConfirm),
            ),
          ],
        ),
      );
    _scrollToRules();
  }

  /// Walks the lazy list towards the rules section; the post-frame re-check
  /// keeps it timer-free (widget tests run under fake async).
  void _scrollToRules() {
    final rulesContext = _rulesKey.currentContext;
    if (rulesContext != null) {
      unawaited(Scrollable.ensureVisible(rulesContext));
      return;
    }
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= maxExtent) return;
    _scrollController.jumpTo(
      math.min(_scrollController.offset + 600, maxExtent),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToRules());
  }

  Future<void> _loadTypeLabels() async {
    try {
      final reference = await context.read<ReferenceDataCache>().load();
      if (!mounted) return;
      setState(() {
        _typeLabels = {
          for (final type in reference.propertyTypes) type.key: type.label,
        };
      });
    } on AppFailure {
      // The title section falls back to the raw property-type key.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PropertyCubit, PropertyState>(
      listener: (context, state) {
        if (state is! PropertyReady) return;
        if (state.pendingResume != null) {
          _consumeResume(context, state);
        }
        if (state.termsUpdatedNotice && !_noticeBannerShown) {
          _showTermsNotice(context);
        }
      },
      builder: (context, state) => switch (state) {
        PropertyNotAvailable() => const NotAvailableScreen(),
        PropertyLoading() => _LoadingBody(
          propertyId: widget.propertyId,
          heroVariants: widget.heroVariants,
        ),
        PropertyFailed(:final error) => Scaffold(
          appBar: AppBar(),
          body: ErrorView(
            message: apiErrorMessage(error, AppLocalizations.of(context)),
            referenceNumber: error.requestId,
            onRetry: context.read<PropertyCubit>().retry,
          ),
        ),
        PropertyOffline() => const Scaffold(
          body: _OfflineBody(),
        ),
        PropertyReady(
          :final details,
          :final stay,
          :final guests,
        ) =>
          _ReadyBody(
            propertyId: widget.propertyId,
            heroVariants: widget.heroVariants,
            details: details,
            stay: stay,
            guests: guests,
            typeLabels: _typeLabels,
            scrollController: _scrollController,
            rulesKey: _rulesKey,
            today: widget.today,
          ),
      },
    );
  }
}

final class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.propertyId, this.heroVariants});

  final String propertyId;
  final List<ImageVariant>? heroVariants;

  @override
  Widget build(BuildContext context) {
    final hero = heroVariants;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hero != null && hero.isNotEmpty)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: OnAirNetworkImage(
                variants: hero,
                heroTag: 'listing-$propertyId',
              ),
            ),
          const Padding(
            padding: EdgeInsetsDirectional.all(Dimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 220, height: 24, radius: Dimens.radiusChip),
                SizedBox(height: Dimens.space16),
                SkeletonBox(height: 120),
                SizedBox(height: Dimens.space16),
                SkeletonBox(height: 120),
                SizedBox(height: Dimens.space16),
                SkeletonBox(height: 160),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Offline details (research R17): a banner plus retry.
final class _OfflineBody extends StatelessWidget {
  const _OfflineBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, connectivity) => Column(
        children: [
          if (!connectivity.isOnline) const OfflineBanner(),
          Expanded(
            child: ErrorView(
              message: l10n.errorNoConnection,
              onRetry: context.read<PropertyCubit>().retry,
            ),
          ),
        ],
      ),
    );
  }
}

final class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.propertyId,
    required this.heroVariants,
    required this.details,
    required this.stay,
    required this.guests,
    required this.typeLabels,
    required this.scrollController,
    required this.rulesKey,
    this.today,
  });

  final String propertyId;
  final List<ImageVariant>? heroVariants;
  final PropertyDetails details;
  final StayRange? stay;
  final int? guests;
  final Map<String, String> typeLabels;
  final ScrollController scrollController;
  final Key rulesKey;
  final DateOnly? today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: PropertyGalleryHeader(
              propertyId: propertyId,
              images: details.images,
              heroVariants: heroVariants,
              actions: [
                BlocBuilder<ConnectivityCubit, ConnectivityState>(
                  builder: (context, connectivity) => Semantics(
                    label: l10n.propertyShare,
                    button: true,
                    child: IconButton(
                      tooltip: l10n.propertyShare,
                      onPressed: connectivity.isOnline
                          ? () => _onShare(context)
                          : null,
                      icon: Icon(
                        Icons.share_outlined,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsetsDirectional.all(Dimens.space16),
            sliver: SliverList.list(
              children: [
                PropertyTitleSection(
                  details: details,
                  typeLabel:
                      typeLabels[details.propertyType] ?? details.propertyType,
                ),
                const SizedBox(height: Dimens.space16),
                PropertySpecsRow(details: details),
                const SizedBox(height: Dimens.space16),
                _DescriptionSection(details: details),
                const SizedBox(height: Dimens.space16),
                PropertyAmenitiesSection(details: details),
                const SizedBox(height: Dimens.space24),
                PropertyAddressSection(details: details),
                const SizedBox(height: Dimens.space24),
                KeyedSubtree(
                  key: rulesKey,
                  child: PropertyRulesSection(details: details),
                ),
                const SizedBox(height: Dimens.space24),
                PropertyPolicySection(details: details),
                const SizedBox(height: Dimens.space24),
                PropertyAvailabilitySection(
                  propertyId: propertyId,
                  today: today,
                ),
                const SizedBox(height: Dimens.space24),
                PropertyReviewsSection(details: details),
                const SizedBox(height: Dimens.space16),
                Center(
                  child: TextButton(
                    onPressed: () => _onContact(context),
                    child: Text(l10n.propertyContactOnAir),
                  ),
                ),
                const SizedBox(height: Dimens.space16),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        details: details,
        stay: stay,
        guests: guests,
      ),
    );
  }

  /// The share text is the title, then the bare verified link without any
  /// query parameters (contracts/app-routes-g1.md, "Share links").
  void _onShare(BuildContext context) {
    final shareLinks = context.read<ShareLinks>();
    unawaited(
      context.read<ShareService>().share(
        '${details.title}\n${shareLinks.property(details.id)}',
      ),
    );
  }

  void _onContact(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    if (auth is SignedIn) {
      unawaited(
        context.push(
          Uri(
            path: AppRoutes.supportNew,
            queryParameters: {'property': details.id},
          ).toString(),
        ),
      );
      return;
    }
    pushVisitorLogin(context, details, stay, guests, ResumeAction.contact);
  }
}

/// The visitor flow (research R10): sign-in carries the current dates and
/// guests plus the resume action — and, for booking, the terms the guest
/// actually saw. Cancelling returns to the same apartment without the
/// resume keys.
void pushVisitorLogin(
  BuildContext context,
  PropertyDetails details,
  StayRange? stay,
  int? guests,
  ResumeAction action,
) {
  final query = <String, String>{
    if (stay != null) 'checkIn': stay.checkIn.toString(),
    if (stay != null) 'checkOut': stay.checkOut.toString(),
    if (guests != null) 'guests': '$guests',
    'resume': action.name,
    if (action == ResumeAction.book) 'terms': details.termsVersion,
  };
  final from = Uri(
    path: AppRoutes.property(details.id),
    queryParameters: query,
  );
  final cancelTo = ResumeIntent.stripFrom(from);
  unawaited(
    context.push(
      Uri(
        path: AppRoutes.login,
        queryParameters: {
          'from': from.toString(),
          'cancelTo': cancelTo.toString(),
        },
      ).toString(),
    ),
  );
}

/// The booking entry carries the shown stay, guests, and terms (AC-013).
Uri _bookingEntryUri(PropertyDetails details, StayRange? stay, int? guests) =>
    Uri(
      path: AppRoutes.bookingEntry(details.id),
      queryParameters: {
        if (stay != null) 'checkIn': stay.checkIn.toString(),
        if (stay != null) 'checkOut': stay.checkOut.toString(),
        if (guests != null) 'guests': '$guests',
        'terms': details.termsVersion,
      },
    );

final class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.details});

  final PropertyDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.propertyDescription,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        ExpandableText(
          text: details.description,
          moreLabel: l10n.showMore,
          lessLabel: l10n.showLess,
        ),
      ],
    );
  }
}

final class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.details,
    required this.stay,
    required this.guests,
  });

  final PropertyDetails details;
  final StayRange? stay;
  final int? guests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final caption = stay == null
        ? null
        : '${DateOnlyFormatter.dayMonth(stay!.checkIn)} – '
              '${DateOnlyFormatter.dayMonth(stay!.checkOut)}';
    return BottomActionBar(
      leading: PriceText(
        price: l10n.nightlyPrice(MoneyFormatter().format(details.nightlyPrice)),
        caption: caption,
      ),
      action: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivity) => OnAirPrimaryButton(
          label: l10n.bookNow,
          onPressed: connectivity.isOnline ? () => _onBookNow(context) : null,
        ),
      ),
    );
  }

  void _onBookNow(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    if (auth is! SignedIn) {
      pushVisitorLogin(context, details, stay, guests, ResumeAction.book);
      return;
    }
    unawaited(
      context.push(
        _bookingEntryUri(details, stay, guests).toString(),
      ),
    );
  }
}
