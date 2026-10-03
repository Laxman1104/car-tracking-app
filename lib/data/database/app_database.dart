import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'schema.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Vehicles,
    FuelEvents,
    MaintenanceRecords,
    MaintenanceItems,
    Attachments,
    ServiceReminders,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE UNIQUE INDEX one_active_vehicle '
        'ON vehicles (is_active) WHERE is_active = 1',
      );
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(
          maintenanceRecords,
          maintenanceRecords.serviceTitle,
        );
      }
      if (from < 3) {
        await migrator.addColumn(
          serviceReminders,
          serviceReminders.completedAt,
        );
        await migrator.addColumn(
          serviceReminders,
          serviceReminders.lastMileageNotificationPercent,
        );
      }
      if (from < 4) {
        await migrator.addColumn(vehicles, vehicles.startingOdometerKm);
        await migrator.addColumn(vehicles, vehicles.photoPath);
      }
      if (from < 5) {
        await migrator.alterTable(
          TableMigration(
            serviceReminders,
            columnTransformer: {
              serviceReminders.targetOdometerKm: serviceReminders
                  .targetOdometerKm
                  .cast<double>(),
            },
          ),
        );
        await migrator.alterTable(
          TableMigration(
            fuelEvents,
            columnTransformer: {
              fuelEvents.odometerKm: fuelEvents.odometerKm.cast<double>(),
            },
          ),
        );
        await migrator.alterTable(
          TableMigration(
            maintenanceRecords,
            columnTransformer: {
              maintenanceRecords.odometerKm: maintenanceRecords.odometerKm
                  .cast<double>(),
            },
          ),
        );
        await migrator.alterTable(
          TableMigration(
            vehicles,
            columnTransformer: {
              vehicles.startingOdometerKm: vehicles.startingOdometerKm
                  .cast<double>(),
            },
          ),
        );
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'car_tracker',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
