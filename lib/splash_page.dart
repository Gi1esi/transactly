import 'package:flutter/material.dart';
import 'user_dao.dart';
import 'home.dart';
import 'register.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 2)); // short splash delay
    final userDao = UserDao();
    final users = await userDao.getAllUsers();

    if (!mounted) return;

    if (users.isEmpty) {
      // No user → go to register/login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterPage()),
      );
    } else {
      // User exists → go to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // you can remove this image to make it "no picture"
            Image.asset(
              'assets/images/accounting.png',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 30),
            Text(
              'Transactly',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Track and manage your finances effortlessly',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(), // shows loading until navigation
          ],
        ),
      ),
    );
  }
}
