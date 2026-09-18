import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/features/plants/presentation/widgets/plant_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 300, child: child))),
    );
  }

  testWidgets('shows the overdue badge when overdue', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PlantCard(
          name: 'Monstera',
          subtitle: 'Bright indirect',
          schedule: 'Mon, Thu',
          layout: PlantCardLayout.list,
          isOverdue: true,
        ),
      ),
    );

    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('hides the overdue badge by default', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PlantCard(
          name: 'Monstera',
          subtitle: 'Bright indirect',
          schedule: 'Mon, Thu',
          layout: PlantCardLayout.list,
        ),
      ),
    );

    expect(find.text('Overdue'), findsNothing);
  });

  testWidgets('grid layout places the badge over the image', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          height: 300,
          child: PlantCard(
            name: 'Monstera',
            subtitle: 'Bright indirect',
            schedule: 'Mon, Thu',
            layout: PlantCardLayout.grid,
            isOverdue: true,
          ),
        ),
      ),
    );

    expect(find.text('Overdue'), findsOneWidget);
  });
}
