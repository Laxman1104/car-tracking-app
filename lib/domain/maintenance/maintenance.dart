enum MaintenanceCategory { service, repairs, accessories }

class MaintenanceItemInput {
  const MaintenanceItemInput({
    required this.name,
    required this.costSen,
    this.description,
  });

  final String name;
  final String? description;
  final int costSen;
}

class ServiceReminderTarget {
  const ServiceReminderTarget({
    required this.vehicleId,
    required this.maintenanceRecordId,
    this.targetDate,
    this.targetOdometerKm,
  }) : assert(targetDate != null || targetOdometerKm != null);

  final int vehicleId;
  final int maintenanceRecordId;
  final DateTime? targetDate;
  final double? targetOdometerKm;
}

enum MaintenanceRuleIssue {
  itemNameRequired,
  itemCostCannotBeNegative,
  nonServiceCannotSetReminder,
  nextServiceOdometerCannotBeNegative,
}

class MaintenancePlanResult {
  const MaintenancePlanResult({required this.issues, required this.reminder});

  final Set<MaintenanceRuleIssue> issues;
  final ServiceReminderTarget? reminder;

  bool get isValid => issues.isEmpty;
}

enum ServiceReminderState { upcoming, due }

enum ServiceReminderTrigger { date, mileage }

class ServiceReminderEvaluation {
  const ServiceReminderEvaluation({
    required this.state,
    required this.reachedTriggers,
  });

  final ServiceReminderState state;
  final Set<ServiceReminderTrigger> reachedTriggers;

  bool get isDue => state == ServiceReminderState.due;
}

class ServiceIntervalProgress {
  const ServiceIntervalProgress({
    required this.travelledKm,
    required this.intervalKm,
    required this.remainingKm,
  });

  final double travelledKm;
  final double intervalKm;
  final double remainingKm;

  double get ratio => travelledKm / intervalKm;
  int get percentage => (ratio * 100).floor();
}

class MaintenanceDomainService {
  const MaintenanceDomainService();

  MaintenancePlanResult buildPlan({
    required int vehicleId,
    required int maintenanceRecordId,
    required MaintenanceCategory category,
    required Iterable<MaintenanceItemInput> items,
    DateTime? nextServiceDate,
    double? nextServiceOdometerKm,
  }) {
    final issues = <MaintenanceRuleIssue>{};
    for (final item in items) {
      if (item.name.trim().isEmpty) {
        issues.add(MaintenanceRuleIssue.itemNameRequired);
      }
      if (item.costSen < 0) {
        issues.add(MaintenanceRuleIssue.itemCostCannotBeNegative);
      }
    }
    if (nextServiceOdometerKm != null && nextServiceOdometerKm < 0) {
      issues.add(MaintenanceRuleIssue.nextServiceOdometerCannotBeNegative);
    }

    final hasReminderTarget =
        nextServiceDate != null || nextServiceOdometerKm != null;
    if (category != MaintenanceCategory.service && hasReminderTarget) {
      issues.add(MaintenanceRuleIssue.nonServiceCannotSetReminder);
    }

    final canCreateReminder =
        issues.isEmpty &&
        category == MaintenanceCategory.service &&
        hasReminderTarget;
    return MaintenancePlanResult(
      issues: Set.unmodifiable(issues),
      reminder: canCreateReminder
          ? ServiceReminderTarget(
              vehicleId: vehicleId,
              maintenanceRecordId: maintenanceRecordId,
              targetDate: nextServiceDate,
              targetOdometerKm: nextServiceOdometerKm,
            )
          : null,
    );
  }

  ServiceReminderEvaluation evaluateReminder({
    required ServiceReminderTarget reminder,
    required DateTime now,
    required double currentOdometerKm,
  }) {
    final reached = <ServiceReminderTrigger>{};
    final targetDate = reminder.targetDate;
    if (targetDate != null && !targetDate.isAfter(now)) {
      reached.add(ServiceReminderTrigger.date);
    }
    final targetOdometer = reminder.targetOdometerKm;
    if (targetOdometer != null && currentOdometerKm >= targetOdometer) {
      reached.add(ServiceReminderTrigger.mileage);
    }

    return ServiceReminderEvaluation(
      state: reached.isEmpty
          ? ServiceReminderState.upcoming
          : ServiceReminderState.due,
      reachedTriggers: Set.unmodifiable(reached),
    );
  }

  ServiceIntervalProgress? evaluateMileageProgress({
    required double serviceOdometerKm,
    required double currentOdometerKm,
    required double targetOdometerKm,
  }) {
    final interval = targetOdometerKm - serviceOdometerKm;
    if (interval <= 0) return null;
    final distanceTravelled = currentOdometerKm - serviceOdometerKm;
    final travelled = distanceTravelled.clamp(0, interval).toDouble();
    return ServiceIntervalProgress(
      travelledKm: travelled,
      intervalKm: interval,
      remainingKm: interval - travelled,
    );
  }
}
