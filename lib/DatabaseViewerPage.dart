import 'package:flutter/material.dart';
import 'database_helper.dart';

class DatabaseViewerPage extends StatefulWidget {
  const DatabaseViewerPage({super.key});

  @override
  _DatabaseViewerPageState createState() => _DatabaseViewerPageState();
}

class _DatabaseViewerPageState extends State<DatabaseViewerPage> {
  Map<String, List<Map<String, dynamic>>> tableData = {};

  final List<String> tables = [
    'users',
    'banks',
    'accounts',
    'categories',
    'transactions',
    'settings'
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    Map<String, List<Map<String, dynamic>>> data = {};
    for (final table in tables) {
      final rows = await DatabaseHelper.instance.queryAll(table);
      data[table] = rows;
    }
    setState(() {
      tableData = data;
    });
  }

  Future<void> insertDummyData() async {
    final db = DatabaseHelper.instance;

    // Insert user: Grace Gausi
    final userId = await db.insert('users', {
      'first_name': 'Grace',
      'last_name': 'Gausi',
    });

    // Insert bank: NBM with sms_address_box 626626
    final bankId = await db.insert('banks', {
      'name': 'NBM',
      'sms_address_box': '626626',
    });

    // Insert account: account_number 1007135544 linked to userId and bankId
    await db.insert('accounts', {
      'account_number': '1007135544',
      'bank': bankId,
      'user': userId,
    });

    // Insert category: Meals, expense, icon_key and color_hex arbitrary
    await db.insert('categories', {
      'name': 'Meals',
      'type': 'expense',
      'icon_key': 'food_icon',
      'color_hex': '#FF6347',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Viewer'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => loadData(),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Insert Dummy Data',
            onPressed: () async {
              await insertDummyData();
              await loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dummy data inserted')),
              );
            },
          ),
          
        ],
      ),
      body: tableData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: tables.map((table) {
                final rows = tableData[table] ?? [];
                return ExpansionTile(
                  title: Text('$table (${rows.length} rows)'),
                  children: rows.isEmpty
                      ? [ListTile(title: Text('No data'))]
                      : rows.map((row) {
                          return ListTile(
                            title: Text(row.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join(', ')),
                          );
                        }).toList(),
                );
              }).toList(),
            ),
    );
  }
}
