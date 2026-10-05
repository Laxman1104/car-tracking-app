import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';

import '../application/fuel/create_fuel_event.dart';
import '../application/fuel/delete_fuel_event.dart';
import '../application/fuel/load_fuel_history.dart';
import '../application/fuel/update_fuel_event.dart';
import '../application/analytics/load_analytics.dart';
import '../application/maintenance/local_service_reminder_scheduler.dart';
import '../application/maintenance/maintenance_record_service.dart';
import '../application/portability/data_portability_service.dart';
import '../application/vehicle/vehicle_lifecycle_service.dart';
import '../data/database/app_database.dart';
import '../data/repositories/attachment_repository.dart';
import '../data/repositories/fuel_event_repository.dart';
import '../data/repositories/maintenance_repository.dart';
import '../data/repositories/service_reminder_repository.dart';
import '../data/repositories/vehicle_repository.dart';
import '../domain/maintenance/maintenance.dart';
import '../domain/odometer/odometer_value.dart';
import '../presentation/fuel/cycle_details_screen.dart';
import '../presentation/fuel/fuel_event_details_screen.dart';
import '../presentation/fuel/fuel_event_form_screen.dart';
import '../presentation/fuel/fuel_history_screen.dart';
import '../presentation/analytics/analytics_screen.dart';
import '../presentation/maintenance/maintenance_history_screen.dart';
import '../presentation/settings/data_management_screen.dart';
import '../presentation/settings/vehicle_lifecycle_screen.dart';
import '../presentation/settings/vehicle_setup_screen.dart';
import '../presentation/theme/app_theme.dart';

class StageFourPreviewApp extends StatefulWidget {
  const StageFourPreviewApp({
    super.key,
    this.seedPreviewData = false,
    this.useInMemoryDatabase = false,
  });

  final bool seedPreviewData;
  final bool useInMemoryDatabase;

  @override
  State<StageFourPreviewApp> createState() => _StageFourPreviewAppState();
}

class _StageFourPreviewAppState extends State<StageFourPreviewApp> {
  late final AppDatabase _database;
  late final AttachmentFileStore _fileStore;
  late final ServiceReminderScheduler _scheduler;
  late Future<Vehicle?> _activeVehicle;

  FuelEventRepository get _fuel => FuelEventRepository(_database);
  MaintenanceRepository get _maintenance => MaintenanceRepository(_database);

  CreateFuelEvent get _createFuel => CreateFuelEvent(
    fuelEvents: _fuel,
    maintenance: _maintenance,
    onOdometerUpdated: _maintenanceService.reconcileReminders,
  );

  UpdateFuelEvent get _updateFuel => UpdateFuelEvent(
    fuelEvents: _fuel,
    maintenance: _maintenance,
    onOdometerUpdated: _maintenanceService.reconcileReminders,
  );

  MaintenanceRecordService get _maintenanceService => MaintenanceRecordService(
    database: _database,
    maintenance: _maintenance,
    fuelEvents: _fuel,
    attachments: AttachmentRepository(_database),
    reminders: ServiceReminderRepository(_database),
    fileStore: _fileStore,
    scheduler: _scheduler,
  );

  LoadAnalytics get _loadAnalytics => LoadAnalytics(
    fuelEvents: _fuel,
    maintenance: _maintenance,
    reminders: ServiceReminderRepository(_database),
  );

  DataPortabilityService get _portability =>
      DataPortabilityService(_database, _fileStore);

  VehicleLifecycleService get _vehicleLifecycle => VehicleLifecycleService(
    database: _database,
    fileStore: _fileStore,
    scheduler: _scheduler,
  );

  @override
  void initState() {
    super.initState();
    _database = widget.useInMemoryDatabase
        ? AppDatabase.forTesting(NativeDatabase.memory())
        : AppDatabase();
    _fileStore = widget.useInMemoryDatabase
        ? _InMemoryAttachmentFileStore()
        : AppAttachmentFileStore();
    _scheduler = widget.useInMemoryDatabase
        ? const NoopServiceReminderScheduler()
        : LocalServiceReminderScheduler();
    _activeVehicle = widget.seedPreviewData ? _seed() : _loadActiveVehicle();
  }

  Future<Vehicle?> _loadActiveVehicle() async {
    final vehicle = await VehicleRepository(_database).findActive();
    if (vehicle != null) {
      await _maintenanceService.reconcileReminders(vehicle.id);
    }
    return vehicle;
  }

  Future<void> _refreshActiveVehicle() async {
    final active = _loadActiveVehicle();
    if (!mounted) return;
    setState(() {
      _activeVehicle = active;
    });
    await active;
  }

  Future<Vehicle> _seed() async {
    final vehicleId = await VehicleRepository(_database).create(
      VehiclesCompanion.insert(
        displayName: 'Proton S70',
        startingOdometerKm: const Value(10000.0),
      ),
    );
    final now = DateTime.now();
    for (final fixture in [
      (14, 10000.0, 'PETRONAS', 40000, 7000, true),
      (7, 10200.0, 'Shell', 12000, 3000, false),
      (1, 10450.0, 'Petron', 18000, 3600, true),
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
        odometerKm: 10450.0,
        category: MaintenanceCategory.service,
        workshop: const Value('Proton Service Centre'),
        serviceTitle: const Value('General Service'),
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
        targetOdometerKm: const Value(20000.0),
      ),
    );
    final tyreRecordId = await _maintenance.createRecord(
      MaintenanceRecordsCompanion.insert(
        vehicleId: vehicleId,
        occurredAt: now.subtract(const Duration(hours: 6)).toUtc(),
        odometerKm: 10450.0,
        category: MaintenanceCategory.service,
        workshop: const Value('Tyre Specialist'),
        serviceTitle: const Value('Tyre Rotation'),
        totalCostSen: 12000,
      ),
    );
    await _maintenance.createItem(
      MaintenanceItemsCompanion.insert(
        vehicleId: vehicleId,
        maintenanceRecordId: tyreRecordId,
        name: 'Tyre inspection',
        description: const Value('Rotation and pressure check'),
        costSen: 12000,
      ),
    );
    await ServiceReminderRepository(_database).create(
      ServiceRemindersCompanion.insert(
        vehicleId: vehicleId,
        maintenanceRecordId: tyreRecordId,
        targetDate: Value(now.add(const Duration(days: 90)).toUtc()),
        targetOdometerKm: const Value(15000.0),
      ),
    );
    return (await VehicleRepository(_database).findById(vehicleId))!;
  }

  Future<void> _createInitialVehicle(VehicleSetupData setup) async {
    final now = DateTime.now().toUtc();
    final repository = VehicleRepository(_database);
    final id = await repository.create(
      VehiclesCompanion.insert(
        displayName: setup.name,
        registrationNumber: Value(setup.registrationNumber),
        startingOdometerKm: Value(setup.startingOdometerKm),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    if (!mounted) return;
    setState(() {
      _activeVehicle = repository.findById(id);
    });
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Car Tracker',
    theme: AppTheme.dark,
    home: FutureBuilder<Vehicle?>(
      future: _activeVehicle,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Could not load vehicle data.')),
          );
        }
        final vehicle = snapshot.data;
        if (vehicle == null) {
          return FirstRunVehicleSetupScreen(onConfirm: _createInitialVehicle);
        }
        final vehicleId = vehicle.id;
        return _PreviewHome(
          vehicleName: vehicle.displayName,
          loadCurrentOdometer: () async =>
              (await _maintenanceService.loadHistory(vehicleId))
                  .currentOdometerKm ??
              vehicle.startingOdometerKm,
          openAnalytics: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => AnalyticsScreen(
                  vehicleId: vehicleId,
                  loadAnalytics: _loadAnalytics.call,
                ),
              ),
            );
          },
          openSettings: () async {
            await Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => DataManagementScreen(
                  service: _portability,
                  onDataRestored: _refreshActiveVehicle,
                  vehicleLifecycleBuilder: (_) => VehicleLifecycleScreen(
                    currentVehicle: vehicle,
                    vehicles: VehicleRepository(_database),
                    deletePastVehicle: _vehicleLifecycle.deleteRetiredVehicle,
                    onVehicleRetired:
                        _vehicleLifecycle.cancelVehicleNotifications,
                    pastFuelBuilder: (_, pastVehicle) => FuelHistoryScreen(
                      vehicleId: pastVehicle.id,
                      loadFuelHistory: LoadFuelHistory(fuelEvents: _fuel).call,
                      readOnly: true,
                      cycleDetailsBuilder: (_, cycle, number) =>
                          CycleDetailsScreen(cycle: cycle, cycleNumber: number),
                    ),
                    pastMaintenanceBuilder: (_, pastVehicle) =>
                        MaintenanceHistoryScreen(
                          vehicleId: pastVehicle.id,
                          service: _maintenanceService,
                          fileStore: _fileStore,
                          readOnly: true,
                        ),
                    pastAnalyticsBuilder: (_, pastVehicle) => AnalyticsScreen(
                      vehicleId: pastVehicle.id,
                      loadAnalytics: _loadAnalytics.call,
                    ),
                  ),
                ),
              ),
            );
            if (mounted) await _refreshActiveVehicle();
          },
          openFuel: () async {
            await Navigator.push<void>(
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
                        deleteFuelEvent: DeleteFuelEvent(
                          fuelEvents: _fuel,
                          onOdometerUpdated:
                              _maintenanceService.reconcileReminders,
                        ),
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
                              deleteFuelEvent: DeleteFuelEvent(
                                fuelEvents: _fuel,
                                onOdometerUpdated:
                                    _maintenanceService.reconcileReminders,
                              ),
                            ),
                      ),
                ),
              ),
            );
          },
          openMaintenance: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => MaintenanceHistoryScreen(
                  vehicleId: vehicleId,
                  service: _maintenanceService,
                  fileStore: _fileStore,
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _PreviewHome extends StatefulWidget {
  const _PreviewHome({
    required this.vehicleName,
    required this.loadCurrentOdometer,
    required this.openFuel,
    required this.openMaintenance,
    required this.openAnalytics,
    required this.openSettings,
  });

  final String vehicleName;
  final Future<double?> Function() loadCurrentOdometer;
  final Future<void> Function() openFuel;
  final Future<void> Function() openMaintenance;
  final Future<void> Function() openAnalytics;
  final Future<void> Function() openSettings;

  @override
  State<_PreviewHome> createState() => _PreviewHomeState();
}

class _PreviewHomeState extends State<_PreviewHome> {
  late Future<double?> _currentOdometer;

  @override
  void initState() {
    super.initState();
    _currentOdometer = widget.loadCurrentOdometer();
  }

  @override
  void didUpdateWidget(covariant _PreviewHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicleName != widget.vehicleName) {
      _currentOdometer = widget.loadCurrentOdometer();
    }
  }

  Future<void> _open(Future<void> Function() destination) async {
    await destination();
    if (!mounted) return;
    setState(() {
      _currentOdometer = widget.loadCurrentOdometer();
    });
  }

  String _formattedOdometer(double currentOdometerKm) =>
      formatOdometerKm(currentOdometerKm);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.teal,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: 12),
          ),
          SizedBox(width: 12),
          Text('Car Tracker'),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => _open(widget.openSettings),
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListView(
      key: const Key('home-screen'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const Text(
          'MY VEHICLE',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.vehicleName,
          key: const Key('home-vehicle-name'),
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.speed_outlined, color: AppColors.teal, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'CURRENT ODOMETER',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<double?>(
                  future: _currentOdometer,
                  builder: (context, snapshot) => Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: snapshot.hasData
                              ? _formattedOdometer(snapshot.requireData!)
                              : '—',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                          text: ' km',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Updated from your latest Fuel or Maintenance record',
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 34),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Destination(
                  key: const Key('preview-fuel'),
                  icon: Icons.local_gas_station_outlined,
                  title: 'Fuel Logs',
                  subtitle: 'Cycles and refuels',
                  accent: AppColors.primary,
                  compact: true,
                  onTap: () => _open(widget.openFuel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Destination(
                  key: const Key('preview-maintenance'),
                  icon: Icons.build_outlined,
                  title: 'Maintenance',
                  subtitle: 'Service and repairs',
                  accent: AppColors.teal,
                  compact: true,
                  onTap: () => _open(widget.openMaintenance),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: _Destination(
            icon: Icons.bar_chart_outlined,
            title: 'View analytics',
            subtitle: 'Consumption and cost trends',
            accent: AppColors.primary,
            onTap: () => _open(widget.openAnalytics),
          ),
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
    required this.accent,
    required this.onTap,
    this.compact = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 16),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: accent, size: 34),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Icon(icon, color: accent, size: 34),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class _InMemoryAttachmentFileStore implements AttachmentFileStore {
  int _nextFile = 0;

  @override
  Future<String> absolutePath(String relativePath) async => relativePath;

  @override
  Future<void> deleteFile(String relativePath) async {}

  @override
  Future<void> deleteRecordDirectory(int recordId) async {}

  @override
  Future<String> importFile(
    int recordId,
    MaintenanceAttachmentInput input,
  ) async => '$recordId/${_nextFile++}_${input.fileName}';
}
