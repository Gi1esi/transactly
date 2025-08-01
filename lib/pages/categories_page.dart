import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'manage_categories.dart';
import '../dao/transaction_dao.dart';
import '../dao/category_dao.dart';
import 'filter_chips.dart';

class CategoryAnalysisPage extends StatefulWidget {
  const CategoryAnalysisPage({super.key});

  @override
  State<CategoryAnalysisPage> createState() => _CategoryAnalysisPageState();
}

class _CategoryAnalysisPageState extends State<CategoryAnalysisPage>
    with SingleTickerProviderStateMixin {
  

  final List<String> filters = ['1D', '1W', '1M', '6M', 'ALL'];
  int selectedFilterIndex = 2; // Default: 1M
  late TabController _tabController;


  Future<List<Map<String, dynamic>>> _loadCategoryData(bool isExpense) async {
    final dao = CategoryDao();
    DateTime? startDate;
    final now = DateTime.now();
    if (selectedFilterIndex == 0) startDate = now.subtract(const Duration(days: 1));
    if (selectedFilterIndex == 1) startDate = now.subtract(const Duration(days: 7));
    if (selectedFilterIndex == 2) startDate = now.subtract(const Duration(days: 30));
    if (selectedFilterIndex == 3) startDate = now.subtract(const Duration(days: 180));

    return await dao.getCategorySummary(isExpense: isExpense, startDate: startDate);
}


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
    final onBackground = theme.colorScheme.onPrimary;

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
         
          FilterChipsModern(
          filters: filters,
          selectedIndex: selectedFilterIndex,
          onSelect: onFilterSelected,
          primary: primary,
          onBackground: onBackground,
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
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _loadCategoryData(isExpense),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final categories = snapshot.data!;
      final total = categories.fold<double>(
        0.0,
        (sum, item) => sum + (item['total'] as double),
      );

     
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
         
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(isExpense ? 'Total Expenses' : 'Total Income',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,)),
                  const SizedBox(height: 8),
                  Text(
                    'MWK ${total.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

           
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: categories.map((cat) {
                    final value = cat['total'] as double;
                    final percent = total == 0 ? 0 : (value / total) * 100;
                    final hex = cat['color_hex'] as String?;
                    final color = (hex != null && hex.length >= 7)
                        ? Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000)
                        : const Color(0xFF00E676); // fallback color
                    return PieChartSectionData(
                      color: color,
                      value: value,
                      title: percent < 5 ? '' : '${percent.toStringAsFixed(0)}%',
                      radius: 70,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

     
            Column(
              children: categories.map((cat) {
                final amount = cat['total'] as double;
                final percent = total == 0 ? 0 : (amount / total) * 100;
                final hex = cat['color_hex'] as String?;
                  final color = (hex != null && hex.length >= 7)
                      ? Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000)
                      : const Color(0xFF00E676); // fallback color
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: color, size: 20),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(cat['categoryName'] ?? 'Uncategorized',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                      Text(
                        'MWK ${amount.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      ),
                      const SizedBox(width: 8),
                      Text('${percent.toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

           
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageCategoriesPage(isExpense: isExpense),
                  ),
                );
              },
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
    },
  );
}

}
