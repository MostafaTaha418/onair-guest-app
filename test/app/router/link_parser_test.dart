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

  test('search-results link keeps only the whitelisted keys, sorted', () {
    expect(
      parser.parse(
        Uri.parse(
          'https://on-air.website/search/results'
          '?g=2&in=2026-11-20&out=2026-11-23&evil=1',
        ),
        isSignedIn: false,
      ),
      '/search/results?g=2&in=2026-11-20&out=2026-11-23',
    );
    // The full whitelist in a scrambled order comes back canonically sorted;
    // the unknown `evil` key is dropped.
    expect(
      parser.parse(
        Uri.parse(
          'https://on-air.website/search/results'
          '?sort=price_desc&type=villa&am=pool,ac&bath=2&bed=1'
          '&pmax=900000&pmin=100000&g=4&out=2026-11-23&in=2026-11-20'
          '&loc=$propertyId&evil=1',
        ),
        isSignedIn: false,
      ),
      '/search/results?am=pool%2Cac&bath=2&bed=1&g=4&in=2026-11-20'
      '&loc=$propertyId&out=2026-11-23&pmax=900000&pmin=100000'
      '&sort=price_desc&type=villa',
    );
  });

  test('property link strips every query parameter, including resume', () {
    expect(
      parser.parse(
        Uri.parse(
          'https://on-air.website/property/$propertyId?resume=book&terms=x',
        ),
        isSignedIn: false,
      ),
      '/property/$propertyId',
    );
  });

  test('other linkable paths still drop every query parameter', () {
    expect(
      parser.parse(
        Uri.parse('https://on-air.website/bookings/$bookingId?status=paid'),
        isSignedIn: true,
      ),
      '/bookings/$bookingId',
    );
  });

  test('user-info links are rejected', () {
    expect(
      parser.parse(
        Uri.parse('https://u@on-air.website/property/$propertyId'),
        isSignedIn: false,
      ),
      AppRoutes.notAvailable,
    );
  });
}
