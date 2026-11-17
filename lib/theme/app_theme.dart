import 'package:flutter/material.dart';

/// Shared tokens for the light and dark palettes.
class AppTheme {
  static const Color primary = Color(0xFFC65A2E);
  static bool _darkMode = false;

  static void setDarkMode(bool value) => _darkMode = value;

  static Color get secondary =>
      _darkMode ? const Color(0xFF91B6A3) : const Color(0xFF315B50);
  static Color get success =>
      _darkMode ? const Color(0xFF8BC6A2) : const Color(0xFF2D755C);
  static Color get warning =>
      _darkMode ? const Color(0xFFE4B763) : const Color(0xFFAD6B1F);
  static Color get danger =>
      _darkMode ? const Color(0xFFF08B7F) : const Color(0xFFB4473D);
  static Color get background =>
      _darkMode ? const Color(0xFF121613) : const Color(0xFFF4F1EA);
  static Color get cardBg =>
      _darkMode ? const Color(0xFF1B211D) : const Color(0xFFFFFEFA);
  static Color get surface =>
      _darkMode ? const Color(0xFF252C27) : const Color(0xFFEAE5DA);
  static Color get textLight =>
      _darkMode ? const Color(0xFFF3F1EA) : const Color(0xFF262A27);
  static Color get textMuted =>
      _darkMode ? const Color(0xFFB4BDB5) : const Color(0xFF686D66);
  static Color get border =>
      _darkMode ? const Color(0xFF39433C) : const Color(0xFFE3DED3);

  static ThemeData get lightTheme => _buildTheme(dark: false);
  static ThemeData get darkTheme => _buildTheme(dark: true);

  static ThemeData _buildTheme({required bool dark}) {
    final colors = dark
        ? ColorScheme.dark(
            primary: primary,
            onPrimary: Colors.white,
            secondary: secondary,
            onSecondary: const Color(0xFF132019),
            surface: cardBg,
            onSurface: textLight,
            error: danger,
            onError: const Color(0xFF2A100D),
            outline: border,
          )
        : ColorScheme.light(
            primary: primary,
            onPrimary: Colors.white,
            secondary: secondary,
            onSecondary: Colors.white,
            surface: cardBg,
            onSurface: textLight,
            error: danger,
            onError: Colors.white,
            outline: border,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textLight),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: cardBg,
        indicatorColor:
            dark ? const Color(0xFF3A2A21) : const Color(0xFFF3E4D9),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? primary : textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : textMuted,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textLight,
          side: BorderSide(color: border),
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: danger),
        ),
        labelStyle: TextStyle(color: textMuted, fontSize: 14),
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
            color: textLight,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7),
        titleLarge: TextStyle(
            color: textLight, fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(
            color: textLight, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textLight, fontSize: 16),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14),
        labelLarge: TextStyle(
            color: textLight, fontSize: 14, fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textLight,
        contentTextStyle: TextStyle(color: background),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
