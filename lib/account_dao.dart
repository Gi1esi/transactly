
import 'database_helper.dart';
import 'account_model.dart';
import 'bank_model.dart';

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
  Future<void> setActiveAccount(int accountId) async {
    final db = await dbHelper.database;
    await db.update('accounts', {'is_active': 0}); // clear all active
    await db.update('accounts', {'is_active': 1},
        where: 'account_id = ?', whereArgs: [accountId]);
  }
  Future<List<Account>> getAllAccountsWithBanks() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT a.*, b.bank_id, b.name, b.sms_address_box
      FROM accounts a
      LEFT JOIN banks b ON a.bank = b.bank_id
    ''');
    return result.map((map) {
      final acc = Account.fromMap(map);
      acc.bank = Bank.fromMap(map);
      return acc;
    }).toList();
  }

}
