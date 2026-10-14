import 'package:flutter/material.dart';

abstract final class CoolCareColors {
  static const primary = Color(0xFF078B96);
  static const primaryDark = Color(0xFF066E77);
  static const surfaceTint = Color(0xFFE9F7F7);
  static const background = Color(0xFFF5F7F8);
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
      canvasColor: CoolCareColors.background,
      dividerColor: CoolCareColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: CoolCareColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: CoolCareColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: CoolCareColors.surfaceTint,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? CoolCareColors.primaryDark
                : CoolCareColors.mutedText,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
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
        filled: true,
        fillColor: const Color(0xFFF8FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CoolCareColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CoolCareColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: CoolCareColors.primary,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: CoolCareColors.primary,
      brightness: Brightness.dark,
      surface: const Color(0xFF102238),
      error: const Color(0xFFFFB4AB),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF071426),
      cardColor: const Color(0xFF102238),
      dividerColor: const Color(0xFF29415A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF102238),
        foregroundColor: Color(0xFFF3F7FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF102238),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF102238),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF102238),
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF102238),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF102238),
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF173951),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF8FE1E5)
                : const Color(0xFF9FB0C6),
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Color(0xFFF3F7FC),
          fontWeight: FontWeight.w700,
          fontSize: 28,
          height: 1.15,
          letterSpacing: -0.6,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFF3F7FC),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: Color(0xFFE3EBF5), height: 1.45),
        bodyMedium: TextStyle(color: Color(0xFF9FB0C6), height: 1.45),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF132A43),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: CoolCareColors.primary,
            width: 1.6,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CoolCareColors.primary,
      ),
    );
  }
}

extension CoolCareThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get appSurface => Theme.of(this).colorScheme.surface;
  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get appText => Theme.of(this).colorScheme.onSurface;
  Color get appMuted =>
      isDarkMode ? const Color(0xFF9FB0C6) : CoolCareColors.mutedText;
  Color get appBorder =>
      isDarkMode ? const Color(0xFF29415A) : CoolCareColors.border;
  Color get appSoftSurface =>
      isDarkMode ? const Color(0xFF132A43) : const Color(0xFFF7FAFA);
  Color get appElevatedSurface =>
      isDarkMode ? const Color(0xFF102238) : Colors.white;
  Color get appAccentSurface =>
      isDarkMode ? const Color(0xFF173951) : CoolCareColors.surfaceTint;
  Color get appSubtleText =>
      isDarkMode ? const Color(0xFFB8C6D8) : const Color(0xFF496565);
}
