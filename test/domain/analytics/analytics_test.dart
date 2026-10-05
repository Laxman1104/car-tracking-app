import 'package:car_tracking_app/domain/analytics/analytics.dart';
import 'package:car_tracking_app/domain/fuel/fuel_cycle.dart';
import 'package:car_tracking_app/domain/maintenance/maintenance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FuelEventSnapshot event(
    int id,
    int day,
    double odometer,
    String brand,
    int ml,
    int sen,
    bool full,
  ) => FuelEventSnapshot(
    id: id,
    vehicleId: 1,
    occurredAt: DateTime.utc(2027, 1, day),
    odometerKm: odometer,
    fuelBrand: brand,
    fuelVolumeMillilitres: ml,
    costSen: sen,
    isFullTank: full,
  );

  test(
    'calculates weighted fuel, ownership, monthly, and category summaries',
    () {
      final events = [
        event(1, 1, 10000, 'PETRONAS', 40000, 7000, true),
        event(2, 5, 10200, 'Shell', 12000, 3000, false),
        event(3, 10, 10450, 'Petron', 18000, 3600, true),
        event(4, 20, 10900, 'Petron', 30000, 6000, true),
      ];
      final history = const FuelCycleEngine().build(events);
      final analytics = const CarAnalyticsEngine().build(
        fuelEvents: events,
        fuelHistory: history,
        maintenanceRecords: [
          MaintenanceAnalyticsRecord(
            id: 1,
            occurredAt: DateTime.utc(2027, 1, 15),
            odometerKm: 10600,
            category: MaintenanceCategory.service,
            costSen: 62000,
            workshop: 'Synthetic Centre',
          ),
          MaintenanceAnalyticsRecord(
            id: 2,
            occurredAt: DateTime.utc(2027, 1, 16),
            odometerKm: 10600,
            category: MaintenanceCategory.repairs,
            costSen: 0,
            workshop: 'Warranty Centre',
          ),
          MaintenanceAnalyticsRecord(
            id: 3,
            occurredAt: DateTime.utc(2027, 1, 17),
            odometerKm: null,
            category: MaintenanceCategory.accessories,
            costSen: 15000,
            workshop: 'Accessory Shop',
          ),
        ],
      );

      expect(analytics.latestCycle!.distanceKm, 450);
      expect(analytics.lifetimeKmPerL, closeTo(15, 0.0001));
      expect(analytics.rollingFiveKmPerL, closeTo(15, 0.0001));
      expect(analytics.totalFuelCostSen, 19600);
      expect(analytics.totalFuelMillilitres, 100000);
      expect(analytics.totalMaintenanceCostSen, 62000);
      expect(analytics.totalOwnershipCostSen, 81600);
      expect(analytics.trackedDistanceKm, 900);
      expect(analytics.monthlySpending.single.totalCostSen, 81600);
      expect(
        analytics.maintenanceCategories
            .firstWhere((e) => e.category == MaintenanceCategory.accessories)
            .costSen,
        15000,
      );
      expect(
        analytics.maintenanceCategories
            .firstWhere((e) => e.category == MaintenanceCategory.repairs)
            .recordCount,
        1,
      );
    },
  );

  test('mixed cycles stay overall but are excluded from brand comparison', () {
    final events = [
      event(1, 1, 10000, 'PETRONAS', 40000, 7000, true),
      event(2, 5, 10200, 'Shell', 12000, 3000, false),
      event(3, 10, 10450, 'Petron', 18000, 3600, true),
      event(4, 20, 10900, 'Petron', 30000, 6000, true),
    ];
    final history = const FuelCycleEngine().build(events);
    final analytics = const CarAnalyticsEngine().build(
      fuelEvents: events,
      fuelHistory: history,
      maintenanceRecords: [],
    );

    expect(analytics.completedCycles, hasLength(2));
    expect(analytics.brandEfficiency, hasLength(1));
    expect(analytics.brandEfficiency.single.brand, 'Petron');
    expect(analytics.brandEfficiency.single.cycleCount, 1);
  });

  test(
    'completed-cycle cost excludes opening Full and pending fuel purchases',
    () {
      final events = [
        event(1, 1, 10000, 'PETRONAS', 45000, 10000, true),
        event(2, 5, 12000, 'PETRONAS', 20000, 10000, false),
        event(3, 10, 14700, 'PETRONAS', 30000, 22900, true),
        event(4, 20, 14800, 'PETRONAS', 12000, 2548, false),
      ];
      final history = const FuelCycleEngine().build(events);
      final analytics = const CarAnalyticsEngine().build(
        fuelEvents: events,
        fuelHistory: history,
        maintenanceRecords: [],
      );

      expect(analytics.totalFuelCostSen, 45448);
      expect(analytics.completedCycleDistanceKm, 4700);
      expect(analytics.completedCycleFuelCostSen, 32900);
      expect(analytics.completedCycleCostPerKm, closeTo(0.07, 0.000001));
    },
  );
}
