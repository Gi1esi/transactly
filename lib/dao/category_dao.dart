
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


  Future<Category?> getCategoryById(int categoryId) async {
    // Query your categories table by id and return a Category object
    final db = await dbHelper.database; 
    final maps = await db.query(
      'categories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<double> getTotalSpentForCategoryWeek(int categoryId, int year, int week) async {
  final db = await dbHelper.database;
  final startDate = _firstDateOfWeek(year, week);
  final endDate = _lastDateOfWeek(year, week);

  final result = await db.rawQuery(
    '''
    SELECT SUM(amount) as total 
    FROM transactions 
    WHERE category_id = ? 
    AND date >= ? 
    AND date <= ?
    ''',
    [categoryId, startDate.toIso8601String(), endDate.toIso8601String()],
  );

  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}

// In your CategoryDao class
Future<double> getTotalSpentForCategoryDateRange(
  int categoryId, 
  DateTime startDate, 
  DateTime endDate
) async {
  final db = await dbHelper.database;
  
  final result = await db.rawQuery('''
    SELECT COALESCE(SUM(amount), 0) as total 
    FROM transactions 
    WHERE category = ? 
    AND date >= ? 
    AND date <= ?
    AND effect = 'dr'
  ''', [
    categoryId,
    startDate.toIso8601String(),
    endDate.toIso8601String(),
  ]);

  return (result.first['total'] as num?)?.toDouble() ?? 0;
}

  Future<double> getTotalSpentForCategoryMonth(int categoryId, int year, int month) async {
    final db = await dbHelper.database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE category_id = ? 
      AND date >= ? 
      AND date <= ?
      ''',
      [categoryId, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalSpentForCategoryYear(int categoryId, int year) async {
    final db = await dbHelper.database;
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year + 1, 1, 1).subtract(const Duration(days: 1));

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE category_id = ? 
      AND date >= ? 
      AND date <= ?
      ''',
      [categoryId, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

      DateTime _firstDateOfWeek(int year, int weekNumber) {
      final jan4 = DateTime(year, 1, 4);
      final daysToMonday = jan4.weekday - DateTime.monday; // jan4.weekday: 1=Mon ... 7=Sun
      final firstMonday = jan4.subtract(Duration(days: daysToMonday));
      return firstMonday.add(Duration(days: (weekNumber - 1) * 7));
    }

    DateTime _lastDateOfWeek(int year, int weekNumber) {
      return _firstDateOfWeek(year, weekNumber).add(const Duration(days: 6));
    }

}
