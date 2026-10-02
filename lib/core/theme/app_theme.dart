import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_scale.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  /// Both themes come from one builder over the design tokens, so light and
  /// dark can't drift apart the way the old seed-generated dark theme did.
  static ThemeData _build(AppPalette p, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      // The brand green is light in both themes, so text on it is always dark.
      onPrimary: brightness == Brightness.light ? p.ink : p.onAccent,
      primaryContainer: p.container,
      onPrimaryContainer: p.ink,
      secondary: p.accent,
      onSecondary: p.onAccent,
      secondaryContainer: p.container,
      onSecondaryContainer: p.ink,
      tertiary: p.amber,
      onTertiary: p.ink,
      tertiaryContainer: p.nudgeBg,
      onTertiaryContainer: p.nudgeInk,
      error: p.overdueInk,
      onError: p.bg,
      errorContainer: p.overdueBg,
      onErrorContainer: p.overdueInk,
      surface: p.card,
      onSurface: p.ink,
      surfaceContainerLowest: p.bg,
      surfaceContainerLow: p.bg,
      surfaceContainer: p.card,
      surfaceContainerHigh: p.card2,
      surfaceContainerHighest: p.card2,
      onSurfaceVariant: p.muted,
      outline: p.line,
      outlineVariant: p.line,
      shadow: p.shadow,
      inverseSurface: p.ink,
      onInverseSurface: p.bg,
      inversePrimary: p.deep,
    );

    final textTheme = AppTypography.lightTextTheme(p.ink).apply(
      bodyColor: p.ink,
      displayColor: p.ink,
    );

    OutlineInputBorder border([Color? color]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: color == null
              ? BorderSide.none
              : BorderSide(color: color, width: 1.5),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      cardColor: p.card,
      dividerColor: p.line,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(),
        enabledBorder: border(),
        focusedBorder: border(p.primary),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: p.muted,
          fontFamily: AppTypography.titleFont,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: textTheme.labelLarge?.copyWith(
          color: p.deep,
          fontFamily: AppTypography.titleFont,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.muted),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.accent,
        side: BorderSide(color: p.line),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge?.copyWith(color: p.ink),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: p.onAccent),
        checkmarkColor: p.onAccent,
        showCheckmark: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.deep,
          side: BorderSide(color: p.line),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.deep),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.line,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.onAccent;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.accent;
          }
          return null;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.bg),
        behavior: SnackBarBehavior.floating,
      ),
      // Material surfaces the app still uses, brought onto the design's
      // rounded, tokenised look so nothing renders with stock corners.
      popupMenuTheme: PopupMenuThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.line),
        ),
        textStyle: textTheme.titleSmall,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.card),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: p.line),
            ),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.titleSmall,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.card),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: p.line),
            ),
          ),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        dialBackgroundColor: p.card2,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        hourMinuteTextStyle: textTheme.headlineSmall,
        helpTextStyle: textTheme.labelLarge?.copyWith(color: p.muted),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          side: WidgetStatePropertyAll(BorderSide(color: p.line)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? p.container : p.card,
          ),
          foregroundColor: WidgetStatePropertyAll(p.ink),
        ),
      ),
      iconTheme: IconThemeData(color: p.ink),
      extensions: [const AppSpacing(), p],
    );
  }

  static TextScaler textScalerForWidth(double width) {
    return AppTextScale.scalerForWidth(width);
  }
}
