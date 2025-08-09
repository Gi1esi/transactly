class Transaction {
  final int? id;
  final String transId;
  String description;
  final double amount;
  final String date; // ISO: YYYY-MM-DD
  final String effect; // 'cr' or 'dr'
  int? category;
  final int? account;
  String? categoryName; // joined name
  final int? parentTransactionId; // NEW
  final bool isSplitChild; // NEW

  Transaction({
    this.id,
    required this.transId,
    required this.description,
    required this.amount,
    required this.date,
    required this.effect,
    this.category,
    this.account,
    this.categoryName,
    this.parentTransactionId,
    this.isSplitChild = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': id,
      'trans_id': transId,
      'description': description,
      'amount': amount,
      'date': date,
      'effect': effect,
      'category': category,
      'account': account,
      'parent_transaction_id': parentTransactionId,
      'is_split_child': isSplitChild ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['transaction_id'],
      transId: map['trans_id'],
      description: map['description'],
      amount: (map['amount'] as num).toDouble(),
      date: map['date'],
      effect: map['effect'],
      category: map['category'],
      account: map['account'],
      categoryName: map['categoryName'] as String?,
      parentTransactionId: map['parent_transaction_id'],
      isSplitChild: (map['is_split_child'] ?? 0) == 1,
    );
  }
}
