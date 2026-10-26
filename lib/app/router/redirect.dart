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
  return null;
}
