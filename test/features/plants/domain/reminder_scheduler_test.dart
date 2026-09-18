import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_it/core/notifications/notification_service.dart';
import 'package:water_it/core/notifications/reminder_plan.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/repositories/care_log_repository.dart';
import 'package:water_it/features/plants/domain/repositories/care_task_repository.dart';
import 'package:water_it/features/plants/domain/services/reminder_planner.dart';
import 'package:water_it/features/plants/domain/services/reminder_scheduler.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';

class MockGetPlants extends Mock implements GetPlants {}

class MockCareTaskRepository extends Mock implements CareTaskRepository {}

class MockCareLogRepository extends Mock implements CareLogRepository {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockGetPlants getPlants;
  late MockCareTaskRepository taskRepository;
  late MockCareLogRepository logRepository;
  late MockNotificationService notificationService;
  late ReminderScheduler scheduler;

  setUpAll(() {
    registerFallbackValue(<ReminderPlan>[]);
  });

  setUp(() {
    getPlants = MockGetPlants();
    taskRepository = MockCareTaskRepository();
    logRepository = MockCareLogRepository();
    notificationService = MockNotificationService();
    when(() => notificationService.cancelAll()).thenAnswer((_) async {});
    when(() => notificationService.applySchedule(any()))
        .thenAnswer((_) async {});
    when(() => getPlants())
        .thenAnswer((_) async => const [Plant(id: 'p1', name: 'Monstera')]);
    when(() => taskRepository.getAllTasks()).thenAnswer(
      (_) async => const [
        CareTask(id: 't1', plantId: 'p1', weekdays: [1, 2, 3, 4, 5, 6, 7]),
      ],
    );
    when(() => logRepository.getLatestEvents()).thenAnswer((_) async => {});
    scheduler = ReminderScheduler(
      getPlants,
      taskRepository,
      logRepository,
      notificationService,
    );
  });

  test('disabled reminders cancel everything and schedule nothing', () async {
    SharedPreferences.setMockInitialValues(
      {'settings_notify_watering_reminders': false},
    );

    await scheduler.rescheduleAll();

    verify(() => notificationService.cancelAll()).called(1);
    verifyNever(() => notificationService.applySchedule(any()));
  });

  test('enabled reminders schedule task plans without summary by default',
      () async {
    SharedPreferences.setMockInitialValues({});

    await scheduler.rescheduleAll();

    final plans = verify(() => notificationService.applySchedule(captureAny()))
        .captured
        .single as List<ReminderPlan>;
    expect(plans.length, 7); // one per weekday
    expect(
      plans.any((p) => p.id == ReminderPlanner.dailySummaryId),
      isFalse,
    );
  });

  test('daily summary toggle adds the summary plan', () async {
    SharedPreferences.setMockInitialValues(
      {'settings_notify_daily_summary': true},
    );

    await scheduler.rescheduleAll();

    final plans = verify(() => notificationService.applySchedule(captureAny()))
        .captured
        .single as List<ReminderPlan>;
    expect(
      plans.any((p) => p.id == ReminderPlanner.dailySummaryId),
      isTrue,
    );
  });
}
