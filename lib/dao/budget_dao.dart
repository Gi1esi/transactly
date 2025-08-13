import 'package:sqflite/sqflite.dart';
import '../utils/database_helper.dart';
import '../models/budget_model.dart';

class BudgetDao {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertBudget(Budget budget) async {
    final db = await dbHelper.database;
    
    
    if (budget.startDate != null && budget.endDate != null) {
      final overlaps = await hasOverlappingBudget(
        budget.categoryId,
        budget.period,
        budget.startDate!,
        budget.endDate!,
        excludeBudgetId: budget.budgetId,
      );
      
      if (overlaps) {
        throw Exception('Budget overlaps with an existing one.');
      }
    }

    return await db.insert(
      'budgets', 
      budget.toMap(), 
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> hasOverlappingBudget(
  int categoryId,
  String period,
  DateTime startDate,
  DateTime endDate, {
  int? excludeBudgetId,
}) async {
  final db = await dbHelper.database;
  
  var query = '''
    SELECT COUNT(*) as count FROM budgets
    WHERE category_id = ?
      AND period = ?
      AND (
        (start_date <= ? AND end_date >= ?) -- new start falls inside existing
        OR
        (start_date <= ? AND end_date >= ?) -- new end falls inside existing
        OR
        (start_date >= ? AND end_date <= ?) -- existing is inside new
      )
  ''';

  final whereArgs = [
    categoryId,
    period,
    endDate.toIso8601String(),
    startDate.toIso8601String(),
    endDate.toIso8601String(),
    startDate.toIso8601String(),
    startDate.toIso8601String(),
    endDate.toIso8601String(),
  ];

  
  if (excludeBudgetId != null) {
    query += ' AND budget_id != ?';
    whereArgs.add(excludeBudgetId);
  }

  final result = await db.rawQuery(query, whereArgs);
  return (result.first['count'] as int) > 0;
}

  Future<int> updateBudget(Budget budget) async {
    final db = await dbHelper.database;
    
    // Check for overlapping budgets (excluding current budget)
    if (budget.startDate != null && budget.endDate != null) {
      final overlaps = await hasOverlappingBudget(
        budget.categoryId,
        budget.period,
        budget.startDate!,
        budget.endDate!,
        excludeBudgetId: budget.budgetId,
      );
      
      if (overlaps) {
        throw Exception('Budget overlaps with an existing one.');
      }
    }

    return await db.update(
      'budgets', 
      budget.toMap(),
      where: 'budget_id = ?', 
      whereArgs: [budget.budgetId],
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'budgets', 
      where: 'budget_id = ?', 
      whereArgs: [id],
    );
  }
Future<Budget?> getBudgetById(int budgetId) async {
  final db = await dbHelper.database;
  final maps = await db.query(
    'budgets',
    where: 'budget_id = ?',
    whereArgs: [budgetId],
  );

  if (maps.isNotEmpty) {
    return Budget.fromMap(maps.first);
  }
  return null;
}
  Future<Budget?> getBudgetForCategory({
    required int categoryId,
    required String period,
    DateTime? startDate,
    DateTime? endDate,
    int? year,
    int? month,
    int? week,
  }) async {
    final db = await dbHelper.database;
    final whereParts = <String>['category_id = ?', 'period = ?'];
    final whereArgs = <dynamic>[categoryId, period];

    if (startDate != null && endDate != null) {
      whereParts.add('start_date = ? AND end_date = ?');
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    } else {
      if (year != null) {
        whereParts.add('year = ?');
        whereArgs.add(year);
      }
      if (month != null) {
        whereParts.add('month = ?');
        whereArgs.add(month);
      }
      if (week != null) {
        whereParts.add('week = ?');
        whereArgs.add(week);
      }
    }

    final result = await db.query(
      'budgets',
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isEmpty ? null : Budget.fromMap(result.first);
  }

  Future<Budget?> getBudgetForCategoryMonth(int categoryId, int year, int month) async {
    return await getBudgetForCategory(
      categoryId: categoryId,
      period: 'monthly',
      year: year,
      month: month,
    );
  }

  Future<List<Budget>> getAllBudgetsForYear(int year) async {
    final db = await dbHelper.database;
    final result = await db.query('budgets');
    // final result = await db.query(
    //   'budgets',
    //   where: 'year = ?',
    //   whereArgs: [year],
    // );
    return result.map((map) => Budget.fromMap(map)).toList();
  }

  Future<List<Budget>> getBudgetsByCategory(int categoryId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'budgets',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return result.map((map) => Budget.fromMap(map)).toList();
  }

  Future<List<Budget>> getActiveBudgets(DateTime date) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT * FROM budgets 
      WHERE start_date <= ? 
        AND end_date >= ?
    ''', [date.toIso8601String(), date.toIso8601String()]);
    return result.map((map) => Budget.fromMap(map)).toList();
  }
}