import 'dart:async';

import 'package:car_tracking_app/domain/fuel/fuel_cycle.dart';
import 'package:car_tracking_app/presentation/fuel/fuel_history_screen.dart';
import 'package:car_tracking_app/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const empty = FuelCycleBuildResult(
    completedCycles: [],
    pendingCycle: null,
    preReferenceEvents: [],
  );

  FuelEventSnapshot event({
    required int id,
    required int odometer,
    required bool full,
    required String brand,
  }) {
    return FuelEventSnapshot(
      id: id,
      vehicleId: 1,
      occurredAt: DateTime.utc(2026, 6, id),
      odometerKm: odometer,
      fuelBrand: brand,
      fuelVolumeMillilitres: 10000,
      costSen: 2000,
      isFullTank: full,
    );
  }

  Future<void> pump(WidgetTester tester, FuelHistoryLoader loader) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: FuelHistoryScreen(
          vehicleId: 1,
          loadFuelHistory: loader,
          fuelFormBuilder: (_, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets('shows loading followed by the empty state', (tester) async {
    final completer = Completer<FuelCycleBuildResult>();
    await pump(tester, (_) => completer.future);
    expect(find.byKey(const Key('fuel-history-loading-state')), findsOneWidget);

    completer.complete(empty);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fuel-history-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('add-fuel-event-fab')), findsOneWidget);
  });

  testWidgets('shows a recoverable error state', (tester) async {
    await pump(tester, (_) => Future.error(StateError('synthetic failure')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fuel-history-error-state')), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('identifies a lone Full as the Starting Reference', (
    tester,
  ) async {
    final result = const FuelCycleEngine().build([
      event(id: 1, odometer: 10000, full: true, brand: 'PETRONAS'),
    ]);
    await pump(tester, (_) async => result);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pending-cycle-card')), findsOneWidget);
    expect(find.text('Starting reference'), findsOneWidget);
    expect(find.byKey(const Key('no-completed-cycles')), findsOneWidget);
  });

  testWidgets('renders Calculated, Mixed, zero-distance and semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final result = const FuelCycleEngine().build([
      event(id: 1, odometer: 5000, full: true, brand: 'PETRONAS'),
      event(id: 2, odometer: 5000, full: true, brand: 'Shell'),
      event(id: 3, odometer: 5200, full: false, brand: 'Petron'),
      event(id: 4, odometer: 5500, full: true, brand: 'BHPetrol'),
    ]);
    await pump(tester, (_) async => result);
    await tester.pumpAndSettle();

    expect(find.text('Mixed'), findsOneWidget);
    expect(find.text('CALCULATED'), findsNWidgets(2));
    expect(find.text('—', findRichText: true), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Calculated fuel cycle 2, Mixed')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
