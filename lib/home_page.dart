import 'package:flutter/material.dart';
import 'utils.dart';
import 'transaction_dao.dart';
import 'transaction_model.dart';
import 'category_dao.dart';
import 'category_model.dart';
import 'transaction_card.dart';


class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key, required this.accountNumber, required this.userName, required this.bank});

  final String accountNumber;
  final String userName;
  final String bank;

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> with SingleTickerProviderStateMixin {
  int selectedFilterIndex = 0;
  final filters = ['1D', '1W', '1M', '6M', 'ALL'];
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  List<Transaction> recentTransactions = [];


  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeInAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _loadDashboardData();
  }

   Future<void> _loadDashboardData() async {
    final dao = TransactionDao();

    // determine date range based on selectedIndex
    final now = DateTime.now();
    DateTime? startDate;
    if (selectedFilterIndex == 0) startDate = now.subtract(Duration(days: 1));
    if (selectedFilterIndex == 1) startDate = now.subtract(Duration(days: 7));
    if (selectedFilterIndex == 2) startDate = now.subtract(Duration(days: 30));
    if (selectedFilterIndex == 3) startDate = now.subtract(Duration(days: 180));

    final income = await dao.getTotalByEffect('cr', startDate: startDate);
    final expense = await dao.getTotalByEffect('dr', startDate: startDate);
    final txns = await dao.getRecentTransactions(limit: 10);

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      recentTransactions = txns;
    });
  }

  void onFilterSelected(int index) {
    setState(() {
      selectedFilterIndex = index;
    });
    _loadDashboardData(); // reload when filter changes
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // inside _HomePageWidgetState
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
            _loadDashboardData();
          },
          child: const Text('Save'),
        ),
        ],
      );
    },
  );
}

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final onBackground = Colors.white.withOpacity(0.9);
    final onSecondary = theme.colorScheme.onSecondary;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BankCard(
                  accountNumber: widget.accountNumber,
                  userName: widget.userName,
                  primary: primary,
                  bank: widget.bank,
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: FilterChipsModern(
                  filters: filters,
                  selectedIndex: selectedFilterIndex,
                  onSelect: onFilterSelected,
                  primary: primary,
                  onBackground: onBackground,
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
  children: [
    Expanded(
      child: SummaryCardModern(
        label: formatAmount(totalIncome),
        color: primary.withOpacity(0.85),
        icon: Icons.arrow_downward,
        outlined: false,
      ),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: SummaryCardModern(
        label: formatAmount(totalExpense),
        color: primary,
        icon: Icons.arrow_upward,
        outlined: true,
      ),
    ),
  ],
),
              ),

              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              const SizedBox(height: 12),

             Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: recentTransactions.isEmpty
                      ? [const Text('No transactions yet', style: TextStyle(color: Colors.white70))]
                      : recentTransactions.map((txn) {
                        return RecentTransactionModern(
                          isIncome: txn.effect == 'cr',
                          description: txn.description,
                          amount: formatAmount(txn.amount),
                          date: txn.date,
                          category: txn.categoryName ?? 'Uncategorized',
                          onEditCategory: () => _editTransaction(txn),
                          primary: primary,
                          onBackground: onBackground,
                          secondary: secondary,
                          onSecondary: onSecondary,
                        );
                      }).toList(),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}

class BankCard extends StatelessWidget {
  final String accountNumber;
  final String userName;
  final Color primary;
  final dynamic bank;

  const BankCard({
    super.key,
    required this.accountNumber,
    required this.userName,
    required this.bank,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            primary.withOpacity(0.9),
            primary.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 16,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            maskAccountNumber(accountNumber),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
              fontFamily: 'Poppins',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    child: Text(
                     (userName.isNotEmpty ? userName[0].toUpperCase() : '?'),

                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Hello, $userName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const Icon(Icons.credit_card, color: Colors.white70, size: 36),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '$bank', // converts to string and uses runtime value
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterChipsModern extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Color primary;
  final Color onBackground;

  const FilterChipsModern({
    super.key,
    required this.filters,
    required this.selectedIndex,
    required this.onSelect,
    required this.primary,
    required this.onBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: List.generate(filters.length, (index) {
        final isSelected = index == selectedIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: isSelected
                ? LinearGradient(
                    colors: [primary.withOpacity(0.9), primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            border: Border.all(color: primary, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onSelect(index),
            child: Text(
              filters[index],
              style: TextStyle(
                color: isSelected ? Colors.white : primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        );
      }),
    );
  }
}

class SummaryCardModern extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool outlined;

  const SummaryCardModern({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = outlined ? color : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(22),
        border: outlined ? Border.all(color: color, width: 2) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        
          
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: textColor, size: 22),
        ],
      ),
    );
  }
}

