import 'database_helper.dart';
import 'bank_model.dart';

class BankDao {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertBank(Bank bank) async {
    final db = await dbHelper.database;
    return await db.insert('banks', bank.toMap());
  }

  Future<List<Bank>> getAllBanks() async {
    final db = await dbHelper.database;
    final maps = await db.query('banks');
    return maps.map((map) => Bank.fromMap(map)).toList();
  }

  Future<int> updateBank(Bank bank) async {
    final db = await dbHelper.database;
    return await db.update(
      'banks',
      bank.toMap(),
      where: 'bank_id = ?',
      whereArgs: [bank.bankId],
    );
  }

  Future<int> deleteBank(int bankId) async {
    final db = await dbHelper.database;
    return await db.delete('banks', where: 'bank_id = ?', whereArgs: [bankId]);
  }

  Future<void> seedBanks() async {
  final bankDao = BankDao();
  final banks = await bankDao.getAllBanks();

  if (banks.isEmpty) {
    final nbm = Bank(
      name: 'NBM',
      smsAddressBox: '626626',
    );
    await bankDao.insertBank(nbm);
    print('DEBUG: Seeded NBM into banks table');
  } else {
    print('DEBUG: Banks table already seeded');
  }
}

}
