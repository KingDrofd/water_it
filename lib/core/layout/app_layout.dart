import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

class AppLayout {
  static const double _navBarHeight = 72;
  static const double _navBarInsetPadding = 16;
  static const double _compactPadding = 16;
  static const double _mediumPadding = 24;
  static const double _expandedPadding = 32;

  static const double _compactGutter = 12;
  static const double _mediumGutter = 16;
  static const double _expandedGutter = 20;

  static const double _mediumMaxWidth = 640;
  static const double _expandedMaxWidth = 920;

  static EdgeInsets pagePadding(double width) {
    switch (AppBreakpoints.sizeClass(width)) {
      case AppSizeClass.compact:
        return const EdgeInsets.all(_compactPadding);
      case AppSizeClass.medium:
        return const EdgeInsets.all(_mediumPadding);
      case AppSizeClass.expanded:
        return const EdgeInsets.all(_expandedPadding);
    }
  }

  static double gutter(double width) {
    switch (AppBreakpoints.sizeClass(width)) {
      case AppSizeClass.compact:
        return _compactGutter;
      case AppSizeClass.medium:
        return _mediumGutter;
      case AppSizeClass.expanded:
        return _expandedGutter;
    }
  }

  static int columns(double width) {
    switch (AppBreakpoints.sizeClass(width)) {
      case AppSizeClass.compact:
        return 4;
      case AppSizeClass.medium:
        return 8;
      case AppSizeClass.expanded:
        return 12;
    }
  }

  static double maxContentWidth(double width) {
    switch (AppBreakpoints.sizeClass(width)) {
      case AppSizeClass.compact:
        return width;
      case AppSizeClass.medium:
        return _mediumMaxWidth.clamp(0, width);
      case AppSizeClass.expanded:
        return _expandedMaxWidth.clamp(0, width);
    }
  }

  static double scaleForWidth(
    double width, {
    double baseWidth = 390,
    double minScale = 0.95,
    double maxScale = 1.2,
  }) {
    if (width <= 0) {
      return 1.0;
    }

    final scale = width / baseWidth;
    return scale.clamp(minScale, maxScale);
  }

  static double navBarInset(double width, {double spacing = 0}) {
    final scale = scaleForWidth(width);
    return (_navBarHeight * scale) + (spacing + _navBarInsetPadding);
  }
}
