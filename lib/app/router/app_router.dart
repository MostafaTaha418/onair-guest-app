import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/app/shell/app_shell.dart';
import 'package:on_air/app/splash/splash_screen.dart';
import 'package:on_air/features/account/presentation/account_placeholder_screen.dart';
import 'package:on_air/features/app_update/presentation/not_available_screen.dart';
import 'package:on_air/features/app_update/presentation/update_required_screen.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/complete_profile_screen.dart';
import 'package:on_air/features/auth/presentation/forgot_password_screen.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';
import 'package:on_air/features/auth/presentation/new_password_screen.dart';
import 'package:on_air/features/auth/presentation/otp_screen.dart';
import 'package:on_air/features/auth/presentation/register_screen.dart';
import 'package:on_air/features/booking/presentation/booking_entry_placeholder_screen.dart';
import 'package:on_air/features/bookings/presentation/bookings_placeholder_screen.dart';
import 'package:on_air/features/favorites/presentation/favorites_placeholder_screen.dart';
import 'package:on_air/features/home/presentation/home_placeholder_screen.dart';
import 'package:on_air/features/search/presentation/results_screen.dart';
import 'package:on_air/features/search/presentation/search_cubit.dart';
import 'package:on_air/features/search/presentation/search_screen.dart';
import 'package:on_air/features/support/presentation/support_entry_placeholder_screen.dart';

bool _defaultUpdateRequired() => false;

GoRouter createAppRouter({
  required Listenable refreshListenable,
  required AuthCubit authCubit,
  required SearchCubit searchCubit,
  bool Function() updateRequired = _defaultUpdateRequired,
  void Function()? openStore,
}) => GoRouter(
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
      name: 'linked-property',
      builder: (_, _) => const NotAvailableScreen(),
    ),
    GoRoute(
      path: AppRoutes.bookingEntryPattern,
      name: 'booking-entry',
      builder: (context, state) => BookingEntryPlaceholderScreen(
        propertyId: state.pathParameters['propertyId']!,
        query: state.uri.queryParameters,
      ),
    ),
    GoRoute(
      path: AppRoutes.supportNew,
      name: 'support-new',
      builder: (_, state) => SupportEntryPlaceholderScreen(
        propertyId: state.uri.queryParameters['property'],
      ),
    ),
    GoRoute(
      path: AppRoutes.bookingDetailsPattern,
      name: 'linked-booking',
      builder: (_, _) => const NotAvailableScreen(),
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
      path: AppRoutes.paymentReturn,
      name: 'linked-payment-return',
      builder: (_, _) => const NotAvailableScreen(),
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
              builder: (_, _) => const HomePlaceholderScreen(),
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
              builder: (_, _) => const BookingsPlaceholderScreen(),
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

/// Opens the results query once per new location, so re-entering the route
/// with the same query never searches twice (research R9).
final class _ResultsQueryOpener extends StatefulWidget {
  const _ResultsQueryOpener({required this.query});

  final Map<String, String> query;

  @override
  State<_ResultsQueryOpener> createState() => _ResultsQueryOpenerState();
}

final class _ResultsQueryOpenerState extends State<_ResultsQueryOpener> {
  String? _openedQuery;

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
    final canonical = Uri(
      queryParameters: widget.query.isEmpty ? null : widget.query,
    ).query;
    if (canonical == _openedQuery) return;
    _openedQuery = canonical;
    unawaited(context.read<SearchCubit>().openFromQuery(widget.query));
  }

  @override
  Widget build(BuildContext context) => const ResultsScreen();
}
