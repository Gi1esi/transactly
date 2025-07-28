import 'transaction_model.dart';
import 'database_helper.dart';

class TransactionDao {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertTransaction(Transaction tx) async {
    final db = await dbHelper.database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await dbHelper.database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => Transaction.fromMap(m)).toList();
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
}
