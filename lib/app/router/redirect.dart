import 'package:on_air/app/router/routes.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';

final class RedirectContext {
  const RedirectContext({
    required this.location,
    required this.authState,
    this.from,
  });
  final String location;
  final AuthState authState;
  final String? from;
}

String? resolveRedirect(RedirectContext context) {
  if (context.authState is AuthUnknown) {
    if (context.location == AppRoutes.splash) return null;
    return Uri(
      path: AppRoutes.splash,
      queryParameters: {'from': context.location},
    ).toString();
  }
  if (context.location == AppRoutes.splash) {
    const visitorRoutes = {
      AppRoutes.home,
      AppRoutes.search,
      AppRoutes.bookings,
      AppRoutes.favorites,
      AppRoutes.account,
    };
    return visitorRoutes.contains(context.from) ? context.from : AppRoutes.home;
  }
  final state = context.authState;
  if (state is SessionEnded) {
    final returnTo = state.returnTo ?? context.location;
    return Uri(
      path: AppRoutes.login,
      queryParameters: {'from': returnTo},
    ).toString();
  }
  if (state is CodeSent || state is RateLimited) {
    return context.location == AppRoutes.otp ? null : AppRoutes.otp;
  }
  if (state is RecoveryVerified) {
    return context.location == AppRoutes.newPassword
        ? null
        : AppRoutes.newPassword;
  }
  if (state is SignedOut &&
      (context.location == AppRoutes.otp ||
          context.location == AppRoutes.completeProfile ||
          context.location == AppRoutes.newPassword)) {
    return AppRoutes.login;
  }
  if (state is SignedIn && !state.isComplete) {
    if (context.location == AppRoutes.completeProfile) return null;
    final returnTo = _isAuthRoute(context.location)
        ? (context.from ?? AppRoutes.home)
        : context.location;
    return Uri(
      path: AppRoutes.completeProfile,
      queryParameters: {'from': returnTo},
    ).toString();
  }
  if (state is SignedIn && state.isComplete && _isAuthRoute(context.location)) {
    final from = context.from;
    return from != null && !_isAuthRoute(from) ? from : AppRoutes.home;
  }
  return null;
}

bool _isAuthRoute(String location) =>
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.otp ||
    location == AppRoutes.completeProfile ||
    location == AppRoutes.forgotPassword ||
    location == AppRoutes.newPassword;
