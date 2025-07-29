
import 'database_helper.dart';
import 'account_model.dart';

class AccountDao {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertAccount(Account account) async {
    final db = await dbHelper.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getAllAccounts() async {
    final db = await dbHelper.database;
    final maps = await db.query('accounts');
    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<int> updateAccount(Account account) async {
    final db = await dbHelper.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'account_id = ?',
      whereArgs: [account.accountId],
    );
  }

  Future<int> deleteAccount(int accountId) async {
    final db = await dbHelper.database;
    return await db.delete('accounts', where: 'account_id = ?', whereArgs: [accountId]);
  }
}
