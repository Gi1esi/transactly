import '../models/transaction_model.dart';
import '../utils/database_helper.dart';
import 'account_dao.dart';
import '../services/budget_service.dart';

class TransactionDao {
  final dbHelper = DatabaseHelper.instance;
  final AccountDao _accountDao = AccountDao();

  Future<int> insertTransaction(Transaction tx) async {
    final db = await dbHelper.database;
    final exists = await transactionExists(tx.transId);
    
    if (exists) {
      print('⚠️ Transaction already exists: ${tx.transId}');
      return 0;
    }

    // Insert the transaction
    final id = await db.insert('transactions', tx.toMap());

    // After inserting, check budget for the category (if present)
    if (tx.category != null) {
      // Make sure BudgetService is initialized somewhere in your app startup
      await BudgetService().checkBudgetAfterTransaction(categoryId: tx.category!);
    }

    return id;
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
    final activeAccount = await _accountDao.getActiveAccount();

    if (activeAccount == null) {
      return []; // Or throw Exception("No active account")
    }

    final result = await db.rawQuery('''
      SELECT t.*, c.name AS categoryName
      FROM transactions t
      LEFT JOIN categories c ON t.category = c.category_id
      WHERE t.account = ?
      ORDER BY t.date DESC
    ''', [activeAccount.accountId]);

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
  Future<bool> transactionExists(String transId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'trans_id = ?',
      whereArgs: [transId],
      limit: 1,
    );
    return result.isNotEmpty;
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
    final activeAccount = await _accountDao.getActiveAccount();

    if (activeAccount == null) return 0.0;

    String where = 'effect = ? AND account = ?';
    List<Object?> args = [effect, activeAccount.accountId];

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
    final activeAccount = await _accountDao.getActiveAccount();

    if (activeAccount == null) {
      return [];
    }

    final result = await db.rawQuery('''
      SELECT t.*, c.name AS categoryName
      FROM transactions t
      LEFT JOIN categories c ON t.category = c.category_id
      WHERE t.account = ?
      ORDER BY t.date DESC
      LIMIT ?
    ''', [activeAccount.accountId, limit]);

    return result.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<int> clearAllTransactions() async {
    final db = await dbHelper.database;
    return await db.delete('transactions');
  }
  Future<double> getTotalForCategoryMonth(int categoryName, int month, int year) async {
  final db = await dbHelper.database;
  final result = await db.rawQuery('''
    SELECT SUM(amount) as total
    FROM transactions
    WHERE categoryName = ?
      AND strftime('%m', date) = ?
      AND strftime('%Y', date) = ?
  ''', [
    categoryName,
    month.toString().padLeft(2, '0'), 
    year.toString()
  ]);

  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}

}
