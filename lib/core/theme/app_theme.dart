import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_scale.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.ink,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onDark,
      secondaryContainer: AppColors.primaryContainer,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.accentSoft,
      onTertiary: AppColors.ink,
      tertiaryContainer: AppColors.accent,
      onTertiaryContainer: AppColors.ink,
      error: const Color(0xFFB00020),
      onError: AppColors.onDark,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceVariant: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.outline,
      shadow: Colors.black,
      inverseSurface: const Color(0xFF1B1B1B),
      onInverseSurface: AppColors.onDark,
      inversePrimary: AppColors.primary,
    );

    final textTheme = AppTypography.lightTextTheme(AppColors.ink).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.outline,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(color: AppColors.muted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
      extensions: const [AppSpacing()],
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: AppTypography.lightTextTheme(Colors.white).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      extensions: const [AppSpacing()],
    );
  }

  static TextScaler textScalerForWidth(double width) {
    return AppTextScale.scalerForWidth(width);
  }
}
