String formatWeekdays(List<int> days) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final ordered = days.toList()..sort();
  return ordered
      .where((day) => day >= 1 && day <= 7)
      .map((day) => labels[day - 1])
      .join(', ');
}
