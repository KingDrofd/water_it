import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/presentation/widgets/care_task_widgets.dart';

void main() {
  group('CareTaskSection', () {
    testWidgets('lists tasks with schedule summaries and paused state',
        (tester) async {
      const tasks = [
        CareTask(
          id: 't1',
          plantId: 'p1',
          type: CareTaskType.water,
          weekdays: [1, 4],
        ),
        CareTask(
          id: 't2',
          plantId: 'p1',
          type: CareTaskType.fertilize,
          scheduleType: CareScheduleType.interval,
          intervalDays: 30,
          active: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CareTaskSection(
              tasks: tasks,
              onAdd: () {},
              onTapTask: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Mon, Thu'), findsOneWidget);
      expect(find.text('Fertilize'), findsOneWidget);
      expect(find.text('Every 30 days'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
    });

    testWidgets('empty state offers the add button', (tester) async {
      var added = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CareTaskSection(
              tasks: const [],
              onAdd: () => added = true,
              onTapTask: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('No care tasks yet.'), findsOneWidget);
      await tester.tap(find.text('Add task'));
      expect(added, isTrue);
    });
  });

  group('care task editor', () {
    // Pumps a host page, opens the editor sheet, and returns the future that
    // resolves with the sheet's result when it closes.
    Future<Future<CareTaskEditorResult?>> pumpAndOpen(
      WidgetTester tester, {
      CareTask? existing,
    }) async {
      late Future<CareTaskEditorResult?> pending;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  pending = showCareTaskEditor(
                    context,
                    plantId: 'p1',
                    existing: existing,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return pending;
    }

    testWidgets('weekly schedule requires at least one day', (tester) async {
      final futureResult = await pumpAndOpen(tester);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Pick at least one day.'), findsOneWidget);

      await tester.tap(find.text('Mon'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final result = await futureResult;
      expect(result, isNotNull);
      expect(result!.deleted, isFalse);
      expect(result.task.type, CareTaskType.water);
      expect(result.task.scheduleType, CareScheduleType.weekly);
      expect(result.task.weekdays, [1]);
      expect(result.task.plantId, 'p1');
      expect(result.task.id, isNotEmpty);
    });

    testWidgets('interval schedule saves the day count', (tester) async {
      final futureResult = await pumpAndOpen(tester);

      await tester.tap(find.text('Fertilize'));
      await tester.pump();
      await tester.tap(find.text('Every N days'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, '30');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final result = await futureResult;
      expect(result!.task.type, CareTaskType.fertilize);
      expect(result.task.scheduleType, CareScheduleType.interval);
      expect(result.task.intervalDays, 30);
    });

    testWidgets('editing an existing task offers delete', (tester) async {
      const existing = CareTask(
        id: 't-old',
        plantId: 'p1',
        type: CareTaskType.prune,
        weekdays: [6],
      );
      final futureResult = await pumpAndOpen(tester, existing: existing);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      final result = await futureResult;
      expect(result!.deleted, isTrue);
      expect(result.task.id, 't-old');
    });
  });
}
