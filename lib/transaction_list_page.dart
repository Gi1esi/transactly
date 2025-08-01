import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_card.dart';
import 'transaction_dao.dart';
import 'transaction_model.dart';
import 'transactions_notifier.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: AnimatedBuilder(
        animation: TransactionsNotifier.instance,
        builder: (context, _) {
          return FutureBuilder<List<Transaction>>(
            future: _transactionDao.getAllTransactions(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final txList = snapshot.data!;
              final totalIncome = txList.where((tx) => tx.effect == 'cr').fold(0.0, (a, b) => a + b.amount);
              final totalSpending = txList.where((tx) => tx.effect == 'dr').fold(0.0, (a, b) => a + b.amount);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('Income: MWK ${totalIncome.toStringAsFixed(2)}  Spending: MWK ${totalSpending.toStringAsFixed(2)}'),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: txList.length,
                      itemBuilder: (context, index) {
                        final tx = txList[index];
                        return ListTile(
                          title: Text(tx.description),
                          subtitle: Text(tx.date),
                          trailing: Text('${tx.amount.toStringAsFixed(2)} ${tx.effect.toUpperCase()}'),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

}
