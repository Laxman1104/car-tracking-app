import '../../data/repositories/fuel_event_repository.dart';

class DeleteFuelEvent {
  const DeleteFuelEvent({required FuelEventRepository fuelEvents})
    : this._(fuelEvents);

  const DeleteFuelEvent._(this._fuelEvents);

  final FuelEventRepository _fuelEvents;

  Future<void> call(int eventId) async {
    await _fuelEvents.deleteById(eventId);
  }
}
