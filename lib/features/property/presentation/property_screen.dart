import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/core/money/money.dart';
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
    super.key,
  });

  final String propertyId;

  /// The card cover's variants from `GoRouterState.extra` (research R9); the
  /// loading state shows this photo while the details load (SC-006).
  final List<ImageVariant>? heroVariants;

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

final class _PropertyScreenState extends State<PropertyScreen> {
  Map<String, String> _typeLabels = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadTypeLabels());
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
        // US4 adds the resume handling here.
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
        PropertyReady(:final details, :final stay, :final guests) => _ReadyBody(
          propertyId: widget.propertyId,
          heroVariants: widget.heroVariants,
          details: details,
          stay: stay,
          guests: guests,
          typeLabels: _typeLabels,
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
  });

  final String propertyId;
  final List<ImageVariant>? heroVariants;
  final PropertyDetails details;
  final StayRange? stay;
  final int? guests;
  final Map<String, String> typeLabels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PropertyGalleryHeader(
              propertyId: propertyId,
              images: details.images,
              heroVariants: heroVariants,
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
                PropertyRulesSection(details: details),
                const SizedBox(height: Dimens.space24),
                PropertyPolicySection(details: details),
                const SizedBox(height: Dimens.space24),
                PropertyAvailabilitySection(propertyId: propertyId),
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
    _pushLogin(context);
  }
}

/// US4 replaces this with the resume protocol (research R10).
void _pushLogin(BuildContext context) {
  final current = GoRouterState.of(context).uri.toString();
  unawaited(
    context.push(
      Uri(
        path: AppRoutes.login,
        queryParameters: {'from': current, 'cancelTo': current},
      ).toString(),
    ),
  );
}

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
      _pushLogin(context);
      return;
    }
    unawaited(
      context.push(
        Uri(
          path: AppRoutes.bookingEntry(details.id),
          queryParameters: {
            if (stay != null) 'checkIn': stay!.checkIn.toString(),
            if (stay != null) 'checkOut': stay!.checkOut.toString(),
            if (guests != null) 'guests': '$guests',
            'terms': details.termsVersion,
          },
        ).toString(),
      ),
    );
  }
}
