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
          Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Top Section with Icon
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              height: size.height * 0.55,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/accounting.png',
                    width: 160,
                    height: 160,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Wave Section
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                color: primary,
                height: size.height * 0.55,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Transactly',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                        color: Colors.white,
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
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();

    path.moveTo(0, 0); // top-left corner
    // create a downward wave by making the curve dip below y=0
    path.quadraticBezierTo(
      size.width * 0.25, 40,  // control point lower than 0 (dips down)
      size.width * 0.5, 20,   // wave bottom point (dips down)
    );
    path.quadraticBezierTo(
      size.width * 0.75, 0,   // control point comes back up to 0
      size.width, 20,         // end of wave dips down a bit
    );

    path.lineTo(size.width, size.height); // down right edge
    path.lineTo(0, size.height);           // bottom edge
    path.close();                         // close path back to start

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
