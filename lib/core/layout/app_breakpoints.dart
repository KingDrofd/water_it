enum AppSizeClass { compact, medium, expanded }

class AppBreakpoints {
  static const double medium = 600;
  static const double expanded = 1024;

  static AppSizeClass sizeClass(double width) {
    if (width >= expanded) {
      return AppSizeClass.expanded;
    }
    if (width >= medium) {
      return AppSizeClass.medium;
    }
    return AppSizeClass.compact;
  }

  static bool isCompact(double width) => sizeClass(width) == AppSizeClass.compact;
  static bool isMedium(double width) => sizeClass(width) == AppSizeClass.medium;
  static bool isExpanded(double width) => sizeClass(width) == AppSizeClass.expanded;
}
