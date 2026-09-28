import 'package:drift/drift.dart';

import '../database/app_database.dart';

class MaintenanceRepository {
  MaintenanceRepository(this._database);

  final AppDatabase _database;

  Future<int> createRecord(MaintenanceRecordsCompanion record) {
    return _database.into(_database.maintenanceRecords).insert(record);
  }

  Future<MaintenanceRecord?> findRecordById(int id) {
    return (_database.select(
      _database.maintenanceRecords,
    )..where((record) => record.id.equals(id))).getSingleOrNull();
  }

  Future<List<MaintenanceRecord>> findRecordsForVehicle(int vehicleId) {
    return (_database.select(_database.maintenanceRecords)
          ..where((record) => record.vehicleId.equals(vehicleId))
          ..orderBy([
            (record) => OrderingTerm.asc(record.occurredAt),
            (record) => OrderingTerm.asc(record.id),
          ]))
        .get();
  }

  Future<bool> updateRecord(MaintenanceRecord record) {
    return _database.update(_database.maintenanceRecords).replace(record);
  }

  Future<int> deleteRecordById(int id) {
    return (_database.delete(
      _database.maintenanceRecords,
    )..where((record) => record.id.equals(id))).go();
  }

  Future<int> createItem(MaintenanceItemsCompanion item) {
    return _database.into(_database.maintenanceItems).insert(item);
  }

  Future<MaintenanceItem?> findItemById(int id) {
    return (_database.select(
      _database.maintenanceItems,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
  }

  Future<List<MaintenanceItem>> findItemsForRecord(int recordId) {
    return (_database.select(_database.maintenanceItems)
          ..where((item) => item.maintenanceRecordId.equals(recordId))
          ..orderBy([
            (item) => OrderingTerm.asc(item.position),
            (item) => OrderingTerm.asc(item.id),
          ]))
        .get();
  }

  Future<bool> updateItem(MaintenanceItem item) {
    return _database.update(_database.maintenanceItems).replace(item);
  }

  Future<int> deleteItemById(int id) {
    return (_database.delete(
      _database.maintenanceItems,
    )..where((item) => item.id.equals(id))).go();
  }

  Future<int> deleteItemsForRecord(int recordId) {
    return (_database.delete(
      _database.maintenanceItems,
    )..where((item) => item.maintenanceRecordId.equals(recordId))).go();
  }
}
