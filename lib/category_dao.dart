
import 'database_helper.dart';
import 'category_model.dart';

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
}
