import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_dao.dart';
import 'transaction_model.dart'; // contains your backend Transaction class
import 'transaction_card.dart';
import 'category_dao.dart';
import 'category_model.dart';
 // contains RecentTransactionModern

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final List<String> filters = ['1D', '1W', '1M', '6M', 'ALL', 'Custom'];
  int selectedFilterIndex = 5;
  DateTimeRange? customRange;


  List<Transaction> allTransactions = [];
  List<Transaction> filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

final CategoryDao _categoryDao = CategoryDao();

Future<void> _editTransaction(Transaction txn) async {
  final categories = await _categoryDao.getAllCategories();
  String newDesc = txn.description;
  Category? selectedCat = categories.firstWhere(
    (c) => c.categoryId == txn.category,
    orElse: () => categories.isNotEmpty ? categories.first : Category(
      name: 'Uncategorized',
      type: txn.effect == 'cr' ? 'income' : 'expense',
      iconKey: 'fastfood',
      colorHex: '#FF6B6B'
    ),
  );

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Edit Transaction'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: newDesc),
                  onChanged: (val) => newDesc = val,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 20),
                DropdownButton<Category>(
                  value: selectedCat,
                  isExpanded: true,
                  items: categories.map((cat) {
                    return DropdownMenuItem<Category>(
                      value: cat,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedCat = val);
                  },
                )
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
         ElevatedButton(
          onPressed: () async {
            txn.description = newDesc;
            txn.category = selectedCat?.categoryId;
            await TransactionDao().updateTransaction(txn);

            if (!mounted) return; // <-- check before using context
            Navigator.pop(context);
            _loadTransactions();
          },
          child: const Text('Save'),
        ),
        ],
      );
    },
  );
}

  Future<void> _loadTransactions() async {
    final txList = await TransactionDao().getAllTransactions();
    setState(() {
      allTransactions = txList;
      filteredTransactions = List.from(txList);
    });
  }

 void applyFilter() {
  final now = DateTime.now();
  DateTime cutoff;
  List<Transaction> tempList;

  if (selectedFilterIndex == filters.length - 1) {
    // Custom
    if (customRange == null) {
      tempList = List.from(allTransactions);
    } else {
      tempList = allTransactions.where((tx) {
        final txDate = DateTime.parse(tx.date);
        return !txDate.isBefore(customRange!.start) &&
               !txDate.isAfter(customRange!.end);
      }).toList();
    }
  } else {
    switch (filters[selectedFilterIndex]) {
      case '1D':
        cutoff = now.subtract(const Duration(days: 1));
        break;
      case '1W':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '1M':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case '6M':
        cutoff = now.subtract(const Duration(days: 180));
        break;
      case 'ALL':
      default:
        cutoff = DateTime(1970);
    }

    tempList = allTransactions.where((tx) {
      final txDate = DateTime.parse(tx.date);
      return !txDate.isBefore(cutoff);
    }).toList();
  }

  setState(() {
    filteredTransactions = tempList;
  });
}


  Future<void> selectCustomDateRange() async {
  final theme = Theme.of(context);
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    initialDateRange: customRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        ),
    builder: (context, child) {
      return Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: Colors.teal, 
            onPrimary: Colors.white, 
            surface: Colors.grey[900], 
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    setState(() {
      customRange = picked;
      applyFilter();
    });
  }
}


  void onFilterSelected(int index) {
    setState(() {
      selectedFilterIndex = index;
      if (filters[index] == 'Custom') {
        selectCustomDateRange();
      } else {
        applyFilter();
      }
    });
  }

  void _editCategory(Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category'),
        content: const Text('Category editing logic goes here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
  final primary = theme.colorScheme.primary;
  final secondary = theme.colorScheme.secondary;
  final onBackground = Colors.white.withOpacity(0.9);
  final onSecondary = theme.colorScheme.onSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Transactions',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary, 
            fontWeight:  FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
            body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              children: List.generate(filters.length, (index) {
                final isSelected = index == selectedFilterIndex;
                final label = filters[index] == 'Custom' && customRange != null
                    ? '${DateFormat('MM/dd').format(customRange!.start)} - ${DateFormat('MM/dd').format(customRange!.end)}'
                    : filters[index];
                  

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => onFilterSelected(index),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Color(0xFF0F172A),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                );
              }),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: filteredTransactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions found.',
                        style: TextStyle(color: Colors.black45),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = filteredTransactions[index];
                        final isIncome = tx.effect == 'cr';
                        final txDate = DateTime.parse(tx.date);
                        final formattedDate =
                            DateFormat('dd MMM yyyy').format(txDate);

                        return RecentTransactionModern(
                          isIncome: isIncome,
                          description: tx.description,
                          amount: 'MWK ${tx.amount.toStringAsFixed(2)}',
                          date: formattedDate,
                          category: tx.categoryName ?? 'Uncategorized',
                          onEditCategory: () => _editTransaction(tx),
                          primary: primary,
                          secondary: secondary,
                          onBackground: onBackground,
                          onSecondary: onSecondary,
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
