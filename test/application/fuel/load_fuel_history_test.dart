import 'package:car_tracking_app/application/fuel/create_fuel_event.dart';
import 'package:car_tracking_app/application/fuel/load_fuel_history.dart';
import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:car_tracking_app/data/repositories/fuel_event_repository.dart';
import 'package:car_tracking_app/data/repositories/maintenance_repository.dart';
import 'package:car_tracking_app/data/repositories/vehicle_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Not Full updates Pending and the next Full completes it', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = FuelEventRepository(database);
    final save = CreateFuelEvent(
      fuelEvents: repository,
      maintenance: MaintenanceRepository(database),
    );
    final load = LoadFuelHistory(fuelEvents: repository);
    final vehicleId = await VehicleRepository(database)
        .create(VehiclesCompanion.insert(displayName: 'Synthetic Test Car'));

    Future<void> add({
      required int day,
      required double odometer,
      required int litres,
      required bool full,
    }) async {
      await save(
        FuelEventInput(
          vehicleId: vehicleId,
          occurredAt: DateTime.utc(2026, 6, day),
          odometerKm: odometer,
          fuelBrand: 'PETRONAS',
          fuelVolumeMillilitres: litres,
          costSen: litres * 2,
          isFullTank: full,
        ),
      );
    }

    await add(day: 1, odometer: 10000, litres: 40000, full: true);
    await add(day: 8, odometer: 10200, litres: 12000, full: false);

    final pending = await load(vehicleId);
    expect(pending.completedCycles, isEmpty);
    expect(pending.pendingCycle!.replenishmentEvents.length, 1);
    expect(pending.pendingCycle!.accumulatedFuelMillilitres, 12000);

    await add(day: 14, odometer: 10450, litres: 18000, full: true);

    final completed = await load(vehicleId);
    expect(completed.completedCycles, hasLength(1));
    expect(completed.completedCycles.single.distanceKm, 450);
    expect(completed.completedCycles.single.fuelConsumedMillilitres, 30000);
    expect(completed.completedCycles.single.fuelEfficiencyKmPerL, 15);
    expect(completed.pendingCycle!.openingFull.odometerKm, 10450);
  });
}
