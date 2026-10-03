import 'package:car_tracking_app/application/fuel/create_fuel_event.dart';
import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:car_tracking_app/data/database/schema.dart';
import 'package:car_tracking_app/data/repositories/fuel_event_repository.dart';
import 'package:car_tracking_app/data/repositories/maintenance_repository.dart';
import 'package:car_tracking_app/data/repositories/vehicle_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late FuelEventRepository fuelEvents;
  late MaintenanceRepository maintenance;
  late CreateFuelEvent createFuelEvent;
  late int vehicleId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    fuelEvents = FuelEventRepository(database);
    maintenance = MaintenanceRepository(database);
    createFuelEvent = CreateFuelEvent(
      fuelEvents: fuelEvents,
      maintenance: maintenance,
    );
    vehicleId = await VehicleRepository(database)
        .create(VehiclesCompanion.insert(displayName: 'Synthetic Test Car'));
  });

  tearDown(() => database.close());

  FuelEventInput input({
    DateTime? occurredAt,
    double odometerKm = 10240,
    int volumeMl = 32400,
    int costSen = 6800,
    bool isFullTank = true,
    int? tripMetres,
  }) {
    return FuelEventInput(
      vehicleId: vehicleId,
      occurredAt: occurredAt ?? DateTime.utc(2026, 6, 14, 17, 35),
      odometerKm: odometerKm,
      fuelBrand: 'Shell',
      fuelVolumeMillilitres: volumeMl,
      costSen: costSen,
      isFullTank: isFullTank,
      tripDistanceMetres: tripMetres,
    );
  }

  test('writes a valid Fuel Event through the repository', () async {
    final id = await createFuelEvent(input(tripMetres: 404000));

    final saved = await fuelEvents.findById(id);
    expect(saved, isNotNull);
    expect(saved!.vehicleId, vehicleId);
    expect(saved.odometerKm, 10240);
    expect(saved.fuelBrand, 'Shell');
    expect(saved.fuelVolumeMillilitres, 32400);
    expect(saved.costSen, 6800);
    expect(saved.isFullTank, isTrue);
    expect(saved.tripDistanceMetres, 404000);
  });

  test('accepts RM0 because it is valid fuel data', () async {
    final id = await createFuelEvent(input(costSen: 0));

    expect((await fuelEvents.findById(id))!.costSen, 0);
  });

  test('rejects invalid volume before persistence', () async {
    await expectLater(
      createFuelEvent(input(volumeMl: 0)),
      throwsA(
        isA<CreateFuelEventException>().having(
          (error) => error.issue,
          'issue',
          CreateFuelEventIssue.invalidFuelValues,
        ),
      ),
    );
    expect(await fuelEvents.findForVehicle(vehicleId), isEmpty);
  });

  test('blocks a backdated odometer that exceeds its next neighbor', () async {
    await createFuelEvent(
      input(occurredAt: DateTime.utc(2026, 9, 10), odometerKm: 10000),
    );
    await maintenance.createRecord(
      MaintenanceRecordsCompanion.insert(
        vehicleId: vehicleId,
        occurredAt: DateTime.utc(2026, 9, 12),
        odometerKm: 10250,
        category: MaintenanceCategory.service,
        totalCostSen: 0,
      ),
    );

    await expectLater(
      createFuelEvent(
        input(occurredAt: DateTime.utc(2026, 9, 11), odometerKm: 10400),
      ),
      throwsA(
        isA<CreateFuelEventException>()
            .having(
              (error) => error.issue,
              'issue',
              CreateFuelEventIssue.odometerChronologyConflict,
            )
            .having(
              (error) => error.message,
              'message',
              contains('must not exceed 10,250.0 km'),
            ),
      ),
    );
  });

  test('accepts a backdated odometer that fits both neighbors', () async {
    await createFuelEvent(
      input(occurredAt: DateTime.utc(2026, 9, 10), odometerKm: 10000),
    );
    await maintenance.createRecord(
      MaintenanceRecordsCompanion.insert(
        vehicleId: vehicleId,
        occurredAt: DateTime.utc(2026, 9, 12),
        odometerKm: 10250,
        category: MaintenanceCategory.service,
        totalCostSen: 0,
      ),
    );

    final id = await createFuelEvent(
      input(occurredAt: DateTime.utc(2026, 9, 11), odometerKm: 10120),
    );
    expect((await fuelEvents.findById(id))!.odometerKm, 10120);
  });

  test('computes Trip B mismatch from the preceding Full boundary', () async {
    await createFuelEvent(
      input(
        occurredAt: DateTime.utc(2026, 6, 1),
        odometerKm: 10000,
        isFullTank: true,
      ),
    );

    final difference = await createFuelEvent.tripBDifferenceMetres(
      vehicleId: vehicleId,
      occurredAt: DateTime.utc(2026, 6, 14),
      odometerKm: 10430,
      tripDistanceMetres: 434000,
    );
    expect(difference, 4000);
  });

  test('does not invent a Trip B comparison before a Full reference', () async {
    final difference = await createFuelEvent.tripBDifferenceMetres(
      vehicleId: vehicleId,
      occurredAt: DateTime.utc(2026, 6, 14),
      odometerKm: 10430,
      tripDistanceMetres: 434000,
    );
    expect(difference, isNull);
  });
}
