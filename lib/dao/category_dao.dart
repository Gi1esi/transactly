
import '../utils/database_helper.dart';
import '../models/category_model.dart';

class CategoryDao {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertCategory(Category category) async {
    final db = await dbHelper.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await dbHelper.database;
    final maps = await db.query('categories');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await dbHelper.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'category_id = ?',
      whereArgs: [category.categoryId],
    );
  }

  Future<int> deleteCategory(int categoryId) async {
    final db = await dbHelper.database;
    return await db.delete('categories', where: 'category_id = ?', whereArgs: [categoryId]);
  }

  Future<List<Map<String, dynamic>>> getCategorySummary({
  required bool isExpense,
  DateTime? startDate,
}) async {
  final db = await dbHelper.database;
  final effect = isExpense ? 'dr' : 'cr';
  final whereArgs = <dynamic>[effect];
  String where = 't.effect = ?';

  if (startDate != null) {
    where += ' AND t.date >= ?';
    whereArgs.add(startDate.toIso8601String());
  }

  final result = await db.rawQuery('''
    SELECT c.name as categoryName, c.color_hex, c.icon_key, SUM(t.amount) as total
    FROM transactions t
    LEFT JOIN categories c ON t.category = c.category_id
    WHERE $where
    GROUP BY t.category
    ORDER BY total DESC
  ''', whereArgs);

  return result;
}
}
