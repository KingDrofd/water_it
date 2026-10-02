import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/features/home/presentation/pages/home_page.dart';

void main() {
  test('greets by time of day', () {
    expect(greetingFor(DateTime(2026, 9, 21, 7), null), 'Good morning');
    expect(greetingFor(DateTime(2026, 9, 21, 13), null), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 9, 21, 20), null), 'Good evening');
  });

  test('adds the name only when one is set', () {
    final morning = DateTime(2026, 9, 21, 9);

    expect(greetingFor(morning, 'Sam'), 'Good morning, Sam');
    expect(greetingFor(morning, '  '), 'Good morning');
    expect(greetingFor(morning, ' Sam '), 'Good morning, Sam');
  });
}
