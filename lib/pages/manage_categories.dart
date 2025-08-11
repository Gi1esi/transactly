// lib/pages/manage_categories_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dao/category_dao.dart';
import '../models/category_model.dart';
import '../dao/budget_dao.dart';
import '../models/budget_model.dart';

class ManageCategoriesPage extends StatefulWidget {
  final bool isExpense;

  const ManageCategoriesPage({super.key, required this.isExpense});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final CategoryDao _categoryDao = CategoryDao();
  final BudgetDao _budgetDao = BudgetDao();
  final TextEditingController _controller = TextEditingController();

  List<Category> categories = [];
  IconData? selectedIcon;
  String? selectedColor;

  final List<IconData> availableIcons = [
    Icons.restaurant,
    Icons.receipt,
    Icons.directions_bus,
    Icons.attach_money,
    Icons.card_giftcard,
    Icons.shopping_cart,
    Icons.coffee,
    Icons.movie,
    Icons.fitness_center,
    Icons.local_gas_station,
    Icons.phone_iphone,
    Icons.home,
    Icons.local_hospital,
    Icons.school,
    Icons.computer,
    Icons.flight,
    Icons.pets,
    Icons.sports_soccer,
    Icons.music_note,
    Icons.beach_access,
    Icons.book,
    Icons.build,
    Icons.local_cafe,
    Icons.bike_scooter,
    Icons.local_pizza,
    Icons.local_bar,
    Icons.theaters,
    Icons.wb_sunny,
    Icons.electrical_services,
    Icons.laptop_mac,
  ];

  final List<String> availableColors = [
    '#FF6B6B', '#6BCB77', '#4D96FF', '#FFD93D', '#FF6BF1', '#6BFFEA', '#FF9F40',
    '#FF6384', '#36A2EB', '#FFCE56', '#9966FF', '#C9CBCF', '#FF7043', '#8BC34A',
    '#00BCD4', '#E91E63', '#9C27B0', '#03A9F4', '#4CAF50', '#FF5722', '#607D8B',
    '#795548', '#009688', '#673AB7', '#FFEB3B', '#CDDC39', '#3F51B5', '#F44336', '#2196F3',
  ];

  final _currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: 'MWK ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final allCategories = await _categoryDao.getAllCategories();
    setState(() {
      categories = allCategories.where((c) => c.type == (widget.isExpense ? 'expense' : 'income')).toList();
    });
  }

 
  int _weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysPassed = date.difference(firstDayOfYear).inDays;
    return ((daysPassed + firstDayOfYear.weekday) / 7).ceil();
  }

  Future<void> _showCategoryBudgetDialog(Category category) async {
  final dao = _budgetDao;
  final now = DateTime.now();

  String selectedPeriod = 'monthly';
  double initialAmount = 0.0;
  DateTime? customStartDate;
  DateTime? customEndDate;

  // Load existing budget if any
  final existingBudget = await dao.getBudgetForCategoryMonth(category.categoryId!, now.year, now.month);
  if (existingBudget != null) {
    initialAmount = existingBudget.limitAmount;
    selectedPeriod = existingBudget.period;
    customStartDate = existingBudget.startDate;
    customEndDate = existingBudget.endDate;
  } else {
    // Default to current date as start date for all periods
    customStartDate = now;
    // Set default end dates based on period type
    if (selectedPeriod == 'weekly') {
      customEndDate = customStartDate.add(const Duration(days: 6));
    } else if (selectedPeriod == 'monthly') {
      customEndDate = DateTime(customStartDate.year, customStartDate.month + 1, 0);
    } else if (selectedPeriod == 'yearly') {
      customEndDate = DateTime(customStartDate.year, 12, 31);
    }
  }

  final controller = TextEditingController(text: initialAmount > 0 ? initialAmount.toString() : '');

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        Widget buildDatePickers() {
          final now = DateTime.now();
          // Disallow dates before today
          final firstDate = DateTime(now.year, now.month, now.day);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: customStartDate ?? now,
                    firstDate: firstDate,
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      customStartDate = picked;
                      // Calculate end date based on selected period
                      if (selectedPeriod == 'weekly') {
                        customEndDate = picked.add(const Duration(days: 6));
                      } else if (selectedPeriod == 'monthly') {
                        // 30 days from start date (or adjust as needed)
                        customEndDate = picked.add(const Duration(days: 30));
                      } else if (selectedPeriod == 'yearly') {
                        // 365 days from start date (accounts for leap years automatically)
                        customEndDate = picked.add(const Duration(days: 365));
                      }
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
          title: Text('Set Budget for ${category.name}'),
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
                        if (selectedPeriod == 'weekly') {
                          customEndDate = customStartDate!.add(const Duration(days: 6));
                        } else if (selectedPeriod == 'monthly') {
                          customEndDate = customStartDate!.add(const Duration(days: 30));
                        } else if (selectedPeriod == 'yearly') {
                          customEndDate = customStartDate!.add(const Duration(days: 365));
                        }
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
                const SizedBox(height: 8),
                Text(
                  selectedPeriod == 'monthly'
                      ? 'Budget applies to 1 month starting from selected date.'
                      : selectedPeriod == 'weekly'
                          ? 'Budget applies to 7 days starting from selected date.'
                          : 'Budget applies to 1 year starting from selected date.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final val = double.tryParse(controller.text.trim()) ?? 0.0;
                if (val <= 0 || customStartDate == null || customEndDate == null) {
                  Navigator.pop(ctx);
                  return;
                }

                await saveBudgetWithDates(
                  categoryId: category.categoryId!,
                  period: selectedPeriod,
                  limitAmount: val,
                  startDate: customStartDate!,
                  endDate: customEndDate!,
                );

                Navigator.pop(ctx);
                _loadCategories();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> saveBudgetWithDates({
  required int categoryId,
  required String period,
  required double limitAmount,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  // Use the existing _budgetDao instance instead of direct db access
  final dao = _budgetDao;
  
  // Calculate year/month/week for backward compatibility
  final year = startDate.year;
  final month = period == 'monthly' ? startDate.month : null;
  final week = period == 'weekly' ? _weekNumber(startDate) : null;

  // Check if budget already exists using the DAO
  final existing = await dao.getBudgetForCategory(
    categoryId: categoryId,
    period: period,
    startDate: startDate,
    endDate: endDate,
  );

  if (existing == null) {
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
  } else {
    // Update existing budget
    existing.limitAmount = limitAmount;
    existing.startDate = startDate;
    existing.endDate = endDate;
    existing.year = year;
    existing.month = month;
    existing.week = week;
    await dao.updateBudget(existing);
  }
}

  Future<void> _addOrEditCategory({Category? existingCategory}) async {
    if (existingCategory != null) {
      _controller.text = existingCategory.name;
      selectedIcon = _iconDataFromKey(existingCategory.iconKey);
      selectedColor = existingCategory.colorHex;
    } else {
      _controller.clear();
      selectedIcon = availableIcons.first;

      final usedColors = categories.map((c) => c.colorHex).toSet();
      selectedColor = availableColors.firstWhere(
        (c) => !usedColors.contains(c),
        orElse: () => availableColors.first,
      );
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(existingCategory == null ? 'Add Category' : 'Edit Category', style: const TextStyle(color: Colors.black)),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(labelText: 'Category Name'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Select Icon:', style: TextStyle(color: Colors.black87)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: availableIcons.map((icon) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedIcon == icon ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                            ),
                            child: Icon(icon, color: selectedIcon == icon ? Colors.white : Colors.black87),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    const Text('Select Color:', style: TextStyle(color: Colors.black87)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: availableColors.map((colorHex) {
                        final color = _colorFromHex(colorHex);
                        final isUsed = categories.any((c) =>
                          c.colorHex == colorHex &&
                          (existingCategory == null || c.categoryId != existingCategory.categoryId)
                        );
                        return GestureDetector(
                          onTap: isUsed ? null : () => setState(() => selectedColor = colorHex),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selectedColor == colorHex ? Border.all(width: 3, color: Colors.black45) : null,
                              boxShadow: isUsed ? [const BoxShadow(color: Colors.black26, blurRadius: 3)] : [],
                            ),
                            child: isUsed ? const Icon(Icons.block, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.black54))),
            ElevatedButton(
              onPressed: () async {
                final name = _controller.text.trim();
                if (name.isEmpty || selectedIcon == null || selectedColor == null) return;

                final iconKey = _iconKeyFromIconData(selectedIcon!);
                final colorHex = selectedColor!;

                if (existingCategory == null) {
                  final newCategory = Category(
                    name: name,
                    type: widget.isExpense ? 'expense' : 'income',
                    iconKey: iconKey,
                    colorHex: colorHex,
                  );
                  await _categoryDao.insertCategory(newCategory);
                } else {
                  final updated = Category(
                    categoryId: existingCategory.categoryId,
                    name: name,
                    type: existingCategory.type,
                    iconKey: iconKey,
                    colorHex: colorHex,
                  );
                  await _categoryDao.updateCategory(updated);
                }
                Navigator.pop(context);
                _loadCategories();
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  IconData _iconDataFromKey(String key) {
    switch (key) {
      case 'fastfood': return Icons.restaurant;
      case 'grocery': return Icons.receipt;
      case 'car': return Icons.directions_bus;
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
      default: return availableIcons.first;
    }
  }

  String _iconKeyFromIconData(IconData icon) {
    if (icon == Icons.restaurant) return 'fastfood';
    if (icon == Icons.receipt) return 'grocery';
    if (icon == Icons.directions_bus) return 'car';
    if (icon == Icons.attach_money) return 'money';
    if (icon == Icons.card_giftcard) return 'gift';
    if (icon == Icons.shopping_cart) return 'shopping';
    if (icon == Icons.coffee) return 'coffee';
    if (icon == Icons.movie) return 'movie';
    if (icon == Icons.fitness_center) return 'fitness';
    if (icon == Icons.local_gas_station) return 'gas';
    if (icon == Icons.phone_iphone) return 'phone';
    if (icon == Icons.home) return 'home';
    if (icon == Icons.local_hospital) return 'hospital';
    if (icon == Icons.school) return 'school';
    if (icon == Icons.computer) return 'computer';
    if (icon == Icons.flight) return 'flight';
    if (icon == Icons.pets) return 'pets';
    if (icon == Icons.sports_soccer) return 'soccer';
    if (icon == Icons.music_note) return 'music';
    if (icon == Icons.beach_access) return 'beach';
    return 'fastfood';
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _deleteCategory(int index) async {
    final cat = categories[index];
    if (cat.categoryId != null) {
      await _categoryDao.deleteCategory(cat.categoryId!);
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isExpense ? 'Manage Expense Categories' : 'Manage Income Categories';
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(title, style: const TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Category', style: TextStyle(color: Colors.white)),
              onPressed: () => _addOrEditCategory(),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.black12),
                itemBuilder: (context, index) {
                  final category = categories[index];

                  return FutureBuilder<Budget?>(
                    future: _budgetDao.getBudgetForCategoryMonth(category.categoryId ?? -1, now.year, now.month),
                    builder: (context, snap) {
                      final budget = snap.data;
                      final budgetText = (budget == null)
                          ? 'No budget'
                          : '${_currencyFmt.format(budget.limitAmount)} / ${budget.period == 'monthly' ? 'mo' : (budget.period == 'weekly' ? 'wk' : 'yr')}';

                      return ListTile(
                        leading: Icon(_iconDataFromKey(category.iconKey), color: _colorFromHex(category.colorHex)),
                        title: Text(category.name, style: const TextStyle(color: Colors.black87)),
                        subtitle: Text(budgetText, style: TextStyle(color: Colors.black54)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () => _addOrEditCategory(existingCategory: category),
                            ),
                            TextButton(
                              onPressed: () => _showCategoryBudgetDialog(category),
                              child: Text(
                                budget == null ? 'Set Budget' : 'Budget: ${_currencyFmt.format(budget.limitAmount)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteCategory(index),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple month/year picker widget (used for monthly budget selection)
class MonthYearPicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;

  const MonthYearPicker({super.key, required this.initialDate, required this.onChanged});

  @override
  State<MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<MonthYearPicker> {
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(21, (i) => DateTime.now().year - 10 + i);
    final months = List.generate(12, (i) => i + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Month and Year:', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        Row(
          children: [
            DropdownButton<int>(
              value: selectedMonth,
              items: months
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(DateFormat.MMMM().format(DateTime(0, m))),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => selectedMonth = v);
                  widget.onChanged(DateTime(selectedYear, selectedMonth, 1));
                }
              },
            ),
            const SizedBox(width: 20),
            DropdownButton<int>(
              value: selectedYear,
              items: years
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text(y.toString()),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => selectedYear = v);
                  widget.onChanged(DateTime(selectedYear, selectedMonth, 1));
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
