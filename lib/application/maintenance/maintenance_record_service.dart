import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';
import '../../data/database/schema.dart';
import '../../data/mappers/history_mappers.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/repositories/fuel_event_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../data/repositories/service_reminder_repository.dart';
import '../../domain/maintenance/maintenance.dart';
import '../../domain/odometer/odometer_timeline.dart';
import '../../domain/validation/domain_validation.dart';

class MaintenanceAttachmentInput {
  const MaintenanceAttachmentInput({
    required this.sourcePath,
    required this.fileName,
    required this.kind,
    required this.mimeType,
    required this.byteSize,
  });

  final String sourcePath;
  final String fileName;
  final AttachmentKind kind;
  final String mimeType;
  final int byteSize;
}

class MaintenanceRecordInput {
  const MaintenanceRecordInput({
    required this.vehicleId,
    required this.occurredAt,
    required this.odometerKm,
    required this.category,
    required this.workshop,
    required this.totalCostSen,
    required this.items,
    this.serviceTitle,
    this.notes,
    this.nextServiceDate,
    this.nextServiceOdometerKm,
    this.newAttachments = const [],
    this.retainedAttachmentIds = const {},
  });

  final int vehicleId;
  final DateTime occurredAt;
  final int odometerKm;
  final MaintenanceCategory category;
  final String workshop;
  final int totalCostSen;
  final List<MaintenanceItemInput> items;
  final String? serviceTitle;
  final String? notes;
  final DateTime? nextServiceDate;
  final int? nextServiceOdometerKm;
  final List<MaintenanceAttachmentInput> newAttachments;
  final Set<int> retainedAttachmentIds;
}

class MaintenanceRecordBundle {
  const MaintenanceRecordBundle({
    required this.record,
    required this.items,
    required this.attachments,
    required this.reminder,
  });

  final MaintenanceRecord record;
  final List<MaintenanceItem> items;
  final List<Attachment> attachments;
  final ServiceReminder? reminder;
}

class MaintenanceHistoryData {
  const MaintenanceHistoryData({
    required this.records,
    required this.currentOdometerKm,
    required this.activeReminder,
    required this.activeReminderTitle,
  });

  final List<MaintenanceRecordBundle> records;
  final int? currentOdometerKm;
  final ServiceReminder? activeReminder;
  final String? activeReminderTitle;
}

enum MaintenanceRecordIssue {
  workshopRequired,
  invalidValues,
  invalidItems,
  invalidReminder,
  odometerChronologyConflict,
  recordNotFound,
}

class MaintenanceRecordException implements Exception {
  const MaintenanceRecordException(this.issue, this.message);

  final MaintenanceRecordIssue issue;
  final String message;

  @override
  String toString() => 'MaintenanceRecordException: $message';
}

abstract interface class ServiceReminderScheduler {
  Future<void> schedule({
    required int maintenanceRecordId,
    required DateTime targetDate,
    required String title,
  });

  Future<void> cancel(int maintenanceRecordId);

  Future<void> showMileageProgress({
    required int maintenanceRecordId,
    required String title,
    required int stagePercent,
    required int currentOdometerKm,
    required int targetOdometerKm,
  });
}

class NoopServiceReminderScheduler implements ServiceReminderScheduler {
  const NoopServiceReminderScheduler();

  @override
  Future<void> cancel(int maintenanceRecordId) async {}

  @override
  Future<void> showMileageProgress({
    required int maintenanceRecordId,
    required String title,
    required int stagePercent,
    required int currentOdometerKm,
    required int targetOdometerKm,
  }) async {}

  @override
  Future<void> schedule({
    required int maintenanceRecordId,
    required DateTime targetDate,
    required String title,
  }) async {}
}

abstract interface class AttachmentFileStore {
  Future<String> importFile(int recordId, MaintenanceAttachmentInput input);
  Future<void> deleteFile(String relativePath);
  Future<void> deleteRecordDirectory(int recordId);
  Future<String> absolutePath(String relativePath);
}

class AppAttachmentFileStore implements AttachmentFileStore {
  Future<Directory> get _root async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'maintenance_attachments'));
  }

  @override
  Future<String> importFile(
    int recordId,
    MaintenanceAttachmentInput input,
  ) async {
    final directory = Directory(p.join((await _root).path, '$recordId'));
    await directory.create(recursive: true);
    final safeName = input.fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final name = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final destination = File(p.join(directory.path, name));
    await File(input.sourcePath).copy(destination.path);
    return p.join('$recordId', name);
  }

  @override
  Future<String> absolutePath(String relativePath) async =>
      p.join((await _root).path, relativePath);

  @override
  Future<void> deleteFile(String relativePath) async {
    final file = File(await absolutePath(relativePath));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> deleteRecordDirectory(int recordId) async {
    final directory = Directory(p.join((await _root).path, '$recordId'));
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}

class MaintenanceRecordService {
  MaintenanceRecordService({
    required AppDatabase database,
    required MaintenanceRepository maintenance,
    required FuelEventRepository fuelEvents,
    required AttachmentRepository attachments,
    required ServiceReminderRepository reminders,
    required AttachmentFileStore fileStore,
    ServiceReminderScheduler scheduler = const NoopServiceReminderScheduler(),
    DomainValidator validator = const DomainValidator(),
    MaintenanceDomainService domain = const MaintenanceDomainService(),
  }) : this._(
         database,
         maintenance,
         fuelEvents,
         attachments,
         reminders,
         fileStore,
         scheduler,
         validator,
         domain,
       );

  MaintenanceRecordService._(
    this._database,
    this._maintenance,
    this._fuelEvents,
    this._attachments,
    this._reminders,
    this._fileStore,
    this._scheduler,
    this._validator,
    this._domain,
  );

  final AppDatabase _database;
  final MaintenanceRepository _maintenance;
  final FuelEventRepository _fuelEvents;
  final AttachmentRepository _attachments;
  final ServiceReminderRepository _reminders;
  final AttachmentFileStore _fileStore;
  final ServiceReminderScheduler _scheduler;
  final DomainValidator _validator;
  final MaintenanceDomainService _domain;

  Future<int> create(MaintenanceRecordInput input) async {
    await _validate(input);
    final recordId = await _database.transaction(() async {
      final id = await _maintenance.createRecord(
        MaintenanceRecordsCompanion.insert(
          vehicleId: input.vehicleId,
          occurredAt: input.occurredAt.toUtc(),
          odometerKm: input.odometerKm,
          category: input.category,
          workshop: Value(input.workshop.trim()),
          serviceTitle: Value(
            input.category == MaintenanceCategory.service
                ? _nullableText(input.serviceTitle)
                : null,
          ),
          totalCostSen: input.totalCostSen,
          notes: Value(_nullableText(input.notes)),
        ),
      );
      await _replaceChildren(id, input, existingAttachments: const []);
      return id;
    });
    await reconcileReminders(input.vehicleId);
    return recordId;
  }

  Future<void> update(int recordId, MaintenanceRecordInput input) async {
    final existing = await _maintenance.findRecordById(recordId);
    if (existing == null || existing.vehicleId != input.vehicleId) {
      throw const MaintenanceRecordException(
        MaintenanceRecordIssue.recordNotFound,
        'The maintenance record no longer exists.',
      );
    }
    await _validate(input, editedRecordId: recordId);
    final oldAttachments = await _attachments.findForRecord(recordId);
    final removed = oldAttachments
        .where((entry) => !input.retainedAttachmentIds.contains(entry.id))
        .toList();
    await _database.transaction(() async {
      await _maintenance.updateRecord(
        existing.copyWith(
          occurredAt: input.occurredAt.toUtc(),
          odometerKm: input.odometerKm,
          category: input.category,
          workshop: Value(input.workshop.trim()),
          serviceTitle: Value(
            input.category == MaintenanceCategory.service
                ? _nullableText(input.serviceTitle)
                : null,
          ),
          totalCostSen: input.totalCostSen,
          notes: Value(_nullableText(input.notes)),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await _replaceChildren(
        recordId,
        input,
        existingAttachments: oldAttachments,
      );
    });
    for (final attachment in removed) {
      await _fileStore.deleteFile(attachment.relativePath);
    }
    _cancelNotification(recordId);
    await reconcileReminders(input.vehicleId);
  }

  Future<void> delete(int recordId) async {
    final existing = await _maintenance.findRecordById(recordId);
    if (existing == null) return;
    await _database.transaction(() => _maintenance.deleteRecordById(recordId));
    await _fileStore.deleteRecordDirectory(recordId);
    _cancelNotification(recordId);
    await reconcileReminders(existing.vehicleId);
  }

  Future<MaintenanceRecordBundle?> loadRecord(int recordId) async {
    final record = await _maintenance.findRecordById(recordId);
    if (record == null) return null;
    final items = await _maintenance.findItemsForRecord(recordId);
    final attachments = await _attachments.findForRecord(recordId);
    final reminder = await _reminders.findForRecord(recordId);
    return MaintenanceRecordBundle(
      record: record,
      items: items,
      attachments: attachments,
      reminder: reminder,
    );
  }

  Future<MaintenanceHistoryData> loadHistory(int vehicleId) async {
    final records = await _maintenance.findRecordsForVehicle(vehicleId);
    final bundles = <MaintenanceRecordBundle>[];
    for (final record in records.reversed) {
      bundles.add((await loadRecord(record.id))!);
    }
    final fuel = await _fuelEvents.findForVehicle(vehicleId);
    final observations = [
      ...fuel.map((event) => event.toOdometerObservation()),
      ...records.map((record) => record.toOdometerObservation()),
    ];
    final current = const OdometerTimelineEngine().resolveCurrent(observations);
    ServiceReminder? active;
    String? activeTitle;
    for (final bundle in bundles) {
      if (bundle.reminder != null && bundle.reminder!.completedAt == null) {
        active = bundle.reminder;
        activeTitle = bundle.record.serviceTitle;
        break;
      }
    }
    return MaintenanceHistoryData(
      records: List.unmodifiable(bundles),
      currentOdometerKm: current?.odometerKm,
      activeReminder: active,
      activeReminderTitle: activeTitle,
    );
  }

  Future<void> _replaceChildren(
    int recordId,
    MaintenanceRecordInput input, {
    required List<Attachment> existingAttachments,
  }) async {
    await _maintenance.deleteItemsForRecord(recordId);
    for (var index = 0; index < input.items.length; index++) {
      final item = input.items[index];
      await _maintenance.createItem(
        MaintenanceItemsCompanion.insert(
          vehicleId: input.vehicleId,
          maintenanceRecordId: recordId,
          name: item.name.trim(),
          description: Value(_nullableText(item.description)),
          costSen: item.costSen,
          position: Value(index),
        ),
      );
    }

    await _reminders.deleteForRecord(recordId);
    if (input.category == MaintenanceCategory.service &&
        (input.nextServiceDate != null ||
            input.nextServiceOdometerKm != null)) {
      await _reminders.create(
        ServiceRemindersCompanion.insert(
          vehicleId: input.vehicleId,
          maintenanceRecordId: recordId,
          targetDate: Value(input.nextServiceDate?.toUtc()),
          targetOdometerKm: Value(input.nextServiceOdometerKm),
        ),
      );
    }

    for (final old in existingAttachments) {
      if (!input.retainedAttachmentIds.contains(old.id)) {
        await _attachments.deleteById(old.id);
      }
    }
    var position = input.retainedAttachmentIds.length;
    for (final attachment in input.newAttachments) {
      final relativePath = await _fileStore.importFile(recordId, attachment);
      await _attachments.create(
        AttachmentsCompanion.insert(
          vehicleId: input.vehicleId,
          maintenanceRecordId: recordId,
          kind: attachment.kind,
          originalFileName: attachment.fileName,
          relativePath: relativePath,
          mimeType: attachment.mimeType,
          byteSize: attachment.byteSize,
          position: Value(position++),
        ),
      );
    }
  }

  Future<void> _validate(
    MaintenanceRecordInput input, {
    int? editedRecordId,
  }) async {
    if (input.workshop.trim().isEmpty) {
      throw const MaintenanceRecordException(
        MaintenanceRecordIssue.workshopRequired,
        'Enter a workshop or service centre.',
      );
    }
    if (!_validator
        .validateMaintenanceValues(
          odometerKm: input.odometerKm,
          totalCostSen: input.totalCostSen,
        )
        .isValid) {
      throw const MaintenanceRecordException(
        MaintenanceRecordIssue.invalidValues,
        'One or more maintenance values are invalid.',
      );
    }
    final plan = _domain.buildPlan(
      vehicleId: input.vehicleId,
      maintenanceRecordId: editedRecordId ?? 0,
      category: input.category,
      items: input.items,
      nextServiceDate: input.nextServiceDate,
      nextServiceOdometerKm: input.nextServiceOdometerKm,
    );
    if (!plan.isValid) {
      throw MaintenanceRecordException(
        plan.issues.contains(MaintenanceRuleIssue.nonServiceCannotSetReminder)
            ? MaintenanceRecordIssue.invalidReminder
            : MaintenanceRecordIssue.invalidItems,
        'Check the itemized work and next-service fields.',
      );
    }
    final fuel = await _fuelEvents.findForVehicle(input.vehicleId);
    final maintenance = await _maintenance.findRecordsForVehicle(
      input.vehicleId,
    );
    final chronology = editedRecordId == null
        ? _validator.validateOdometerInsert(
            candidate: OdometerObservation(
              key: const OdometerObservationKey(
                OdometerSource.maintenance,
                0x7fffffffffffffff,
              ),
              vehicleId: input.vehicleId,
              occurredAt: input.occurredAt.toUtc(),
              odometerKm: input.odometerKm,
            ),
            existing: [
              ...fuel.map((event) => event.toOdometerObservation()),
              ...maintenance.map((record) => record.toOdometerObservation()),
            ],
          )
        : _validator.validateOdometerEdit(
            candidate: OdometerObservation(
              key: OdometerObservationKey(
                OdometerSource.maintenance,
                editedRecordId,
              ),
              vehicleId: input.vehicleId,
              occurredAt: input.occurredAt.toUtc(),
              odometerKm: input.odometerKm,
            ),
            existing: [
              ...fuel.map((event) => event.toOdometerObservation()),
              ...maintenance.map((record) => record.toOdometerObservation()),
            ],
          );
    if (!chronology.isValid) {
      final previous = chronology.previous;
      final next = chronology.next;
      throw MaintenanceRecordException(
        MaintenanceRecordIssue.odometerChronologyConflict,
        previous != null && input.odometerKm < previous.odometerKm
            ? 'Odometer must be at least ${previous.odometerKm} km for this date and time.'
            : 'Odometer must not exceed ${next!.odometerKm} km for this date and time.',
      );
    }
  }

  Future<void> markReminderDone(int maintenanceRecordId) async {
    final reminder = await _reminders.findForRecord(maintenanceRecordId);
    if (reminder == null || reminder.completedAt != null) return;
    await _reminders.update(
      reminder.copyWith(completedAt: Value(DateTime.now().toUtc())),
    );
    _cancelNotification(maintenanceRecordId);
  }

  Future<void> reconcileReminders(int vehicleId) async {
    final reminders = await _reminders.findForVehicle(vehicleId);
    final records = await _maintenance.findRecordsForVehicle(vehicleId);
    final recordById = {for (final record in records) record.id: record};
    final fuel = await _fuelEvents.findForVehicle(vehicleId);
    final currentOdometer = const OdometerTimelineEngine().resolveCurrent([
      ...fuel.map((event) => event.toOdometerObservation()),
      ...records.map((record) => record.toOdometerObservation()),
    ])?.odometerKm;
    for (final reminder in reminders) {
      if (reminder.completedAt != null) continue;
      final record = recordById[reminder.maintenanceRecordId];
      if (record == null) continue;
      if (reminder.targetDate case final date?) {
        unawaited(
          _scheduleDateNotification(
            reminder.maintenanceRecordId,
            date,
            record.serviceTitle ?? 'Service reminder',
          ),
        );
      }
      final target = reminder.targetOdometerKm;
      if (target == null || currentOdometer == null) continue;
      final progress = _domain.evaluateMileageProgress(
        serviceOdometerKm: record.odometerKm,
        currentOdometerKm: currentOdometer,
        targetOdometerKm: target,
      );
      if (progress == null) continue;
      final percentage = progress.percentage;
      final stage = percentage >= 100
          ? 100
          : percentage >= 90
          ? 90
          : percentage >= 80
          ? 80
          : 0;
      if (stage == 0 ||
          stage <= (reminder.lastMileageNotificationPercent ?? 0)) {
        continue;
      }
      unawaited(
        _showMileageNotification(
          maintenanceRecordId: reminder.maintenanceRecordId,
          title: record.serviceTitle ?? 'Service reminder',
          stagePercent: stage,
          currentOdometerKm: currentOdometer,
          targetOdometerKm: target,
        ),
      );
      await _reminders.update(
        reminder.copyWith(lastMileageNotificationPercent: Value(stage)),
      );
    }
  }

  void _cancelNotification(int maintenanceRecordId) {
    unawaited(_cancelNotificationSafely(maintenanceRecordId));
  }

  Future<void> _cancelNotificationSafely(int maintenanceRecordId) async {
    try {
      await _scheduler.cancel(maintenanceRecordId);
    } catch (_) {
      // Persistence and recalculation are authoritative; notification cleanup
      // is best effort when the platform service is unavailable.
    }
  }

  Future<void> _scheduleDateNotification(
    int maintenanceRecordId,
    DateTime targetDate,
    String title,
  ) async {
    try {
      await _scheduler.schedule(
        maintenanceRecordId: maintenanceRecordId,
        targetDate: targetDate,
        title: title,
      );
    } catch (_) {
      // Notification availability must never roll back or block a record.
    }
  }

  Future<void> _showMileageNotification({
    required int maintenanceRecordId,
    required String title,
    required int stagePercent,
    required int currentOdometerKm,
    required int targetOdometerKm,
  }) async {
    try {
      await _scheduler.showMileageProgress(
        maintenanceRecordId: maintenanceRecordId,
        title: title,
        stagePercent: stagePercent,
        currentOdometerKm: currentOdometerKm,
        targetOdometerKm: targetOdometerKm,
      );
    } catch (_) {
      // In-app reminder state remains valid if OS notifications are denied.
    }
  }

  String? _nullableText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
