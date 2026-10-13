import 'package:intl/intl.dart';

final NumberFormat inrFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String formatInr(double amount) => inrFormat.format(amount);
