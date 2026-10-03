import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:car_tracking_app/data/database/schema.dart';
import 'package:car_tracking_app/data/repositories/attachment_repository.dart';
import 'package:car_tracking_app/data/repositories/fuel_event_repository.dart';
import 'package:car_tracking_app/data/repositories/maintenance_repository.dart';
import 'package:car_tracking_app/data/repositories/service_reminder_repository.dart';
import 'package:car_tracking_app/data/repositories/vehicle_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
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
    String name = 'Test Car',
    bool isActive = true,
    DateTime? retiredAt,
  }) {
    return vehicles.create(
      VehiclesCompanion.insert(
        displayName: name,
        registrationNumber: const Value('TEST-001'),
        isActive: Value(isActive),
        retiredAt: Value(retiredAt),
      ),
    );
  }

  Future<int> createMaintenanceRecord(
    int vehicleId, {
    MaintenanceCategory category = MaintenanceCategory.service,
    int totalCostSen = 0,
  }) {
    return maintenance.createRecord(
      MaintenanceRecordsCompanion.insert(
        vehicleId: vehicleId,
        occurredAt: DateTime.utc(2027, 3, 10, 9),
        odometerKm: 10240,
        category: category,
        workshop: const Value('Synthetic Service Centre'),
        totalCostSen: totalCostSen,
        notes: const Value('Synthetic fixture only'),
      ),
    );
  }

  group('repository CRUD', () {
    test('creates, reads, updates, lists, and deletes a vehicle', () async {
      final id = await createVehicle(name: 'Primary Test Car');
      final inserted = await vehicles.findById(id);

      expect(inserted, isNotNull);
      expect(inserted!.displayName, 'Primary Test Car');
      expect(inserted.registrationNumber, 'TEST-001');
      expect(inserted.isActive, isTrue);
      expect(inserted.retiredAt, isNull);
      expect(inserted.createdAt, isNotNull);
      expect(inserted.updatedAt, isNotNull);

      final changedAt = DateTime.utc(2027, 3, 11);
      expect(
        await vehicles.update(
          inserted.copyWith(
            displayName: 'Renamed Test Car',
            updatedAt: changedAt,
          ),
        ),
        isTrue,
      );
      expect((await vehicles.findById(id))!.displayName, 'Renamed Test Car');
      expect((await vehicles.findAll()).map((vehicle) => vehicle.id), [id]);

      expect(await vehicles.deleteById(id), 1);
      expect(await vehicles.findById(id), isNull);
    });

    test(
      'CRUDs fuel events and keeps occurrence separate from audit time',
      () async {
        final vehicleId = await createVehicle();
        final occurredAt = DateTime.utc(2027, 1, 2, 8, 30);
        final createdAt = DateTime.utc(2027, 2, 1, 12);
        final id = await fuelEvents.create(
          FuelEventsCompanion.insert(
            vehicleId: vehicleId,
            occurredAt: occurredAt,
            odometerKm: 250,
            fuelBrand: 'PETRONAS',
            fuelVolumeMillilitres: 40000,
            costSen: 7000,
            isFullTank: true,
            tripDistanceMetres: const Value(250000),
            createdAt: Value(createdAt),
            updatedAt: Value(createdAt),
          ),
        );

        final inserted = await fuelEvents.findById(id);
        expect(inserted, isNotNull);
        expect(inserted!.occurredAt.isAtSameMomentAs(occurredAt), isTrue);
        expect(inserted.createdAt.isAtSameMomentAs(createdAt), isTrue);
        expect(inserted.fuelVolumeMillilitres, 40000);
        expect(inserted.costSen, 7000);
        expect(inserted.tripDistanceMetres, 250000);

        expect(
          await fuelEvents.update(inserted.copyWith(costSen: 7050)),
          isTrue,
        );
        expect((await fuelEvents.findById(id))!.costSen, 7050);
        expect((await fuelEvents.findForVehicle(vehicleId)).single.id, id);

        expect(await fuelEvents.deleteById(id), 1);
        expect(await fuelEvents.findById(id), isNull);
      },
    );

    test(
      'lists backfilled fuel events by occurrence instead of save order',
      () async {
        final vehicleId = await createVehicle();
        for (final event in [
          (DateTime.utc(2027, 9, 12), 10250.0),
          (DateTime.utc(2027, 9, 10), 10000.0),
          (DateTime.utc(2027, 9, 11), 10120.0),
        ]) {
          await fuelEvents.create(
            FuelEventsCompanion.insert(
              vehicleId: vehicleId,
              occurredAt: event.$1,
              odometerKm: event.$2,
              fuelBrand: 'Synthetic',
              fuelVolumeMillilitres: 1000,
              costSen: 200,
              isFullTank: false,
            ),
          );
        }

        expect(
          (await fuelEvents.findForVehicle(vehicleId))
              .map((event) => event.odometerKm),
          [10000, 10120, 10250],
        );
      },
    );

    test('CRUDs maintenance records and manually itemized costs', () async {
      final vehicleId = await createVehicle();
      final recordId = await createMaintenanceRecord(
        vehicleId,
        totalCostSen: 62000,
      );
      final itemId = await maintenance.createItem(
        MaintenanceItemsCompanion.insert(
          vehicleId: vehicleId,
          maintenanceRecordId: recordId,
          name: 'Engine oil',
          description: const Value('Replaced'),
          costSen: 18000,
          position: const Value(2),
        ),
      );

      final record = await maintenance.findRecordById(recordId);
      expect(record, isNotNull);
      expect(record!.category, MaintenanceCategory.service);
      expect(record.totalCostSen, 62000);
      expect(record.workshop, 'Synthetic Service Centre');

      final item = await maintenance.findItemById(itemId);
      expect(item, isNotNull);
      expect(item!.name, 'Engine oil');
      expect(item.costSen, 18000);
      expect(item.position, 2);

      expect(
        await maintenance.updateRecord(
          record.copyWith(notes: const Value('Corrected synthetic note')),
        ),
        isTrue,
      );
      expect(
        await maintenance.updateItem(item.copyWith(costSen: 17500)),
        isTrue,
      );
      expect(
        (await maintenance.findRecordsForVehicle(vehicleId)).single.notes,
        'Corrected synthetic note',
      );
      expect(
        (await maintenance.findItemsForRecord(recordId)).single.costSen,
        17500,
      );

      expect(await maintenance.deleteItemById(itemId), 1);
      expect(await maintenance.findItemById(itemId), isNull);
      expect(await maintenance.deleteRecordById(recordId), 1);
      expect(await maintenance.findRecordById(recordId), isNull);
    });

    test('CRUDs ordered image and PDF attachment metadata', () async {
      final vehicleId = await createVehicle();
      final recordId = await createMaintenanceRecord(vehicleId);
      final imageId = await attachments.create(
        AttachmentsCompanion.insert(
          vehicleId: vehicleId,
          maintenanceRecordId: recordId,
          kind: AttachmentKind.image,
          originalFileName: 'receipt.jpg',
          relativePath: 'attachments/test/receipt.jpg',
          mimeType: 'image/jpeg',
          byteSize: 1024,
          position: const Value(1),
        ),
      );
      final pdfId = await attachments.create(
        AttachmentsCompanion.insert(
          vehicleId: vehicleId,
          maintenanceRecordId: recordId,
          kind: AttachmentKind.pdf,
          originalFileName: 'invoice.pdf',
          relativePath: 'attachments/test/invoice.pdf',
          mimeType: 'application/pdf',
          byteSize: 4096,
          position: const Value(0),
        ),
      );

      final ordered = await attachments.findForRecord(recordId);
      expect(ordered.map((attachment) => attachment.id), [pdfId, imageId]);
      expect(ordered.first.kind, AttachmentKind.pdf);

      final image = (await attachments.findById(imageId))!;
      expect(
        await attachments.update(
          image.copyWith(originalFileName: 'receipt-page-1.jpg'),
        ),
        isTrue,
      );
      expect(
        (await attachments.findById(imageId))!.originalFileName,
        'receipt-page-1.jpg',
      );

      expect(await attachments.deleteById(pdfId), 1);
      expect(await attachments.findById(pdfId), isNull);
    });

    test('CRUDs a whole-service reminder with both target types', () async {
      final vehicleId = await createVehicle();
      final recordId = await createMaintenanceRecord(vehicleId);
      final targetDate = DateTime.utc(2027, 9, 10);
      final id = await reminders.create(
        ServiceRemindersCompanion.insert(
          vehicleId: vehicleId,
          maintenanceRecordId: recordId,
          targetDate: Value(targetDate),
          targetOdometerKm: const Value(20000),
        ),
      );

      final inserted = await reminders.findById(id);
      expect(inserted, isNotNull);
      expect(inserted!.targetDate!.isAtSameMomentAs(targetDate), isTrue);
      expect(inserted.targetOdometerKm, 20000);

      expect(
        await reminders.update(
          inserted.copyWith(targetOdometerKm: const Value(20500)),
        ),
        isTrue,
      );
      expect(
        (await reminders.findForVehicle(vehicleId)).single.targetOdometerKm,
        20500,
      );

      expect(await reminders.deleteById(id), 1);
      expect(await reminders.findById(id), isNull);
    });
  });
}
