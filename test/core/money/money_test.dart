import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/money/money.dart';

void main() {
  test('stores integer piasters and compares by value', () {
    expect(Money(1250), Money(1250));
    expect(Money(1250).amountMinor, 1250);
    expect(Money(1250).currency, 'EGP');
  });

  test('rejects unsupported currency and mixed-currency arithmetic', () {
    expect(() => Money(100, currency: 'USD'), throwsArgumentError);
    expect(() => Money(100) + Money(20, currency: 'USD'), throwsArgumentError);
  });

  test('arithmetic preserves piasters without floating point', () {
    expect(Money(100) + Money(25), Money(125));
    expect(Money(100) - Money(125), Money(-25));
  });

  test('formatter uses Western digits', () {
    expect(MoneyFormatter().format(Money(123450)), contains('1,234.50'));
  });
}
