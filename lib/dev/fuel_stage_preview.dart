import 'package:drift/native.dart';
import 'package:flutter/material.dart';

import '../application/fuel/create_fuel_event.dart';
import '../application/fuel/load_fuel_history.dart';
import '../data/database/app_database.dart';
import '../data/repositories/fuel_event_repository.dart';
import '../data/repositories/maintenance_repository.dart';
import '../data/repositories/vehicle_repository.dart';
import '../presentation/fuel/cycle_details_screen.dart';
import '../presentation/fuel/fuel_event_form_screen.dart';
import '../presentation/fuel/fuel_history_screen.dart';
import '../presentation/theme/app_theme.dart';

class FuelStagePreviewApp extends StatefulWidget {
  const FuelStagePreviewApp({super.key});

  @override
  State<FuelStagePreviewApp> createState() => _FuelStagePreviewAppState();
}

class _FuelStagePreviewAppState extends State<FuelStagePreviewApp> {
  late final AppDatabase _database;
  late final Future<int> _vehicleId;

  FuelEventRepository get _fuelEvents => FuelEventRepository(_database);

  CreateFuelEvent get _saveFuel => CreateFuelEvent(
    fuelEvents: _fuelEvents,
    maintenance: MaintenanceRepository(_database),
  );

  @override
  void initState() {
    super.initState();
    _database = AppDatabase.forTesting(NativeDatabase.memory());
    _vehicleId = _seedPreview();
  }

  Future<int> _seedPreview() async {
    final vehicleId = await VehicleRepository(_database)
        .create(VehiclesCompanion.insert(displayName: 'Stage 2 Preview Car'));
    final now = DateTime.now();
    final fixtures = [
      (14, 10000.0, 'PETRONAS', 40000, 7000, true),
      (7, 10200.0, 'Shell', 12000, 3000, false),
      (1, 10450.0, 'Petron', 18000, 3600, true),
    ];
    for (final fixture in fixtures) {
      await _saveFuel(
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
    return vehicleId;
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car Tracker · Stage 2 Preview',
      theme: AppTheme.dark,
      home: FutureBuilder<int>(
        future: _vehicleId,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Could not start the Stage 2 preview.')),
            );
          }
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final vehicleId = snapshot.requireData;
          return FuelHistoryScreen(
            vehicleId: vehicleId,
            loadFuelHistory: LoadFuelHistory(fuelEvents: _fuelEvents).call,
            fuelFormBuilder: (context, saved) => FuelEventFormScreen(
              vehicleId: vehicleId,
              createFuelEvent: _saveFuel,
              onSaved: (_) => saved(),
            ),
            cycleDetailsBuilder: (context, cycle, number) =>
                CycleDetailsScreen(cycle: cycle, cycleNumber: number),
          );
        },
      ),
    );
  }
}
