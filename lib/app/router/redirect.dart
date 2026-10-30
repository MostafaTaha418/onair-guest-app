import 'package:on_air/app/router/routes.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';

final class RedirectContext {
  const RedirectContext({
    required this.location,
    required this.authState,
    this.from,
    this.updateRequired = false,
  });

  final String location;
  final AuthState authState;
  final String? from;

  /// Server-confirmed version gate: the installed build is below the minimum
  /// supported build for the platform. A failed config check never sets this.
  final bool updateRequired;
}

String? resolveRedirect(RedirectContext context) {
  final path = Uri.tryParse(context.location)?.path ?? context.location;
  // The version gate outranks every other rule: an unsupported build cannot
  // reach any screen, including splash and auth.
  if (context.updateRequired) {
    return path == AppRoutes.updateRequired ? null : AppRoutes.updateRequired;
  }
  if (path == AppRoutes.updateRequired) {
    // The gate lifted (server is the authority); recover to a usable screen.
    return AppRoutes.home;
  }
  if (context.authState is AuthUnknown) {
    if (path == AppRoutes.splash) return null;
    final returnTo = _safeReturnLocation(context.location) ?? AppRoutes.home;
    return Uri(
      path: AppRoutes.splash,
      queryParameters: {'from': returnTo},
    ).toString();
  }
  if (path == AppRoutes.splash) {
    return _safeReturnLocation(context.from) ?? AppRoutes.home;
  }
  final state = context.authState;
  if (state is SessionEnded) {
    final returnTo =
        _safeReturnLocation(state.returnTo) ??
        _safeReturnLocation(context.location) ??
        AppRoutes.home;
    return _loginFor(returnTo);
  }
  if (state is CodeSent || state is RateLimited) {
    if (path == AppRoutes.otp) return null;
    // The refresh pass can evaluate an app route rather than the pushed
    // login screen; never hijack those — the login screen carries `from`
    // to the code screen itself (SC-007, research R10).
    if (!AppRoutes.isAuthLocation(context.location)) return null;
    // When the pass does see the login screen, carry the safe return
    // target along so the `from` chain survives into the code screen.
    final returnTo = _safeReturnLocation(context.from);
    return Uri(
      path: AppRoutes.otp,
      queryParameters: returnTo == null ? null : {'from': returnTo},
    ).toString();
  }
  if (state is RecoveryVerified) {
    return path == AppRoutes.newPassword ? null : AppRoutes.newPassword;
  }
  if (state is SignedOut && AppRoutes.requiresAccount(context.location)) {
    return _loginFor(context.location);
  }
  if (state is SignedOut &&
      (path == AppRoutes.otp ||
          path == AppRoutes.completeProfile ||
          path == AppRoutes.newPassword)) {
    return AppRoutes.login;
  }
  if (state is SignedIn && !state.isComplete) {
    if (path == AppRoutes.completeProfile) return null;
    final returnTo = AppRoutes.isAuthLocation(context.location)
        ? (_safeReturnLocation(context.from) ?? AppRoutes.home)
        : (_safeReturnLocation(context.location) ?? AppRoutes.home);
    return Uri(
      path: AppRoutes.completeProfile,
      queryParameters: {'from': returnTo},
    ).toString();
  }
  if (state is SignedIn &&
      state.isComplete &&
      AppRoutes.isAuthLocation(context.location)) {
    return _safeReturnLocation(context.from) ?? AppRoutes.home;
  }
  return null;
}

/// Where a *cancelled* sign-in should land. Account-gated routes are useless
/// without a session, so they fall back to Home.
String resolveAuthCancelDestination(String? origin) {
  final safe = _safeReturnLocation(origin);
  if (safe == null ||
      AppRoutes.requiresAccount(safe) ||
      AppRoutes.isAuthLocation(safe)) {
    return AppRoutes.home;
  }
  return safe;
}

/// Where a *completed* sign-in should land. Unlike the cancel destination,
/// account-gated routes are exactly why the guest signed in, so they are
/// kept (SC-007): only auth screens themselves and unknown locations fall
/// back to Home.
String resolveAuthReturnDestination(String? origin) {
  final safe = _safeReturnLocation(origin);
  if (safe == null || AppRoutes.isAuthLocation(safe)) {
    return AppRoutes.home;
  }
  return safe;
}

String _loginFor(String location) => Uri(
  path: AppRoutes.login,
  queryParameters: {'from': _safeReturnLocation(location) ?? AppRoutes.home},
).toString();

String? _safeReturnLocation(String? location) {
  if (!AppRoutes.isRegisteredLocation(location)) return null;
  if (AppRoutes.isAuthLocation(location!)) return null;
  if (Uri.parse(location).path == AppRoutes.splash) return null;
  return location;
}
