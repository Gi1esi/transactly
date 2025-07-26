import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'transaction.dart';
import 'main.dart'; // For parseSms if needed

class TransactionListPage extends StatefulWidget {
  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final box = Hive.box<Transaction>('transactions');

  final sampleSms = '''
Acc: 1007135544 got a Funds Transfer by Mo626of MWK27,000.00DR
To Acct: 1010653928
Date/Time: 25/07/25 10:53
Desc: jean.
Ref: FT252064Y73S\\BNK
Thanks NBM
Mo626 @ 16
''';

  void addSampleTransaction() {
    final tx = parseSms(sampleSms);
    if (tx != null) {
      box.add(tx);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = box.values.toList();
    double income = 0;
    double spending = 0;

    for (var t in transactions) {
      if (t.isDebit) {
        spending += t.amount;
      } else {
        income += t.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Transactions')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: addSampleTransaction,
            child: Text('Add Sample Transaction'),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Text('Income: MWK $income  Spending: MWK $spending'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return ListTile(
                  title: Text('${tx.description} - MWK ${tx.amount.toStringAsFixed(2)}'),
                  subtitle: Text('${tx.dateTime} - ${tx.isDebit ? "Debit" : "Credit"}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
