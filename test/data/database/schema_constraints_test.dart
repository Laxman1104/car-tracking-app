import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:car_tracking_app/data/database/schema.dart';
import 'package:car_tracking_app/data/repositories/attachment_repository.dart';
import 'package:car_tracking_app/data/repositories/fuel_event_repository.dart';
import 'package:car_tracking_app/data/repositories/maintenance_repository.dart';
import 'package:car_tracking_app/data/repositories/service_reminder_repository.dart';
import 'package:car_tracking_app/data/repositories/vehicle_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late VehicleRepository vehicles;
  late FuelEventRepository fuelEvents;
  late MaintenanceRepository maintenance;
  late AttachmentRepository attachments;
  late ServiceReminderRepository reminders;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    vehicles = VehicleRepository(database);
    fuelEvents = FuelEventRepository(database);
    maintenance = MaintenanceRepository(database);
    attachments = AttachmentRepository(database);
    reminders = ServiceReminderRepository(database);
  });

  tearDown(() => database.close());

  Future<int> createVehicle({
    required String name,
    bool isActive = true,
    DateTime? retiredAt,
  }) {
    return vehicles.create(
      VehiclesCompanion.insert(
        displayName: name,
        isActive: Value(isActive),
        retiredAt: Value(retiredAt),
      ),
    );
  }

  Future<int> createRecord(int vehicleId) {
    return maintenance.createRecord(
      MaintenanceRecordsCompanion.insert(
        vehicleId: vehicleId,
        occurredAt: DateTime.utc(2027, 3, 10),
        odometerKm: 10240,
        category: MaintenanceCategory.service,
        totalCostSen: 0,
      ),
    );
  }

  test(
    'migration creates every Task 1.1 table and enables foreign keys',
    () async {
      await database.validateDatabaseSchema();

      final tables = await database.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''').get();
      final tableNames = tables.map((row) => row.read<String>('name')).toList();

      expect(tableNames, [
        'attachments',
        'fuel_events',
        'maintenance_items',
        'maintenance_records',
        'service_reminders',
        'vehicles',
      ]);
      expect(
        (await database.customSelect('PRAGMA foreign_keys').getSingle())
            .read<int>('foreign_keys'),
        1,
      );
      expect(
        (await database.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        5,
      );
    },
  );

  test(
    'only one active vehicle is allowed and lifecycle state is coherent',
    () async {
      await createVehicle(name: 'Active car');

      await expectLater(
        createVehicle(name: 'Second active car'),
        throwsA(anything),
      );
      await expectLater(
        createVehicle(name: 'Inactive without retirement', isActive: false),
        throwsA(anything),
      );
      await expectLater(
        createVehicle(
          name: 'Active with retirement',
          retiredAt: DateTime.utc(2027, 1, 1),
        ),
        throwsA(anything),
      );

      final retiredId = await createVehicle(
        name: 'Retired car',
        isActive: false,
        retiredAt: DateTime.utc(2027, 1, 1),
      );
      expect((await vehicles.findById(retiredId))!.isActive, isFalse);
    },
  );

  test('foreign keys reject orphan top-level records', () async {
    await expectLater(
      fuelEvents.create(
        FuelEventsCompanion.insert(
          vehicleId: 999,
          occurredAt: DateTime.utc(2027, 1, 1),
          odometerKm: 100,
          fuelBrand: 'Shell',
          fuelVolumeMillilitres: 10000,
          costSen: 2500,
          isFullTank: true,
        ),
      ),
      throwsA(anything),
    );
    await expectLater(
      maintenance.createRecord(
        MaintenanceRecordsCompanion.insert(
          vehicleId: 999,
          occurredAt: DateTime.utc(2027, 1, 1),
          odometerKm: 100,
          category: MaintenanceCategory.repairs,
          totalCostSen: 0,
        ),
      ),
      throwsA(anything),
    );
  });

  test('child rows reject a parent belonging to another vehicle', () async {
    final firstVehicleId = await createVehicle(name: 'Active car');
    final secondVehicleId = await createVehicle(
      name: 'Retired car',
      isActive: false,
      retiredAt: DateTime.utc(2026, 12, 31),
    );
    final recordId = await createRecord(firstVehicleId);

    await expectLater(
      maintenance.createItem(
        MaintenanceItemsCompanion.insert(
          vehicleId: secondVehicleId,
          maintenanceRecordId: recordId,
          name: 'Invalid cross-vehicle item',
          costSen: 0,
        ),
      ),
      throwsA(anything),
    );
    await expectLater(
      attachments.create(
        AttachmentsCompanion.insert(
          vehicleId: secondVehicleId,
          maintenanceRecordId: recordId,
          kind: AttachmentKind.pdf,
          originalFileName: 'invalid.pdf',
          relativePath: 'attachments/invalid.pdf',
          mimeType: 'application/pdf',
          byteSize: 1,
        ),
      ),
      throwsA(anything),
    );
    await expectLater(
      reminders.create(
        ServiceRemindersCompanion.insert(
          vehicleId: secondVehicleId,
          maintenanceRecordId: recordId,
          targetOdometerKm: const Value(20000),
        ),
      ),
      throwsA(anything),
    );
  });

  test(
    'deleting maintenance cascades only its items, files, and reminder',
    () async {
      final vehicleId = await createVehicle(name: 'Active car');
      final recordId = await createRecord(vehicleId);
      final itemId = await maintenance.createItem(
        MaintenanceItemsCompanion.insert(
          vehicleId: vehicleId,
          maintenanceRecordId: recordId,
          name: 'Oil filter',
          costSen: 3500,
        ),
      );
      final attachmentId = await attachments.create(
        AttachmentsCompanion.insert(
          vehicleId: vehicleId,
          maintenanceRecordId: recordId,
          kind: AttachmentKind.image,
          originalFileName: 'receipt.jpg',
          relativePath: 'attachments/cascade/receipt.jpg',
          mimeType: 'image/jpeg',
          byteSize: 200,
        ),
      );
      final reminderId = await reminders.create(
        ServiceRemindersCompanion.insert(
          vehicleId: vehicleId,
          maintenanceRecordId: recordId,
          targetDate: Value(DateTime.utc(2027, 9, 10)),
        ),
      );

      expect(await maintenance.deleteRecordById(recordId), 1);
      expect(await maintenance.findItemById(itemId), isNull);
      expect(await attachments.findById(attachmentId), isNull);
      expect(await reminders.findById(reminderId), isNull);
      expect(await vehicles.findById(vehicleId), isNotNull);
    },
  );

  test('vehicle deletion is restricted while owned history exists', () async {
    final vehicleId = await createVehicle(name: 'Active car');
    await fuelEvents.create(
      FuelEventsCompanion.insert(
        vehicleId: vehicleId,
        occurredAt: DateTime.utc(2027, 1, 1),
        odometerKm: 250,
        fuelBrand: 'PETRONAS',
        fuelVolumeMillilitres: 40000,
        costSen: 7000,
        isFullTank: true,
      ),
    );

    await expectLater(vehicles.deleteById(vehicleId), throwsA(anything));
    expect(await vehicles.findById(vehicleId), isNotNull);
  });

  test(
    'database constraints preserve locked zero and positive rules',
    () async {
      final vehicleId = await createVehicle(name: 'Active car');

      await expectLater(
        fuelEvents.create(
          FuelEventsCompanion.insert(
            vehicleId: vehicleId,
            occurredAt: DateTime.utc(2027, 1, 1),
            odometerKm: 250,
            fuelBrand: 'PETRONAS',
            fuelVolumeMillilitres: 0,
            costSen: 0,
            isFullTank: true,
          ),
        ),
        throwsA(anything),
      );
      await expectLater(
        fuelEvents.create(
          FuelEventsCompanion.insert(
            vehicleId: vehicleId,
            occurredAt: DateTime.utc(2027, 1, 1),
            odometerKm: 250,
            fuelBrand: 'PETRONAS',
            fuelVolumeMillilitres: 1000,
            costSen: -1,
            isFullTank: true,
          ),
        ),
        throwsA(anything),
      );

      final zeroFuelId = await fuelEvents.create(
        FuelEventsCompanion.insert(
          vehicleId: vehicleId,
          occurredAt: DateTime.utc(2027, 1, 1),
          odometerKm: 250,
          fuelBrand: 'PETRONAS',
          fuelVolumeMillilitres: 1000,
          costSen: 0,
          isFullTank: true,
        ),
      );
      final sameOdometerFuelId = await fuelEvents.create(
        FuelEventsCompanion.insert(
          vehicleId: vehicleId,
          occurredAt: DateTime.utc(2027, 1, 1, 1),
          odometerKm: 250,
          fuelBrand: 'Shell',
          fuelVolumeMillilitres: 500,
          costSen: 100,
          isFullTank: true,
        ),
      );
      final zeroMaintenanceId = await maintenance.createRecord(
        MaintenanceRecordsCompanion.insert(
          vehicleId: vehicleId,
          occurredAt: DateTime.utc(2027, 1, 2),
          odometerKm: 300,
          category: MaintenanceCategory.repairs,
          totalCostSen: 0,
        ),
      );

      expect((await fuelEvents.findById(zeroFuelId))!.costSen, 0);
      expect((await fuelEvents.findById(sameOdometerFuelId))!.odometerKm, 250);
      expect(
        (await maintenance.findRecordById(zeroMaintenanceId))!.totalCostSen,
        0,
      );
    },
  );

  test(
    'service reminder requires at least one target and one per service',
    () async {
      final vehicleId = await createVehicle(name: 'Active car');
      final recordId = await createRecord(vehicleId);

      await expectLater(
        reminders.create(
          ServiceRemindersCompanion.insert(
            vehicleId: vehicleId,
            maintenanceRecordId: recordId,
          ),
        ),
        throwsA(anything),
      );

      await reminders.create(
        ServiceRemindersCompanion.insert(
          vehicleId: vehicleId,
          maintenanceRecordId: recordId,
          targetOdometerKm: const Value(20000),
        ),
      );
      await expectLater(
        reminders.create(
          ServiceRemindersCompanion.insert(
            vehicleId: vehicleId,
            maintenanceRecordId: recordId,
            targetDate: Value(DateTime.utc(2027, 9, 10)),
          ),
        ),
        throwsA(anything),
      );
    },
  );

  test(
    'integer units retain exact fuel and money sums without drift',
    () async {
      final vehicleId = await createVehicle(name: 'Active car');
      for (final values in [(1, 12345, 4567), (2, 18000, 3001)]) {
        await fuelEvents.create(
          FuelEventsCompanion.insert(
            vehicleId: vehicleId,
            occurredAt: DateTime.utc(2027, 1, values.$1),
            odometerKm: values.$1 * 100,
            fuelBrand: 'Synthetic',
            fuelVolumeMillilitres: values.$2,
            costSen: values.$3,
            isFullTank: false,
          ),
        );
      }

      final totals = await database
          .customSelect(
            '''
      SELECT
        SUM(fuel_volume_millilitres) AS volume_total,
        SUM(cost_sen) AS cost_total
      FROM fuel_events
      WHERE vehicle_id = ?
    ''',
            variables: [Variable(vehicleId)],
          )
          .getSingle();

      expect(totals.read<int>('volume_total'), 30345);
      expect(totals.read<int>('cost_total'), 7568);
    },
  );

  test('repository queries never merge records across vehicles', () async {
    final activeId = await createVehicle(name: 'Active car');
    final retiredId = await createVehicle(
      name: 'Retired car',
      isActive: false,
      retiredAt: DateTime.utc(2026, 12, 31),
    );

    for (final vehicleId in [activeId, retiredId]) {
      await fuelEvents.create(
        FuelEventsCompanion.insert(
          vehicleId: vehicleId,
          occurredAt: DateTime.utc(2027, 1, vehicleId),
          odometerKm: vehicleId * 100,
          fuelBrand: 'Synthetic',
          fuelVolumeMillilitres: 1000,
          costSen: 200,
          isFullTank: true,
        ),
      );
      await createRecord(vehicleId);
    }

    expect(
      (await fuelEvents.findForVehicle(activeId))
          .every((event) => event.vehicleId == activeId),
      isTrue,
    );
    expect(
      (await maintenance.findRecordsForVehicle(retiredId))
          .every((record) => record.vehicleId == retiredId),
      isTrue,
    );
    expect(await fuelEvents.findForVehicle(activeId), hasLength(1));
    expect(await maintenance.findRecordsForVehicle(retiredId), hasLength(1));
  });
}
