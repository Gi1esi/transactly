import '../utils/database_helper.dart';
import '../models/account_model.dart';
import '../models/bank_model.dart';

class AccountDao {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertAccount(Account account) async {
    final db = await dbHelper.database;
    
    final insertedId = await db.insert('accounts', account.toMap());

    // Count how many accounts exist
    final accounts = await getAllAccounts();
    if (accounts.length == 1) {
      await setActiveAccount(insertedId);
    }

    return insertedId;
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
    await db.update('accounts', {'is_active': 0});
    await db.update(
      'accounts',
      {'is_active': 1},
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }

  Future<Account?> getActiveAccount() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'accounts',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Account.fromMap(result.first);
    }
    return null;
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

  Future<int?> getLastReadTimestamp(int accountId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'accounts',
      columns: ['last_read_timestamp'],
      where: 'account_id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['last_read_timestamp'] as int?;
    }
    return null;
  }

  Future<void> updateLastReadTimestamp(int accountId, int timestamp) async {
    final db = await dbHelper.database;
    await db.update(
      'accounts',
      {'last_read_timestamp': timestamp},
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }

  Future<int?> getLastReadForActiveAccount() async {
    final active = await getActiveAccount();
    if (active != null) {
      return getLastReadTimestamp(active.accountId!);
    }
    return null;
  }

  Future<void> updateLastReadForActiveAccount([int? timestamp]) async {
    final active = await getActiveAccount();
    if (active != null) {
      await updateLastReadTimestamp(
        active.accountId!,
        timestamp ?? DateTime.now().millisecondsSinceEpoch,
      );
    }
  }
  Future<int?> getLastReadForAccount(int accountId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'accounts',
      columns: ['last_read_timestamp'],
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
    if (result.isNotEmpty) {
      return result.first['lastRead'] as int?;
    }
    return null;
  }
}
