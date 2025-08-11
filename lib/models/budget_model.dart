// lib/models/budget_model.dart
class Budget {
  int? budgetId;
  int categoryId;
  String period; 
  int? year;
  int? month;
  int? week;
  double limitAmount;
  DateTime? startDate;  // Removed 'final'
  DateTime? endDate;

  Budget({
    this.budgetId,
    required this.categoryId,
    required this.period,
    this.year,
    this.month,
    this.week,
    required this.limitAmount,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
  return {
    'budget_id': budgetId,
    'category_id': categoryId,
    'period': period,
    'limit_amount': limitAmount,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'year': year,
    'month': month,
    'week': week,
  };
}

factory Budget.fromMap(Map<String, dynamic> map) {
  return Budget(
    budgetId: map['budget_id'] as int?,
    categoryId: map['category_id'] as int,
    period: map['period'] as String,
    limitAmount: (map['limit_amount'] as num).toDouble(),
    startDate: map['start_date'] != null 
        ? DateTime.parse(map['start_date'] as String) 
        : null,
    endDate: map['end_date'] != null 
        ? DateTime.parse(map['end_date'] as String) 
        : null,
    year: map['year'] as int?,
    month: map['month'] as int?,
    week: map['week'] as int?,
  );
}
}
