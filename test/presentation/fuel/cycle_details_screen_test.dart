import 'package:car_tracking_app/domain/fuel/fuel_cycle.dart';
import 'package:car_tracking_app/presentation/fuel/cycle_details_screen.dart';
import 'package:car_tracking_app/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FuelEventSnapshot event({
    required int id,
    required int day,
    required int odometer,
    required bool full,
    String brand = 'PETRONAS',
  }) {
    return FuelEventSnapshot(
      id: id,
      vehicleId: 1,
      occurredAt: DateTime.utc(2026, 6, day, 9),
      odometerKm: odometer,
      fuelBrand: brand,
      fuelVolumeMillilitres: 20000,
      costSen: 4000,
      isFullTank: full,
    );
  }

  CompletedFuelCycle cycle(List<FuelEventSnapshot> events) {
    return const FuelCycleEngine().build(events).completedCycles.single;
  }

  Future<void> pump(WidgetTester tester, CompletedFuelCycle value) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: CycleDetailsScreen(cycle: value, cycleNumber: 1),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Full-to-Full cycle always shows both boundary events', (
    tester,
  ) async {
    await pump(
      tester,
      cycle([
        event(id: 1, day: 1, odometer: 10000, full: true),
        event(id: 2, day: 14, odometer: 10400, full: true),
      ]),
    );

    expect(find.byKey(const Key('cycle-event-1')), findsOneWidget);
    expect(find.byKey(const Key('cycle-event-2')), findsOneWidget);
    expect(find.text('Start Full · Baseline'), findsOneWidget);
    expect(find.text('End Full · Closing'), findsOneWidget);
    expect(find.text('Not Full · Partial'), findsNothing);
  });

  testWidgets('partial events render between the Full boundaries', (
    tester,
  ) async {
    await pump(
      tester,
      cycle([
        event(id: 1, day: 1, odometer: 10000, full: true),
        event(id: 2, day: 7, odometer: 10200, full: false, brand: 'Shell'),
        event(id: 3, day: 14, odometer: 10450, full: true),
      ]),
    );

    expect(find.byKey(const Key('cycle-event-1')), findsOneWidget);
    expect(find.byKey(const Key('cycle-event-2')), findsOneWidget);
    expect(find.byKey(const Key('cycle-event-3')), findsOneWidget);
    expect(find.text('Not Full · Partial'), findsOneWidget);
    expect(find.text('11.25 km/L', findRichText: true), findsOneWidget);
  });
}
