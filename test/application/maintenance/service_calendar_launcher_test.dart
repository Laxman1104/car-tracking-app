import 'package:car_tracking_app/application/maintenance/service_calendar_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('car_tracker/service_calendar');

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('opens Android calendar with title, date, and mileage target', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    MethodCall? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          captured = call;
          return null;
        });
    final target = DateTime.utc(2027, 9, 10);

    await const PlatformServiceCalendarLauncher().addServiceReminder(
      title: 'Tyre Rotation',
      targetDate: target,
      targetOdometerKm: 5000,
    );

    final localDate = target.toLocal();
    final expectedStart = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      9,
    );
    expect(captured?.method, 'addServiceReminder');
    expect(captured?.arguments['title'], 'Tyre Rotation');
    expect(
      captured?.arguments['startMillis'],
      expectedStart.millisecondsSinceEpoch,
    );
    expect(captured?.arguments['description'], contains('5000 km'));
  });
}
