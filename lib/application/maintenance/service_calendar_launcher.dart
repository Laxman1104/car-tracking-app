import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class ServiceCalendarLauncher {
  Future<void> addServiceReminder({
    required String title,
    required DateTime targetDate,
    int? targetOdometerKm,
  });
}

class PlatformServiceCalendarLauncher implements ServiceCalendarLauncher {
  const PlatformServiceCalendarLauncher();

  static const _channel = MethodChannel('car_tracker/service_calendar');

  @override
  Future<void> addServiceReminder({
    required String title,
    required DateTime targetDate,
    int? targetOdometerKm,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'Calendar export is currently available on Android.',
      );
    }
    final localDate = targetDate.toLocal();
    final start = DateTime(localDate.year, localDate.month, localDate.day, 9);
    await _channel.invokeMethod<void>('addServiceReminder', {
      'title': title,
      'startMillis': start.millisecondsSinceEpoch,
      'description': targetOdometerKm == null
          ? 'Service reminder from Car Tracker.'
          : 'Service reminder from Car Tracker. Mileage target: '
                '$targetOdometerKm km.',
    });
  }
}
