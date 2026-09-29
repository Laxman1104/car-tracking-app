import 'package:car_tracking_app/application/maintenance/maintenance_record_service.dart';
import 'package:car_tracking_app/application/vehicle/vehicle_lifecycle_service.dart';
import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:car_tracking_app/data/database/schema.dart';
import 'package:car_tracking_app/data/repositories/vehicle_repository.dart';
import 'package:car_tracking_app/domain/maintenance/maintenance.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deletes only the selected retired vehicle and its owned history',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final vehicles = VehicleRepository(database);
      final activeId = await vehicles.create(
        VehiclesCompanion.insert(displayName: 'Active car'),
      );
      final retiredId = await vehicles.create(
        VehiclesCompanion.insert(
          displayName: 'Retired car',
          isActive: const Value(false),
          retiredAt: Value(DateTime.utc(2027, 1, 1)),
        ),
      );
      await database
          .into(database.fuelEvents)
          .insert(
            FuelEventsCompanion.insert(
              vehicleId: retiredId,
              occurredAt: DateTime.utc(2026, 1, 1),
              odometerKm: 10000,
              fuelBrand: 'PETRONAS',
              fuelVolumeMillilitres: 30000,
              costSen: 6000,
              isFullTank: true,
            ),
          );
      final recordId = await database
          .into(database.maintenanceRecords)
          .insert(
            MaintenanceRecordsCompanion.insert(
              vehicleId: retiredId,
              occurredAt: DateTime.utc(2026, 2, 1),
              odometerKm: 11000,
              category: MaintenanceCategory.service,
              totalCostSen: 10000,
            ),
          );
      await database
          .into(database.maintenanceItems)
          .insert(
            MaintenanceItemsCompanion.insert(
              vehicleId: retiredId,
              maintenanceRecordId: recordId,
              name: 'Oil',
              costSen: 10000,
            ),
          );

      final files = _FakeFiles();
      final service = VehicleLifecycleService(
        database: database,
        fileStore: files,
        scheduler: const NoopServiceReminderScheduler(),
      );
      await service.deleteRetiredVehicle(retiredId);

      expect(await vehicles.findById(retiredId), isNull);
      expect(await vehicles.findById(activeId), isNotNull);
      expect(await database.select(database.fuelEvents).get(), isEmpty);
      expect(await database.select(database.maintenanceRecords).get(), isEmpty);
      expect(await database.select(database.maintenanceItems).get(), isEmpty);
      expect(files.deletedRecordIds, [recordId]);
    },
  );

  test('refuses to delete the active vehicle', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final vehicles = VehicleRepository(database);
    final activeId = await vehicles.create(
      VehiclesCompanion.insert(displayName: 'Active car'),
    );
    final service = VehicleLifecycleService(
      database: database,
      fileStore: _FakeFiles(),
      scheduler: const NoopServiceReminderScheduler(),
    );

    await expectLater(
      service.deleteRetiredVehicle(activeId),
      throwsA(isA<StateError>()),
    );
    expect(await vehicles.findById(activeId), isNotNull);
  });
}

class _FakeFiles implements AttachmentFileStore {
  final deletedRecordIds = <int>[];

  @override
  Future<String> absolutePath(String relativePath) async => relativePath;

  @override
  Future<void> deleteFile(String relativePath) async {}

  @override
  Future<void> deleteRecordDirectory(int recordId) async {
    deletedRecordIds.add(recordId);
  }

  @override
  Future<String> importFile(
    int recordId,
    MaintenanceAttachmentInput input,
  ) async => '$recordId/${input.fileName}';
}
