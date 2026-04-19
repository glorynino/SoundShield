import 'package:flutter/material.dart';
import 'screens/biometric_gate_screen.dart';
import 'screens/home_screen.dart'; // ton écran principal

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio App',
      theme: ThemeData.dark(),
      // BiometricGateScreen est le point d'entrée
      home: BiometricGateScreen(nextScreen: const HomeScreen()),
    );
  }
}