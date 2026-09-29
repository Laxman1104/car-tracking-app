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
    await _plugin.cancel(id: maintenanceRecordId * 100 + 7);
    for (final stage in const [80, 90, 100]) {
      await _plugin.cancel(id: maintenanceRecordId * 100 + stage);
    }
  }

  @override
  Future<void> schedule({
    required int maintenanceRecordId,
    required DateTime targetDate,
    required String title,
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
    final dueDate = tz.TZDateTime(
      tz.local,
      localDate.year,
      localDate.month,
      localDate.day,
      9,
    );
    final oneWeekBefore = dueDate.subtract(const Duration(days: 7));
    final now = tz.TZDateTime.now(tz.local);
    if (oneWeekBefore.isAfter(now)) {
      await _scheduleDateAlert(
        id: maintenanceRecordId * 100 + 7,
        maintenanceRecordId: maintenanceRecordId,
        title: title,
        body: 'Due in one week.',
        scheduledDate: oneWeekBefore,
      );
    }
    if (dueDate.isAfter(now)) {
      await _scheduleDateAlert(
        id: maintenanceRecordId * 100 + 1,
        maintenanceRecordId: maintenanceRecordId,
        title: title,
        body: 'Due today.',
        scheduledDate: dueDate,
      );
    }
  }

  Future<void> _scheduleDateAlert({
    required int id,
    required int maintenanceRecordId,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: scheduledDate,
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
