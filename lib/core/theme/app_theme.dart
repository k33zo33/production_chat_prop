import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _seedColor = Color(0xFF155EEF);
  static const _scaffoldColor = Color(0xFFF7F8FB);
  static const _cardBorderColor = Color(0xFFE7ECF5);
  static const _fieldBorderColor = Color(0xFFD7DFEE);
  static const _headlineColor = Color(0xFF101828);
  static const _bodyColor = Color(0xFF344054);
  static const _mutedBodyColor = Color(0xFF667085);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor);
    final baseTheme = ThemeData(useMaterial3: true, colorScheme: colorScheme);
    final textTheme = baseTheme.textTheme.copyWith(
      headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
        color: _headlineColor,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
        color: _headlineColor,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
        color: _headlineColor,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
        color: _headlineColor,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
        color: _headlineColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
        color: _bodyColor,
        height: 1.45,
      ),
      bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
        color: _bodyColor,
        height: 1.45,
      ),
      bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
        color: _mutedBodyColor,
        height: 1.4,
      ),
      labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
        color: _headlineColor,
        fontWeight: FontWeight.w600,
      ),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: _cardBorderColor),
    );

    return baseTheme.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: _scaffoldColor,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: _scaffoldColor,
        foregroundColor: _headlineColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _cardBorderColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: dialogShape,
      ),
      dividerTheme: const DividerThemeData(
        color: _cardBorderColor,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: textTheme.bodyMedium?.copyWith(color: _mutedBodyColor),
        labelStyle: textTheme.bodyMedium?.copyWith(color: _mutedBodyColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _fieldBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _fieldBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
          side: const BorderSide(color: _fieldBorderColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: _fieldBorderColor),
        backgroundColor: Colors.white,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: const Color(0xFFF1F4FA),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: _bodyColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
