import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

void main() {
  GuestAccount account({
    AccountStatus status = AccountStatus.active,
    String? phone = '+201012345678',
    String? fullName,
  }) => GuestAccount(
    id: 'id',
    status: status,
    phone: phone,
    email: 'guest@example.com',
    fullName: fullName,
  );

  group('GuestAccount.isComplete (server status)', () {
    test('is true only when the status is active', () {
      expect(account().isComplete, isTrue);
      for (final status in [
        AccountStatus.incomplete,
        AccountStatus.suspended,
        AccountStatus.deleted,
        AccountStatus.unknown,
      ]) {
        expect(account(status: status).isComplete, isFalse, reason: '$status');
      }
    });

    test('an incomplete account may have no phone', () {
      expect(
        account(status: AccountStatus.incomplete, phone: null),
        isA<GuestAccount>(),
      );
    });

    test('an active account without phone asserts in debug', () {
      expect(
        () => GuestAccount(
          id: 'id',
          status: AccountStatus.active,
          email: 'guest@example.com',
        ),
        throwsAssertionError,
      );
    });

    test('the local name/terms rule is gone', () {
      // A named account on an old terms version is still incomplete when the
      // server says so — no local computation any more (Constitution II).
      final stale = GuestAccount(
        id: 'id',
        status: AccountStatus.incomplete,
        phone: '+201012345678',
        email: 'guest@example.com',
        fullName: 'Guest Name',
        acceptedTermsVersion: 'anything',
      );
      expect(stale.isComplete, isFalse);
    });
  });

  group('validation', () {
    test('fullName must be 2–80 characters', () {
      expect(() => account(fullName: 'a'), throwsArgumentError);
      expect(() => account(fullName: 'a' * 81), throwsArgumentError);
      expect(account(fullName: 'ab').fullName, 'ab');
      expect(account(fullName: 'ab' * 40).fullName, hasLength(80));
    });

    test('phone must be an Egyptian mobile number', () {
      expect(
        () => account(phone: '+971501234567'),
        throwsArgumentError,
      );
    });
  });

  group('enums', () {
    test('AccountStatus.fromJson falls back to unknown', () {
      expect(AccountStatus.fromJson('active'), AccountStatus.active);
      expect(AccountStatus.fromJson('incomplete'), AccountStatus.incomplete);
      expect(AccountStatus.fromJson('suspended'), AccountStatus.suspended);
      expect(AccountStatus.fromJson('deleted'), AccountStatus.deleted);
      expect(
        AccountStatus.fromJson('something_new'),
        AccountStatus.unknown,
      );
      expect(AccountStatus.fromJson(null), AccountStatus.unknown);
    });

    test(
      'AuthProvider.fromJson maps the known providers and ignores others',
      () {
        expect(AuthProvider.fromJson('email'), AuthProvider.email);
        expect(AuthProvider.fromJson('google'), AuthProvider.google);
        expect(AuthProvider.fromJson('apple'), AuthProvider.apple);
        expect(AuthProvider.fromJson('something_new'), isNull);
      },
    );
  });
}
