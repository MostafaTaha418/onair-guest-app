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
}
