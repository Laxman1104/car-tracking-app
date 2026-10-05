import 'package:car_tracking_app/application/fuel/create_fuel_event.dart';
import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:car_tracking_app/data/repositories/fuel_event_repository.dart';
import 'package:car_tracking_app/data/repositories/maintenance_repository.dart';
import 'package:car_tracking_app/data/repositories/vehicle_repository.dart';
import 'package:car_tracking_app/presentation/fuel/fuel_event_form_screen.dart';
import 'package:car_tracking_app/presentation/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late FuelEventRepository fuelEvents;
  late CreateFuelEvent createFuelEvent;
  late int vehicleId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    fuelEvents = FuelEventRepository(database);
    createFuelEvent = CreateFuelEvent(
      fuelEvents: fuelEvents,
      maintenance: MaintenanceRepository(database),
    );
    vehicleId = await VehicleRepository(database)
        .create(VehiclesCompanion.insert(displayName: 'Synthetic Test Car'));
  });

  tearDown(() => database.close());

  Future<void> pumpForm(
    WidgetTester tester, {
    FuelEventSaved? onSaved,
    DateTime? occurredAt,
  }) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: FuelEventFormScreen(
          vehicleId: vehicleId,
          createFuelEvent: createFuelEvent,
          initialOccurredAt: occurredAt ?? DateTime.utc(2026, 6, 14, 17, 35),
          onSaved: onSaved,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillRequiredFields(
    WidgetTester tester, {
    String odometer = '10240',
    String cost = '68.00',
  }) async {
    await tester.enterText(
      find.byKey(const Key('fuel-odometer-field')),
      odometer,
    );
    await tester.tap(find.byKey(const Key('fuel-brand-shell')));
    await tester.enterText(find.byKey(const Key('fuel-litres-field')), '32.40');
    await tester.enterText(find.byKey(const Key('fuel-cost-field')), cost);
    await tester.tap(find.text('Yes'));
  }

  Future<void> tapSave(WidgetTester tester) async {
    final save = find.byKey(const Key('save-fuel-event-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('renders the required controls in design order', (tester) async {
    await pumpForm(tester);

    final odometer = tester.getTopLeft(
      find.byKey(const Key('fuel-odometer-field')),
    );
    final shell = tester.getTopLeft(find.byKey(const Key('fuel-brand-shell')));
    final litres = tester.getTopLeft(
      find.byKey(const Key('fuel-litres-field')),
    );
    final cost = tester.getTopLeft(find.byKey(const Key('fuel-cost-field')));

    expect(find.text('New Fuel Event'), findsOneWidget);
    expect(find.text('PETRONAS'), findsOneWidget);
    expect(find.text('BHPetrol'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(odometer.dy, lessThan(shell.dy));
    expect(shell.dy, lessThan(litres.dy));
    expect(litres.dy, lessThan(cost.dy));
  });

  testWidgets('RM0 caution remains non-blocking and persists exact values', (
    tester,
  ) async {
    int? savedId;
    await pumpForm(tester, onSaved: (id) => savedId = id);
    await fillRequiredFields(tester, cost: '0');
    await tester.pump();

    expect(find.byKey(const Key('zero-cost-caution')), findsOneWidget);
    await tapSave(tester);

    expect(savedId, isNotNull);
    final saved = await fuelEvents.findById(savedId!);
    expect(saved!.fuelVolumeMillilitres, 32400);
    expect(saved.costSen, 0);
    expect(saved.isFullTank, isTrue);
  });

  testWidgets('Trip B mismatch is inline and does not block saving', (
    tester,
  ) async {
    await createFuelEvent(
      FuelEventInput(
        vehicleId: vehicleId,
        occurredAt: DateTime.utc(2026, 6, 1),
        odometerKm: 10000,
        fuelBrand: 'PETRONAS',
        fuelVolumeMillilitres: 40000,
        costSen: 7000,
        isFullTank: true,
      ),
    );
    int? savedId;
    await pumpForm(tester, onSaved: (id) => savedId = id);
    await fillRequiredFields(tester, odometer: '10430');
    await tester.enterText(find.byKey(const Key('fuel-trip-b-field')), '434');
    await tester.pumpAndSettle();

    expect(find.text('Mismatch detected — Difference of 4 km'), findsOneWidget);
    await tapSave(tester);
    expect(savedId, isNotNull);
  });

  testWidgets('chronology conflict is field-local and blocks persistence', (
    tester,
  ) async {
    await createFuelEvent(
      FuelEventInput(
        vehicleId: vehicleId,
        occurredAt: DateTime.utc(2026, 6, 1),
        odometerKm: 10000,
        fuelBrand: 'PETRONAS',
        fuelVolumeMillilitres: 40000,
        costSen: 7000,
        isFullTank: true,
      ),
    );
    await createFuelEvent(
      FuelEventInput(
        vehicleId: vehicleId,
        occurredAt: DateTime.utc(2026, 6, 20),
        odometerKm: 10500,
        fuelBrand: 'Shell',
        fuelVolumeMillilitres: 30000,
        costSen: 6000,
        isFullTank: true,
      ),
    );
    await pumpForm(tester, occurredAt: DateTime.utc(2026, 6, 14));
    await fillRequiredFields(tester, odometer: '10600');
    await tapSave(tester);

    expect(
      find.text('Odometer must not exceed 10,500 km for this date and time.'),
      findsOneWidget,
    );
    expect((await fuelEvents.findForVehicle(vehicleId)).length, 2);
  });

  testWidgets('required brand and Full Tank choices report inline errors', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.enterText(
      find.byKey(const Key('fuel-odometer-field')),
      '10240',
    );
    await tester.enterText(find.byKey(const Key('fuel-litres-field')), '32.4');
    await tester.enterText(find.byKey(const Key('fuel-cost-field')), '68');
    await tapSave(tester);

    expect(find.text('Choose a fuel brand.'), findsOneWidget);
    expect(find.text('Choose Yes or No for Full tank.'), findsOneWidget);
    expect(await fuelEvents.findForVehicle(vehicleId), isEmpty);
  });
}
