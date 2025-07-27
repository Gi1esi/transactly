import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CategoryAnalysisPage extends StatefulWidget {
  const CategoryAnalysisPage({Key? key}) : super(key: key);

  @override
  State<CategoryAnalysisPage> createState() => _CategoryAnalysisPageState();
}

class _CategoryAnalysisPageState extends State<CategoryAnalysisPage>
    with SingleTickerProviderStateMixin {

  final List<String> filters = ['1D', '1W', '1M', '6M', 'ALL'];
  int selectedFilterIndex = 2; // Default: 1M
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void onFilterSelected(int index) {
    setState(() {
      selectedFilterIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Analysis'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Filter chips
          Wrap(
            spacing: 12,
            children: List.generate(filters.length, (index) {
              final isSelected = index == selectedFilterIndex;
              return ChoiceChip(
                label: Text(filters[index]),
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryTab(isExpense: true, primary: primary, secondary: secondary),
                _buildCategoryTab(isExpense: false, primary: primary, secondary: secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab({required bool isExpense, required Color primary, required Color secondary}) {
    // Hardcoded data
    final categories = isExpense
        ? [
            {'name': 'Food', 'amount': 50000.0, 'icon': Icons.restaurant, 'color': secondary},
            {'name': 'Transport', 'amount': 15000.0, 'icon': Icons.directions_bus, 'color': primary},
            {'name': 'Bills', 'amount': 20000.0, 'icon': Icons.receipt, 'color': Colors.orange},
          ]
        : [
            {'name': 'Salary', 'amount': 120000.0, 'icon': Icons.attach_money, 'color': primary},
            {'name': 'Freelance', 'amount': 30000.0, 'icon': Icons.laptop, 'color': secondary},
          ];

    final total = categories.fold<double>(
      0.0,
      (sum, item) => sum + (item['amount'] as double),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overview card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  isExpense ? 'Total Expenses' : 'Total Income',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'MWK ${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pie Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: categories.map((cat) {
                  final value = cat['amount'] as double;
                  final percent = total == 0 ? 0 : (value / total) * 100;
                  return PieChartSectionData(
                    color: cat['color'] as Color,
                    value: value,
                    title: '${percent.toStringAsFixed(0)}%',
                    radius: 70,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category cards
          Column(
            children: categories.map((cat) {
              final amount = cat['amount'] as double;
              final percent = total == 0 ? 0 : (amount / total) * 100;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: (cat['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        cat['name'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'MWK ${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cat['color'] as Color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Manage categories button
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isExpense ? 'Manage Expense Categories' : 'Manage Income Categories',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
