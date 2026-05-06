import 'package:ar_wardrobe_frontend/auth_state_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToAuthStateScreen();
  }

  Future<void> _navigateToAuthStateScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthStateScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E), // Dark blue/navy background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                children: const [
                  TextSpan(
                    text: 'AR ',
                    style: TextStyle(
                      color: Color(0xFF2ACAEA), // Bright blue/cyan
                    ),
                  ),
                  TextSpan(
                    text: '| ',
                    style: TextStyle(
                      color: Color(0xFF2ACAEA), // Bright blue/cyan
                    ),
                  ),
                  TextSpan(
                    text: 'Wardrobe',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Try Before You Buy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
