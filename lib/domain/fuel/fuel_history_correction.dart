import 'fuel_cycle.dart';

class FuelHistoryCorrectionException implements Exception {
  const FuelHistoryCorrectionException(this.message);

  final String message;

  @override
  String toString() => 'FuelHistoryCorrectionException: $message';
}

class FuelHistoryCorrectionEngine {
  const FuelHistoryCorrectionEngine({
    this.fuelCycleEngine = const FuelCycleEngine(),
  });

  final FuelCycleEngine fuelCycleEngine;

  FuelCycleBuildResult rebuild(Iterable<FuelEventSnapshot> events) {
    return fuelCycleEngine.build(events);
  }

  FuelCycleBuildResult editEvent({
    required Iterable<FuelEventSnapshot> events,
    required FuelEventSnapshot replacement,
  }) {
    final updated = events.toList();
    final matchingIndexes = <int>[];
    for (var index = 0; index < updated.length; index++) {
      final event = updated[index];
      if (event.id == replacement.id &&
          event.vehicleId == replacement.vehicleId) {
        matchingIndexes.add(index);
      }
    }
    if (matchingIndexes.length != 1) {
      throw FuelHistoryCorrectionException(
        matchingIndexes.isEmpty
            ? 'The fuel event being edited does not exist.'
            : 'Fuel event identity is not unique.',
      );
    }

    updated[matchingIndexes.single] = replacement;
    return fuelCycleEngine.build(updated);
  }
}
