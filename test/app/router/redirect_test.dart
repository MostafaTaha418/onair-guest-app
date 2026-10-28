import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

void main() {
  final incomplete = GuestAccount(id: 'id', phone: '+201012345678');
  final complete = GuestAccount(
    id: 'id',
    phone: '+201012345678',
    fullName: 'Guest Name',
    acceptedTermsVersion: 'v1',
  );

  test('incomplete signed-in account is forced to profile completion', () {
    expect(
      resolveRedirect(
        RedirectContext(
          location: AppRoutes.bookings,
          authState: SignedIn(incomplete, isComplete: false),
        ),
      ),
      '/auth/complete-profile?from=%2Fbookings',
    );
  });

  test('complete signed-in account is not redirected from app routes', () {
    expect(
      resolveRedirect(
        RedirectContext(
          location: AppRoutes.bookings,
          authState: SignedIn(complete, isComplete: true),
        ),
      ),
      isNull,
    );
  });

  test('members-only route sends a visitor to login with a safe return', () {
    expect(
      resolveRedirect(
        const RedirectContext(
          location: AppRoutes.bookings,
          authState: SignedOut(),
        ),
      ),
      '/auth/login?from=%2Fbookings',
    );
  });

  test('signed-in auth route accepts only registered relative from paths', () {
    for (final unsafe in [
      'https://evil.example/bookings',
      '//evil.example/bookings',
      '/unknown',
      AppRoutes.login,
    ]) {
      expect(
        resolveRedirect(
          RedirectContext(
            location: AppRoutes.login,
            authState: SignedIn(complete, isComplete: true),
            from: unsafe,
          ),
        ),
        AppRoutes.home,
      );
    }
    expect(
      resolveRedirect(
        RedirectContext(
          location: AppRoutes.login,
          authState: SignedIn(complete, isComplete: true),
          from: AppRoutes.bookings,
        ),
      ),
      AppRoutes.bookings,
    );
  });

  test('sign-in cancel returns to a safe public origin as a visitor', () {
    expect(resolveAuthCancelDestination(AppRoutes.search), AppRoutes.search);
    expect(resolveAuthCancelDestination(AppRoutes.bookings), AppRoutes.home);
    expect(
      resolveAuthCancelDestination('https://evil.example'),
      AppRoutes.home,
    );
  });

  test('an active version gate sends every route to update-required', () {
    final contexts = [
      (
        AppRoutes.splash,
        const AuthUnknown(),
      ),
      (AppRoutes.home, const SignedOut()),
      (AppRoutes.bookings, const SignedOut()),
      (AppRoutes.login, const SignedOut()),
      (AppRoutes.home, SignedIn(complete, isComplete: true)),
      (AppRoutes.completeProfile, SignedIn(incomplete, isComplete: false)),
    ];
    for (final (location, authState) in contexts) {
      expect(
        resolveRedirect(
          RedirectContext(
            location: location,
            authState: authState,
            updateRequired: true,
          ),
        ),
        AppRoutes.updateRequired,
        reason: '$location must be blocked by the version gate',
      );
    }
  });

  test('update-required route stays put while the gate is active', () {
    expect(
      resolveRedirect(
        const RedirectContext(
          location: AppRoutes.updateRequired,
          authState: SignedOut(),
          updateRequired: true,
        ),
      ),
      isNull,
    );
  });

  test('a failed config fetch keeps the gate off, so nothing redirects', () {
    // updateRequired defaults to false when the gate could not reach the
    // server: the app must continue normally and check again next time.
    expect(
      resolveRedirect(
        const RedirectContext(location: AppRoutes.home, authState: SignedOut()),
      ),
      isNull,
    );
    expect(
      resolveRedirect(
        RedirectContext(
          location: AppRoutes.home,
          authState: SignedIn(complete, isComplete: true),
        ),
      ),
      isNull,
    );
  });

  test('a lifted gate returns a stale update screen to home', () {
    expect(
      resolveRedirect(
        RedirectContext(
          location: AppRoutes.updateRequired,
          authState: SignedIn(complete, isComplete: true),
        ),
      ),
      AppRoutes.home,
    );
  });
}
