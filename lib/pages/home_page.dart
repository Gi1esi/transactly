import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';
import '../utils/utils.dart';
import '../dao/transaction_dao.dart';
import '../models/transaction_model.dart';
import '../dao/category_dao.dart';
import '../models/category_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AccountProvider>(context, listen: false);
      if (provider.activeAccount == null) {
        provider.loadActiveAccount();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    final dao = TransactionDao();
    final now = DateTime.now();
    DateTime? startDate;

    switch (selectedFilterIndex) {
      case 0:
        startDate = now.subtract(const Duration(days: 1));
        break;
      case 1:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 2:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 3:
        startDate = now.subtract(const Duration(days: 180));
        break;
      default:
        startDate = null;
    }

    final income = await dao.getTotalByEffect('cr', startDate: startDate);
    final expense = await dao.getTotalByEffect('dr', startDate: startDate);
    final txns = await dao.getRecentTransactions(limit: 10);

    if (mounted) {
      setState(() {
        totalIncome = income;
        totalExpense = expense;
        recentTransactions = txns;
      });
    }
  }

  void onFilterSelected(int index) {
    setState(() {
      selectedFilterIndex = index;
    });
    _loadDashboardData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _editTransaction(Transaction txn) async {
    final categories = await CategoryDao().getAllCategories();
    String newDesc = txn.description;
    Category? selectedCat = categories.firstWhere(
      (c) => c.categoryId == txn.category,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : Category(name: 'Uncategorized', type: txn.effect == 'cr' ? 'income' : 'expense', iconKey: 'fastfood', colorHex: '#FF6B6B'),
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
                  const SizedBox(height: 14),
                  DropdownButton<Category>(
                    value: selectedCat,
                    isExpanded: true,
                    items: categories.map((cat) {
                      return DropdownMenuItem<Category>(value: cat, child: Text(cat.name));
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
                if (!mounted) return;
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
                _loadDashboardData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction split successfully')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error splitting transaction: $e')));
              }
            },
            child: const Text('Split'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final onPrimary = theme.colorScheme.onPrimary;
    final background = theme.colorScheme.background;

    return Consumer<AccountProvider>(
      builder: (context, accountProvider, _) {
        if (accountProvider.activeAccount == null || accountProvider.bank == null) {
          return const Center(child: CircularProgressIndicator());
        }

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
                      accountNumber: accountProvider.activeAccount!.accountNumber,
                      userName: accountProvider.user?.firstName ?? 'User',
                      primary: primary,
                      bank: accountProvider.bank!.name,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Filters - horizontal pill scroll (compact)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 44,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(filters.length, (index) {
                            final isSelected = index == selectedFilterIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => onFilterSelected(index),
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primary : surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: primary.withOpacity(isSelected ? 0.0 : 0.08)),
                                  ),
                                  child: Text(
                                    filters[index],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? onPrimary : primary,
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

                  const SizedBox(height: 20),

                  // Summary cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: SummaryCardModern(
                            label: formatAmount(totalIncome),
                            color: primary.withOpacity(0.9),
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

                  const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: recentTransactions.isEmpty
                          ? [Text('No transactions yet', style: TextStyle(color: onSurface.withOpacity(0.6)))]
                          : recentTransactions.map((txn) {
                              final isIncome = txn.effect == 'cr';
                              final amountColor = isIncome ? primary : secondary;
                              final avatarBg = amountColor.withOpacity(0.12);
                              String txDate;
                              try {
                                txDate = DateFormat('dd MMM yyyy').format(DateTime.parse(txn.date));
                              } catch (_) {
                                txDate = txn.date;
                              }
                              final categoryName = txn.categoryName ?? 'Uncategorized';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: primary.withOpacity(0.03)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: avatarBg,
                                      child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: amountColor, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            txn.description,
                                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: onSurface),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(txDate, style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.62))),
                                          const SizedBox(height: 4),
                                          Text(categoryName, style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.62))),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "${isIncome ? '+' : '-'}${formatAmount(txn.amount)}",
                                          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 14),
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
                                              onPressed: () => _splitTransaction(txn),
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
                                              onPressed: () => _editTransaction(txn),
                                              child: const Text('Edit'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ---------- BankCard ---------- */
class BankCard extends StatelessWidget {
  final String accountNumber;
  final String userName;
  final Color primary;
  final dynamic bank;

  const BankCard({super.key, required this.accountNumber, required this.userName, required this.bank, required this.primary});

  String maskAccountNumber(String acc) {
    if (acc.length <= 4) return acc;
    return '**** **** ${acc.substring(acc.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final avatarBg = onPrimary.withOpacity(0.16);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [primary.withOpacity(0.95), primary.withOpacity(0.65)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.22), offset: const Offset(0, 8), blurRadius: 14)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(maskAccountNumber(accountNumber), style: TextStyle(color: onPrimary, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 22, backgroundColor: avatarBg, child: Text((userName.isNotEmpty ? userName[0].toUpperCase() : '?'), style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold, fontSize: 18))),
                  const SizedBox(width: 12),
                  Text('Hello, $userName', style: TextStyle(color: onPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              Icon(Icons.credit_card, color: onPrimary.withOpacity(0.9), size: 34)
            ],
          ),
          Align(alignment: Alignment.bottomRight, child: Text('$bank', style: TextStyle(color: onPrimary.withOpacity(0.9), fontWeight: FontWeight.bold, letterSpacing: 3))),
        ],
      ),
    );
  }
}

/* ---------- SummaryCardModern ---------- */
class SummaryCardModern extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool outlined;

  const SummaryCardModern({super.key, required this.label, required this.color, required this.icon, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final textColor = outlined ? color : Theme.of(context).colorScheme.onPrimary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(16),
        border: outlined ? Border.all(color: color, width: 2) : null,
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(width: 8),
        Icon(icon, color: textColor, size: 20)
      ]),
    );
  }
}
