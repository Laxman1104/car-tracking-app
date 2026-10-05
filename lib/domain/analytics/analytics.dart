import '../fuel/fuel_cycle.dart';
import '../maintenance/maintenance.dart';

class MaintenanceAnalyticsRecord {
  const MaintenanceAnalyticsRecord({
    required this.id,
    required this.occurredAt,
    required this.odometerKm,
    required this.category,
    required this.costSen,
    required this.workshop,
  });

  final int id;
  final DateTime occurredAt;
  final double? odometerKm;
  final MaintenanceCategory category;
  final int costSen;
  final String? workshop;
}

class MonthlySpending {
  const MonthlySpending({
    required this.year,
    required this.month,
    required this.fuelCostSen,
    required this.maintenanceCostSen,
  });

  final int year;
  final int month;
  final int fuelCostSen;
  final int maintenanceCostSen;
  int get totalCostSen => fuelCostSen + maintenanceCostSen;
}

class MonthlyFuelEfficiency {
  const MonthlyFuelEfficiency({
    required this.year,
    required this.month,
    required this.distanceKm,
    required this.fuelMillilitres,
  });

  final int year;
  final int month;
  final double distanceKm;
  final int fuelMillilitres;
  double? get kmPerL => distanceKm == 0 || fuelMillilitres == 0
      ? null
      : distanceKm * 1000 / fuelMillilitres;
}

class BrandEfficiencySummary {
  const BrandEfficiencySummary({
    required this.brand,
    required this.cycleCount,
    required this.distanceKm,
    required this.fuelMillilitres,
  });

  final String brand;
  final int cycleCount;
  final double distanceKm;
  final int fuelMillilitres;
  double? get kmPerL => distanceKm == 0 || fuelMillilitres == 0
      ? null
      : distanceKm * 1000 / fuelMillilitres;
}

class MaintenanceCategorySummary {
  const MaintenanceCategorySummary({
    required this.category,
    required this.recordCount,
    required this.costSen,
    required this.spendingShare,
  });

  final MaintenanceCategory category;
  final int recordCount;
  final int costSen;
  final double spendingShare;
}

class UpcomingServiceReminder {
  const UpcomingServiceReminder({
    required this.maintenanceRecordId,
    required this.title,
    this.targetDate,
    this.targetOdometerKm,
  });

  final int maintenanceRecordId;
  final String title;
  final DateTime? targetDate;
  final double? targetOdometerKm;
}

class CarAnalytics {
  const CarAnalytics({
    required this.fuelEvents,
    required this.completedCycles,
    required this.maintenanceRecords,
    required this.latestCycle,
    required this.lifetimeKmPerL,
    required this.rollingFiveKmPerL,
    required this.completedCycleCostPerKm,
    required this.totalFuelMillilitres,
    required this.totalFuelCostSen,
    required this.totalMaintenanceCostSen,
    required this.trackedDistanceKm,
    required this.monthlySpending,
    required this.monthlyFuelEfficiency,
    required this.brandEfficiency,
    required this.maintenanceCategories,
    required this.upcomingServiceReminders,
  });

  final List<FuelEventSnapshot> fuelEvents;
  final List<CompletedFuelCycle> completedCycles;
  final List<MaintenanceAnalyticsRecord> maintenanceRecords;
  final CompletedFuelCycle? latestCycle;
  final double? lifetimeKmPerL;
  final double? rollingFiveKmPerL;
  final double? completedCycleCostPerKm;
  final int totalFuelMillilitres;
  final int totalFuelCostSen;
  final int totalMaintenanceCostSen;
  final double? trackedDistanceKm;
  final List<MonthlySpending> monthlySpending;
  final List<MonthlyFuelEfficiency> monthlyFuelEfficiency;
  final List<BrandEfficiencySummary> brandEfficiency;
  final List<MaintenanceCategorySummary> maintenanceCategories;
  final List<UpcomingServiceReminder> upcomingServiceReminders;

  int get fillCount => fuelEvents.length;
  double get completedCycleDistanceKm =>
      completedCycles.fold(0.0, (sum, cycle) => sum + cycle.distanceKm);
  int get completedCycleFuelCostSen =>
      completedCycles.fold(0, (sum, cycle) => sum + cycle.fuelCostSen);
  int get maintenanceRecordCount => maintenanceRecords.length;
  int get maintenanceExpenditureRecordCount => maintenanceRecords
      .where((record) => record.category != MaintenanceCategory.accessories)
      .length;
  int get totalOwnershipCostSen => totalFuelCostSen + totalMaintenanceCostSen;
  double? get ownershipCostPerKm => trackedDistanceKm == null
      ? null
      : totalOwnershipCostSen / 100 / trackedDistanceKm!;
}

class CarAnalyticsEngine {
  const CarAnalyticsEngine({this.rollingWindow = 5});

  final int rollingWindow;

  CarAnalytics build({
    required Iterable<FuelEventSnapshot> fuelEvents,
    required FuelCycleBuildResult fuelHistory,
    required Iterable<MaintenanceAnalyticsRecord> maintenanceRecords,
    Iterable<UpcomingServiceReminder> upcomingServiceReminders = const [],
  }) {
    final events = fuelEvents.toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final maintenance = maintenanceRecords.toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final cycles = fuelHistory.completedCycles;
    final recent = cycles.length <= rollingWindow
        ? cycles
        : cycles.sublist(cycles.length - rollingWindow);
    final totalFuelCost = events.fold<int>(0, (sum, e) => sum + e.costSen);
    final ownershipMaintenance = maintenance
        .where((record) => record.category != MaintenanceCategory.accessories)
        .fold<int>(0, (sum, record) => sum + record.costSen);
    return CarAnalytics(
      fuelEvents: List.unmodifiable(events),
      completedCycles: List.unmodifiable(cycles),
      maintenanceRecords: List.unmodifiable(maintenance),
      latestCycle: cycles.isEmpty ? null : cycles.last,
      lifetimeKmPerL: _weightedEfficiency(cycles),
      rollingFiveKmPerL: _weightedEfficiency(recent),
      completedCycleCostPerKm: _costPerKm(cycles),
      totalFuelMillilitres: events.fold(
        0,
        (sum, event) => sum + event.fuelVolumeMillilitres,
      ),
      totalFuelCostSen: totalFuelCost,
      totalMaintenanceCostSen: ownershipMaintenance,
      trackedDistanceKm: _trackedDistance(events, maintenance),
      monthlySpending: _monthlySpending(events, maintenance),
      monthlyFuelEfficiency: _monthlyEfficiency(cycles),
      brandEfficiency: _brandEfficiency(cycles),
      maintenanceCategories: _maintenanceCategories(
        maintenance,
        ownershipMaintenance,
      ),
      upcomingServiceReminders: List.unmodifiable(upcomingServiceReminders),
    );
  }

  double? _weightedEfficiency(Iterable<CompletedFuelCycle> cycles) {
    final valid = cycles.where((cycle) => cycle.distanceKm > 0);
    final distance = valid.fold<double>(
      0,
      (sum, cycle) => sum + cycle.distanceKm,
    );
    final fuel = valid.fold<int>(
      0,
      (sum, cycle) => sum + cycle.fuelConsumedMillilitres,
    );
    return distance == 0 || fuel == 0 ? null : distance * 1000 / fuel;
  }

  double? _costPerKm(Iterable<CompletedFuelCycle> cycles) {
    final valid = cycles.where((cycle) => cycle.distanceKm > 0);
    final distance = valid.fold<double>(
      0,
      (sum, cycle) => sum + cycle.distanceKm,
    );
    final cost = valid.fold<int>(0, (sum, cycle) => sum + cycle.fuelCostSen);
    return distance == 0 ? null : cost / 100 / distance;
  }

  double? _trackedDistance(
    List<FuelEventSnapshot> fuel,
    List<MaintenanceAnalyticsRecord> maintenance,
  ) {
    final values = [
      ...fuel.map((event) => event.odometerKm),
      ...maintenance.map((record) => record.odometerKm).whereType<double>(),
    ];
    if (values.length < 2) return null;
    values.sort();
    final distance = values.last - values.first;
    return distance == 0 ? null : distance;
  }

  List<MonthlySpending> _monthlySpending(
    List<FuelEventSnapshot> fuel,
    List<MaintenanceAnalyticsRecord> maintenance,
  ) {
    final values = <(int, int), (int, int)>{};
    for (final event in fuel) {
      final key = (event.occurredAt.year, event.occurredAt.month);
      final old = values[key] ?? (0, 0);
      values[key] = (old.$1 + event.costSen, old.$2);
    }
    for (final record in maintenance.where(
      (record) => record.category != MaintenanceCategory.accessories,
    )) {
      final key = (record.occurredAt.year, record.occurredAt.month);
      final old = values[key] ?? (0, 0);
      values[key] = (old.$1, old.$2 + record.costSen);
    }
    final keys = values.keys.toList()
      ..sort(
        (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
      );
    return List.unmodifiable(
      keys.map(
        (key) => MonthlySpending(
          year: key.$1,
          month: key.$2,
          fuelCostSen: values[key]!.$1,
          maintenanceCostSen: values[key]!.$2,
        ),
      ),
    );
  }

  List<MonthlyFuelEfficiency> _monthlyEfficiency(
    List<CompletedFuelCycle> cycles,
  ) {
    final values = <(int, int), (double, int)>{};
    for (final cycle in cycles.where((entry) => entry.distanceKm > 0)) {
      final date = cycle.closingFull.occurredAt;
      final key = (date.year, date.month);
      final old = values[key] ?? (0.0, 0);
      values[key] = (
        old.$1 + cycle.distanceKm,
        old.$2 + cycle.fuelConsumedMillilitres,
      );
    }
    final keys = values.keys.toList()
      ..sort(
        (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
      );
    return List.unmodifiable(
      keys.map(
        (key) => MonthlyFuelEfficiency(
          year: key.$1,
          month: key.$2,
          distanceKm: values[key]!.$1,
          fuelMillilitres: values[key]!.$2,
        ),
      ),
    );
  }

  List<BrandEfficiencySummary> _brandEfficiency(
    List<CompletedFuelCycle> cycles,
  ) {
    final values = <String, (int, double, int)>{};
    for (final cycle in cycles.where(
      (entry) =>
          entry.brandKind == FuelCycleBrandKind.singleBrand &&
          entry.attributedBrand != null &&
          entry.distanceKm > 0,
    )) {
      final brand = cycle.attributedBrand!;
      final old = values[brand] ?? (0, 0.0, 0);
      values[brand] = (
        old.$1 + 1,
        old.$2 + cycle.distanceKm,
        old.$3 + cycle.fuelConsumedMillilitres,
      );
    }
    final result =
        values.entries
            .map(
              (entry) => BrandEfficiencySummary(
                brand: entry.key,
                cycleCount: entry.value.$1,
                distanceKm: entry.value.$2,
                fuelMillilitres: entry.value.$3,
              ),
            )
            .toList()
          ..sort((a, b) => (b.kmPerL ?? 0).compareTo(a.kmPerL ?? 0));
    return List.unmodifiable(result);
  }

  List<MaintenanceCategorySummary> _maintenanceCategories(
    List<MaintenanceAnalyticsRecord> records,
    int totalCost,
  ) => List.unmodifiable(
    MaintenanceCategory.values.map((category) {
      final matches = records.where((record) => record.category == category);
      final cost = matches.fold<int>(0, (sum, record) => sum + record.costSen);
      return MaintenanceCategorySummary(
        category: category,
        recordCount: matches.length,
        costSen: cost,
        spendingShare:
            category == MaintenanceCategory.accessories || totalCost == 0
            ? 0
            : cost / totalCost,
      );
    }),
  );
}
