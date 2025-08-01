import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bank_mvp.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL
      )
    ''');

     await db.execute('''
    CREATE TABLE banks (
      bank_id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      long_name TEXT,
      sms_address_box TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE accounts (
      account_id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_number TEXT NOT NULL,
      bank INTEGER,
      user INTEGER,
      is_active INTEGER DEFAULT 0,
      FOREIGN KEY (bank) REFERENCES banks(bank_id) ON DELETE SET NULL ON UPDATE CASCADE,
      FOREIGN KEY (user) REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE
    )
  ''');

    await db.execute('''
      CREATE TABLE categories (
        category_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT CHECK(type IN ('income', 'expense')) NOT NULL,
        icon_key TEXT NOT NULL,
        color_hex TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
        trans_id TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        effect TEXT CHECK(effect IN ('cr', 'dr')) NOT NULL,
        category INTEGER,
        account INTEGER,
        FOREIGN KEY (category) REFERENCES categories(category_id) ON DELETE SET NULL ON UPDATE CASCADE,
        FOREIGN KEY (account) REFERENCES accounts(account_id) ON DELETE SET NULL ON UPDATE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_transaction_date ON transactions(date)');

    // Settings table to store last sync timestamp
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<int> deleteAll(String table) async {
    final db = await database;
    return await db.delete(table);
  }

  // Save last read timestamp
  Future<void> saveLastReadTimestamp(int timestamp) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'last_read_timestamp', 'value': timestamp.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get last read timestamp
  Future<int?> getLastReadTimestamp() async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['last_read_timestamp'],
    );
    if (result.isNotEmpty) {
      return int.tryParse(result.first['value'] as String);
    }
    return null;
  }
}
