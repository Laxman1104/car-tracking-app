import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:path/path.dart' as p;

import '../../data/database/app_database.dart';
import '../../domain/odometer/odometer_value.dart';
import '../../data/mappers/history_mappers.dart';
import '../../domain/fuel/fuel_cycle.dart';
import '../maintenance/maintenance_record_service.dart';

class PortableFile {
  const PortableFile({required this.fileName, required this.bytes});
  final String fileName;
  final Uint8List bytes;
}

class BackupValidationException implements Exception {
  const BackupValidationException(this.message);
  final String message;

  @override
  String toString() => 'BackupValidationException: $message';
}

class RestoreResult {
  const RestoreResult({
    required this.vehicleCount,
    required this.fuelEventCount,
    required this.maintenanceRecordCount,
    required this.attachmentCount,
  });

  final int vehicleCount;
  final int fuelEventCount;
  final int maintenanceRecordCount;
  final int attachmentCount;
}

class DataPortabilityService {
  DataPortabilityService(
    this._database,
    this._fileStore, {
    this.appVersion = '1.0.0',
  });

  static const backupFormatVersion = 1;
  final AppDatabase _database;
  final AttachmentFileStore _fileStore;
  final String appVersion;

  Future<PortableFile> createExcelExport({DateTime? createdAt}) async {
    final snapshot = await _readSnapshot();
    final bytes = _createWorkbook(snapshot);
    return PortableFile(
      fileName:
          'CarTracker_Records_${_dateStamp(createdAt ?? DateTime.now())}.xlsx',
      bytes: bytes,
    );
  }

  Future<PortableFile> createMaintenanceArchive({DateTime? createdAt}) async {
    final snapshot = await _readSnapshot();
    final archive = Archive();
    final workbook = _createWorkbook(snapshot);
    archive.addFile(
      ArchiveFile('Maintenance_Records.xlsx', workbook.length, workbook),
    );
    final records = {
      for (final record in snapshot.maintenanceRecords) record.id: record,
    };
    for (final attachment in snapshot.attachments) {
      final record = records[attachment.maintenanceRecordId]!;
      final source = await _fileStore.absolutePath(attachment.relativePath);
      final bytes = await File(source).readAsBytes();
      final folder =
          '${_dateStamp(record.occurredAt)}_'
          '${formatOdometerKm(record.odometerKm, grouped: false)}km_'
          '${record.category.name}';
      final name =
          'Receipts/${_safeName(folder)}/${_safeName(attachment.originalFileName)}';
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    return PortableFile(
      fileName:
          'Maintenance_History_${_dateStamp(createdAt ?? DateTime.now())}.zip',
      bytes: bytes,
    );
  }

  Future<PortableFile> createFullBackup({DateTime? createdAt}) async {
    final snapshot = await _readSnapshot();
    final timestamp = (createdAt ?? DateTime.now()).toUtc();
    final data = _snapshotJson(snapshot);
    final manifest = <String, Object?>{
      'backupFormatVersion': backupFormatVersion,
      'schemaVersion': _database.schemaVersion,
      'appVersion': appVersion,
      'createdAt': timestamp.toIso8601String(),
      'vehicleCount': snapshot.vehicles.length,
      'fuelEventCount': snapshot.fuelEvents.length,
      'maintenanceRecordCount': snapshot.maintenanceRecords.length,
      'maintenanceItemCount': snapshot.maintenanceItems.length,
      'serviceReminderCount': snapshot.serviceReminders.length,
      'attachmentCount': snapshot.attachments.length,
    };
    final archive = Archive()..addFile(_jsonFile('manifest.json', manifest));
    for (final entry in data.entries) {
      archive.addFile(_jsonFile('data/${entry.key}.json', entry.value));
    }
    for (final attachment in snapshot.attachments) {
      final path = await _fileStore.absolutePath(attachment.relativePath);
      final bytes = await File(path).readAsBytes();
      final archivePath =
          'attachments/${attachment.relativePath.replaceAll('\\', '/')}';
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
    }
    return PortableFile(
      fileName: 'CarTracker_Backup_${_dateStamp(timestamp)}.zip',
      bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
    );
  }

  Future<RestoreResult> restoreFullBackup(Uint8List bytes) async {
    final decoded = _decodeAndValidate(bytes);
    final snapshot = decoded.snapshot;
    final oldAttachments = await _database.select(_database.attachments).get();
    final temporary = await Directory.systemTemp.createTemp(
      'car_tracker_restore_',
    );
    final staged = <int, String>{};
    try {
      for (final attachment in snapshot.attachments) {
        final archiveName =
            'attachments/${attachment.relativePath.replaceAll('\\', '/')}';
        final content = decoded.files[archiveName]!;
        final source = File(
          p.join(
            temporary.path,
            '${attachment.id}_${_safeName(attachment.originalFileName)}',
          ),
        );
        await source.writeAsBytes(content, flush: true);
        staged[attachment.id] = await _fileStore.importFile(
          attachment.maintenanceRecordId,
          MaintenanceAttachmentInput(
            sourcePath: source.path,
            fileName: attachment.originalFileName,
            kind: attachment.kind,
            mimeType: attachment.mimeType,
            byteSize: content.length,
          ),
        );
      }

      await _database.transaction(() async {
        await _database.delete(_database.attachments).go();
        await _database.delete(_database.serviceReminders).go();
        await _database.delete(_database.maintenanceItems).go();
        await _database.delete(_database.maintenanceRecords).go();
        await _database.delete(_database.fuelEvents).go();
        await _database.delete(_database.vehicles).go();
        for (final row in snapshot.vehicles) {
          await _database
              .into(_database.vehicles)
              .insert(row.toCompanion(true));
        }
        for (final row in snapshot.fuelEvents) {
          await _database
              .into(_database.fuelEvents)
              .insert(row.toCompanion(true));
        }
        for (final row in snapshot.maintenanceRecords) {
          await _database
              .into(_database.maintenanceRecords)
              .insert(row.toCompanion(true));
        }
        for (final row in snapshot.maintenanceItems) {
          await _database
              .into(_database.maintenanceItems)
              .insert(row.toCompanion(true));
        }
        for (final row in snapshot.serviceReminders) {
          await _database
              .into(_database.serviceReminders)
              .insert(row.toCompanion(true));
        }
        for (final row in snapshot.attachments) {
          await _database
              .into(_database.attachments)
              .insert(
                row.copyWith(relativePath: staged[row.id]!).toCompanion(true),
              );
        }
      });
      for (final old in oldAttachments) {
        if (!staged.values.contains(old.relativePath)) {
          await _fileStore.deleteFile(old.relativePath);
        }
      }
      return RestoreResult(
        vehicleCount: snapshot.vehicles.length,
        fuelEventCount: snapshot.fuelEvents.length,
        maintenanceRecordCount: snapshot.maintenanceRecords.length,
        attachmentCount: snapshot.attachments.length,
      );
    } catch (_) {
      for (final path in staged.values) {
        await _fileStore.deleteFile(path);
      }
      rethrow;
    } finally {
      await temporary.delete(recursive: true);
    }
  }

  _DecodedBackup _decodeAndValidate(Uint8List bytes) {
    late Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (_) {
      throw const BackupValidationException(
        'The selected file is not a valid backup ZIP.',
      );
    }
    final files = <String, Uint8List>{};
    for (final file in archive.files.where((entry) => entry.isFile)) {
      final name = file.name.replaceAll('\\', '/');
      if (name.startsWith('/') || name.split('/').contains('..')) {
        throw const BackupValidationException(
          'The backup contains an unsafe file path.',
        );
      }
      files[name] = file.content;
    }
    Map<String, dynamic> object(String name) {
      final content = files[name];
      if (content == null) throw BackupValidationException('Missing $name.');
      try {
        return jsonDecode(utf8.decode(content)) as Map<String, dynamic>;
      } catch (_) {
        throw BackupValidationException('$name is not valid JSON.');
      }
    }

    List<dynamic> list(String name) {
      final content = files[name];
      if (content == null) throw BackupValidationException('Missing $name.');
      try {
        return jsonDecode(utf8.decode(content)) as List<dynamic>;
      } catch (_) {
        throw BackupValidationException('$name is not a valid JSON list.');
      }
    }

    final manifest = object('manifest.json');
    if (manifest['backupFormatVersion'] != backupFormatVersion) {
      throw const BackupValidationException(
        'This backup format is not supported.',
      );
    }
    if (manifest['schemaVersion'] != _database.schemaVersion) {
      throw const BackupValidationException(
        'This backup uses an incompatible database schema.',
      );
    }
    final snapshot = _snapshotFromJson({
      'vehicles': list('data/vehicles.json'),
      'fuel_events': list('data/fuel_events.json'),
      'maintenance_records': list('data/maintenance_records.json'),
      'maintenance_items': list('data/maintenance_items.json'),
      'service_reminders': list('data/service_reminders.json'),
      'attachments': list('data/attachments.json'),
    });
    _checkCount(manifest, 'vehicleCount', snapshot.vehicles.length);
    _checkCount(manifest, 'fuelEventCount', snapshot.fuelEvents.length);
    _checkCount(
      manifest,
      'maintenanceRecordCount',
      snapshot.maintenanceRecords.length,
    );
    _checkCount(manifest, 'attachmentCount', snapshot.attachments.length);
    final vehicleIds = snapshot.vehicles.map((e) => e.id).toSet();
    final recordIds = snapshot.maintenanceRecords.map((e) => e.id).toSet();
    if (snapshot.vehicles.where((e) => e.isActive).length > 1 ||
        snapshot.fuelEvents.any((e) => !vehicleIds.contains(e.vehicleId)) ||
        snapshot.maintenanceRecords.any(
          (e) => !vehicleIds.contains(e.vehicleId),
        ) ||
        snapshot.maintenanceItems.any(
          (e) => !recordIds.contains(e.maintenanceRecordId),
        ) ||
        snapshot.serviceReminders.any(
          (e) => !recordIds.contains(e.maintenanceRecordId),
        ) ||
        snapshot.attachments.any(
          (e) => !recordIds.contains(e.maintenanceRecordId),
        )) {
      throw const BackupValidationException(
        'The backup contains broken record relationships.',
      );
    }
    for (final attachment in snapshot.attachments) {
      final name =
          'attachments/${attachment.relativePath.replaceAll('\\', '/')}';
      final content = files[name];
      if (content == null || content.length != attachment.byteSize) {
        throw BackupValidationException(
          'Attachment ${attachment.originalFileName} is missing or damaged.',
        );
      }
    }
    return _DecodedBackup(snapshot: snapshot, files: files);
  }

  void _checkCount(Map<String, dynamic> manifest, String key, int actual) {
    if (manifest[key] != actual) {
      throw BackupValidationException('Backup count mismatch for $key.');
    }
  }

  Future<_PortabilitySnapshot> _readSnapshot() async => _PortabilitySnapshot(
    vehicles: await _database.select(_database.vehicles).get(),
    fuelEvents: await _database.select(_database.fuelEvents).get(),
    maintenanceRecords: await _database
        .select(_database.maintenanceRecords)
        .get(),
    maintenanceItems: await _database.select(_database.maintenanceItems).get(),
    attachments: await _database.select(_database.attachments).get(),
    serviceReminders: await _database.select(_database.serviceReminders).get(),
  );

  Uint8List _createWorkbook(_PortabilitySnapshot snapshot) {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final cyclesSheet = excel['Fuel Cycles'];
    _append(cyclesSheet, [
      'Vehicle ID',
      'Opening Event ID',
      'Closing Event ID',
      'Start',
      'End',
      'Start Odometer km',
      'End Odometer km',
      'Distance km',
      'Fuel Used L',
      'Cycle Cost RM',
      'km/L',
      'RM/km',
      'Brand',
    ]);
    for (final group in _groupFuel(snapshot.fuelEvents).entries) {
      final history = const FuelCycleEngine().build(
        group.value.map((e) => e.toSnapshot()),
      );
      for (final cycle in history.completedCycles) {
        _append(cyclesSheet, [
          group.key,
          cycle.openingFull.id,
          cycle.closingFull.id,
          cycle.openingFull.occurredAt.toIso8601String(),
          cycle.closingFull.occurredAt.toIso8601String(),
          cycle.openingFull.odometerKm,
          cycle.closingFull.odometerKm,
          cycle.distanceKm,
          cycle.fuelConsumedMillilitres / 1000,
          cycle.fuelCostSen / 100,
          cycle.fuelEfficiencyKmPerL,
          cycle.costRinggitPerKm,
          cycle.attributedBrand ?? 'Mixed',
        ]);
      }
    }
    final fuelSheet = excel['Fuel Events'];
    _append(fuelSheet, [
      'ID',
      'Vehicle ID',
      'Occurred At',
      'Odometer km',
      'Brand',
      'Litres',
      'Cost RM',
      'Full Tank',
      'Trip B km',
    ]);
    for (final row in snapshot.fuelEvents) {
      _append(fuelSheet, [
        row.id,
        row.vehicleId,
        row.occurredAt.toIso8601String(),
        row.odometerKm,
        row.fuelBrand,
        row.fuelVolumeMillilitres / 1000,
        row.costSen / 100,
        row.isFullTank,
        row.tripDistanceMetres == null ? null : row.tripDistanceMetres! / 1000,
      ]);
    }
    final recordsSheet = excel['Maintenance Records'];
    _append(recordsSheet, [
      'ID',
      'Vehicle ID',
      'Occurred At',
      'Odometer km',
      'Category',
      'Service Title',
      'Workshop',
      'Total Cost RM',
      'Notes',
      'Attachment Paths',
    ]);
    for (final row in snapshot.maintenanceRecords) {
      final paths = snapshot.attachments
          .where((e) => e.maintenanceRecordId == row.id)
          .map((e) => e.relativePath)
          .join('; ');
      _append(recordsSheet, [
        row.id,
        row.vehicleId,
        row.occurredAt.toIso8601String(),
        row.odometerKm,
        row.category.name,
        row.serviceTitle,
        row.workshop,
        row.totalCostSen / 100,
        row.notes,
        paths,
      ]);
    }
    final itemsSheet = excel['Maintenance Items'];
    _append(itemsSheet, [
      'ID',
      'Vehicle ID',
      'Maintenance Record ID',
      'Position',
      'Name',
      'Description',
      'Cost RM',
    ]);
    for (final row in snapshot.maintenanceItems) {
      _append(itemsSheet, [
        row.id,
        row.vehicleId,
        row.maintenanceRecordId,
        row.position,
        row.name,
        row.description,
        row.costSen / 100,
      ]);
    }
    final bytes = excel.save();
    if (bytes == null) throw StateError('Could not encode the Excel workbook.');
    return Uint8List.fromList(bytes);
  }

  void _append(Sheet sheet, List<Object?> values) => sheet.appendRow(
    values
        .map<CellValue?>(
          (value) => switch (value) {
            null => null,
            int v => IntCellValue(v),
            double v => DoubleCellValue(v),
            bool v => BoolCellValue(v),
            _ => TextCellValue(value.toString()),
          },
        )
        .toList(),
  );

  Map<int, List<FuelEvent>> _groupFuel(List<FuelEvent> events) {
    final result = <int, List<FuelEvent>>{};
    for (final event in events) {
      result.putIfAbsent(event.vehicleId, () => []).add(event);
    }
    return result;
  }

  Map<String, Object?> _snapshotJson(_PortabilitySnapshot s) => {
    'vehicles': s.vehicles.map((e) => e.toJson()).toList(),
    'fuel_events': s.fuelEvents.map((e) => e.toJson()).toList(),
    'maintenance_records': s.maintenanceRecords.map((e) => e.toJson()).toList(),
    'maintenance_items': s.maintenanceItems.map((e) => e.toJson()).toList(),
    'service_reminders': s.serviceReminders.map((e) => e.toJson()).toList(),
    'attachments': s.attachments.map((e) => e.toJson()).toList(),
  };

  _PortabilitySnapshot _snapshotFromJson(Map<String, dynamic> json) {
    List<T> rows<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (json[key] as List<dynamic>)
            .map((e) => parse(Map<String, dynamic>.from(e as Map)))
            .toList();
    try {
      return _PortabilitySnapshot(
        vehicles: rows('vehicles', Vehicle.fromJson),
        fuelEvents: rows('fuel_events', FuelEvent.fromJson),
        maintenanceRecords: rows(
          'maintenance_records',
          MaintenanceRecord.fromJson,
        ),
        maintenanceItems: rows('maintenance_items', MaintenanceItem.fromJson),
        serviceReminders: rows('service_reminders', ServiceReminder.fromJson),
        attachments: rows('attachments', Attachment.fromJson),
      );
    } catch (_) {
      throw const BackupValidationException('The backup data is malformed.');
    }
  }

  ArchiveFile _jsonFile(String name, Object? value) {
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(value),
    );
    return ArchiveFile(name, bytes.length, bytes);
  }

  String _safeName(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  String _dateStamp(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _PortabilitySnapshot {
  const _PortabilitySnapshot({
    required this.vehicles,
    required this.fuelEvents,
    required this.maintenanceRecords,
    required this.maintenanceItems,
    required this.attachments,
    required this.serviceReminders,
  });
  final List<Vehicle> vehicles;
  final List<FuelEvent> fuelEvents;
  final List<MaintenanceRecord> maintenanceRecords;
  final List<MaintenanceItem> maintenanceItems;
  final List<Attachment> attachments;
  final List<ServiceReminder> serviceReminders;
}

class _DecodedBackup {
  const _DecodedBackup({required this.snapshot, required this.files});
  final _PortabilitySnapshot snapshot;
  final Map<String, Uint8List> files;
}
