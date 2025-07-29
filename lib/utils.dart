String maskAccountNumber(String accountNumber) {
  if (accountNumber.length <= 4) return accountNumber;
  final last4 = accountNumber.substring(accountNumber.length - 4);
  return '*' * (accountNumber.length - 4) + last4;
}


String formatAmount(double amount) {
  if (amount >= 1000000) {
    double value = amount / 1000000;
    return 'MWK ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}M';
  } else if (amount >= 1000) {
    double value = amount / 1000;
    return 'MWK ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}K';
  } else {
    return 'MWK ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }
}
