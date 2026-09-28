import 'package:car_tracking_app/domain/maintenance/maintenance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = MaintenanceDomainService();

  MaintenancePlanResult buildPlan({
    MaintenanceCategory category = MaintenanceCategory.service,
    List<MaintenanceItemInput> items = const [],
    DateTime? targetDate,
    int? targetOdometerKm,
  }) {
    return service.buildPlan(
      vehicleId: 1,
      maintenanceRecordId: 10,
      category: category,
      items: items,
      nextServiceDate: targetDate,
      nextServiceOdometerKm: targetOdometerKm,
    );
  }

  test(
    'manual items accept zero cost but reject negative cost or blank name',
    () {
      final valid = buildPlan(
        items: const [
          MaintenanceItemInput(name: 'Warranty replacement', costSen: 0),
        ],
      );
      expect(valid.isValid, isTrue);

      final invalid = buildPlan(
        items: const [MaintenanceItemInput(name: ' ', costSen: -1)],
      );
      expect(invalid.isValid, isFalse);
      expect(invalid.issues, contains(MaintenanceRuleIssue.itemNameRequired));
      expect(
        invalid.issues,
        contains(MaintenanceRuleIssue.itemCostCannotBeNegative),
      );
    },
  );

  test('Service can create a date-only whole-service reminder', () {
    final target = DateTime.utc(2027, 9, 10);
    final plan = buildPlan(targetDate: target);

    expect(plan.isValid, isTrue);
    expect(plan.reminder!.targetDate, target);
    expect(plan.reminder!.targetOdometerKm, isNull);
  });

  test('Service can create a mileage-only whole-service reminder', () {
    final plan = buildPlan(targetOdometerKm: 20000);

    expect(plan.isValid, isTrue);
    expect(plan.reminder!.targetDate, isNull);
    expect(plan.reminder!.targetOdometerKm, 20000);
  });

  test('Service without a target remains valid and creates no reminder', () {
    final plan = buildPlan();

    expect(plan.isValid, isTrue);
    expect(plan.reminder, isNull);
  });

  test('Repairs and Accessories cannot store service reminder targets', () {
    for (final category in [
      MaintenanceCategory.repairs,
      MaintenanceCategory.accessories,
    ]) {
      final plan = buildPlan(
        category: category,
        targetDate: DateTime.utc(2027, 9, 10),
        targetOdometerKm: 20000,
      );
      expect(plan.isValid, isFalse);
      expect(plan.reminder, isNull);
      expect(
        plan.issues,
        contains(MaintenanceRuleIssue.nonServiceCannotSetReminder),
      );
    }
  });

  test('date-first target makes the reminder due immediately', () {
    final reminder = buildPlan(
      targetDate: DateTime.utc(2027, 9, 10),
      targetOdometerKm: 20000,
    ).reminder!;
    final result = service.evaluateReminder(
      reminder: reminder,
      now: DateTime.utc(2027, 9, 10),
      currentOdometerKm: 15000,
    );

    expect(result.isDue, isTrue);
    expect(result.reachedTriggers, {ServiceReminderTrigger.date});
  });

  test('mileage-first target makes the reminder due immediately', () {
    final reminder = buildPlan(
      targetDate: DateTime.utc(2027, 9, 10),
      targetOdometerKm: 20000,
    ).reminder!;
    final result = service.evaluateReminder(
      reminder: reminder,
      now: DateTime.utc(2027, 8, 1),
      currentOdometerKm: 20000,
    );

    expect(result.isDue, isTrue);
    expect(result.reachedTriggers, {ServiceReminderTrigger.mileage});
  });

  test('both future targets keep the reminder upcoming', () {
    final reminder = buildPlan(
      targetDate: DateTime.utc(2027, 9, 10),
      targetOdometerKm: 20000,
    ).reminder!;
    final result = service.evaluateReminder(
      reminder: reminder,
      now: DateTime.utc(2027, 8, 1),
      currentOdometerKm: 15000,
    );

    expect(result.state, ServiceReminderState.upcoming);
    expect(result.reachedTriggers, isEmpty);
  });

  test('mileage status is re-evaluated from each new shared odometer', () {
    final reminder = buildPlan(targetOdometerKm: 20000).reminder!;

    expect(
      service
          .evaluateReminder(
            reminder: reminder,
            now: DateTime.utc(2027, 8, 1),
            currentOdometerKm: 19999,
          )
          .state,
      ServiceReminderState.upcoming,
    );
    expect(
      service
          .evaluateReminder(
            reminder: reminder,
            now: DateTime.utc(2027, 8, 1),
            currentOdometerKm: 20000,
          )
          .state,
      ServiceReminderState.due,
    );
  });

  test('both reached targets report both due triggers', () {
    final reminder = buildPlan(
      targetDate: DateTime.utc(2027, 9, 10),
      targetOdometerKm: 20000,
    ).reminder!;
    final result = service.evaluateReminder(
      reminder: reminder,
      now: DateTime.utc(2027, 9, 11),
      currentOdometerKm: 20001,
    );

    expect(result.isDue, isTrue);
    expect(result.reachedTriggers, {
      ServiceReminderTrigger.date,
      ServiceReminderTrigger.mileage,
    });
  });
}
