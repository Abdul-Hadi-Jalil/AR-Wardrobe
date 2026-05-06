import 'package:ar_wardrobe_frontend/screens/login_screen.dart';
import 'package:ar_wardrobe_frontend/screens/register_screen.dart';
import 'package:flutter/material.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  bool inLoginScreen = true;

  void toggleScreen() {
    setState(() {
      inLoginScreen = !inLoginScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (inLoginScreen) {
      return LoginScreen(onToggleScreen: toggleScreen);
    } else {
      return RegisterScreen(onToggleScreen: toggleScreen);
    }
  }
}
