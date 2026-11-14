import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

void main() {
  final incomplete = GuestAccount(
    id: 'id',
    status: AccountStatus.incomplete,
    email: 'guest@example.com',
  );
  final complete = GuestAccount(
    id: 'id',
    status: AccountStatus.active,
    phone: '+201012345678',
    fullName: 'Guest Name',
    acceptedTermsVersion: 'v1',
  );
  final suspended = GuestAccount(
    id: 'id',
    status: AccountStatus.suspended,
    phone: '+201012345678',
    email: 'guest@example.com',
    fullName: 'Guest Name',
    acceptedTermsVersion: 'v1',
  );
  final unknown = GuestAccount(
    id: 'id',
    status: AccountStatus.unknown,
    phone: '+201012345678',
    email: 'guest@example.com',
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

  test('a suspended account never sees «أكّد رقمك»; account routes show the '
      'suspended screen', () {
    // Account-gated route: the notice, not the phone step.
    expect(
      resolveRedirect(
        RedirectContext(
          location: AppRoutes.bookings,
          authState: SignedIn(suspended, isComplete: false),
        ),
      ),
      AppRoutes.accountSuspended,
    );
    expect(
      resolveRedirect(
        RedirectContext(
          location: AppRoutes.accountSuspended,
          authState: SignedIn(suspended, isComplete: false),
        ),
      ),
      isNull,
    );
    // Public routes stay usable; the session survives.
    expect(
      resolveRedirect(
        RedirectContext(
          location: AppRoutes.home,
          authState: SignedIn(suspended, isComplete: false),
        ),
      ),
      isNull,
    );
  });

  test('a suspended account that lands on «أكّد رقمك» or an auth screen goes '
      'to the suspended screen', () {
    for (final location in [
      '${AppRoutes.completeProfile}?from=%2Fhome',
      AppRoutes.accountPhone,
      AppRoutes.login,
      AppRoutes.otp,
    ]) {
      expect(
        resolveRedirect(
          RedirectContext(
            location: location,
            authState: SignedIn(suspended, isComplete: false),
          ),
        ),
        AppRoutes.accountSuspended,
        reason: location,
      );
    }
  });

  test('a visitor on the suspended screen goes home', () {
    expect(
      resolveRedirect(
        const RedirectContext(
          location: AppRoutes.accountSuspended,
          authState: SignedOut(),
        ),
      ),
      AppRoutes.home,
    );
  });

  test('an unknown status routes like active: no phone-step redirect', () {
    expect(
      resolveRedirect(
        RedirectContext(
          location: AppRoutes.bookings,
          authState: SignedIn(unknown, isComplete: false),
        ),
      ),
      isNull,
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

  group('resolveAuthReturnDestination', () {
    const uuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

    test('keeps the account-gated route the guest signed in for', () {
      expect(
        resolveAuthReturnDestination('/bookings/$uuid'),
        '/bookings/$uuid',
      );
      expect(
        resolveAuthReturnDestination('/book/$uuid/dates'),
        '/book/$uuid/dates',
      );
      expect(
        resolveAuthReturnDestination(AppRoutes.supportNew),
        AppRoutes.supportNew,
      );
    });

    test(
      'falls back to home for auth screens, external links, and unknowns',
      () {
        expect(resolveAuthReturnDestination(AppRoutes.login), AppRoutes.home);
        expect(
          resolveAuthReturnDestination('https://evil.example/bookings'),
          AppRoutes.home,
        );
        expect(resolveAuthReturnDestination(null), AppRoutes.home);
        expect(resolveAuthReturnDestination('/unknown'), AppRoutes.home);
        expect(resolveAuthReturnDestination(AppRoutes.splash), AppRoutes.home);
      },
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

  group('S005: a server-incomplete account is forced to «أكّد رقمك»', () {
    const uuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

    test('every account-gated route and deep link carries its return', () {
      final destinations = <String, String>{
        AppRoutes.favorites: AppRoutes.favorites,
        AppRoutes.bookings: AppRoutes.bookings,
        AppRoutes.account: AppRoutes.account,
        AppRoutes.accountPhone: AppRoutes.accountPhone,
        AppRoutes.notifications: AppRoutes.notifications,
        AppRoutes.bookingDetails(uuid): AppRoutes.bookingDetails(uuid),
        '${AppRoutes.bookingEntry(uuid)}?guests=2':
            '${AppRoutes.bookingEntry(uuid)}?guests=2',
      };
      for (final MapEntry(key: location, value: from) in destinations.entries) {
        expect(
          resolveRedirect(
            RedirectContext(
              location: location,
              authState: SignedIn(incomplete, isComplete: false),
            ),
          ),
          '/auth/complete-profile?from=${Uri.encodeComponent(from)}',
          reason: location,
        );
      }
    });

    test('the same rule also catches public routes (existing behaviour)', () {
      for (final location in [
        AppRoutes.home,
        AppRoutes.search,
        AppRoutes.property(uuid),
      ]) {
        expect(
          resolveRedirect(
            RedirectContext(
              location: location,
              authState: SignedIn(incomplete, isComplete: false),
            ),
          ),
          '/auth/complete-profile?from=${Uri.encodeComponent(location)}',
          reason: location,
        );
      }
    });

    test('an active account returns from the completion route to `from`', () {
      expect(
        resolveRedirect(
          RedirectContext(
            location:
                '${AppRoutes.completeProfile}?from=${AppRoutes.favorites}',
            authState: SignedIn(complete, isComplete: true),
            from: AppRoutes.favorites,
          ),
        ),
        AppRoutes.favorites,
      );
    });
  });

  test('the route builders build the documented paths', () {
    const uuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    expect(AppRoutes.property(uuid), '/property/$uuid');
    expect(AppRoutes.propertyGallery(uuid), '/property/$uuid/gallery');
    expect(AppRoutes.propertyReviews(uuid), '/property/$uuid/reviews');
    expect(AppRoutes.bookingEntry(uuid), '/book/$uuid/dates');
  });
}
