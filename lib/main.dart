import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/home.dart';
import 'pages/splash_page.dart';
import 'dao/bank_dao.dart';
import 'utils/database_helper.dart';
import 'dao/user_dao.dart';
import 'utils/read_sms.dart';
import 'utils/transactions_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    const Color darkBg = Color(0xFFFFFFFF);     
    const Color primary = Color(0xFF087CA7);  
    const Color secondary = Color(0xFFFF644F); 

   return MaterialApp(
  title: 'Bank SMS Summarizer',
  theme: ThemeData(
    brightness: Brightness.light, 
    scaffoldBackgroundColor: darkBg,
    primaryColor: primary,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: const Color(0xFFFFFFFF),
      onSurface: Colors.black87, // darker text on white surfaces
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.black87,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: primary,
      unselectedItemColor: Colors.black54,
    ),
    cardColor: Colors.white,
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    ),
  ),
  home: SplashScreen(),
);

  }
}
