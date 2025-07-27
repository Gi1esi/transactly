import 'package:flutter/material.dart';
import 'utils.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key, required this.accountNumber, required this.userName});

  final String accountNumber;
  final String userName;

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> with SingleTickerProviderStateMixin {
  int selectedFilterIndex = 0;
  final filters = ['1D', '1W', '1M', '6M', 'ALL'];

  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeInAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void onFilterSelected(int index) {
    setState(() {
      selectedFilterIndex = index;
    });
    // Add filter logic here
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final onBackground = Colors.white.withOpacity(0.9);

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
                        label: 'MWK 120,000',
                        color: primary.withOpacity(0.85),
                        icon: Icons.arrow_downward,
                        outlined: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCardModern(
                        label: 'MWK 85,000',
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
                    color: onBackground,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: const [
                    RecentTransactionModern(
                      isIncome: true,
                      description: 'Salary',
                      amount: 'MWK 120,000',
                      date: '25 Jul 2025',
                    ),
                    RecentTransactionModern(
                      isIncome: false,
                      description: 'Groceries',
                      amount: 'MWK 20,000',
                      date: '24 Jul 2025',
                    ),
                  ],
                ),
              ),
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

  const BankCard({
    Key? key,
    required this.accountNumber,
    required this.userName,
    required this.primary,
  }) : super(key: key);

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
              fontSize: 20,
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
                      userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Hello, $userName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const Icon(Icons.credit_card, color: Colors.white70, size: 36),
            ],
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'VISA',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 24,
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
    Key? key,
    required this.filters,
    required this.selectedIndex,
    required this.onSelect,
    required this.primary,
    required this.onBackground,
  }) : super(key: key);

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
                color: isSelected ? Colors.white : onBackground,
                fontWeight: FontWeight.w700,
                fontSize: 15,
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
    Key? key,
    required this.label,
    required this.color,
    required this.icon,
    this.outlined = false,
  }) : super(key: key);

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          Icon(icon, color: textColor, size: 26),
        ],
      ),
    );
  }
}

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
