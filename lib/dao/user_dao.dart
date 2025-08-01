
import '../utils/database_helper.dart';
import '../models/user_model.dart';

class UserDao {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertUser(User user) async {
    final db = await dbHelper.database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getAllUsers() async {
    final db = await dbHelper.database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await dbHelper.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.userId],
    );
  }

  Future<int> deleteUser(int userId) async {
    final db = await dbHelper.database;
    return await db.delete('users', where: 'user_id = ?', whereArgs: [userId]);
  }
}
