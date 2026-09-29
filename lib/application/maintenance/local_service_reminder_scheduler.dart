import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'maintenance_record_service.dart';

class LocalServiceReminderScheduler implements ServiceReminderScheduler {
  LocalServiceReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  @override
  Future<void> cancel(int maintenanceRecordId) async {
    await initialize();
    await _plugin.cancel(id: maintenanceRecordId);
    await _plugin.cancel(id: maintenanceRecordId * 100 + 1);
    for (final stage in const [80, 90, 100]) {
      await _plugin.cancel(id: maintenanceRecordId * 100 + stage);
    }
  }

  @override
  Future<void> schedule({
    required int maintenanceRecordId,
    required DateTime targetDate,
  }) async {
    await initialize();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final allowed = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (allowed == false) return;
    }
    final localDate = targetDate.toLocal();
    final scheduled = tz.TZDateTime(
      tz.local,
      localDate.year,
      localDate.month,
      localDate.day,
      9,
    );
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: maintenanceRecordId * 100 + 1,
      title: 'Service reminder',
      body: 'Your next whole-service target is due today.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'service_reminders',
          'Service reminders',
          channelDescription: 'Date reminders for the next whole service',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'maintenance:$maintenanceRecordId',
    );
  }

  @override
  Future<void> showMileageProgress({
    required int maintenanceRecordId,
    required String title,
    required int stagePercent,
    required int currentOdometerKm,
    required int targetOdometerKm,
  }) async {
    await initialize();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final allowed = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (allowed == false) return;
    }
    final body = stagePercent >= 100
        ? 'Due now at $targetOdometerKm km.'
        : '$stagePercent% of the mileage interval reached. Current odometer: '
              '$currentOdometerKm km; target: $targetOdometerKm km.';
    await _plugin.show(
      id: maintenanceRecordId * 100 + stagePercent,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'service_mileage_reminders',
          'Service mileage reminders',
          channelDescription: 'Mileage progress alerts for upcoming services',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'maintenance:$maintenanceRecordId',
    );
  }
}
