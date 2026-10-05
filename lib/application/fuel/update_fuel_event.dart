import 'package:drift/drift.dart';

import '../../data/mappers/history_mappers.dart';
import '../../data/repositories/fuel_event_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../domain/odometer/odometer_timeline.dart';
import '../../domain/odometer/odometer_value.dart';
import '../../domain/validation/domain_validation.dart';
import 'create_fuel_event.dart';

class UpdateFuelEvent {
  const UpdateFuelEvent({
    required FuelEventRepository fuelEvents,
    required MaintenanceRepository maintenance,
    DomainValidator validator = const DomainValidator(),
    OdometerUpdated? onOdometerUpdated,
  }) : this._(fuelEvents, maintenance, validator, onOdometerUpdated);

  const UpdateFuelEvent._(
    this._fuelEvents,
    this._maintenance,
    this._validator,
    this._onOdometerUpdated,
  );

  final FuelEventRepository _fuelEvents;
  final MaintenanceRepository _maintenance;
  final DomainValidator _validator;
  final OdometerUpdated? _onOdometerUpdated;

  Future<int> call(int eventId, FuelEventInput input) async {
    final current = await _fuelEvents.findById(eventId);
    if (current == null || current.vehicleId != input.vehicleId) {
      throw const CreateFuelEventException(
        issue: CreateFuelEventIssue.odometerChronologyConflict,
        message: 'The fuel event no longer exists.',
      );
    }
    final brand = input.fuelBrand.trim();
    if (brand.isEmpty) {
      throw const CreateFuelEventException(
        issue: CreateFuelEventIssue.fuelBrandRequired,
        message: 'Choose a fuel brand.',
      );
    }
    if (!_validator
        .validateFuelValues(
          odometerKm: input.odometerKm,
          fuelVolumeMillilitres: input.fuelVolumeMillilitres,
          costSen: input.costSen,
        )
        .isValid) {
      throw const CreateFuelEventException(
        issue: CreateFuelEventIssue.invalidFuelValues,
        message: 'One or more fuel values are invalid.',
      );
    }
    final fuel = await _fuelEvents.findForVehicle(input.vehicleId);
    final maintenance = await _maintenance.findRecordsForVehicle(
      input.vehicleId,
    );
    final chronology = _validator.validateOdometerEdit(
      candidate: OdometerObservation(
        key: OdometerObservationKey(OdometerSource.fuel, eventId),
        vehicleId: input.vehicleId,
        occurredAt: input.occurredAt.toUtc(),
        odometerKm: input.odometerKm,
      ),
      existing: [
        ...fuel.map((event) => event.toOdometerObservation()),
        ...maintenance
            .map((record) => record.toOdometerObservation())
            .whereType<OdometerObservation>(),
      ],
    );
    if (!chronology.isValid) {
      final previous = chronology.previous;
      final next = chronology.next;
      throw CreateFuelEventException(
        issue: CreateFuelEventIssue.odometerChronologyConflict,
        message: previous != null && input.odometerKm < previous.odometerKm
            ? 'Odometer must be at least ${formatOdometerKm(previous.odometerKm)} km for this date and time.'
            : 'Odometer must not exceed ${formatOdometerKm(next!.odometerKm)} km for this date and time.',
        odometerValidation: chronology,
      );
    }
    await _fuelEvents.update(
      current.copyWith(
        occurredAt: input.occurredAt.toUtc(),
        odometerKm: input.odometerKm,
        fuelBrand: brand,
        fuelVolumeMillilitres: input.fuelVolumeMillilitres,
        costSen: input.costSen,
        isFullTank: input.isFullTank,
        tripDistanceMetres: Value(input.tripDistanceMetres),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await _onOdometerUpdated?.call(input.vehicleId);
    return eventId;
  }
}
