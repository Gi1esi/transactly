import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'manage_categories.dart';
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
  int selectedFilterIndex = 0;
  late TabController _tabController;
  bool _showPieChart = false;

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
        title: Text(
          'Category Analysis',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: primary.withOpacity(0.5),
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

        final barGroups = categories.asMap().entries.map((entry) {
          final idx = entry.key;
          final cat = entry.value;
          final amount = cat['total'] as double;
          final hex = cat['color_hex'] as String?;
          final color = (hex != null && hex.length >= 7)
              ? Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000)
              : const Color.fromARGB(255, 31, 163, 154);

          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: amount,
                color: color,
                width: 18,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          );
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTotalCard(isExpense, total, primary),
              const SizedBox(height: 20),
              if (categories.isEmpty)
                _buildEmptyState(isExpense, primary)
              else ...[
                _buildChartToggle(primary),
                const SizedBox(height: 20),
                _showPieChart
                    ? _buildPieChart(categories, total)
                    : _buildBarChart(categories, total, barGroups, primary),
                const SizedBox(height: 20),
                _buildCategoryList(categories, total),
              ],
              const SizedBox(height: 20),
              _buildManageButton(isExpense, primary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalCard(bool isExpense, double total, Color primary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            isExpense ? 'Total Expenses' : 'Total Income',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: primary.withOpacity(0.7)),
          ),
          const SizedBox(height: 6),
          Text(
            'MWK ${total.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isExpense, Color primary) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'No ${isExpense ? 'expenses' : 'income'} recorded in this period.',
        style: TextStyle(color: primary, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildChartToggle(Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showPieChart = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showPieChart ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Bar Chart",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_showPieChart ? Colors.white : primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showPieChart = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showPieChart ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Pie Chart",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _showPieChart ? Colors.white : primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> categories, double total) {
    return SizedBox(
      height: 220,
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
                : const Color.fromARGB(255, 31, 163, 154);
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
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> categories, double total, List<BarChartGroupData> barGroups, Color primary) {
    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: (categories.map((c) => c['total'] as double).reduce((a, b) => a > b ? a : b)) * 1.2,
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= categories.length) return const SizedBox.shrink();
                  String name = categories[idx]['categoryName'] ?? 'Other';
                  if (name.length > 6) name = '${name.substring(0, 6)}...';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(name, style: TextStyle(color: primary, fontSize: 10)),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value % (total / 5) == 0) {
                    return Text('MWK ${value.toInt()}', style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          barTouchData: BarTouchData(enabled: true),
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<Map<String, dynamic>> categories, double total) {
    return Column(
      children: categories.map((cat) {
        final amount = cat['total'] as double;
        final percent = total == 0 ? 0 : (amount / total) * 100;
        final hex = cat['color_hex'] as String?;
        final color = (hex != null && hex.length >= 7)
            ? Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000)
            : const Color.fromARGB(255, 31, 163, 154);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, color: color, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cat['categoryName'] ?? 'Uncategorized',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
              Text(
                'MWK ${amount.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(width: 8),
              Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildManageButton(bool isExpense, Color primary) {
    return ElevatedButton(
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      child: Text(
        isExpense ? 'Manage Expense Categories' : 'Manage Income Categories',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}
