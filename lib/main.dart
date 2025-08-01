import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'transaction_list_page.dart';
import 'home.dart';
import 'splash_page.dart';
import 'bank_dao.dart';
import 'database_helper.dart';
import 'user_dao.dart';
import 'read_sms.dart';
import 'transactions_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   // This line forces the DB to initialize
   // Initialize database
  await DatabaseHelper.instance.database;

  // Seed banks
  await BankDao().seedBanks();

  final users = await UserDao().getAllUsers();
  if (users.isNotEmpty) {
    await SmsWatcher().startWatching();
  }


  runApp(
  AnimatedBuilder(
    animation: TransactionsNotifier.instance,
    builder: (context, _) => const MyApp(),
  ),
);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF0F172A);     
    const Color primary = Color.fromARGB(255, 5, 160, 103);    
    const Color secondary = Color(0xFFFF644F); 

    return MaterialApp(
      title: 'Bank SMS Summarizer',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        primaryColor: primary,
        colorScheme: ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: const Color(0xFF1E293B), // slightly lighter for cards
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: primary,
          unselectedItemColor: Colors.white70,
        ),
        cardColor: const Color(0xFF1E293B),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
