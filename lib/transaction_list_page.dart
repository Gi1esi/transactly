import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_card.dart';
import 'transaction_dao.dart';
import 'transaction_model.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final TransactionDao _transactionDao = TransactionDao();

  List<Transaction> transactions = [];
  double income = 0;
  double spending = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final txList = await _transactionDao.getAllTransactions();

    double totalIncome = 0;
    double totalSpending = 0;

    for (var tx in txList) {
      if (tx.effect == 'dr') {
        totalSpending += tx.amount;
      } else {
        totalIncome += tx.amount;
      }
    }

    setState(() {
      transactions = txList;
      income = totalIncome;
      spending = totalSpending;
    });
  }

  void _editCategory(Transaction tx) {
    // Open category selection dialog or page
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category'),
        content: const Text('Category editing logic goes here.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en', symbol: 'MWK ');

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Income: ${currency.format(income)}   Spending: ${currency.format(spending)}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];

                  // Format the stored date (ISO string)
                  String formattedDate;
                  try {
                    final parsed = DateTime.parse(tx.date);
                    formattedDate = DateFormat('dd MMM yyyy').format(parsed);
                  } catch (_) {
                    formattedDate = tx.date; // fallback if parse fails
                  }

                  return RecentTransactionModern(
                    isIncome: tx.effect == 'cr',
                    description: tx.description,
                    amount: 'MWK ${tx.amount.toStringAsFixed(2)}',
                    date: formattedDate,
                    category: tx.categoryName ?? 'Uncategorized',
                    onEditCategory: () => _editCategory(tx),
                    primary: Colors.white,
                    secondary: Colors.black,
                    onBackground: Colors.black12,
                    onSecondary: Colors.black26,

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
