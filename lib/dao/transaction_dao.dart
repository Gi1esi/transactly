import '../models/transaction_model.dart';
import '../utils/database_helper.dart';

class TransactionDao {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertTransaction(Transaction tx) async {
    final db = await dbHelper.database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<int> splitTransaction({
    required Transaction parent,
    required double splitAmount,
    required String splitDescription,
    int? splitCategory,
    int? splitAccount,
  }) async {
    print('>>> DEBUG: splitTransaction() called');

    final db = await dbHelper.database;

    try {
      // Safety check
      if (splitAmount > parent.amount) {
        throw Exception(
          'Split amount (${splitAmount.toStringAsFixed(2)}) exceeds parent amount (${parent.amount.toStringAsFixed(2)})',
        );
      }

      assert(parent.id != null, 'Parent transaction ID is null!');
      print('>>> DEBUG: parent.id = ${parent.id}, type = ${parent.id.runtimeType}');

      return await db.transaction((txn) async {
        final newTx = {
          'trans_id': '${parent.transId}-split-${DateTime.now().millisecondsSinceEpoch}',
          'description': splitDescription,
          'amount': splitAmount,
          'date': parent.date,
          'effect': parent.effect,
          'category': splitCategory,
          'account': splitAccount ?? parent.account,
          'parent_transaction_id': parent.id,
          'is_split_child': 1,
        };

        print('>>> DEBUG: Inserting split child transaction...');
        await txn.insert('transactions', newTx);

        final newParentAmount = parent.amount - splitAmount;
        print('>>> DEBUG: Updating parent transaction amount to $newParentAmount');

        final rowsUpdated = await txn.update(
          'transactions',
          {'amount': newParentAmount},
          where: 'transaction_id = ?',
          whereArgs: [parent.id],
        );

        print('>>> DEBUG: Parent update affected $rowsUpdated row(s)');
        return 1;
      });
    } catch (e, stacktrace) {
      print('>>> ERROR in splitTransaction: $e');
      print(stacktrace);
      rethrow;
    }
  }


  Future<List<Transaction>> getAllTransactions() async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
      SELECT t.*, c.name AS categoryName
      FROM transactions t
      LEFT JOIN categories c ON t.category = c.category_id
      ORDER BY t.date DESC
    ''');

    return result.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<Transaction?> getTransactionById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'transaction_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Transaction.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'transactions',
      where: 'transaction_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTransaction(Transaction tx) async {
    final db = await dbHelper.database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'transaction_id = ?',
      whereArgs: [tx.id],
    );
  }

  // NEW: Get total income/expense based on effect (cr or dr)
  Future<double> getTotalByEffect(String effect, {DateTime? startDate}) async {
    final db = await dbHelper.database;
    String where = 'effect = ?';
    List<Object?> args = [effect];

    if (startDate != null) {
      where += ' AND date >= ?';
      args.add(startDate.toIso8601String());
    }

    final result = await db.query(
      'transactions',
      columns: ['SUM(amount) as total'],
      where: where,
      whereArgs: args,
    );

    final value = result.first['total'];
    return value != null ? (value as num).toDouble() : 0.0;
  }

  // NEW: Get recent transactions with a limit
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
      SELECT t.*, c.name AS categoryName
      FROM transactions t
      LEFT JOIN categories c ON t.category = c.category_id
      ORDER BY t.date DESC
      LIMIT ?
    ''', [limit]);

    return result.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<int> clearAllTransactions() async {
    final db = await dbHelper.database;
    return await db.delete('transactions');
  }
}
