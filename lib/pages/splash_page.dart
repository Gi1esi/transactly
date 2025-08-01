import 'package:flutter/material.dart';
import '../dao/user_dao.dart';
import 'home.dart';
import 'register.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 5));
    final userDao = UserDao();
    final users = await userDao.getAllUsers();

    if (!mounted) return;

    if (users.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFeature(String text, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: primary, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/accounting.png',
              width: 160,
              height: 160,
            ),
            const SizedBox(height: 25),
            Text(
              'Transactly',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your money. Your insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),

          
            _buildFeature("Turns bank SMS into a live dashboard", primary),
            _buildFeature("Automatic tracking – no manual entry", primary),
            _buildFeature("Clear view of income vs expenses", primary),

            const SizedBox(height: 40),

           
            SizedBox(
              width: 100,
              height: 6,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _controller.value,
                    backgroundColor: Colors.white24,
                    color: primary,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
