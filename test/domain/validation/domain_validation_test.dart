import 'package:car_tracking_app/domain/odometer/odometer_timeline.dart';
import 'package:car_tracking_app/domain/validation/domain_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = DomainValidator();

  test('fuel litres must be positive', () {
    for (final volume in [0, -1]) {
      final result = validator.validateFuelValues(
        odometerKm: 100,
        fuelVolumeMillilitres: volume,
        costSen: 100,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues,
        contains(DomainValidationIssue.fuelVolumeMustBePositive),
      );
    }
  });

  test('fuel cost cannot be negative but zero is valid with caution', () {
    final negative = validator.validateFuelValues(
      odometerKm: 100,
      fuelVolumeMillilitres: 1000,
      costSen: -1,
    );
    expect(negative.isValid, isFalse);
    expect(
      negative.issues,
      contains(DomainValidationIssue.fuelCostCannotBeNegative),
    );

    final zero = validator.validateFuelValues(
      odometerKm: 100,
      fuelVolumeMillilitres: 1000,
      costSen: 0,
    );
    expect(zero.isValid, isTrue);
    expect(zero.showZeroCostCaution, isTrue);

    final positive = validator.validateFuelValues(
      odometerKm: 100,
      fuelVolumeMillilitres: 1000,
      costSen: 1,
    );
    expect(positive.isValid, isTrue);
    expect(positive.showZeroCostCaution, isFalse);
  });

  test('maintenance cost cannot be negative but zero has no warning state', () {
    final zero = validator.validateMaintenanceValues(
      odometerKm: 100,
      totalCostSen: 0,
    );
    expect(zero.isValid, isTrue);
    expect(zero.issues, isEmpty);

    final negative = validator.validateMaintenanceValues(
      odometerKm: 100,
      totalCostSen: -1,
    );
    expect(negative.isValid, isFalse);
    expect(
      negative.issues,
      contains(DomainValidationIssue.maintenanceCostCannotBeNegative),
    );
  });

  test('negative odometer is rejected for both entry types', () {
    expect(
      validator
          .validateFuelValues(
            odometerKm: -1,
            fuelVolumeMillilitres: 1000,
            costSen: 100,
          )
          .issues,
      contains(DomainValidationIssue.odometerCannotBeNegative),
    );
    expect(
      validator
          .validateMaintenanceValues(odometerKm: -1, totalCostSen: 0)
          .issues,
      contains(DomainValidationIssue.odometerCannotBeNegative),
    );
  });

  test('Trip B helper returns an absolute non-blocking difference', () {
    expect(
      validator.absoluteTripDifferenceMetres(
        odometerDistanceKm: 430,
        tripDistanceMetres: 434000,
      ),
      4000,
    );
    expect(
      validator.absoluteTripDifferenceMetres(
        odometerDistanceKm: 430,
        tripDistanceMetres: 426000,
      ),
      4000,
    );
    expect(
      validator.absoluteTripDifferenceMetres(
        odometerDistanceKm: 430,
        tripDistanceMetres: null,
      ),
      isNull,
    );
  });

  test('central odometer validation delegates insert and edit rules', () {
    final first = OdometerObservation(
      key: const OdometerObservationKey(OdometerSource.fuel, 1),
      vehicleId: 1,
      occurredAt: DateTime.utc(2027, 9, 10),
      odometerKm: 10000,
    );
    final last = OdometerObservation(
      key: const OdometerObservationKey(OdometerSource.maintenance, 2),
      vehicleId: 1,
      occurredAt: DateTime.utc(2027, 9, 12),
      odometerKm: 10250,
    );
    final invalid = OdometerObservation(
      key: const OdometerObservationKey(OdometerSource.fuel, 3),
      vehicleId: 1,
      occurredAt: DateTime.utc(2027, 9, 11),
      odometerKm: 10400,
    );

    expect(
      validator
          .validateOdometerInsert(candidate: invalid, existing: [first, last])
          .issues,
      contains(OdometerValidationIssue.aboveNextReading),
    );
    expect(
      validator
          .validateOdometerEdit(candidate: last, existing: [first, last])
          .isValid,
      isTrue,
    );
  });
}
