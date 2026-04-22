import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.royalDark,
              AppColors.royal,
              Color(0xFF4E34D7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 32,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/logo.png'),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'ASLANOĞLU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 6,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Kuyumculuk',
                style: TextStyle(
                  color: Color(0xFFD9D4FF),
                  fontSize: 15,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
