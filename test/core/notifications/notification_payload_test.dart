import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/core/notifications/notification_payload.dart';

void main() {
  test('encode/decode round-trips every field', () {
    const payload = NotificationPayload(
      plantId: 'p1',
      taskId: 't1',
      type: 'fertilize',
      title: 'Fertilize Basil',
      body: 'Half strength',
      hour: 18,
      minute: 30,
      intervalDays: 10,
    );

    final decoded = NotificationPayload.decode(payload.encode());

    expect(decoded!.plantId, 'p1');
    expect(decoded.taskId, 't1');
    expect(decoded.type, 'fertilize');
    expect(decoded.title, 'Fertilize Basil');
    expect(decoded.body, 'Half strength');
    expect(decoded.hour, 18);
    expect(decoded.minute, 30);
    expect(decoded.intervalDays, 10);
  });

  test('decode tolerates null, empty, and garbage input', () {
    expect(NotificationPayload.decode(null), isNull);
    expect(NotificationPayload.decode(''), isNull);
    expect(NotificationPayload.decode('not json'), isNull);
  });
}
