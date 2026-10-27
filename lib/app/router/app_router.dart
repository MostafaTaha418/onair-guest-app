import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/app/shell/app_shell.dart';
import 'package:on_air/app/splash/splash_screen.dart';
import 'package:on_air/features/account/presentation/account_placeholder_screen.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/complete_profile_screen.dart';
import 'package:on_air/features/auth/presentation/forgot_password_screen.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';
import 'package:on_air/features/auth/presentation/new_password_screen.dart';
import 'package:on_air/features/auth/presentation/otp_screen.dart';
import 'package:on_air/features/auth/presentation/register_screen.dart';
import 'package:on_air/features/bookings/presentation/bookings_placeholder_screen.dart';
import 'package:on_air/features/favorites/presentation/favorites_placeholder_screen.dart';
import 'package:on_air/features/home/presentation/home_placeholder_screen.dart';
import 'package:on_air/features/search/presentation/search_placeholder_screen.dart';

GoRouter createAppRouter({
  required Listenable refreshListenable,
  required AuthCubit authCubit,
}) => GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: refreshListenable,
  redirect: (_, state) => resolveRedirect(
    RedirectContext(
      location: state.uri.path,
      authState: authCubit.state,
      from: state.uri.queryParameters['from'],
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
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
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
              builder: (_, _) => const SearchPlaceholderScreen(),
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
