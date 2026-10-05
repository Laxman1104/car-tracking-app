import '../../domain/fuel/fuel_cycle.dart';
import '../../domain/maintenance/maintenance.dart';
import '../../domain/odometer/odometer_timeline.dart';
import '../database/app_database.dart';

extension FuelEventDomainMapping on FuelEvent {
  FuelEventSnapshot toSnapshot() {
    return FuelEventSnapshot(
      id: id,
      vehicleId: vehicleId,
      occurredAt: occurredAt,
      odometerKm: odometerKm,
      fuelBrand: fuelBrand,
      fuelVolumeMillilitres: fuelVolumeMillilitres,
      costSen: costSen,
      isFullTank: isFullTank,
      tripDistanceMetres: tripDistanceMetres,
    );
  }

  OdometerObservation toOdometerObservation() {
    return OdometerObservation(
      key: OdometerObservationKey(OdometerSource.fuel, id),
      vehicleId: vehicleId,
      occurredAt: occurredAt,
      odometerKm: odometerKm,
    );
  }
}

extension MaintenanceRecordDomainMapping on MaintenanceRecord {
  OdometerObservation? toOdometerObservation() {
    if (category == MaintenanceCategory.accessories) return null;
    return OdometerObservation(
      key: OdometerObservationKey(OdometerSource.maintenance, id),
      vehicleId: vehicleId,
      occurredAt: occurredAt,
      odometerKm: odometerKm,
    );
  }
}

extension ServiceReminderDomainMapping on ServiceReminder {
  ServiceReminderTarget toTarget() {
    return ServiceReminderTarget(
      vehicleId: vehicleId,
      maintenanceRecordId: maintenanceRecordId,
      targetDate: targetDate,
      targetOdometerKm: targetOdometerKm,
    );
  }
}
