import 'package:flutter/material.dart';

abstract final class CoolCareColors {
  static const primary = Color(0xFF078B96);
  static const primaryDark = Color(0xFF066E77);
  static const surfaceTint = Color(0xFFE9F7F7);
  static const background = Color(0xFFFFFFFF);
  static const text = Color(0xFF17333A);
  static const mutedText = Color(0xFF718087);
  static const border = Color(0xFFE1E8EA);
  static const error = Color(0xFFB42318);
}

abstract final class CoolCareTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: CoolCareColors.primary,
      brightness: Brightness.light,
      surface: Colors.white,
      error: CoolCareColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CoolCareColors.background,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: CoolCareColors.text,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          height: 1.15,
          letterSpacing: -0.6,
        ),
        titleMedium: TextStyle(
          color: CoolCareColors.text,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: CoolCareColors.text, height: 1.45),
        bodyMedium: TextStyle(color: CoolCareColors.mutedText, height: 1.45),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CoolCareColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CoolCareColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: CoolCareColors.primary,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CoolCareColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CoolCareColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CoolCareColors.primaryDark,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CoolCareColors.primary,
      ),
    );
  }
}
