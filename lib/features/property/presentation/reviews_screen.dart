import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/property/presentation/reviews_cubit.dart';
import 'package:on_air/features/property/presentation/widgets/property_reviews_section.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// All approved reviews of one apartment (`/property/:id/reviews`), driven
/// by [ReviewsCubit] with cursor pagination.
final class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) {
      final cubit = ReviewsCubit(
        repo: context.read<ListingsRepository>(),
        propertyId: propertyId,
      );
      unawaited(cubit.load());
      return cubit;
    },
    child: const _ReviewsView(),
  );
}

final class _ReviewsView extends StatefulWidget {
  const _ReviewsView();

  @override
  State<_ReviewsView> createState() => _ReviewsViewState();
}

final class _ReviewsViewState extends State<_ReviewsView> {
  bool _onScrollNotification(ScrollNotification notification) {
    final cubit = context.read<ReviewsCubit>();
    final state = cubit.state;
    if (state is! ReviewsReady || state.loadingMore) return false;
    if (state.nextCursor != null && notification.metrics.extentAfter < 600) {
      unawaited(cubit.loadMore());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.propertyReviews)),
      body: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivity) => Column(
          children: [
            if (!connectivity.isOnline) const OfflineBanner(),
            Expanded(
              child: BlocBuilder<ReviewsCubit, ReviewsState>(
                builder: (context, state) =>
                    NotificationListener<ScrollNotification>(
                      onNotification: _onScrollNotification,
                      child: switch (state) {
                        ReviewsLoading() => _skeletons(),
                        ReviewsEmpty() => EmptyView(
                          icon: Icons.star_outline,
                          message: l10n.reviewsNone,
                        ),
                        ReviewsFailed(:final error) => ErrorView(
                          message: apiErrorMessage(error, l10n),
                          referenceNumber: error.requestId,
                          onRetry: context.read<ReviewsCubit>().retry,
                        ),
                        ReviewsReady() => _list(context, state),
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletons() => ListView(
    padding: const EdgeInsetsDirectional.all(Dimens.space16),
    children: [
      for (var index = 0; index < 4; index++)
        const Padding(
          padding: EdgeInsetsDirectional.only(bottom: Dimens.space16),
          child: SkeletonBox(height: 96),
        ),
    ],
  );

  Widget _list(BuildContext context, ReviewsReady state) => ListView.builder(
    padding: const EdgeInsetsDirectional.all(Dimens.space16),
    itemCount: state.items.length + (state.loadingMore ? 1 : 0),
    itemBuilder: (context, index) {
      if (index >= state.items.length) {
        return const Padding(
          padding: EdgeInsetsDirectional.only(bottom: Dimens.space16),
          child: SkeletonBox(height: 96),
        );
      }
      return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: Dimens.space16),
        child: ReviewTile(review: state.items[index]),
      );
    },
  );
}
