import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_database/generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('v1 to v5 preserves records and converts odometers safely', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase.execute(
      "INSERT INTO vehicles "
      "(created_at, updated_at, display_name, is_active) "
      "VALUES (0, 0, 'Legacy car', 1)",
    );
    schema.rawDatabase.execute(
      "INSERT INTO maintenance_records "
      "(created_at, updated_at, vehicle_id, occurred_at, odometer_km, "
      "category, workshop, total_cost_sen) "
      "VALUES (0, 0, 1, 0, 10000, 'service', 'Legacy centre', 62000)",
    );
    schema.rawDatabase.execute(
      "INSERT INTO service_reminders "
      "(created_at, updated_at, vehicle_id, maintenance_record_id, "
      "target_odometer_km) VALUES (0, 0, 1, 1, 15200)",
    );

    final database = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(database, 5);
    final records = await database.select(database.maintenanceRecords).get();

    expect(records, hasLength(1));
    expect(records.single.workshop, 'Legacy centre');
    expect(records.single.totalCostSen, 62000);
    expect(records.single.serviceTitle, isNull);
    final reminders = await database.select(database.serviceReminders).get();
    expect(reminders.single.targetOdometerKm, 15200.0);
    expect(reminders.single.completedAt, isNull);
    expect(reminders.single.lastMileageNotificationPercent, isNull);
    final vehicles = await database.select(database.vehicles).get();
    expect(vehicles.single.startingOdometerKm, 0.0);
    expect(vehicles.single.photoPath, isNull);
    await database.close();
    schema.close();
  });
}
