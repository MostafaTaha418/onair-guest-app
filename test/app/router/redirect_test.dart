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

  test('discovery dynamic routes accept only UUID v4 IDs', () {
    const uuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    for (final valid in [
      AppRoutes.property(uuid),
      AppRoutes.propertyGallery(uuid),
      AppRoutes.propertyReviews(uuid),
      AppRoutes.bookingEntry(uuid),
    ]) {
      expect(AppRoutes.isRegisteredLocation(valid), isTrue, reason: valid);
    }
    for (final invalid in [
      '/property/not-a-uuid',
      '/property/not-a-uuid/gallery',
      '/property/not-a-uuid/reviews',
      '/book/not-a-uuid/dates',
      '/property/00000000-0000-1000-8000-000000000001',
    ]) {
      expect(
        AppRoutes.isRegisteredLocation(invalid),
        isFalse,
        reason: invalid,
      );
    }
  });

  test('the booking entry requires an account, the gallery does not', () {
    const uuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    expect(AppRoutes.requiresAccount(AppRoutes.bookingEntry(uuid)), isTrue);
    expect(AppRoutes.requiresAccount(AppRoutes.supportNew), isTrue);
    expect(AppRoutes.requiresAccount(AppRoutes.property(uuid)), isFalse);
    expect(AppRoutes.requiresAccount(AppRoutes.propertyGallery(uuid)), isFalse);
    expect(AppRoutes.requiresAccount(AppRoutes.propertyReviews(uuid)), isFalse);
    expect(AppRoutes.requiresAccount(AppRoutes.searchResults), isFalse);
  });

  test('a visitor on the booking entry is sent to login with a return', () {
    const uuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    expect(
      resolveRedirect(
        RedirectContext(
          location: AppRoutes.bookingEntry(uuid),
          authState: const SignedOut(),
        ),
      ),
      '/auth/login?from=%2Fbook%2F${Uri.encodeComponent(uuid)}%2Fdates',
    );
  });

  test('the route builders build the documented paths', () {
    const uuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    expect(AppRoutes.property(uuid), '/property/$uuid');
    expect(AppRoutes.propertyGallery(uuid), '/property/$uuid/gallery');
    expect(AppRoutes.propertyReviews(uuid), '/property/$uuid/reviews');
    expect(AppRoutes.bookingEntry(uuid), '/book/$uuid/dates');
  });
}
