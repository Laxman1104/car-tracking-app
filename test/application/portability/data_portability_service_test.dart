import 'dart:io';

import 'package:archive/archive.dart';
import 'package:car_tracking_app/application/maintenance/maintenance_record_service.dart';
import 'package:car_tracking_app/application/portability/data_portability_service.dart';
import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:car_tracking_app/data/database/schema.dart';
import 'package:car_tracking_app/data/repositories/attachment_repository.dart';
import 'package:car_tracking_app/data/repositories/fuel_event_repository.dart';
import 'package:car_tracking_app/data/repositories/maintenance_repository.dart';
import 'package:car_tracking_app/data/repositories/service_reminder_repository.dart';
import 'package:car_tracking_app/data/repositories/vehicle_repository.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;
  late AppDatabase source;
  late _TestFiles sourceFiles;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('portability_test_');
    source = AppDatabase.forTesting(NativeDatabase.memory());
    sourceFiles = _TestFiles(Directory(p.join(temp.path, 'source')));
    final vehicleId = await VehicleRepository(source)
        .create(VehiclesCompanion.insert(displayName: 'Synthetic S70'));
    final fuel = FuelEventRepository(source);
    for (final row in [
      (DateTime.utc(2027, 1, 1), 10000.0, 40000, 7000, true),
      (DateTime.utc(2027, 1, 10), 10450.0, 30000, 6600, true),
    ]) {
      await fuel.create(
        FuelEventsCompanion.insert(
          vehicleId: vehicleId,
          occurredAt: row.$1,
          odometerKm: row.$2,
          fuelBrand: 'PETRONAS',
          fuelVolumeMillilitres: row.$3,
          costSen: row.$4,
          isFullTank: row.$5,
        ),
      );
    }
    final maintenance = MaintenanceRepository(source);
    final recordId = await maintenance.createRecord(
      MaintenanceRecordsCompanion.insert(
        vehicleId: vehicleId,
        occurredAt: DateTime.utc(2027, 1, 12),
        odometerKm: 10500,
        category: MaintenanceCategory.service,
        serviceTitle: const Value('General Service'),
        workshop: const Value('Synthetic Centre'),
        totalCostSen: 62000,
      ),
    );
    await maintenance.createItem(
      MaintenanceItemsCompanion.insert(
        vehicleId: vehicleId,
        maintenanceRecordId: recordId,
        name: 'Engine oil',
        costSen: 18000,
      ),
    );
    await ServiceReminderRepository(source).create(
      ServiceRemindersCompanion.insert(
        vehicleId: vehicleId,
        maintenanceRecordId: recordId,
        targetDate: Value(DateTime.utc(2027, 7, 12)),
        targetOdometerKm: const Value(20000),
      ),
    );
    final receipt = File(p.join(temp.path, 'receipt.pdf'));
    await receipt.writeAsBytes([1, 2, 3, 4]);
    final relative = await sourceFiles.importFile(
      recordId,
      MaintenanceAttachmentInput(
        sourcePath: receipt.path,
        fileName: 'receipt.pdf',
        kind: AttachmentKind.pdf,
        mimeType: 'application/pdf',
        byteSize: 4,
      ),
    );
    await AttachmentRepository(source).create(
      AttachmentsCompanion.insert(
        vehicleId: vehicleId,
        maintenanceRecordId: recordId,
        kind: AttachmentKind.pdf,
        originalFileName: 'receipt.pdf',
        relativePath: relative,
        mimeType: 'application/pdf',
        byteSize: 4,
      ),
    );
  });

  tearDown(() async {
    await source.close();
    await temp.delete(recursive: true);
  });

  test('Excel export has the four locked readable sheets', () async {
    final output = await DataPortabilityService(
      source,
      sourceFiles,
    ).createExcelExport(createdAt: DateTime.utc(2027, 1, 20));
    final excel = Excel.decodeBytes(output.bytes);
    expect(
      excel.tables.keys,
      containsAll([
        'Fuel Cycles',
        'Fuel Events',
        'Maintenance Records',
        'Maintenance Items',
      ]),
    );
    expect(excel['Fuel Events'].maxRows, 3);
    expect(excel['Maintenance Records'].maxRows, 2);
  });

  test(
    'full backup restores records, relationships, and attachment bytes',
    () async {
      final service = DataPortabilityService(source, sourceFiles);
      final backup = await service.createFullBackup(
        createdAt: DateTime.utc(2027, 1, 20),
      );
      final archive = ZipDecoder().decodeBytes(backup.bytes, verify: true);
      expect(archive.findFile('manifest.json'), isNotNull);
      expect(archive.findFile('data/fuel_events.json'), isNotNull);

      final target = AppDatabase.forTesting(NativeDatabase.memory());
      final targetFiles = _TestFiles(Directory(p.join(temp.path, 'target')));
      addTearDown(target.close);
      await VehicleRepository(target)
          .create(VehiclesCompanion.insert(displayName: 'Replace me'));

      final result = await DataPortabilityService(
        target,
        targetFiles,
      ).restoreFullBackup(backup.bytes);
      expect(result.vehicleCount, 1);
      expect(result.fuelEventCount, 2);
      expect(result.maintenanceRecordCount, 1);
      expect(result.attachmentCount, 1);
      expect(
        (await VehicleRepository(target).findAll()).single.displayName,
        'Synthetic S70',
      );
      final activeVehicle = await VehicleRepository(target).findActive();
      expect(activeVehicle?.displayName, 'Synthetic S70');
      final records = await MaintenanceRepository(target)
          .findRecordsForVehicle(1);
      expect(records.single.serviceTitle, 'General Service');
      final restoredHistory = await MaintenanceRecordService(
        database: target,
        maintenance: MaintenanceRepository(target),
        fuelEvents: FuelEventRepository(target),
        attachments: AttachmentRepository(target),
        reminders: ServiceReminderRepository(target),
        fileStore: targetFiles,
      ).loadHistory(activeVehicle!.id);
      expect(restoredHistory.currentOdometerKm, 10500);
      final attachments = await AttachmentRepository(target)
          .findForRecord(records.single.id);
      expect(
        await File(
          await targetFiles.absolutePath(attachments.single.relativePath),
        ).readAsBytes(),
        [1, 2, 3, 4],
      );
    },
  );

  test('invalid manifest fails before current data is changed', () async {
    final invalid = Archive()
      ..addFile(
        ArchiveFile.string('manifest.json', '{"backupFormatVersion":999}'),
      );
    final bytes = Uint8List.fromList(ZipEncoder().encode(invalid));
    final before = await VehicleRepository(source).findAll();

    await expectLater(
      DataPortabilityService(source, sourceFiles).restoreFullBackup(bytes),
      throwsA(isA<BackupValidationException>()),
    );
    expect(await VehicleRepository(source).findAll(), before);
  });
}

class _TestFiles implements AttachmentFileStore {
  _TestFiles(this.root);
  final Directory root;

  @override
  Future<String> absolutePath(String relativePath) async =>
      p.join(root.path, relativePath);

  @override
  Future<void> deleteFile(String relativePath) async {
    final file = File(await absolutePath(relativePath));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> deleteRecordDirectory(int recordId) async {
    final directory = Directory(p.join(root.path, '$recordId'));
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  @override
  Future<String> importFile(
    int recordId,
    MaintenanceAttachmentInput input,
  ) async {
    final directory = Directory(p.join(root.path, '$recordId'));
    await directory.create(recursive: true);
    final relative = p.join(
      '$recordId',
      '${DateTime.now().microsecondsSinceEpoch}_${input.fileName}',
    );
    await File(input.sourcePath).copy(p.join(root.path, relative));
    return relative;
  }
}
