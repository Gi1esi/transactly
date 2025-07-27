import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

class Transaction {
  final bool isIncome;
  final String description;
  final double amount;
  final DateTime date;

  Transaction({
    required this.isIncome,
    required this.description,
    required this.amount,
    required this.date,
  });

  String get amountFormatted => 'MWK ${amount.toStringAsFixed(0)}';

  String get dateFormatted => DateFormat('dd MMM yyyy').format(date);
}

class SummaryPage extends StatefulWidget {
  const SummaryPage({Key? key}) : super(key: key);

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  // Quick filters + 'Custom'
  final List<String> filters = ['1D', '1W', '1M', '6M', 'ALL', 'Custom'];
  int selectedFilterIndex = 5; // Default: Custom (shows all initially)
  DateTimeRange? customRange;

  late List<Transaction> allTransactions;
  late List<Transaction> filteredTransactions;

  @override
  void initState() {
    super.initState();

    // Hardcoded sample transactions
    allTransactions = [
      Transaction(isIncome: true, description: 'Salary', amount: 120000, date: DateTime.now().subtract(Duration(days: 1))),
      Transaction(isIncome: false, description: 'Groceries', amount: 20000, date: DateTime.now().subtract(Duration(days: 2))),
      Transaction(isIncome: false, description: 'Electricity Bill', amount: 5000, date: DateTime.now().subtract(Duration(days: 10))),
      Transaction(isIncome: true, description: 'Freelance', amount: 35000, date: DateTime.now().subtract(Duration(days: 20))),
      Transaction(isIncome: false, description: 'Internet Bill', amount: 7000, date: DateTime.now().subtract(Duration(days: 35))),
      Transaction(isIncome: false, description: 'Restaurant', amount: 15000, date: DateTime.now().subtract(Duration(days: 50))),
      Transaction(isIncome: true, description: 'Bonus', amount: 50000, date: DateTime.now().subtract(Duration(days: 180))),
    ];

    filteredTransactions = List.from(allTransactions);
  }

  void applyFilter() {
    final now = DateTime.now();
    DateTime cutoff;
    List<Transaction> tempList;

    if (selectedFilterIndex == filters.length - 1) {
      // Custom range
      if (customRange == null) {
        tempList = List.from(allTransactions);
      } else {
        tempList = allTransactions.where((tx) {
          return !tx.date.isBefore(customRange!.start) && !tx.date.isAfter(customRange!.end);
        }).toList();
      }
    } else {
      switch (filters[selectedFilterIndex]) {
        case '1D':
          cutoff = now.subtract(Duration(days: 1));
          break;
        case '1W':
          cutoff = now.subtract(Duration(days: 7));
          break;
        case '1M':
          cutoff = DateTime(now.year, now.month - 1, now.day);
          break;
        case '6M':
          cutoff = DateTime(now.year, now.month - 6, now.day);
          break;
        case 'ALL':
        default:
          cutoff = DateTime(1970);
      }

      tempList = allTransactions.where((tx) => tx.date.isAfter(cutoff)).toList();
    }

    setState(() {
      filteredTransactions = tempList;
    });
  }

  Future<void> selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: customRange ?? DateTimeRange(start: DateTime.now().subtract(Duration(days: 30)), end: DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
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

    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters row
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
                  selectedColor: primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : primary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: primary),
                );
              }),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions found.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = filteredTransactions[index];
                        return RecentTransactionModern(
                          isIncome: tx.isIncome,
                          description: tx.description,
                          amount: tx.amountFormatted,
                          date: tx.dateFormatted,
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


// Reuse your RecentTransactionModern widget here
class RecentTransactionModern extends StatelessWidget {
  final bool isIncome;
  final String description;
  final String amount;
  final String date;

  const RecentTransactionModern({
    Key? key,
    required this.isIncome,
    required this.description,
    required this.amount,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incomeColor = theme.colorScheme.primary;
    final expenseColor = theme.colorScheme.secondary;
    final iconColor = isIncome ? incomeColor : expenseColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Poppins',
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
