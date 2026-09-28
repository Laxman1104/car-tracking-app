import 'package:drift/drift.dart';

import '../database/app_database.dart';

class FuelEventRepository {
  FuelEventRepository(this._database);

  final AppDatabase _database;

  Future<int> create(FuelEventsCompanion event) {
    return _database.into(_database.fuelEvents).insert(event);
  }

  Future<FuelEvent?> findById(int id) {
    return (_database.select(
      _database.fuelEvents,
    )..where((event) => event.id.equals(id))).getSingleOrNull();
  }

  Future<List<FuelEvent>> findForVehicle(int vehicleId) {
    return (_database.select(_database.fuelEvents)
          ..where((event) => event.vehicleId.equals(vehicleId))
          ..orderBy([
            (event) => OrderingTerm.asc(event.occurredAt),
            (event) => OrderingTerm.asc(event.id),
          ]))
        .get();
  }

  Future<bool> update(FuelEvent event) {
    return _database.update(_database.fuelEvents).replace(event);
  }

  Future<int> deleteById(int id) {
    return (_database.delete(
      _database.fuelEvents,
    )..where((event) => event.id.equals(id))).go();
  }
}
