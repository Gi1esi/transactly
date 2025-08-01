import 'bank_model.dart';
class Account {
  int? accountId;
  String accountNumber;
  int? bankId;
  int? userId;
  bool isActive;
  Bank? bank; 

  Account({
    this.accountId,
    required this.accountNumber,
    this.bankId,
    this.userId,
    this.isActive = false,
  });


  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'account_number': accountNumber,
      'bank': bankId,
      'user': userId,
      'is_active': isActive ? 1 : 0,
    };
  }


  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      accountId: map['account_id'],
      accountNumber: map['account_number'],
      bankId: map['bank'],
      userId: map['user'],
      isActive: (map['is_active'] ?? 0) == 1,
    );
  }
}
