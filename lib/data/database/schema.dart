import 'package:drift/drift.dart';

import '../../domain/maintenance/maintenance.dart';

export '../../domain/maintenance/maintenance.dart' show MaintenanceCategory;

enum AttachmentKind { image, pdf }

abstract class AuditedTable extends Table {
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
}

class Vehicles extends AuditedTable {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get displayName => text().withLength(min: 1, max: 120)();

  TextColumn get registrationNumber =>
      text().withLength(min: 1, max: 32).nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get retiredAt => dateTime().nullable()();

  @override
  List<String> get customConstraints => const [
    'CHECK ((is_active = 1 AND retired_at IS NULL) OR '
        '(is_active = 0 AND retired_at IS NOT NULL))',
  ];
}

@TableIndex(
  name: 'fuel_events_vehicle_occurred_at',
  columns: {#vehicleId, #occurredAt},
)
class FuelEvents extends AuditedTable {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get vehicleId => integer().references(
    Vehicles,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  DateTimeColumn get occurredAt => dateTime()();

  IntColumn get odometerKm => integer()();

  TextColumn get fuelBrand => text().withLength(min: 1, max: 80)();

  /// Litres are persisted as millilitres so sums remain exact.
  IntColumn get fuelVolumeMillilitres => integer()();

  /// Malaysian Ringgit values are persisted as sen so sums remain exact.
  IntColumn get costSen => integer()();

  BoolColumn get isFullTank => boolean()();

  /// Optional Trip B reading in metres, preserving up to 0.001 km.
  IntColumn get tripDistanceMetres => integer().nullable()();

  @override
  List<String> get customConstraints => const [
    'CHECK (odometer_km >= 0)',
    'CHECK (fuel_volume_millilitres > 0)',
    'CHECK (cost_sen >= 0)',
    'CHECK (trip_distance_metres IS NULL OR trip_distance_metres >= 0)',
  ];
}

@TableIndex(
  name: 'maintenance_records_vehicle_occurred_at',
  columns: {#vehicleId, #occurredAt},
)
class MaintenanceRecords extends AuditedTable {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get vehicleId => integer().references(
    Vehicles,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  DateTimeColumn get occurredAt => dateTime()();

  IntColumn get odometerKm => integer()();

  TextColumn get category => textEnum<MaintenanceCategory>()();

  TextColumn get workshop => text().withLength(min: 1, max: 160).nullable()();

  IntColumn get totalCostSen => integer()();

  TextColumn get notes => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {id, vehicleId},
  ];

  @override
  List<String> get customConstraints => const [
    'CHECK (odometer_km >= 0)',
    'CHECK (total_cost_sen >= 0)',
    "CHECK (category IN ('service', 'repairs', 'accessories'))",
  ];
}

@TableIndex(
  name: 'maintenance_items_record',
  columns: {#maintenanceRecordId, #position},
)
class MaintenanceItems extends AuditedTable {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get vehicleId => integer()();

  IntColumn get maintenanceRecordId => integer()();

  TextColumn get name => text().withLength(min: 1, max: 160)();

  TextColumn get description => text().nullable()();

  IntColumn get costSen => integer()();

  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => const [
    'CHECK (cost_sen >= 0)',
    'CHECK (position >= 0)',
    'FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) '
        'ON UPDATE CASCADE ON DELETE RESTRICT',
    'FOREIGN KEY (maintenance_record_id, vehicle_id) '
        'REFERENCES maintenance_records(id, vehicle_id) '
        'ON UPDATE CASCADE ON DELETE CASCADE',
  ];
}

@TableIndex(
  name: 'attachments_record',
  columns: {#maintenanceRecordId, #position},
)
class Attachments extends AuditedTable {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get vehicleId => integer()();

  IntColumn get maintenanceRecordId => integer()();

  TextColumn get kind => textEnum<AttachmentKind>()();

  TextColumn get originalFileName => text().withLength(min: 1, max: 255)();

  TextColumn get relativePath => text().unique()();

  TextColumn get mimeType => text().withLength(min: 1, max: 120)();

  IntColumn get byteSize => integer()();

  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => const [
    'CHECK (byte_size >= 0)',
    'CHECK (position >= 0)',
    "CHECK (kind IN ('image', 'pdf'))",
    'FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) '
        'ON UPDATE CASCADE ON DELETE RESTRICT',
    'FOREIGN KEY (maintenance_record_id, vehicle_id) '
        'REFERENCES maintenance_records(id, vehicle_id) '
        'ON UPDATE CASCADE ON DELETE CASCADE',
  ];
}

@TableIndex(name: 'service_reminders_vehicle', columns: {#vehicleId})
class ServiceReminders extends AuditedTable {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get vehicleId => integer()();

  IntColumn get maintenanceRecordId => integer()();

  DateTimeColumn get targetDate => dateTime().nullable()();

  IntColumn get targetOdometerKm => integer().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {maintenanceRecordId},
  ];

  @override
  List<String> get customConstraints => const [
    'CHECK (target_date IS NOT NULL OR target_odometer_km IS NOT NULL)',
    'CHECK (target_odometer_km IS NULL OR target_odometer_km >= 0)',
    'FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) '
        'ON UPDATE CASCADE ON DELETE RESTRICT',
    'FOREIGN KEY (maintenance_record_id, vehicle_id) '
        'REFERENCES maintenance_records(id, vehicle_id) '
        'ON UPDATE CASCADE ON DELETE CASCADE',
  ];
}
