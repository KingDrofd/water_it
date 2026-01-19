import 'package:flutter/material.dart';

class HomeReminderItem {
  final String plantName;
  final String task;
  final DateTime dueAt;
  final IconData icon;
  final String plantId;

  const HomeReminderItem({
    required this.plantId,
    required this.plantName,
    required this.task,
    required this.dueAt,
    required this.icon,
  });
}
