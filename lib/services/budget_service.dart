import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../dao/budget_dao.dart';
import '../dao/category_dao.dart';
import '../dao/transaction_dao.dart';
import '../models/category_model.dart';



class BudgetService {
  static final BudgetService _instance = BudgetService._();
  factory BudgetService() => _instance;
  BudgetService._();

  final _flt = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _flt.initialize(const InitializationSettings(android: android, iOS: ios));
    _initialized = true;
  }

  Future<void> _showNotification({required String title, required String body}) async {
    const android = AndroidNotificationDetails('budget_channel', 'Budgets', channelDescription: 'Budget alerts', importance: Importance.high);
    const ios = DarwinNotificationDetails();
    await _flt.show(0, title, body, NotificationDetails(android: android, iOS: ios));
  }

  /// Call this after a transaction is added/updated.
  /// The transactionDao.getCategoryTotalForMonth should return sum for that category in the month.
  Future<void> checkBudgetAfterTransaction({required int categoryId}) async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final budgetDao = BudgetDao();
    final txnDao = TransactionDao();
    final categoryDao = CategoryDao();

    final budget = await budgetDao.getBudgetForCategoryMonth(categoryId, year, month);
    if (budget == null) return;

    // get total spent for that category for the same month
    final total = await txnDao.getTotalForCategoryMonth(categoryId, year, month);

    final limit = budget.limitAmount;
    if (limit <= 0) return;

    final percent = (total / limit) * 100;
if (percent >= 100) {
  final cat = (await categoryDao.getAllCategories()).firstWhere(
    (c) => c.categoryId == categoryId,
    orElse: () => Category(
      categoryId: -1,
      name: 'Uncategorized',
      type: 'expense',  // or 'income' if appropriate
      iconKey: 'default_icon',
      colorHex: '#CCCCCC',
    ),
  );
  final name = cat.name;
  await _showNotification(
    title: 'Budget exceeded',
    body: '$name has exceeded the budget ($percent% of limit).',
  );
} else if (percent >= 80) {
  final cat = (await categoryDao.getAllCategories()).firstWhere(
    (c) => c.categoryId == categoryId,
    orElse: () => Category(
      categoryId: -1,
      name: 'Uncategorized',
      type: 'expense',
      iconKey: 'default_icon',
      colorHex: '#CCCCCC',
    ),
  );
  final name = cat.name;
  await _showNotification(
    title: 'Budget near limit',
    body: '$name has used ${percent.toStringAsFixed(0)}% of its budget.',
  );
}

  }
}
