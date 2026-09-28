import 'package:drift/drift.dart';

import '../database/app_database.dart';

class VehicleRepository {
  VehicleRepository(this._database);

  final AppDatabase _database;

  Future<int> create(VehiclesCompanion vehicle) {
    return _database.into(_database.vehicles).insert(vehicle);
  }

  Future<Vehicle?> findById(int id) {
    return (_database.select(
      _database.vehicles,
    )..where((vehicle) => vehicle.id.equals(id))).getSingleOrNull();
  }

  Future<List<Vehicle>> findAll() {
    return (_database.select(
      _database.vehicles,
    )..orderBy([(vehicle) => OrderingTerm.asc(vehicle.id)])).get();
  }

  Future<bool> update(Vehicle vehicle) {
    return _database.update(_database.vehicles).replace(vehicle);
  }

  Future<int> deleteById(int id) {
    return (_database.delete(
      _database.vehicles,
    )..where((vehicle) => vehicle.id.equals(id))).go();
  }

  Future<int> retireAndCreate({
    required int activeVehicleId,
    required DateTime retiredAt,
    required VehiclesCompanion newVehicle,
  }) {
    return _database.transaction(() async {
      final current = await findById(activeVehicleId);
      if (current == null || !current.isActive) {
        throw StateError('The vehicle being retired is not active.');
      }

      await update(
        current.copyWith(
          isActive: false,
          retiredAt: Value(retiredAt),
          updatedAt: retiredAt,
        ),
      );
      return create(
        newVehicle.copyWith(
          isActive: const Value(true),
          retiredAt: const Value(null),
        ),
      );
    });
  }
}
