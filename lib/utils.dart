String maskAccountNumber(String accountNumber) {
  if (accountNumber.length <= 4) return accountNumber;
  final last4 = accountNumber.substring(accountNumber.length - 4);
  return '*' * (accountNumber.length - 4) + last4;
}
