import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';

void main() {
  group('EgyptPhone', () {
    test('normalizes local and E.164 Egyptian numbers', () {
      expect(EgyptPhone.parse('01012345678').e164, '+201012345678');
      expect(EgyptPhone.parse('+20 10 1234 5678').e164, '+201012345678');
    });

    test('accepts only Egyptian mobile prefixes', () {
      for (final prefix in ['010', '011', '012', '015']) {
        expect(EgyptPhone.tryParse('${prefix}12345678'), isNotNull);
      }
    });

    test('rejects other countries, prefixes, and lengths', () {
      for (final value in [
        '+971501234567',
        '01312345678',
        '0101234567',
        '010123456789',
        '',
      ]) {
        expect(EgyptPhone.tryParse(value), isNull, reason: value);
      }
    });
  });

  group('maskPhone', () {
    test('renders the server masked_target style', () {
      expect(maskPhone('+201012345678'), '+20 10•• ••• 678');
      expect(maskPhone('+201098765432'), '+20 10•• ••• 432');
      expect(maskPhone('+201155544400'), '+20 11•• ••• 400');
    });

    test('keeps a too-short number unchanged', () {
      expect(maskPhone('+20100'), '+20100');
    });
  });
}
