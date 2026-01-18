import 'package:flutter/material.dart';

class AppTextScale {
  static const double baseWidth = 390;
  static const double minScale = 0.9;
  static const double maxScale = 1.1;

  static double forWidth(double width) {
    if (width <= 0) {
      return 1.0;
    }

    final scale = width / baseWidth;
    return scale.clamp(minScale, maxScale);
  }

  static TextScaler scalerForWidth(double width) {
    return TextScaler.linear(forWidth(width));
  }
}
