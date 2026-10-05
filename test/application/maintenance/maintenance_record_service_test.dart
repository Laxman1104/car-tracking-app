import 'package:car_tracking_app/application/fuel/create_fuel_event.dart';
import 'package:car_tracking_app/application/maintenance/maintenance_record_service.dart';
import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:car_tracking_app/data/database/schema.dart';
import 'package:car_tracking_app/data/repositories/attachment_repository.dart';
import 'package:car_tracking_app/data/repositories/fuel_event_repository.dart';
import 'package:car_tracking_app/data/repositories/maintenance_repository.dart';
import 'package:car_tracking_app/data/repositories/service_reminder_repository.dart';
import 'package:car_tracking_app/data/repositories/vehicle_repository.dart';
import 'package:car_tracking_app/domain/maintenance/maintenance.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late MaintenanceRepository maintenance;
  late AttachmentRepository attachments;
  late ServiceReminderRepository reminders;
  late FuelEventRepository fuel;
  late _FakeFiles files;
  late _FakeScheduler scheduler;
  late MaintenanceRecordService service;
  late int vehicleId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    maintenance = MaintenanceRepository(database);
    attachments = AttachmentRepository(database);
    reminders = ServiceReminderRepository(database);
    fuel = FuelEventRepository(database);
    files = _FakeFiles();
    scheduler = _FakeScheduler();
    service = MaintenanceRecordService(
      database: database,
      maintenance: maintenance,
      fuelEvents: fuel,
      attachments: attachments,
      reminders: reminders,
      fileStore: files,
      scheduler: scheduler,
    );
    vehicleId = await VehicleRepository(database)
        .create(VehiclesCompanion.insert(displayName: 'Maintenance Test Car'));
  });

  tearDown(() => database.close());

  MaintenanceRecordInput input({
    MaintenanceCategory category = MaintenanceCategory.service,
    int costSen = 0,
    List<MaintenanceItemInput> items = const [],
    DateTime? nextDate,
    double? nextOdometer,
    List<MaintenanceAttachmentInput> newAttachments = const [],
    Set<int> retained = const {},
    double? odometer = 10240,
    DateTime? occurredAt,
  }) => MaintenanceRecordInput(
    vehicleId: vehicleId,
    occurredAt: occurredAt ?? DateTime.utc(2027, 3, 10),
    odometerKm: odometer,
    category: category,
    workshop: 'Synthetic Service Centre',
    totalCostSen: costSen,
    items: items,
    nextServiceDate: nextDate,
    nextServiceOdometerKm: nextOdometer,
    newAttachments: newAttachments,
    retainedAttachmentIds: retained,
  );

  test(
    'creates RM0 record with items, mixed attachments, and reminder',
    () async {
      final date = DateTime.utc(2027, 9, 10);
      final id = await service.create(
        input(
          items: const [
            MaintenanceItemInput(name: 'Warranty repair', costSen: 0),
            MaintenanceItemInput(name: 'Inspection', costSen: 0),
          ],
          nextDate: date,
          nextOdometer: 20000,
          newAttachments: const [
            MaintenanceAttachmentInput(
              sourcePath: 'photo-source',
              fileName: 'receipt.jpg',
              kind: AttachmentKind.image,
              mimeType: 'image/jpeg',
              byteSize: 100,
            ),
            MaintenanceAttachmentInput(
              sourcePath: 'pdf-source',
              fileName: 'invoice.pdf',
              kind: AttachmentKind.pdf,
              mimeType: 'application/pdf',
              byteSize: 200,
            ),
          ],
        ),
      );

      final bundle = (await service.loadRecord(id))!;
      expect(bundle.record.totalCostSen, 0);
      expect(bundle.items, hasLength(2));
      expect(bundle.attachments.map((entry) => entry.kind), [
        AttachmentKind.image,
        AttachmentKind.pdf,
      ]);
      expect(bundle.reminder!.targetOdometerKm, 20000);
      expect(scheduler.scheduled[id]!.isAtSameMomentAs(date), isTrue);
      expect(scheduler.scheduledTitles[id], 'Service reminder');
    },
  );

  test(
    'edit replaces items, removes reminder, and retains selected file',
    () async {
      final id = await service.create(
        input(
          costSen: 62000,
          items: const [MaintenanceItemInput(name: 'Oil', costSen: 62000)],
          nextOdometer: 20000,
          newAttachments: const [
            MaintenanceAttachmentInput(
              sourcePath: 'photo-source',
              fileName: 'receipt.jpg',
              kind: AttachmentKind.image,
              mimeType: 'image/jpeg',
              byteSize: 100,
            ),
            MaintenanceAttachmentInput(
              sourcePath: 'pdf-source',
              fileName: 'invoice.pdf',
              kind: AttachmentKind.pdf,
              mimeType: 'application/pdf',
              byteSize: 200,
            ),
          ],
        ),
      );
      final before = (await service.loadRecord(id))!;
      final kept = before.attachments.first;

      await service.update(
        id,
        input(
          category: MaintenanceCategory.repairs,
          costSen: 1000,
          items: const [MaintenanceItemInput(name: 'Clip', costSen: 1000)],
          retained: {kept.id},
        ),
      );

      final after = (await service.loadRecord(id))!;
      expect(after.record.category, MaintenanceCategory.repairs);
      expect(after.items.single.name, 'Clip');
      expect(after.attachments.single.id, kept.id);
      expect(after.reminder, isNull);
      expect(files.deleted, hasLength(1));
      expect(scheduler.cancelled, contains(id));
    },
  );

  test(
    'accessories save without an odometer or affecting current mileage',
    () async {
      await CreateFuelEvent(fuelEvents: fuel, maintenance: maintenance)(
        FuelEventInput(
          vehicleId: vehicleId,
          occurredAt: DateTime.utc(2027, 3, 9),
          odometerKm: 10000,
          fuelBrand: 'Shell',
          fuelVolumeMillilitres: 30000,
          costSen: 6000,
          isFullTank: true,
        ),
      );

      final id = await service.create(
        input(
          category: MaintenanceCategory.accessories,
          odometer: null,
          costSen: 25000,
        ),
      );

      expect(
        (await service.loadRecord(id))!.record.category,
        MaintenanceCategory.accessories,
      );
      expect((await service.loadHistory(vehicleId)).currentOdometerKm, 10000);
    },
  );

  test('maintenance chronology shares the fuel odometer timeline', () async {
    await CreateFuelEvent(fuelEvents: fuel, maintenance: maintenance)(
      FuelEventInput(
        vehicleId: vehicleId,
        occurredAt: DateTime.utc(2027, 3, 20),
        odometerKm: 11000,
        fuelBrand: 'Shell',
        fuelVolumeMillilitres: 30000,
        costSen: 6000,
        isFullTank: true,
      ),
    );

    expect(
      () => service.create(input(odometer: 12000)),
      throwsA(
        isA<MaintenanceRecordException>().having(
          (error) => error.issue,
          'issue',
          MaintenanceRecordIssue.odometerChronologyConflict,
        ),
      ),
    );
  });

  test(
    'delete cascades children and removes private attachment files',
    () async {
      final id = await service.create(
        input(
          items: const [MaintenanceItemInput(name: 'Oil', costSen: 0)],
          nextOdometer: 20000,
          newAttachments: const [
            MaintenanceAttachmentInput(
              sourcePath: 'photo-source',
              fileName: 'receipt.jpg',
              kind: AttachmentKind.image,
              mimeType: 'image/jpeg',
              byteSize: 100,
            ),
          ],
        ),
      );

      await service.delete(id);

      expect(await service.loadRecord(id), isNull);
      expect(await maintenance.findItemsForRecord(id), isEmpty);
      expect(await attachments.findForRecord(id), isEmpty);
      expect(await reminders.findForRecord(id), isNull);
      expect(files.deletedRecords, [id]);
    },
  );

  test('each dated Service reminder remains independently scheduled', () async {
    final firstDate = DateTime.utc(2027, 9, 10);
    final firstId = await service.create(
      input(nextDate: firstDate, nextOdometer: 20000),
    );
    final secondDate = DateTime.utc(2028, 3, 10);
    final secondId = await service.create(
      input(
        occurredAt: DateTime.utc(2027, 9, 10),
        odometer: 20000,
        nextDate: secondDate,
        nextOdometer: 30000,
      ),
    );

    expect(scheduler.scheduled.keys, {firstId, secondId});
    expect(scheduler.scheduled[secondId]!.isAtSameMomentAs(secondDate), isTrue);
    await service.delete(secondId);
    expect(scheduler.scheduled.keys, {firstId});
    expect(scheduler.scheduled[firstId]!.isAtSameMomentAs(firstDate), isTrue);
  });

  test(
    'fuel odometer updates notify once at 80, 90, and 100 percent',
    () async {
      final recordId = await service.create(input(nextOdometer: 15200));
      final createFuel = CreateFuelEvent(
        fuelEvents: fuel,
        maintenance: maintenance,
        onOdometerUpdated: service.reconcileReminders,
      );

      Future<void> log(double odometer, int day) async {
        await createFuel(
          FuelEventInput(
            vehicleId: vehicleId,
            occurredAt: DateTime.utc(2027, 3, day),
            odometerKm: odometer,
            fuelBrand: 'PETRONAS',
            fuelVolumeMillilitres: 10000,
            costSen: 2000,
            isFullTank: true,
          ),
        );
      }

      await log(14208, 11);
      expect(scheduler.mileageStages[recordId], 80);
      await log(14704, 12);
      expect(scheduler.mileageStages[recordId], 90);
      await log(15200, 13);
      expect(scheduler.mileageStages[recordId], 100);
      expect(
        (await reminders.findForRecord(recordId))!
            .lastMileageNotificationPercent,
        100,
      );
    },
  );

  test(
    'marking a reminder done keeps its record but removes it from active use',
    () async {
      final recordId = await service.create(input(nextOdometer: 15200));

      await service.markReminderDone(recordId);

      expect(await maintenance.findRecordById(recordId), isNotNull);
      expect((await reminders.findForRecord(recordId))!.completedAt, isNotNull);
      expect((await service.loadHistory(vehicleId)).activeReminder, isNull);
      expect(scheduler.cancelled, contains(recordId));
    },
  );

  test(
    'notification failures do not undo a saved maintenance record',
    () async {
      final resilientService = MaintenanceRecordService(
        database: database,
        maintenance: maintenance,
        fuelEvents: fuel,
        attachments: attachments,
        reminders: reminders,
        fileStore: files,
        scheduler: const _ThrowingScheduler(),
      );

      final recordId = await resilientService.create(
        input(nextDate: DateTime.utc(2027, 9, 10), nextOdometer: 20000),
      );

      expect(await maintenance.findRecordById(recordId), isNotNull);
      expect(await reminders.findForRecord(recordId), isNotNull);
    },
  );
}

class _FakeFiles implements AttachmentFileStore {
  final deleted = <String>[];
  final deletedRecords = <int>[];
  int _counter = 0;

  @override
  Future<String> absolutePath(String relativePath) async => relativePath;

  @override
  Future<void> deleteFile(String relativePath) async =>
      deleted.add(relativePath);

  @override
  Future<void> deleteRecordDirectory(int recordId) async =>
      deletedRecords.add(recordId);

  @override
  Future<String> importFile(
    int recordId,
    MaintenanceAttachmentInput input,
  ) async => '$recordId/${_counter++}_${input.fileName}';
}

class _FakeScheduler implements ServiceReminderScheduler {
  final scheduled = <int, DateTime>{};
  final scheduledTitles = <int, String>{};
  final cancelled = <int>[];
  final mileageStages = <int, int>{};

  @override
  Future<void> cancel(int maintenanceRecordId) async {
    cancelled.add(maintenanceRecordId);
    scheduled.remove(maintenanceRecordId);
  }

  @override
  Future<void> schedule({
    required int maintenanceRecordId,
    required DateTime targetDate,
    required String title,
  }) async {
    scheduled[maintenanceRecordId] = targetDate;
    scheduledTitles[maintenanceRecordId] = title;
  }

  @override
  Future<void> showMileageProgress({
    required int maintenanceRecordId,
    required String title,
    required int stagePercent,
    required double currentOdometerKm,
    required double targetOdometerKm,
  }) async => mileageStages[maintenanceRecordId] = stagePercent;
}

class _ThrowingScheduler implements ServiceReminderScheduler {
  const _ThrowingScheduler();

  @override
  Future<void> cancel(int maintenanceRecordId) =>
      Future.error(StateError('Notifications unavailable'));

  @override
  Future<void> schedule({
    required int maintenanceRecordId,
    required DateTime targetDate,
    required String title,
  }) => Future.error(StateError('Notifications unavailable'));

  @override
  Future<void> showMileageProgress({
    required int maintenanceRecordId,
    required String title,
    required int stagePercent,
    required double currentOdometerKm,
    required double targetOdometerKm,
  }) => Future.error(StateError('Notifications unavailable'));
}
