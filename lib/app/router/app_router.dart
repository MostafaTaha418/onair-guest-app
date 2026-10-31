import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/app/shell/app_shell.dart';
import 'package:on_air/app/splash/splash_screen.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/account/presentation/account_placeholder_screen.dart';
import 'package:on_air/features/app_update/presentation/not_available_screen.dart';
import 'package:on_air/features/app_update/presentation/update_required_screen.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/complete_profile_screen.dart';
import 'package:on_air/features/auth/presentation/forgot_password_screen.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';
import 'package:on_air/features/auth/presentation/new_password_screen.dart';
import 'package:on_air/features/auth/presentation/otp_screen.dart';
import 'package:on_air/features/auth/presentation/register_screen.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/presentation/booking_flow_cubit.dart';
import 'package:on_air/features/booking/presentation/dates_screen.dart';
import 'package:on_air/features/booking/presentation/payment_return_screen.dart';
import 'package:on_air/features/booking/presentation/summary_screen.dart';
import 'package:on_air/features/booking/presentation/verify_identity_cubit.dart';
import 'package:on_air/features/booking/presentation/verify_identity_screen.dart';
import 'package:on_air/features/bookings/data/arrival_instructions_store.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/features/bookings/presentation/bookings_cubit.dart';
import 'package:on_air/features/bookings/presentation/bookings_screen.dart';
import 'package:on_air/features/favorites/presentation/favorites_placeholder_screen.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/home/presentation/home_cubit.dart';
import 'package:on_air/features/home/presentation/home_screen.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:on_air/features/notifications/presentation/notifications_cubit.dart';
import 'package:on_air/features/notifications/presentation/notifications_screen.dart';
import 'package:on_air/features/notifications/presentation/unread_count_cubit.dart';
import 'package:on_air/features/property/domain/resume_intent.dart';
import 'package:on_air/features/property/presentation/gallery_screen.dart';
import 'package:on_air/features/property/presentation/property_cubit.dart';
import 'package:on_air/features/property/presentation/property_screen.dart';
import 'package:on_air/features/property/presentation/reviews_screen.dart';
import 'package:on_air/features/search/presentation/results_screen.dart';
import 'package:on_air/features/search/presentation/search_cubit.dart';
import 'package:on_air/features/search/presentation/search_screen.dart';
import 'package:on_air/features/support/presentation/support_entry_placeholder_screen.dart';

bool _defaultUpdateRequired() => false;

/// Same bounds as `ResumeIntent`'s guests (1–50); anything else means «any».
int? _boundedGuests(String? raw) {
  final value = int.tryParse(raw ?? '');
  return value == null || value < 1 || value > 50 ? null : value;
}

/// The bookings tab from a `/bookings?tab=` query; anything else is current.
BookingTab _tabFrom(String? raw) => switch (raw) {
  'past' => BookingTab.past,
  'cancelled' => BookingTab.cancelled,
  _ => BookingTab.current,
};

/// The booking flow shares one draft across verify → dates → summary, so
/// the routes live under one shell that owns `BookingFlowCubit`; leaving
/// the branch disposes the draft (contracts/app-routes-g2.md §1).
final _bookingNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'booking',
);

GoRouter createAppRouter({
  required Listenable refreshListenable,
  required AuthCubit authCubit,
  required SearchCubit searchCubit,
  GlobalKey<NavigatorState>? navigatorKey,
  bool Function() updateRequired = _defaultUpdateRequired,
  void Function()? openStore,
}) => GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: AppRoutes.splash,
  refreshListenable: refreshListenable,
  redirect: (_, state) => resolveRedirect(
    RedirectContext(
      location: state.uri.toString(),
      authState: authCubit.state,
      from: state.uri.queryParameters['from'],
      updateRequired: updateRequired(),
    ),
  ),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (_, _) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (_, _) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      name: 'otp',
      builder: (_, _) => const OtpScreen(),
    ),
    GoRoute(
      path: AppRoutes.completeProfile,
      name: 'complete-profile',
      builder: (_, _) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgot-password',
      builder: (_, _) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.newPassword,
      name: 'new-password',
      builder: (_, _) => const NewPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.notAvailable,
      name: 'not-available',
      builder: (_, _) => const NotAvailableScreen(),
    ),
    GoRoute(
      path: AppRoutes.updateRequired,
      name: 'update-required',
      builder: (_, _) => UpdateRequiredScreen(onOpenStore: openStore),
    ),
    GoRoute(
      path: AppRoutes.propertyPattern,
      name: 'property',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final query = state.uri.queryParameters;
        return BlocProvider<PropertyCubit>(
          create: (context) {
            final cubit = PropertyCubit(
              repo: context.read<ListingsRepository>(),
              connectivity: context.read<ConnectivityCubit>(),
              propertyId: id,
              initialStay: StayRange.tryCreate(
                DateOnly.tryParse(query['checkIn']),
                DateOnly.tryParse(query['checkOut']),
                CairoTime.today(),
              ),
              initialGuests: _boundedGuests(query['guests']),
              pendingResume: ResumeIntent.fromQuery(
                query,
                today: CairoTime.today(),
              ),
            );
            unawaited(cubit.load());
            return cubit;
          },
          child: PropertyScreen(
            propertyId: id,
            // `extra` comes from the results card's push; never assume the
            // caller's type (a deep link has no extra at all).
            heroVariants: state.extra is List<ImageVariant>
                ? state.extra! as List<ImageVariant>
                : null,
          ),
        );
      },
      routes: [
        GoRoute(
          path: 'gallery',
          name: 'property-gallery',
          builder: (context, state) => GalleryScreen(
            propertyId: state.pathParameters['id']!,
            initialIndex:
                int.tryParse(state.uri.queryParameters['index'] ?? '') ?? 0,
            // The details header pushes the images along; a direct link has
            // no extra and the screen falls back to loading them.
            images: state.extra is List<ListingImage>
                ? state.extra! as List<ListingImage>
                : null,
          ),
        ),
        GoRoute(
          path: 'reviews',
          name: 'property-reviews',
          builder: (context, state) =>
              ReviewsScreen(propertyId: state.pathParameters['id']!),
        ),
      ],
    ),
    ShellRoute(
      navigatorKey: _bookingNavigatorKey,
      builder: (context, state, child) {
        final propertyId = state.pathParameters['propertyId']!;
        final query = state.uri.queryParameters;
        return BlocProvider<BookingFlowCubit>(
          key: ValueKey(propertyId),
          create: (context) {
            final cubit = BookingFlowCubit(
              listings: context.read<ListingsRepository>(),
              flow: context.read<BookingFlowRepository>(),
              connectivity: context.read<ConnectivityCubit>(),
              propertyId: propertyId,
              termsHash: query['terms'] ?? '',
              initialStay: StayRange.tryCreate(
                DateOnly.tryParse(query['checkIn']),
                DateOnly.tryParse(query['checkOut']),
                CairoTime.today(),
              ),
              initialGuests: _boundedGuests(query['guests']),
            );
            unawaited(cubit.load());
            return cubit;
          },
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.bookingEntryPattern,
          name: 'booking-dates',
          builder: (_, state) =>
              DatesScreen(propertyId: state.pathParameters['propertyId']!),
        ),
        GoRoute(
          path: AppRoutes.bookingSummaryPattern,
          name: 'booking-summary',
          builder: (_, state) =>
              SummaryScreen(propertyId: state.pathParameters['propertyId']!),
        ),
        GoRoute(
          path: AppRoutes.bookingVerifyPattern,
          name: 'booking-verify',
          builder: (context, state) => BlocProvider<VerifyIdentityCubit>(
            create: (context) {
              final cubit = VerifyIdentityCubit(
                flow: context.read<BookingFlowRepository>(),
                auth: context.read<AuthRepository>(),
              );
              unawaited(cubit.start());
              return cubit;
            },
            child: const VerifyIdentityScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.supportNew,
      name: 'support-new',
      builder: (_, state) {
        final booking = state.uri.queryParameters['booking'];
        return SupportEntryPlaceholderScreen(
          propertyId: state.uri.queryParameters['property'],
          bookingId: AppRoutes.isUuidV4(booking ?? '') ? booking : null,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.bookingDetailsPattern,
      name: 'booking-details',
      builder: (context, state) {
        final bookingId = state.pathParameters['id']!;
        return BlocProvider<BookingDetailsCubit>(
          create: (context) {
            final cubit = BookingDetailsCubit(
              bookings: context.read<BookingsRepository>(),
              cache: context.read<BookingsCache>(),
              arrival: context.read<ArrivalInstructionsStore>(),
              signals: context.read<NotificationSignalSource>(),
              connectivity: context.read<ConnectivityCubit>(),
              bookingId: bookingId,
            );
            unawaited(cubit.load());
            return cubit;
          },
          child: BookingDetailsScreen(bookingId: bookingId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.remainingPaymentPattern,
      name: 'linked-remaining-payment',
      builder: (_, _) => const NotAvailableScreen(),
    ),
    GoRoute(
      path: AppRoutes.damageClaimPattern,
      name: 'linked-damage-claim',
      builder: (_, _) => const NotAvailableScreen(),
    ),
    GoRoute(
      path: AppRoutes.bookingReviewPattern,
      name: 'linked-booking-review',
      builder: (_, _) => const NotAvailableScreen(),
    ),
    GoRoute(
      path: AppRoutes.supportCasePattern,
      name: 'linked-support-case',
      builder: (_, _) => const NotAvailableScreen(),
    ),
    GoRoute(
      path: AppRoutes.paymentReturnPath,
      name: 'payment-return',
      builder: (_, state) => PaymentReturnScreen(
        bookingIdFromLink: state.uri.queryParameters['booking'],
      ),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      name: 'notifications',
      builder: (context, state) => BlocProvider<NotificationsCubit>(
        create: (context) {
          final cubit = NotificationsCubit(
            notifications: context.read<NotificationsRepository>(),
            signals: context.read<NotificationSignalSource>(),
            connectivity: context.read<ConnectivityCubit>(),
            unread: context.read<UnreadCountCubit>(),
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: const NotificationsScreen(),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, _, shell) => BlocProvider<SearchCubit>.value(
        value: searchCubit,
        child: AppShell(navigationShell: shell),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (context, _) => BlocProvider<HomeCubit>(
                create: (context) {
                  final cubit = HomeCubit(
                    repo: context.read<ListingsRepository>(),
                    cache: context.read<HomeFeedCache>(),
                    reference: context.read<ReferenceDataCache>(),
                    connectivity: context.read<ConnectivityCubit>(),
                    auth: context.read<AuthCubit>(),
                  );
                  unawaited(cubit.start());
                  return cubit;
                },
                child: const HomeScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.search,
              name: 'search',
              builder: (_, _) => const SearchScreen(),
              routes: [
                GoRoute(
                  path: 'results',
                  name: 'search-results',
                  builder: (_, state) =>
                      _ResultsQueryOpener(query: state.uri.queryParameters),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.bookings,
              name: 'bookings',
              builder: (context, state) {
                final tab = _tabFrom(state.uri.queryParameters['tab']);
                return BlocProvider<BookingsCubit>(
                  create: (context) {
                    final cubit = BookingsCubit(
                      bookings: context.read<BookingsRepository>(),
                      cache: context.read<BookingsCache>(),
                      connectivity: context.read<ConnectivityCubit>(),
                    );
                    unawaited(cubit.start(tab));
                    return cubit;
                  },
                  child: BookingsScreen(initialTab: tab),
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.favorites,
              name: 'favorites',
              builder: (_, _) => const FavoritesPlaceholderScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.account,
              name: 'account',
              builder: (_, _) => const AccountPlaceholderScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Opens the results query for every new location. Repeat queries are
/// deduplicated inside `SearchCubit.openFromQuery` itself (research R9).
final class _ResultsQueryOpener extends StatefulWidget {
  const _ResultsQueryOpener({required this.query});

  final Map<String, String> query;

  @override
  State<_ResultsQueryOpener> createState() => _ResultsQueryOpenerState();
}

final class _ResultsQueryOpenerState extends State<_ResultsQueryOpener> {
  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(_ResultsQueryOpener oldWidget) {
    super.didUpdateWidget(oldWidget);
    _open();
  }

  void _open() {
    unawaited(context.read<SearchCubit>().openFromQuery(widget.query));
  }

  @override
  Widget build(BuildContext context) => const ResultsScreen();
}
