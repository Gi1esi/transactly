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

DateTime addPeriodToDate(DateTime date, String period) {
  if (period == 'weekly') {
    return date.add(const Duration(days: 6));
  } else if (period == 'monthly') {
    // Add exactly 1 month
    try {
      return DateTime(date.year, date.month + 1, date.day);
    } catch (e) {
      // If the day doesn't exist in next month (e.g., Jan 31 → Feb 31)
      // Use last day of next month instead
      return DateTime(date.year, date.month + 2, 0);
    }
  } else if (period == 'yearly') {
    // Add exactly 1 year
    try {
      return DateTime(date.year + 1, date.month, date.day);
    } catch (e) {
      // Handle February 29th in non-leap years
      return DateTime(date.year + 1, date.month + 1, 0);
    }
  }
  return date;
}
