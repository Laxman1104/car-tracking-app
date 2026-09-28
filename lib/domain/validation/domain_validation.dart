import '../odometer/odometer_timeline.dart';

enum DomainValidationIssue {
  odometerCannotBeNegative,
  fuelVolumeMustBePositive,
  fuelCostCannotBeNegative,
  maintenanceCostCannotBeNegative,
}

class FuelValueValidation {
  const FuelValueValidation({
    required this.issues,
    required this.showZeroCostCaution,
  });

  final Set<DomainValidationIssue> issues;
  final bool showZeroCostCaution;

  bool get isValid => issues.isEmpty;
}

class MaintenanceValueValidation {
  const MaintenanceValueValidation({required this.issues});

  final Set<DomainValidationIssue> issues;

  bool get isValid => issues.isEmpty;
}

class DomainValidator {
  const DomainValidator({
    this.odometerTimelineEngine = const OdometerTimelineEngine(),
  });

  final OdometerTimelineEngine odometerTimelineEngine;

  FuelValueValidation validateFuelValues({
    required int odometerKm,
    required int fuelVolumeMillilitres,
    required int costSen,
  }) {
    final issues = <DomainValidationIssue>{};
    if (odometerKm < 0) {
      issues.add(DomainValidationIssue.odometerCannotBeNegative);
    }
    if (fuelVolumeMillilitres <= 0) {
      issues.add(DomainValidationIssue.fuelVolumeMustBePositive);
    }
    if (costSen < 0) {
      issues.add(DomainValidationIssue.fuelCostCannotBeNegative);
    }

    return FuelValueValidation(
      issues: Set.unmodifiable(issues),
      showZeroCostCaution: costSen == 0,
    );
  }

  MaintenanceValueValidation validateMaintenanceValues({
    required int odometerKm,
    required int totalCostSen,
  }) {
    final issues = <DomainValidationIssue>{};
    if (odometerKm < 0) {
      issues.add(DomainValidationIssue.odometerCannotBeNegative);
    }
    if (totalCostSen < 0) {
      issues.add(DomainValidationIssue.maintenanceCostCannotBeNegative);
    }
    return MaintenanceValueValidation(issues: Set.unmodifiable(issues));
  }

  OdometerValidationResult validateOdometerInsert({
    required OdometerObservation candidate,
    required Iterable<OdometerObservation> existing,
  }) {
    return odometerTimelineEngine.validateInsert(
      candidate: candidate,
      existing: existing,
    );
  }

  OdometerValidationResult validateOdometerEdit({
    required OdometerObservation candidate,
    required Iterable<OdometerObservation> existing,
  }) {
    return odometerTimelineEngine.validateEdit(
      candidate: candidate,
      existing: existing,
    );
  }

  /// Returns the absolute Trip B difference in metres, or null when omitted.
  int? absoluteTripDifferenceMetres({
    required int odometerDistanceKm,
    required int? tripDistanceMetres,
  }) {
    if (tripDistanceMetres == null) return null;
    final odometerDistanceMetres = odometerDistanceKm * 1000;
    return (tripDistanceMetres - odometerDistanceMetres).abs();
  }
}
