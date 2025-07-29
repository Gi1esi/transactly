
class Account {
  int? accountId;
  String accountNumber;
  int? bankId;
  int? userId;

  Account({this.accountId, required this.accountNumber, this.bankId, this.userId});

  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'account_number': accountNumber,
      'bank': bankId,
      'user': userId,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      accountId: map['account_id'],
      accountNumber: map['account_number'],
      bankId: map['bank'],
      userId: map['user'],
    );
  }
}
