import 'dart:async';

import '../../data/database/app_database.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../maintenance/maintenance_record_service.dart';

class VehicleLifecycleService {
  const VehicleLifecycleService({
    required AppDatabase database,
    required AttachmentFileStore fileStore,
    required ServiceReminderScheduler scheduler,
  }) : this._(database, fileStore, scheduler);

  const VehicleLifecycleService._(
    this._database,
    this._fileStore,
    this._scheduler,
  );

  final AppDatabase _database;
  final AttachmentFileStore _fileStore;
  final ServiceReminderScheduler _scheduler;

  Future<void> deleteRetiredVehicle(int vehicleId) async {
    final vehicle = await VehicleRepository(_database).findById(vehicleId);
    if (vehicle == null) return;
    if (vehicle.isActive) {
      throw StateError('The active vehicle cannot be deleted.');
    }

    final records = await (_database.select(
      _database.maintenanceRecords,
    )..where((record) => record.vehicleId.equals(vehicleId))).get();
    final reminders = await (_database.select(
      _database.serviceReminders,
    )..where((reminder) => reminder.vehicleId.equals(vehicleId))).get();

    await _database.transaction(() async {
      await (_database.delete(
        _database.fuelEvents,
      )..where((event) => event.vehicleId.equals(vehicleId))).go();
      await (_database.delete(
        _database.maintenanceRecords,
      )..where((record) => record.vehicleId.equals(vehicleId))).go();
      await (_database.delete(
        _database.vehicles,
      )..where((vehicle) => vehicle.id.equals(vehicleId))).go();
    });

    for (final reminder in reminders) {
      unawaited(_cancelNotification(reminder.maintenanceRecordId));
    }
    for (final record in records) {
      await _fileStore.deleteRecordDirectory(record.id);
    }
  }

  Future<void> cancelVehicleNotifications(int vehicleId) async {
    final reminders = await (_database.select(
      _database.serviceReminders,
    )..where((reminder) => reminder.vehicleId.equals(vehicleId))).get();
    for (final reminder in reminders) {
      unawaited(_cancelNotification(reminder.maintenanceRecordId));
    }
  }

  Future<void> _cancelNotification(int maintenanceRecordId) async {
    try {
      await _scheduler.cancel(maintenanceRecordId);
    } catch (_) {
      // Database lifecycle state remains authoritative if notifications are
      // unavailable on the current platform.
    }
  }
}
