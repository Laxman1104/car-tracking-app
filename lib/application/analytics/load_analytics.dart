import '../../data/mappers/history_mappers.dart';
import '../../data/repositories/fuel_event_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../data/repositories/service_reminder_repository.dart';
import '../../domain/analytics/analytics.dart';
import '../../domain/fuel/fuel_cycle.dart';
import '../../domain/maintenance/maintenance.dart';
import '../../domain/odometer/odometer_timeline.dart';

class LoadAnalytics {
  const LoadAnalytics({
    required this.fuelEvents,
    required this.maintenance,
    required this.reminders,
  });

  final FuelEventRepository fuelEvents;
  final MaintenanceRepository maintenance;
  final ServiceReminderRepository reminders;

  Future<CarAnalytics> call(int vehicleId) async {
    final fuelRows = await fuelEvents.findForVehicle(vehicleId);
    final snapshots = fuelRows.map((event) => event.toSnapshot()).toList();
    final maintenanceRows = await maintenance.findRecordsForVehicle(vehicleId);
    final reminderRows = await reminders.findForVehicle(vehicleId);
    final reminderByRecord = {
      for (final reminder in reminderRows)
        reminder.maintenanceRecordId: reminder,
    };
    final currentOdometer = const OdometerTimelineEngine().resolveCurrent([
      ...fuelRows.map((event) => event.toOdometerObservation()),
      ...maintenanceRows
          .map((record) => record.toOdometerObservation())
          .whereType<OdometerObservation>(),
    ])?.odometerKm;
    final now = DateTime.now().toUtc();
    final upcomingReminders = maintenanceRows
        .map((record) {
          final reminder = reminderByRecord[record.id];
          if (reminder == null || reminder.completedAt != null) return null;
          final dateIsUpcoming =
              reminder.targetDate == null || reminder.targetDate!.isAfter(now);
          final mileageIsUpcoming =
              reminder.targetOdometerKm == null ||
              currentOdometer == null ||
              reminder.targetOdometerKm! > currentOdometer;
          if (!dateIsUpcoming || !mileageIsUpcoming) return null;
          return UpcomingServiceReminder(
            maintenanceRecordId: record.id,
            title: record.serviceTitle ?? 'Next whole service',
            targetDate: reminder.targetDate,
            targetOdometerKm: reminder.targetOdometerKm,
          );
        })
        .whereType<UpcomingServiceReminder>()
        .toList();
    return const CarAnalyticsEngine().build(
      fuelEvents: snapshots,
      fuelHistory: const FuelCycleEngine().build(snapshots),
      maintenanceRecords: maintenanceRows.map(
        (record) => MaintenanceAnalyticsRecord(
          id: record.id,
          occurredAt: record.occurredAt,
          odometerKm: record.category == MaintenanceCategory.accessories
              ? null
              : record.odometerKm,
          category: record.category,
          costSen: record.totalCostSen,
          workshop: record.workshop,
        ),
      ),
      upcomingServiceReminders: upcomingReminders,
    );
  }
}
