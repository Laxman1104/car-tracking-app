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
}
