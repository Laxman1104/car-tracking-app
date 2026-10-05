import 'package:car_tracking_app/domain/analytics/analytics.dart';
import 'package:car_tracking_app/domain/fuel/fuel_cycle.dart';
import 'package:car_tracking_app/domain/maintenance/maintenance.dart';
import 'package:car_tracking_app/presentation/analytics/analytics_screen.dart';
import 'package:car_tracking_app/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fuel analytics renders a monthly efficiency line chart', (
    tester,
  ) async {
    final events = [
      _event(1, DateTime.utc(2027, 1, 1), 10000, 40000, 7000),
      _event(2, DateTime.utc(2027, 1, 20), 10500, 35000, 6500),
      _event(3, DateTime.utc(2027, 2, 20), 11000, 30000, 6000),
    ];
    final analytics = const CarAnalyticsEngine().build(
      fuelEvents: events,
      fuelHistory: const FuelCycleEngine().build(events),
      maintenanceRecords: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: AnalyticsScreen(
          vehicleId: 1,
          loadAnalytics: (_) async => analytics,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('analytics-sections')),
        matching: find.text('Fuel'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Monthly km/L trajectory'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('monthly-efficiency-line-chart')), findsOne);
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Brand efficiency'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets(
    'maintenance analytics explains its total and omits accessory percentage',
    (tester) async {
      final analytics = const CarAnalyticsEngine().build(
        fuelEvents: [],
        fuelHistory: const FuelCycleEngine().build([]),
        maintenanceRecords: [
          MaintenanceAnalyticsRecord(
            id: 1,
            occurredAt: DateTime.utc(2027, 1, 1),
            odometerKm: null,
            category: MaintenanceCategory.accessories,
            costSen: 6332,
            workshop: 'Accessory Shop',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: AnalyticsScreen(
            vehicleId: 1,
            loadAnalytics: (_) async => analytics,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('analytics-sections')),
          matching: find.text('Maintenance'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Service + Repairs'), findsOneWidget);
      expect(find.text('RM0.00'), findsOneWidget);
      expect(
        find.byKey(const Key('accessories-separate-header')),
        findsOneWidget,
      );
      expect(
        find.text('Tracked separately from maintenance expenditure'),
        findsOneWidget,
      );
      expect(find.text('Accessories · 1'), findsOneWidget);
      expect(find.text('RM63.32', skipOffstage: false), findsWidgets);
      expect(
        find.textContaining('RM63.32 ·', skipOffstage: false),
        findsNothing,
      );
    },
  );
}

FuelEventSnapshot _event(
  int id,
  DateTime occurredAt,
  double odometerKm,
  int millilitres,
  int costSen,
) => FuelEventSnapshot(
  id: id,
  vehicleId: 1,
  occurredAt: occurredAt,
  odometerKm: odometerKm,
  fuelBrand: 'PETRONAS',
  fuelVolumeMillilitres: millilitres,
  costSen: costSen,
  isFullTank: true,
);
