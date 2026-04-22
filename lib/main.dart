import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'splash_screen.dart';

void main() {
  runApp(const KuyumcuApp());
}

class KuyumcuApp extends StatelessWidget {
  const KuyumcuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aslanoğlu Kuyumculuk',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
    );
  }
}
