import 'package:bank_mvp/transaction_list_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'categories_page.dart';
import 'read_sms.dart';
import 'DatabaseViewerPage.dart';
import 'account_dao.dart';
import 'user_dao.dart';
import 'bank_dao.dart';
import 'account_model.dart';
import 'bank_model.dart';
import 'all_transactions.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  String? accountNumber;
  String? userName;
  String? bankName;
  bool isLoading = true; // Prevents UI until data is loaded

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
    _loadUserAndAccount();
  }

  Future<void> _loadUserAndAccount() async {
    final userDao = UserDao();
    final accountDao = AccountDao();
    final bankDao = BankDao();

    final users = await userDao.getAllUsers();
    if (users.isNotEmpty) {
      final user = users.first;
      print('DEBUG: Loaded user ${user.firstName} ${user.lastName} (ID: ${user.userId})');

      final accounts = await accountDao.getAllAccounts();
      print('DEBUG: Found ${accounts.length} accounts');

      final account = accounts.firstWhere(
        (a) => a.userId == user.userId,
        orElse: () => Account(accountNumber: '', userId: user.userId),
      );

      final banks = await bankDao.getAllBanks();

      final bank = banks.firstWhere(
        (element) => element.bankId == account.bankId,
        orElse: () => Bank(bankId: 0, name: 'Unknown Bank', smsAddressBox: '626626'),
      );

      print('DEBUG: Loaded account number ${account.accountNumber} for userId ${account.userId}');

      setState(() {
        accountNumber = account.accountNumber;
        userName = user.firstName;
        bankName = bank.name;
        isLoading = false;
      });
    } else {
      print('DEBUG: No users found in DB');
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    _animationController.reverse().then((_) {
      setState(() => _selectedIndex = index);
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      HomePageWidget(
        accountNumber: accountNumber ?? '',
        userName: userName ?? '',
        bank: bankName ?? '',
      ),
      CategoryAnalysisPage(),
      SummaryPage(),
    ];

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/images/Transactly.png',
                height: 50,
                fit: BoxFit.contain,
              ),
              CircleAvatar(
                backgroundColor: primary.withOpacity(0.15),
                child: Text(
                  (userName?.isNotEmpty == true)
                      ? userName![0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: pages[_selectedIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: secondary,
          unselectedItemColor: primary.withOpacity(0.7),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontFamily: 'Poppins',
            fontSize: 12,
          ),
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Spending Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              label: 'All Transactions',
            ),
            
          ],
        ),
      ),
    );
  }
}
