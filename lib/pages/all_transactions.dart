import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dao/transaction_dao.dart';
import '../models/transaction_model.dart';
import '../dao/category_dao.dart';
import '../models/category_model.dart';
import '../utils/utils.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final List<String> filters = ['1D', '1W', '1M', '6M', 'All', 'Custom'];
  int selectedFilterIndex = 4; // All
  DateTimeRange? customRange;

  final List<String> typeFilters = ['All', 'Income', 'Expense'];
  int selectedTypeFilterIndex = 0;

  final CategoryDao _categoryDao = CategoryDao();
  List<Transaction> allTransactions = [];
  List<Transaction> filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final txList = await TransactionDao().getAllTransactions();
    setState(() {
      allTransactions = txList;
      filteredTransactions = List.from(txList);
    });
  }

  Future<void> _editTransaction(Transaction txn) async {
    final categories = await _categoryDao.getAllCategories();
    String newDesc = txn.description;
    Category? selectedCat = categories.firstWhere(
      (c) => c.categoryId == txn.category,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : Category(
              name: 'Uncategorized',
              type: txn.effect == 'cr' ? 'income' : 'expense',
              iconKey: 'fastfood',
              colorHex: '#FF6B6B',
            ),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Transaction'),
          content: StatefulBuilder(builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: newDesc),
                  onChanged: (v) => newDesc = v,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
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
                ),
              ],
            );
          }),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                txn.description = newDesc;
                txn.category = selectedCat?.categoryId;
                await TransactionDao().updateTransaction(txn);
                if (!mounted) return;
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

  Future<void> _splitTransaction(Transaction tx) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Split Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Split Amount'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Split Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dao = TransactionDao();
                await dao.splitTransaction(
                  parent: tx,
                  splitAmount: double.tryParse(amountController.text.trim()) ?? 0.0,
                  splitDescription: descriptionController.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                _loadTransactions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction split successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error splitting transaction: $e')),
                );
              }
            },
            child: const Text('Split'),
          ),
        ],
      ),
    );
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
          return !txDate.isBefore(customRange!.start) && !txDate.isAfter(customRange!.end);
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
        case 'All':
        default:
          cutoff = DateTime(1970);
      }

      tempList = allTransactions.where((tx) {
        final txDate = DateTime.parse(tx.date);
        return !txDate.isBefore(cutoff);
      }).toList();
    }

    if (selectedTypeFilterIndex == 1) {
      tempList = tempList.where((tx) => tx.effect == 'cr').toList();
    } else if (selectedTypeFilterIndex == 2) {
      tempList = tempList.where((tx) => tx.effect != 'cr').toList();
    }

    setState(() => filteredTransactions = tempList);
  }

  Future<void> selectCustomDateRange() async {
    final theme = Theme.of(context);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: customRange ??
          DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
              surface: theme.colorScheme.surface,
              onSurface: theme.colorScheme.onSurface,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text('Transactions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: primary)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date filter - horizontal pill scroll
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: SizedBox(
              height: 42,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(filters.length, (index) {
                    final isSelected = index == selectedFilterIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => onFilterSelected(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? primary : surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primary.withOpacity(isSelected ? 0.0 : 0.12)),
                          ),
                          child: Text(
                            filters[index],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? theme.colorScheme.onPrimary : primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // Type filters - small segmented style
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: List.generate(typeFilters.length, (index) {
                final isSelected = index == selectedTypeFilterIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        selectedTypeFilterIndex = index;
                        applyFilter();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? secondary : surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: secondary.withOpacity(isSelected ? 0.0 : 0.12)),
                      ),
                      child: Text(
                        typeFilters[index],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? theme.colorScheme.onSecondary : secondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 6),

          // Transactions list
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 56, color: onSurface.withOpacity(0.18)),
                        const SizedBox(height: 12),
                        Text('No transactions yet', style: TextStyle(fontSize: 15, color: onSurface.withOpacity(0.6))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      final isIncome = tx.effect == 'cr';
                      final amountColor = isIncome ? primary : secondary;
                      final avatarBg = amountColor.withOpacity(0.12);
                      final txDate = DateFormat('dd MMM yyyy').format(DateTime.parse(tx.date));
                      final categoryName = tx.categoryName ?? 'Uncategorized';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primary.withOpacity(0.04)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: avatarBg,
                              child: Icon(
                                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                color: amountColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Description
                                  Text(
                                    tx.description,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  // Date (below description)
                                  Text(
                                    txDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: onSurface.withOpacity(0.62),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Category (below date)
                                  Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: onSurface.withOpacity(0.62),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Amount + actions
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${isIncome ? '+' : '-'}${formatAmount(tx.amount)}",
                                  style: TextStyle(
                                    color: amountColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(56, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        foregroundColor: primary,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _splitTransaction(tx),
                                      child: const Text('Split'),
                                    ),
                                    const SizedBox(width: 6),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(56, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        foregroundColor: primary,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _editTransaction(tx),
                                      child: const Text('Edit'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
