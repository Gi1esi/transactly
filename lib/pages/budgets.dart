import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dao/budget_dao.dart';
import '../dao/category_dao.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../utils/utils.dart';
import 'create_budget.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BudgetDao _budgetDao = BudgetDao();
  final CategoryDao _categoryDao = CategoryDao();
  final _currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: 'MWK ', decimalDigits: 0);

  bool _loading = true;

  Map<String, List<_BudgetInfo>> _budgetsByPeriod = {
    'weekly': [],
    'monthly': [],
    'yearly': [],
  };

  final List<String> _periods = ['weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
    _loadBudgets();
  }

  Future<DateTime?> _showDatePickerWithValidation({
      required BuildContext context,
      required DateTime? initialDate,
    }) async {
      final now = DateTime.now();
      final firstDate = DateTime(now.year, now.month, now.day);
      final effectiveInitialDate = initialDate ?? now;
      
      return await showDatePicker(
        context: context,
        initialDate: effectiveInitialDate.isBefore(firstDate) ? firstDate : effectiveInitialDate,
        firstDate: firstDate,
        lastDate: DateTime(2100),
      );
    }


  Future<void> _loadBudgets() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final allBudgets = await _budgetDao.getAllBudgetsForYear(now.year);

    Map<String, List<_BudgetInfo>> grouped = {
      'weekly': [],
      'monthly': [],
      'yearly': [],
    };

    for (var budget in allBudgets) {
      final cat = await _categoryDao.getCategoryById(budget.categoryId);
      if (cat == null) continue;

      double spent = 0;
      DateTime? startDate = budget.startDate;
      DateTime? endDate = budget.endDate;

      if (startDate == null || endDate == null) {
        if (budget.period == 'monthly' && budget.month != null) {
          startDate = DateTime(budget.year ?? now.year, budget.month!, 1);
          endDate = DateTime(budget.year ?? now.year, budget.month! + 1, 0);
        } else if (budget.period == 'yearly' && budget.year != null) {
          startDate = DateTime(budget.year!, 1, 1);
          endDate = DateTime(budget.year!, 12, 31);
        } else if (budget.period == 'weekly' && budget.week != null) {
          startDate = _dateFromWeekNumber(budget.year ?? now.year, budget.week!);
          endDate = startDate.add(const Duration(days: 6));
        }
      }

      if (startDate != null && endDate != null) {
        spent = await _categoryDao.getTotalSpentForCategoryDateRange(
          cat.categoryId!,
          startDate,
          endDate,
        );
      }

      grouped[budget.period]?.add(
        _BudgetInfo(category: cat, budget: budget, spentAmount: spent),
      );
    }

    grouped.forEach((period, budgets) {
      budgets.sort((a, b) {
        // Put editable budgets first
        final aEditable = _isBudgetEditable(a.budget);
        final bEditable = _isBudgetEditable(b.budget);
        if (aEditable != bEditable) {
          return aEditable ? -1 : 1;
        }
        
        // Then sort by progress
        final aProg = a.budget.limitAmount > 0 ? a.spentAmount / a.budget.limitAmount : 0;
        final bProg = b.budget.limitAmount > 0 ? b.spentAmount / b.budget.limitAmount : 0;
        return bProg.compareTo(aProg);
      });
    });

    setState(() {
      _budgetsByPeriod = grouped;
      _loading = false;
    });
  }

  DateTime _dateFromWeekNumber(int year, int weekNumber) {
    final firstDay = DateTime(year, 1, 1);
    final daysToAdd = (weekNumber - 1) * 7;
    return firstDay.add(Duration(days: daysToAdd - firstDay.weekday + 1));
  }

  int _weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysPassed = date.difference(firstDayOfYear).inDays;
    return ((daysPassed + firstDayOfYear.weekday) / 7).ceil();
  }

  void _navigateToCreateBudget() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CreateBudgetPage(
        categoryDao: _categoryDao,
        budgetDao: _budgetDao,
        onBudgetCreated: _loadBudgets,
      ),
    ),
  );
  
  if (result == true) {
    _loadBudgets();
  }
}

 Future<void> _saveBudgetWithDates({
  required int categoryId,
  required String period,
  required double limitAmount,
  required DateTime startDate,
  required DateTime endDate,
  int? budgetId, // Add this parameter
}) async {
  final dao = _budgetDao;
  
  // Calculate year/month/week for backward compatibility
  final year = startDate.year;
  final month = period == 'monthly' ? startDate.month : null;
  final week = period == 'weekly' ? _weekNumber(startDate) : null;

  if (budgetId != null) {
    final existing = await dao.getBudgetById(budgetId);
    if (existing != null) {
      existing.limitAmount = limitAmount;
      existing.startDate = startDate;
      existing.endDate = endDate;
      existing.year = year;
      existing.month = month;
      existing.week = week;
      existing.period = period;
      await dao.updateBudget(existing);
    }
  } else {
    // Insert new budget
    await dao.insertBudget(Budget(
      categoryId: categoryId,
      period: period,
      limitAmount: limitAmount,
      startDate: startDate,
      endDate: endDate,
      year: year,
      month: month,
      week: week,
    ));
  }
}
  
  Future<void> _editBudget(_BudgetInfo budgetInfo) async {
  if (!_isBudgetEditable(budgetInfo.budget)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot edit completed budgets')),
    );
    return;
  }

  final controller = TextEditingController(text: budgetInfo.budget.limitAmount.toString());
  String selectedPeriod = budgetInfo.budget.period;
  DateTime? customStartDate = budgetInfo.budget.startDate;
  DateTime? customEndDate = budgetInfo.budget.endDate;
  final now = DateTime.now();
  String? errorMessage;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        Widget buildDatePickers() {
          final firstDate = DateTime(now.year, now.month, now.day);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              TextButton(
                onPressed: () async {
                  final picked = await _showDatePickerWithValidation(
                    context: context,
                    initialDate: customStartDate,
                  );
                  if (picked != null) {
                    setState(() {
                      customStartDate = picked;
                      customEndDate = addPeriodToDate(picked, selectedPeriod);
                      errorMessage = null; // Clear error when dates change
                    });
                  }
                },
                child: Text(
                  customStartDate == null
                      ? 'Select start date'
                      : selectedPeriod == 'weekly'
                          ? 'Week: ${DateFormat.yMd().format(customStartDate!)} - ${DateFormat.yMd().format(customEndDate!)}'
                          : selectedPeriod == 'monthly'
                              ? 'Month: ${DateFormat.yMd().format(customStartDate!)} - ${DateFormat.yMd().format(customEndDate!)}'
                              : 'Year: ${DateFormat.yMd().format(customStartDate!)} - ${DateFormat.yMd().format(customEndDate!)}',
                ),
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text('Edit Budget for ${budgetInfo.category.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  decoration: const InputDecoration(labelText: 'Duration'),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (v) {
                    if (v != null && customStartDate != null) {
                      setState(() {
                        selectedPeriod = v;
                        customEndDate = addPeriodToDate(customStartDate!, selectedPeriod);
                        errorMessage = null; // Clear error when period changes
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: selectedPeriod == 'yearly'
                        ? 'Yearly limit (MWK)'
                        : (selectedPeriod == 'weekly' ? 'Weekly limit (MWK)' : 'Monthly limit (MWK)'),
                  ),
                ),
                const SizedBox(height: 12),
                buildDatePickers(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = double.tryParse(controller.text.trim()) ?? 0.0;
                if (val <= 0 || customStartDate == null || customEndDate == null) {
                  setState(() {
                    errorMessage = 'Please fill all fields correctly';
                  });
                  return;
                }

                try {
                  await _saveBudgetWithDates(
                    categoryId: budgetInfo.category.categoryId!,
                    period: selectedPeriod,
                    limitAmount: val,
                    startDate: customStartDate!,
                    endDate: customEndDate!,
                    budgetId: budgetInfo.budget.budgetId,
                  );

                  Navigator.pop(ctx);
                  _loadBudgets();
                } catch (e) {
                  setState(() {
                    errorMessage = e.toString();
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Budgets Overview',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.primary.withOpacity(0.5),
          indicatorColor: theme.colorScheme.primary,
          tabs: _periods.map((p) => Tab(text: p[0].toUpperCase() + p.substring(1))).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
         onPressed: _navigateToCreateBudget,
         child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _periods.map((period) {
                final budgets = _budgetsByPeriod[period] ?? [];
                if (budgets.isEmpty) {
                  return Center(
                    child: Text(
                      'No $period budgets set',
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final info = budgets[index];
                    final progress = info.budget.limitAmount > 0
                        ? (info.spentAmount / info.budget.limitAmount).clamp(0.0, 1.0)
                        : 0.0;
                    final remaining = info.budget.limitAmount - info.spentAmount;
                    final isOverBudget = remaining < 0;

                    return BudgetCard(
                      category: info.category,
                      budget: info.budget,
                      spentAmount: info.spentAmount,
                      progress: progress,
                      remaining: remaining,
                      isOverBudget: isOverBudget,
                      onTap: () => _editBudget(info),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  final Category category;
  final Budget budget;
  final double spentAmount;
  final double progress;
  final double remaining;
  final bool isOverBudget;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.category,
    required this.budget,
    required this.spentAmount,
    required this.progress,
    required this.remaining,
    required this.isOverBudget,
    this.onTap,
  });

  // Helper method to safely format date range
  Widget _buildDateRangeText(BuildContext context, ThemeData theme) {
    final hasDates = budget.startDate != null && budget.endDate != null;
    final status = _getBudgetStatus();

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDates)
            Text(
              '${DateFormat('MMM d, y').format(budget.startDate!)} - ${DateFormat('MMM d, y').format(budget.endDate!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            )
          else
            Text(
              'No date range set',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          if (!_isBudgetEditable(budget))
            Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  String _getBudgetStatus() {
    if (budget.endDate == null) return 'No end date';
    
    final now = DateTime.now();
    if (budget.endDate!.isBefore(now)) {
      return 'Completed';
    }
    if (budget.startDate != null && budget.startDate!.isAfter(now)) {
      return 'Upcoming';
    }
    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorFromHex(category.colorHex);
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: 'MWK ', decimalDigits: 0);
    final isEditable = _isBudgetEditable(budget);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isEditable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(_iconDataFromKey(category.iconKey), color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    currencyFmt.format(remaining),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isOverBudget ? Colors.red : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              _buildDateRangeText(context, theme),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(
                    progress >= 1.0
                        ? Colors.red
                        : progress >= 0.8
                            ? Colors.orange
                            : color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% used',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    Text(
                      '${currencyFmt.format(spentAmount)} / ${currencyFmt.format(budget.limitAmount)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
bool _isBudgetEditable(Budget budget) {
  final now = DateTime.now();
  return budget.endDate == null || budget.endDate!.isAfter(now);
}
IconData _iconDataFromKey(String key) {
  switch (key) {
    case 'fastfood': return Icons.restaurant;
    case 'grocery': return Icons.receipt;
    case 'car': return Icons.directions_car;
    case 'money': return Icons.attach_money;
    case 'gift': return Icons.card_giftcard;
    case 'shopping': return Icons.shopping_cart;
    case 'coffee': return Icons.coffee;
    case 'movie': return Icons.movie;
    case 'fitness': return Icons.fitness_center;
    case 'gas': return Icons.local_gas_station;
    case 'phone': return Icons.phone_iphone;
    case 'home': return Icons.home;
    case 'hospital': return Icons.local_hospital;
    case 'school': return Icons.school;
    case 'computer': return Icons.computer;
    case 'flight': return Icons.flight;
    case 'pets': return Icons.pets;
    case 'soccer': return Icons.sports_soccer;
    case 'music': return Icons.music_note;
    case 'beach': return Icons.beach_access;
    default: return Icons.category;
  }
}

Color _colorFromHex(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class _BudgetInfo {
  final Category category;
  final Budget budget;
  final double spentAmount;

  _BudgetInfo({
    required this.category,
    required this.budget,
    required this.spentAmount,
  });
}