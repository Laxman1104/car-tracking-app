import '../../data/repositories/fuel_event_repository.dart';
import 'create_fuel_event.dart';

class DeleteFuelEvent {
  const DeleteFuelEvent({
    required FuelEventRepository fuelEvents,
    OdometerUpdated? onOdometerUpdated,
  }) : this._(fuelEvents, onOdometerUpdated);

  const DeleteFuelEvent._(this._fuelEvents, this._onOdometerUpdated);

  final FuelEventRepository _fuelEvents;
  final OdometerUpdated? _onOdometerUpdated;

  Future<void> call(int eventId) async {
    final event = await _fuelEvents.findById(eventId);
    await _fuelEvents.deleteById(eventId);
    if (event != null) await _onOdometerUpdated?.call(event.vehicleId);
  }
}
