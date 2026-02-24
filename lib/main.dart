import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const KuyumcuApp());
}

class KuyumcuApp extends StatelessWidget {
  const KuyumcuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}