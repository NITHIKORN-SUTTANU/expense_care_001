import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount, String currencyCode) {
    try {
      return NumberFormat.currency(name: currencyCode, decimalDigits: 2)
          .format(amount);
    } catch (_) {
      return '$currencyCode ${amount.toStringAsFixed(2)}';
    }
  }

  static String formatCompact(double amount, String currencyCode) {
    try {
      return NumberFormat.compactCurrency(name: currencyCode, decimalDigits: 1)
          .format(amount);
    } catch (_) {
      return '$currencyCode ${amount.toStringAsFixed(1)}';
    }
  }

  static String symbol(String currencyCode) {
    try {
      return NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
    } catch (_) {
      return currencyCode;
    }
  }

  // Quick helper — no Intl lookup needed for common currencies
  static String formatSimple(double amount, String currencyCode) {
    final sym = _simpleSymbols[currencyCode] ?? currencyCode;
    return '$sym${amount.toStringAsFixed(2)}';
  }

  static const _simpleSymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'THB': '฿',
    'SGD': 'S\$',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'CNY': '¥',
    'KRW': '₩',
    'INR': '₹',
    'BTC': '₿',
  };
}
