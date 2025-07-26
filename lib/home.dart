import 'package:flutter/material.dart';
import 'home_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  final List<Widget> _pages = [
    HomePageWidget(
      accountNumber: '1007 1355 44',
      userName: 'Grace',
    ),
    Center(child: Text('Category Analytics Page', style: TextStyle(fontSize: 24))),
    Center(child: Text('Summary Page', style: TextStyle(fontSize: 24))),
    Center(child: Text('Settings Page', style: TextStyle(fontSize: 24))),
  ];

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    // Animate fade out, then switch page, then fade in
    _animationController.reverse().then((_) {
      setState(() => _selectedIndex = index);
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactly',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primary,
                  fontFamily: 'Poppins',
                ),
              ),
              CircleAvatar(
                backgroundColor: primary.withOpacity(0.1),
                child: Text(
                  'GG',
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
          child: _pages[_selectedIndex],
        ),
        bottomNavigationBar: Container(
  color: Colors.transparent, // Transparent container background
  child: BottomNavigationBar(
    backgroundColor: Colors.transparent, // Transparent BottomNavigationBar
    type: BottomNavigationBarType.fixed,
    currentIndex: _selectedIndex,
    onTap: _onItemTapped,
    selectedItemColor: primary,
    unselectedItemColor: primary,
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
        label: 'Categories',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.analytics_outlined),
        label: 'Summary',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        label: 'Settings',
      ),
    ],
  ),
),

      ),
    );
  }
}
