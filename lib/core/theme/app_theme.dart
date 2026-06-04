import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Custom Color Palettes - Dark Slate & Premium Teal
  static const Color primaryLight = Color(0xFF0D9488); // Teal 600
  static const Color primaryDark = Color(0xFF14B8A6);  // Teal 500
  
  static const Color secondaryLight = Color(0xFF0284C7); // Sky 600
  static const Color secondaryDark = Color(0xFF38BDF8);  // Sky 400

  // Neutral Colors Light
  static const Color bgLight = Color(0xFFF8FAFC);      // Slate 50
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600

  // Neutral Colors Dark
  static const Color bgDark = Color(0xFF0F172A);       // Slate 900
  static const Color cardDark = Color(0xFF1E293B);     // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC);  // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400

  // Accents
  static const Color accentRose = Color(0xFFF43F5E);    // Rose 500
  static const Color accentAmber = Color(0xFFF59E0B);   // Amber 500
  static const Color accentEmerald = Color(0xFF10B981); // Emerald 500

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        surface: bgLight,
        error: accentRose,
      ),
      scaffoldBackgroundColor: bgLight,
      cardTheme: CardTheme(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Slate 100
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: primaryLight, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: accentRose, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)), // Slate 400
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimaryLight, fontSize: 32.0, fontWeight: FontWeight.w800, letterSpacing: -1.0),
        headlineMedium: TextStyle(color: textPrimaryLight, fontSize: 24.0, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(color: textPrimaryLight, fontSize: 20.0, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimaryLight, fontSize: 16.0, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimaryLight, fontSize: 16.0),
        bodyMedium: TextStyle(color: textSecondaryLight, fontSize: 14.0),
        labelLarge: TextStyle(color: primaryLight, fontSize: 14.0, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        surface: bgDark,
        error: accentRose,
      ),
      scaffoldBackgroundColor: bgDark,
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: const BorderSide(color: Color(0xFF334155), width: 1.0), // Slate 700
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: bgDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B), // Slate 800
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: primaryDark, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: accentRose, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        hintStyle: const TextStyle(color: Color(0xFF64748B)), // Slate 500
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimaryDark, fontSize: 32.0, fontWeight: FontWeight.w800, letterSpacing: -1.0),
        headlineMedium: TextStyle(color: textPrimaryDark, fontSize: 24.0, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(color: textPrimaryDark, fontSize: 20.0, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimaryDark, fontSize: 16.0, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimaryDark, fontSize: 16.0),
        bodyMedium: TextStyle(color: textSecondaryDark, fontSize: 14.0),
        labelLarge: TextStyle(color: primaryDark, fontSize: 14.0, fontWeight: FontWeight.w600),
      ),
    );
  }
}
