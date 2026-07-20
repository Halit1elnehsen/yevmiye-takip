import 'package:flutter/material.dart';

class AppTheme {
  // Renk Paleti
  static const Color primary = Color(0xFFFF6B35); // İnşaat Turuncusu
  static const Color secondary = Color(0xFF004E89); // Koyu Mavi
  static const Color success = Color(0xFF2ECC71); // Yeşil (Tamamlandı)
  static const Color warning = Color(0xFFF39C12); // Sarı (Avans)
  static const Color danger = Color(0xFFE74C3C); // Kırmızı (Sil/Gelmedi)
  static const Color background = Color(0xFF1A1A2E); // Ana Arka Plan
  static const Color cardBg = Color(0xFF16213E); // Kart Arka Planı
  static const Color surface = Color(0xFF0F3460); // Yüzey Rengi
  static const Color textLight = Color(0xFFFFFFFF); // Açık Yazı
  static const Color textMuted = Color(0xFFB5B5C3); // Silik Yazı

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: cardBg,
        error: danger,
        onPrimary: textLight,
        onSecondary: textLight,
        onSurface: textLight,
        onError: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textLight),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textLight,
          minimumSize: const Size.fromHeight(50), // Normal modern boyut
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textLight,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textLight, fontSize: 28, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textLight, fontSize: 16),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14),
        labelLarge: TextStyle(color: textLight, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: cardBg,
        contentTextStyle: TextStyle(color: textLight),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
