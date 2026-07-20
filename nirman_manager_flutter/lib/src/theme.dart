import 'package:flutter/material.dart';

/// Brand colours carried over from the Nirman Manager web app.
class AppColors {
  static const navy = Color(0xFF152A52);
  static const navy2 = Color(0xFF1F3A6E);
  static const orange = Color(0xFFE8622C);
  static const orangeDark = Color(0xFFC94E1E);
  static const bg = Color(0xFFF2F3F6);
  static const line = Color(0xFFE3E6EC);
  static const ink = Color(0xFF1B2333);
  static const inkSoft = Color(0xFF616B7C);
  static const green = Color(0xFF2E8B57);
  static const greenLight = Color(0xFFE4F3EA);
  static const amber = Color(0xFFD69F2E);
  static const amberLight = Color(0xFFFBF0DC);
  static const red = Color(0xFFC1442D);
  static const redLight = Color(0xFFF5E1DB);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      secondary: AppColors.orange,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.line),
      ),
      margin: const EdgeInsets.only(bottom: 10),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.navy, width: 2),
      ),
    ),
  );
}
