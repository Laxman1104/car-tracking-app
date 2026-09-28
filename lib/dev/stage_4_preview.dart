import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';

import '../application/fuel/create_fuel_event.dart';
import '../application/fuel/delete_fuel_event.dart';
import '../application/fuel/load_fuel_history.dart';
import '../application/fuel/update_fuel_event.dart';
import '../application/maintenance/local_service_reminder_scheduler.dart';
import '../application/maintenance/maintenance_record_service.dart';
import '../data/database/app_database.dart';
import '../data/repositories/attachment_repository.dart';
import '../data/repositories/fuel_event_repository.dart';
import '../data/repositories/maintenance_repository.dart';
import '../data/repositories/service_reminder_repository.dart';
import '../data/repositories/vehicle_repository.dart';
import '../domain/maintenance/maintenance.dart';
import '../presentation/fuel/cycle_details_screen.dart';
import '../presentation/fuel/fuel_event_details_screen.dart';
import '../presentation/fuel/fuel_event_form_screen.dart';
import '../presentation/fuel/fuel_history_screen.dart';
import '../presentation/maintenance/maintenance_history_screen.dart';
import '../presentation/theme/app_theme.dart';

class StageFourPreviewApp extends StatefulWidget {
  const StageFourPreviewApp({super.key});

  @override
  State<StageFourPreviewApp> createState() => _StageFourPreviewAppState();
}

class _StageFourPreviewAppState extends State<StageFourPreviewApp> {
  late final AppDatabase _database;
  late final AttachmentFileStore _fileStore;
  late final LocalServiceReminderScheduler _scheduler;
  late final Future<int> _vehicleId;

  FuelEventRepository get _fuel => FuelEventRepository(_database);
  MaintenanceRepository get _maintenance => MaintenanceRepository(_database);

  CreateFuelEvent get _createFuel =>
      CreateFuelEvent(fuelEvents: _fuel, maintenance: _maintenance);

  UpdateFuelEvent get _updateFuel =>
      UpdateFuelEvent(fuelEvents: _fuel, maintenance: _maintenance);

  MaintenanceRecordService get _maintenanceService => MaintenanceRecordService(
    database: _database,
    maintenance: _maintenance,
    fuelEvents: _fuel,
    attachments: AttachmentRepository(_database),
    reminders: ServiceReminderRepository(_database),
    fileStore: _fileStore,
    scheduler: _scheduler,
  );

  @override
  void initState() {
    super.initState();
    _database = AppDatabase.forTesting(NativeDatabase.memory());
    _fileStore = AppAttachmentFileStore();
    _scheduler = LocalServiceReminderScheduler();
    _vehicleId = _seed();
  }

  Future<int> _seed() async {
    final vehicleId = await VehicleRepository(_database)
        .create(VehiclesCompanion.insert(displayName: 'Stage 4 Preview Car'));
    final now = DateTime.now();
    for (final fixture in [
      (14, 10000, 'PETRONAS', 40000, 7000, true),
      (7, 10200, 'Shell', 12000, 3000, false),
      (1, 10450, 'Petron', 18000, 3600, true),
    ]) {
      await _createFuel(
        FuelEventInput(
          vehicleId: vehicleId,
          occurredAt: now.subtract(Duration(days: fixture.$1)),
          odometerKm: fixture.$2,
          fuelBrand: fixture.$3,
          fuelVolumeMillilitres: fixture.$4,
          costSen: fixture.$5,
          isFullTank: fixture.$6,
        ),
      );
    }
    final recordId = await _maintenance.createRecord(
      MaintenanceRecordsCompanion.insert(
        vehicleId: vehicleId,
        occurredAt: now.subtract(const Duration(hours: 12)).toUtc(),
        odometerKm: 10450,
        category: MaintenanceCategory.service,
        workshop: const Value('Proton Service Centre'),
        totalCostSen: 62000,
        notes: const Value('Scheduled service and inspection.'),
      ),
    );
    for (final item in [
      ('Engine oil', 'Replaced', 18000),
      ('Oil filter', 'Replaced', 3500),
      ('Air filter', 'Inspected and replaced', 6500),
      ('Transmission fluid', 'Flush and refill', 24000),
      ('Labour', 'General inspection', 10000),
    ].indexed) {
      await _maintenance.createItem(
        MaintenanceItemsCompanion.insert(
          vehicleId: vehicleId,
          maintenanceRecordId: recordId,
          name: item.$2.$1,
          description: Value(item.$2.$2),
          costSen: item.$2.$3,
          position: Value(item.$1),
        ),
      );
    }
    await ServiceReminderRepository(_database).create(
      ServiceRemindersCompanion.insert(
        vehicleId: vehicleId,
        maintenanceRecordId: recordId,
        targetDate: Value(now.add(const Duration(days: 180)).toUtc()),
        targetOdometerKm: const Value(20000),
      ),
    );
    return vehicleId;
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Car Tracker · Stages 3–4 Preview',
    theme: AppTheme.dark,
    home: FutureBuilder<int>(
      future: _vehicleId,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final vehicleId = snapshot.requireData;
        return _PreviewHome(
          openFuel: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FuelHistoryScreen(
                vehicleId: vehicleId,
                loadFuelHistory: LoadFuelHistory(fuelEvents: _fuel).call,
                fuelFormBuilder: (context, saved) => FuelEventFormScreen(
                  vehicleId: vehicleId,
                  createFuelEvent: _createFuel,
                  onSaved: (_) => saved(),
                ),
                fuelEventDetailsBuilder: (context, event) =>
                    FuelEventDetailsScreen(
                      event: event,
                      createFuelEvent: _createFuel,
                      updateFuelEvent: _updateFuel,
                      deleteFuelEvent: DeleteFuelEvent(fuelEvents: _fuel),
                    ),
                cycleDetailsBuilder: (context, cycle, number) =>
                    CycleDetailsScreen(
                      cycle: cycle,
                      cycleNumber: number,
                      eventDetailsBuilder: (context, event) =>
                          FuelEventDetailsScreen(
                            event: event,
                            createFuelEvent: _createFuel,
                            updateFuelEvent: _updateFuel,
                            deleteFuelEvent: DeleteFuelEvent(fuelEvents: _fuel),
                          ),
                    ),
              ),
            ),
          ),
          openMaintenance: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MaintenanceHistoryScreen(
                vehicleId: vehicleId,
                service: _maintenanceService,
                fileStore: _fileStore,
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _PreviewHome extends StatelessWidget {
  const _PreviewHome({required this.openFuel, required this.openMaintenance});
  final VoidCallback openFuel;
  final VoidCallback openMaintenance;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Car Tracker Preview')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Stages 3 & 4',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Test maintenance, attachments, reminders, and historical corrections.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        _Destination(
          key: const Key('preview-fuel'),
          icon: Icons.local_gas_station_outlined,
          title: 'Fuel History',
          subtitle: 'Open a cycle and tap an event to edit or delete it.',
          onTap: openFuel,
        ),
        const SizedBox(height: 12),
        _Destination(
          key: const Key('preview-maintenance'),
          icon: Icons.home_repair_service_outlined,
          title: 'Maintenance History',
          subtitle:
              'Add, edit, attach receipts, set reminders, or delete records.',
          onTap: openMaintenance,
        ),
      ],
    ),
  );
}

class _Destination extends StatelessWidget {
  const _Destination({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: AppColors.teal, size: 34),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}
