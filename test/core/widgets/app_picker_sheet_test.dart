import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/core/theme/app_theme.dart';
import 'package:water_it/core/widgets/pickers/app_picker_sheet.dart';

enum _Size { small, large }

void main() {
  const options = [
    AppPickerOption<_Size?>(value: null, label: 'Not set'),
    AppPickerOption<_Size?>(value: _Size.small, label: 'Small'),
    AppPickerOption<_Size?>(value: _Size.large, label: 'Large'),
  ];

  Widget harness({
    required _Size? value,
    required ValueChanged<_Size?> onChanged,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: AppSelectField<_Size>(
          label: 'Size',
          value: value,
          options: options,
          onChanged: onChanged,
        ),
      ),
    );
  }

  testWidgets('shows the placeholder until a value is chosen', (tester) async {
    await tester.pumpWidget(harness(value: null, onChanged: (_) {}));

    expect(find.text('Size'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('picking a value reports it', (tester) async {
    _Size? picked;
    var calls = 0;
    await tester.pumpWidget(harness(
      value: null,
      onChanged: (v) {
        picked = v;
        calls++;
      },
    ));

    await tester.tap(find.text('Not set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();

    expect(picked, _Size.large);
    expect(calls, 1);
  });

  testWidgets('choosing "Not set" clears the value', (tester) async {
    _Size? picked = _Size.large;
    var calls = 0;
    await tester.pumpWidget(harness(
      value: _Size.large,
      onChanged: (v) {
        picked = v;
        calls++;
      },
    ));

    await tester.tap(find.text('Large').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not set').last);
    await tester.pumpAndSettle();

    expect(calls, 1, reason: 'clearing must report a change');
    expect(picked, isNull);
  });

  testWidgets('dismissing the sheet changes nothing', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      harness(value: _Size.small, onChanged: (_) => calls++),
    );

    await tester.tap(find.text('Small').first);
    await tester.pumpAndSettle();
    // Tap the scrim above the sheet.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });
}
