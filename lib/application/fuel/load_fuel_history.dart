import '../../data/mappers/history_mappers.dart';
import '../../data/repositories/fuel_event_repository.dart';
import '../../domain/fuel/fuel_cycle.dart';

class LoadFuelHistory {
  const LoadFuelHistory({
    required FuelEventRepository fuelEvents,
    FuelCycleEngine cycleEngine = const FuelCycleEngine(),
  }) : this._internal(fuelEvents, cycleEngine);

  const LoadFuelHistory._internal(this._fuelEvents, this._cycleEngine);

  final FuelEventRepository _fuelEvents;
  final FuelCycleEngine _cycleEngine;

  Future<FuelCycleBuildResult> call(int vehicleId) async {
    final events = await _fuelEvents.findForVehicle(vehicleId);
    return _cycleEngine.build(events.map((event) => event.toSnapshot()));
  }
}
