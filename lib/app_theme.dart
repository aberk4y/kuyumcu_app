import 'package:flutter/material.dart';

class AppColors {
  static const Color royal = Color(0xFF2A179D);
  static const Color royalDark = Color(0xFF1A0F6C);
  static const Color accent = Color(0xFFF4C542);
  static const Color success = Color(0xFF28B463);
  static const Color danger = Color(0xFFE74C3C);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F5F9);
  static const Color textPrimary = Color(0xFF20304A);
  static const Color textMuted = Color(0xFF7A879B);
  static const Color line = Color(0xFFE1E5EF);
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.royal,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    dividerColor: AppColors.line,
  );
}
