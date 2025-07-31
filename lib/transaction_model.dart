class Transaction {
  final int? id;
  final String transId;
  String description;
  final double amount;
  final String date; // stored as ISO string: YYYY-MM-DD
  final String effect; // 'cr' or 'dr'
  int? category;
  final int? account;
  String? categoryName; // <-- added for the joined name

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
    );
  }
}
