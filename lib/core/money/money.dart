import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// An amount in piasters. No floating-point value enters the money model.
@immutable
final class Money {
  Money(this.amountMinor, {this.currency = 'EGP'}) {
    if (currency != 'EGP') {
      throw ArgumentError.value(currency, 'currency', 'Only EGP is supported');
    }
  }

  final int amountMinor;
  final String currency;

  Money operator +(Money other) {
    _checkCurrency(other);
    return Money(amountMinor + other.amountMinor);
  }

  Money operator -(Money other) {
    _checkCurrency(other);
    return Money(amountMinor - other.amountMinor);
  }

  void _checkCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError.value(other.currency, 'other.currency');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amountMinor == amountMinor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amountMinor, currency);
}

final class MoneyFormatter {
  MoneyFormatter() : _format = NumberFormat.decimalPattern('en_US');

  final NumberFormat _format;

  String format(Money money) {
    final absolute = money.amountMinor.abs();
    final whole = _format.format(absolute ~/ 100);
    final piasters = (absolute % 100).toString().padLeft(2, '0');
    final sign = money.amountMinor < 0 ? '-' : '';
    return 'EGP $sign$whole.$piasters';
  }
}
