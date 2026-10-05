import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import '../../data/mappers/history_mappers.dart';
import '../../data/repositories/fuel_event_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../domain/odometer/odometer_timeline.dart';
import '../../domain/odometer/odometer_value.dart';
import '../../domain/validation/domain_validation.dart';

typedef OdometerUpdated = Future<void> Function(int vehicleId);

class FuelEventInput {
  const FuelEventInput({
    required this.vehicleId,
    required this.occurredAt,
    required this.odometerKm,
    required this.fuelBrand,
    required this.fuelVolumeMillilitres,
    required this.costSen,
    required this.isFullTank,
    this.tripDistanceMetres,
  });

  final int vehicleId;
  final DateTime occurredAt;
  final double odometerKm;
  final String fuelBrand;
  final int fuelVolumeMillilitres;
  final int costSen;
  final bool isFullTank;
  final int? tripDistanceMetres;
}

enum CreateFuelEventIssue {
  fuelBrandRequired,
  invalidFuelValues,
  odometerChronologyConflict,
}

class CreateFuelEventException implements Exception {
  const CreateFuelEventException({
    required this.issue,
    required this.message,
    this.odometerValidation,
  });

  final CreateFuelEventIssue issue;
  final String message;
  final OdometerValidationResult? odometerValidation;

  @override
  String toString() => 'CreateFuelEventException: $message';
}

class CreateFuelEvent {
  const CreateFuelEvent({
    required FuelEventRepository fuelEvents,
    required MaintenanceRepository maintenance,
    DomainValidator validator = const DomainValidator(),
    OdometerUpdated? onOdometerUpdated,
  }) : this._internal(fuelEvents, maintenance, validator, onOdometerUpdated);

  const CreateFuelEvent._internal(
    this._fuelEvents,
    this._maintenance,
    this._validator,
    this._onOdometerUpdated,
  );

  final FuelEventRepository _fuelEvents;
  final MaintenanceRepository _maintenance;
  final DomainValidator _validator;
  final OdometerUpdated? _onOdometerUpdated;

  Future<int> call(FuelEventInput input) async {
    final brand = input.fuelBrand.trim();
    if (brand.isEmpty) {
      throw const CreateFuelEventException(
        issue: CreateFuelEventIssue.fuelBrandRequired,
        message: 'Choose a fuel brand.',
      );
    }

    final valueValidation = _validator.validateFuelValues(
      odometerKm: input.odometerKm,
      fuelVolumeMillilitres: input.fuelVolumeMillilitres,
      costSen: input.costSen,
    );
    if (!valueValidation.isValid) {
      throw const CreateFuelEventException(
        issue: CreateFuelEventIssue.invalidFuelValues,
        message: 'One or more fuel values are invalid.',
      );
    }

    final existingFuel = await _fuelEvents.findForVehicle(input.vehicleId);
    final existingMaintenance = await _maintenance.findRecordsForVehicle(
      input.vehicleId,
    );
    final existingObservations = <OdometerObservation>[
      ...existingFuel.map((event) => event.toOdometerObservation()),
      ...existingMaintenance
          .map((record) => record.toOdometerObservation())
          .whereType<OdometerObservation>(),
    ];
    final chronology = _validator.validateOdometerInsert(
      candidate: OdometerObservation(
        key: const OdometerObservationKey(
          OdometerSource.fuel,
          0x7fffffffffffffff,
        ),
        vehicleId: input.vehicleId,
        occurredAt: input.occurredAt.toUtc(),
        odometerKm: input.odometerKm,
      ),
      existing: existingObservations,
    );
    if (!chronology.isValid) {
      throw CreateFuelEventException(
        issue: CreateFuelEventIssue.odometerChronologyConflict,
        message: _chronologyMessage(chronology),
        odometerValidation: chronology,
      );
    }

    final id = await _fuelEvents.create(
      FuelEventsCompanion.insert(
        vehicleId: input.vehicleId,
        occurredAt: input.occurredAt.toUtc(),
        odometerKm: input.odometerKm,
        fuelBrand: brand,
        fuelVolumeMillilitres: input.fuelVolumeMillilitres,
        costSen: input.costSen,
        isFullTank: input.isFullTank,
        tripDistanceMetres: Value(input.tripDistanceMetres),
      ),
    );
    await _onOdometerUpdated?.call(input.vehicleId);
    return id;
  }

  /// Compares Trip B with the odometer distance from the preceding Full event.
  /// Returns null until a Full starting reference exists.
  Future<int?> tripBDifferenceMetres({
    required int vehicleId,
    required DateTime occurredAt,
    required double odometerKm,
    required int tripDistanceMetres,
  }) async {
    final events = await _fuelEvents.findForVehicle(vehicleId);
    FuelEvent? openingFull;
    for (final event in events) {
      if (event.occurredAt.isAfter(occurredAt.toUtc())) break;
      if (event.isFullTank) openingFull = event;
    }
    if (openingFull == null) return null;

    return _validator.absoluteTripDifferenceMetres(
      odometerDistanceKm: odometerKm - openingFull.odometerKm,
      tripDistanceMetres: tripDistanceMetres,
    );
  }

  String _chronologyMessage(OdometerValidationResult result) {
    if (result.issues.contains(OdometerValidationIssue.belowPreviousReading) &&
        result.previous != null) {
      return 'Odometer must be at least ${formatOdometerKm(result.previous!.odometerKm)} km '
          'for this date and time.';
    }
    if (result.issues.contains(OdometerValidationIssue.aboveNextReading) &&
        result.next != null) {
      return 'Odometer must not exceed ${formatOdometerKm(result.next!.odometerKm)} km '
          'for this date and time.';
    }
    return 'This odometer reading conflicts with the vehicle history.';
  }
}
