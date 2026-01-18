import 'package:flutter/material.dart';

class AppTypography {
  static const String displayFont = 'Pacifico';
  static const String titleFont = 'Quicksand';
  static const String bodyFont = 'Raleway';

  static TextTheme lightTextTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 34,
        fontWeight: FontWeight.w400,
        height: 1.1,
        color: color,
      ),
      displayMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.1,
        color: color,
      ),
      displaySmall: TextStyle(
        fontFamily: displayFont,
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.15,
        color: color,
      ),
      headlineLarge: TextStyle(
        fontFamily: titleFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontFamily: titleFont,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontFamily: titleFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: color,
      ),
      titleLarge: TextStyle(
        fontFamily: titleFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: color,
      ),
      titleMedium: TextStyle(
        fontFamily: titleFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: color,
      ),
      titleSmall: TextStyle(
        fontFamily: titleFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: color,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      ),
      labelLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      ),
    );
  }
}
