import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/theme/app_theme.dart';

void main() {
  group('AppTheme.lightTheme', () {
    final theme = AppTheme.lightTheme;

    test('uses polished typography and floating feedback surfaces', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F8FB));
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
      expect(theme.dialogTheme.surfaceTintColor, Colors.transparent);
    });

    test('keeps stronger title hierarchy and readable body contrast', () {
      expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w700);
      expect(theme.textTheme.titleMedium?.fontWeight, FontWeight.w600);
      expect(theme.textTheme.bodyMedium?.color, const Color(0xFF344054));
      expect(theme.textTheme.bodySmall?.color, const Color(0xFF667085));
    });

    test('applies consistent button sizing and field chrome', () {
      final filledStyle = theme.filledButtonTheme.style;
      final outlinedStyle = theme.outlinedButtonTheme.style;
      final textStyle = theme.textButtonTheme.style;

      expect(filledStyle?.minimumSize?.resolve({}), const Size(0, 48));
      expect(outlinedStyle?.minimumSize?.resolve({}), const Size(0, 48));
      expect(textStyle?.minimumSize?.resolve({}), const Size(0, 48));
      expect(theme.dividerTheme.space, 1);
      expect(theme.inputDecorationTheme.fillColor, Colors.white);
      expect(
        theme.inputDecorationTheme.enabledBorder,
        isA<OutlineInputBorder>(),
      );
      final errorBorder = theme.inputDecorationTheme.errorBorder;
      final focusedErrorBorder = theme.inputDecorationTheme.focusedErrorBorder;

      expect(errorBorder, isA<OutlineInputBorder>());
      expect(focusedErrorBorder, isA<OutlineInputBorder>());

      if (errorBorder case final OutlineInputBorder border) {
        expect(border.borderSide.color, theme.colorScheme.error);
        expect(border.borderSide.width, 1);
      } else {
        fail('Expected an OutlineInputBorder for errorBorder.');
      }

      if (focusedErrorBorder case final OutlineInputBorder border) {
        expect(border.borderSide.color, theme.colorScheme.error);
        expect(border.borderSide.width, 1.4);
      } else {
        fail('Expected an OutlineInputBorder for focusedErrorBorder.');
      }
      expect(theme.chipTheme.showCheckmark, isFalse);
    });
  });
}
