import 'package:intl/intl.dart';

String maskAccountNumber(String accountNumber) {
  if (accountNumber.length <= 4) return accountNumber;
  final last4 = accountNumber.substring(accountNumber.length - 4);
  return '*' * (accountNumber.length - 4) + last4;
}


String formatAmount(double amount) {
  final formatter = NumberFormat('#,##0');
  if (amount >= 1000000) {
    double value = amount / 1000000;
    return 'K ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}M';
  } else if (amount >= 100000) {
    double value = amount / 1000;
    return 'K ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}K';
  } else {
    return 'K ${formatter.format(amount)}';
  }
}
