import 'package:intl/intl.dart';

String _currencyCode = 'INR';

void setCurrencyCode(String currencyCode) {
  _currencyCode = currencyCode;
}

String get currencySymbol => switch (_currencyCode) {
  'USD' => r'$',
  'EUR' => '€',
  'GBP' => '£',
  _ => '₹',
};

String formatInr(double amount) {
  final locale = switch (_currencyCode) {
    'USD' => 'en_US',
    'EUR' => 'de_DE',
    'GBP' => 'en_GB',
    _ => 'en_IN',
  };
  return NumberFormat.currency(
    locale: locale,
    name: _currencyCode,
    symbol: currencySymbol,
    decimalDigits: _currencyCode == 'INR' ? 0 : 2,
  ).format(amount);
}
