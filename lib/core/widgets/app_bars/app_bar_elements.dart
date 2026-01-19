import 'package:flutter/material.dart';

class AppBarElements {
  final Widget? leading;
  final Widget title;
  final Widget? action;

  const AppBarElements({
    this.leading,
    required this.title,
    this.action,
  });
}
