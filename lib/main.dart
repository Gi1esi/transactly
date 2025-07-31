import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'transaction.dart';
import 'transaction_list_page.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF0F172A);     
    const Color primary = Color(0xFFC2BBF0);    // primary color
    const Color secondary = Color(0xFFEE6352);  // secondary color

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
      home: const HomePage(),
    );
  }
}
