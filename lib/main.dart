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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank SMS Summarizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,          // ← your main theme color
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: Colors.blueAccent,      // ← accent color if you need it
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,      // ← ensures all AppBars are blue
          foregroundColor: Colors.white,     // ← text/icon color in AppBar
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.blue,      // ← nav bar background
          selectedItemColor: Colors.white,   // ← selected icon/text color
          unselectedItemColor: Colors.white70,
        ),
      ),
      home: HomePage(),
    );
  }
}

