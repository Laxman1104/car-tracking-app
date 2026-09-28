import 'package:drift/drift.dart';

import '../database/app_database.dart';

class ServiceReminderRepository {
  ServiceReminderRepository(this._database);

  final AppDatabase _database;

  Future<int> create(ServiceRemindersCompanion reminder) {
    return _database.into(_database.serviceReminders).insert(reminder);
  }

  Future<ServiceReminder?> findById(int id) {
    return (_database.select(
      _database.serviceReminders,
    )..where((reminder) => reminder.id.equals(id))).getSingleOrNull();
  }

  Future<List<ServiceReminder>> findForVehicle(int vehicleId) {
    return (_database.select(_database.serviceReminders)
          ..where((reminder) => reminder.vehicleId.equals(vehicleId))
          ..orderBy([(reminder) => OrderingTerm.asc(reminder.id)]))
        .get();
  }

  Future<bool> update(ServiceReminder reminder) {
    return _database.update(_database.serviceReminders).replace(reminder);
  }

  Future<int> deleteById(int id) {
    return (_database.delete(
      _database.serviceReminders,
    )..where((reminder) => reminder.id.equals(id))).go();
  }
}
