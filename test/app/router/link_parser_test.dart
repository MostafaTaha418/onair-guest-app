import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/router/link_parser.dart';
import 'package:on_air/app/router/routes.dart';

void main() {
  const propertyId = '550e8400-e29b-41d4-a716-446655440000';
  const bookingId = '123e4567-e89b-42d3-a456-426614174000';

  const parser = LinkParser('on-air.website');

  test('accepts only HTTPS links on the configured domain', () {
    expect(
      parser.parse(
        Uri.parse('https://on-air.website/property/$propertyId'),
        isSignedIn: false,
      ),
      '/property/$propertyId',
    );
    for (final link in [
      'https://evil.example/property/$propertyId',
      'http://on-air.website/property/$propertyId',
      'onair://on-air.website/property/$propertyId',
    ]) {
      expect(
        parser.parse(Uri.parse(link), isSignedIn: false),
        AppRoutes.notAvailable,
      );
    }
  });

  test('requires UUID v4 path identifiers', () {
    for (final id in [
      'not-a-uuid',
      '550e8400-e29b-11d4-a716-446655440000',
      '550e8400-e29b-41d4-7716-446655440000',
    ]) {
      expect(
        parser.parse(
          Uri.parse('https://on-air.website/bookings/$id'),
          isSignedIn: true,
        ),
        AppRoutes.notAvailable,
      );
    }
  });

  test('ignores query parameters and rejects unknown paths', () {
    expect(
      parser.parse(
        Uri.parse(
          'https://on-air.website/property/$propertyId?status=paid&intent=x',
        ),
        isSignedIn: false,
      ),
      '/property/$propertyId',
    );
    expect(
      parser.parse(
        Uri.parse('https://on-air.website/admin?role=owner'),
        isSignedIn: true,
      ),
      AppRoutes.notAvailable,
    );
  });

  test('members-only link signs in first then returns to the link', () {
    final link = Uri.parse('https://on-air.website/bookings/$bookingId');
    expect(
      parser.parse(link, isSignedIn: false),
      '/auth/login?from=%2Fbookings%2F$bookingId',
    );
    expect(
      parser.parse(link, isSignedIn: true),
      '/bookings/$bookingId',
    );
  });
}
