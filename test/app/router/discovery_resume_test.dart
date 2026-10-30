import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

void main() {
  const uuid = '550e8400-e29b-41d4-a716-446655440000';
  final account = GuestAccount(
    id: 'guest',
    phone: '+201012345678',
    phoneVerified: true,
    fullName: 'زائر',
    acceptedTermsVersion: 'v1',
    acceptedTermsAt: DateTime.utc(2026),
  );

  test('a property location carrying a resume is a safe return target', () {
    final from = Uri(
      path: '/property/$uuid',
      queryParameters: {
        'checkIn': '2026-11-20',
        'checkOut': '2026-11-23',
        'guests': '2',
        'resume': 'book',
        'terms': 't1',
      },
    ).toString();

    final redirect = resolveRedirect(
      RedirectContext(
        location: AppRoutes.login,
        authState: SignedIn(account, isComplete: true),
        from: from,
      ),
    );

    expect(
      redirect,
      from,
      reason:
          'the full query — resume and terms included — must survive sign-in',
    );
  });

  test('a signed-out cancel returns the same property location, not home', () {
    final origin = Uri(
      path: '/property/$uuid',
      queryParameters: {
        'checkIn': '2026-11-20',
        'checkOut': '2026-11-23',
        'guests': '2',
      },
    ).toString();

    expect(resolveAuthCancelDestination(origin), origin);
  });

  test('the booking entry still requires an account while signed out', () {
    const bookingEntry = '/book/$uuid/dates';

    final redirect = resolveRedirect(
      const RedirectContext(location: bookingEntry, authState: SignedOut()),
    );

    expect(redirect, startsWith('${AppRoutes.login}?'));
    expect(redirect, contains(Uri.encodeComponent(bookingEntry)));
  });
}
