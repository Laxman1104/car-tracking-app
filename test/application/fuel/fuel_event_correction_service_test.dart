import 'package:car_tracking_app/application/fuel/create_fuel_event.dart';
import 'package:car_tracking_app/application/fuel/delete_fuel_event.dart';
import 'package:car_tracking_app/application/fuel/load_fuel_history.dart';
import 'package:car_tracking_app/application/fuel/update_fuel_event.dart';
import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:car_tracking_app/data/repositories/fuel_event_repository.dart';
import 'package:car_tracking_app/data/repositories/maintenance_repository.dart';
import 'package:car_tracking_app/data/repositories/vehicle_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late FuelEventRepository repository;
  late CreateFuelEvent create;
  late UpdateFuelEvent update;
  late DeleteFuelEvent delete;
  late LoadFuelHistory load;
  late int vehicleId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FuelEventRepository(database);
    final maintenance = MaintenanceRepository(database);
    create = CreateFuelEvent(fuelEvents: repository, maintenance: maintenance);
    update = UpdateFuelEvent(fuelEvents: repository, maintenance: maintenance);
    delete = DeleteFuelEvent(fuelEvents: repository);
    load = LoadFuelHistory(fuelEvents: repository);
    vehicleId = await VehicleRepository(database)
        .create(VehiclesCompanion.insert(displayName: 'Correction Test Car'));
  });

  tearDown(() => database.close());

  Future<int> add(int day, int odometer, int ml, int sen, bool full) => create(
    FuelEventInput(
      vehicleId: vehicleId,
      occurredAt: DateTime.utc(2027, 1, day),
      odometerKm: odometer,
      fuelBrand: 'PETRONAS',
      fuelVolumeMillilitres: ml,
      costSen: sen,
      isFullTank: full,
    ),
  );

  test('editing a partial recalculates its completed cycle', () async {
    await add(1, 10000, 40000, 7000, true);
    final partialId = await add(5, 10200, 12000, 3000, false);
    await add(10, 10450, 18000, 3600, true);

    await update(
      partialId,
      FuelEventInput(
        vehicleId: vehicleId,
        occurredAt: DateTime.utc(2027, 1, 5),
        odometerKm: 10200,
        fuelBrand: 'PETRONAS',
        fuelVolumeMillilitres: 14000,
        costSen: 3300,
        isFullTank: false,
      ),
    );

    final cycle = (await load(vehicleId)).completedCycles.single;
    expect(cycle.fuelConsumedMillilitres, 32000);
    expect(cycle.fuelCostSen, 6900);
  });

  test('deleting a partial removes its litres and cost', () async {
    await add(1, 10000, 40000, 7000, true);
    final partialId = await add(5, 10200, 12000, 3000, false);
    await add(10, 10450, 18000, 3600, true);

    await delete(partialId);

    final cycle = (await load(vehicleId)).completedCycles.single;
    expect(cycle.fuelConsumedMillilitres, 18000);
    expect(cycle.fuelCostSen, 3600);
  });

  test('deleting a Full boundary merges surrounding cycles', () async {
    await add(1, 10000, 40000, 7000, true);
    final middleFullId = await add(10, 10400, 28000, 5600, true);
    await add(20, 10800, 30000, 6000, true);

    await delete(middleFullId);

    final result = await load(vehicleId);
    expect(result.completedCycles, hasLength(1));
    expect(result.completedCycles.single.distanceKm, 800);
    expect(result.completedCycles.single.fuelConsumedMillilitres, 30000);
  });
}
